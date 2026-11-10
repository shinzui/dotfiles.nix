#!/usr/bin/env python3
"""Evidence for moving the Rei/Mori databases between hosts.

Collects and verifies evidence only. It never stops services, changes schemas,
restores databases, overwrites targets, or opens ingress. Every database
session runs with default_transaction_read_only=on.

  inventory      databases, roles, tablespaces, extensions, writers and
                 activity of one cluster, as private JSON
  fingerprint    exact row counts and SHA-256 digests of every user table,
                 sequence state, large objects, schema and database metadata
                 of selected databases, read in one snapshot per database
  sqlite         the same for a SQLite file (Mina's tracking store)
  compare        compare two fingerprints; exit 1 on any difference
  conflicts      exit 1 if any selected database already exists on a cluster
  manifest       seal a bundle directory: per-file SHA-256, then a COMPLETE marker
  verify-bundle  recompute a sealed bundle; exit 4 if it is incomplete

Database operations need an explicit --socket and --role. Output goes to an
--out file that must not exist, inside a directory only this user can read.
The terminal shows counts, statuses and object names, never row data.

Exit status: 0 pass, 1 difference or failed verification, 2 usage,
3 refused as unsafe, 4 incomplete bundle.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import sqlite3
import stat
import subprocess
import sys
import tempfile

MISMATCH, USAGE, REFUSED, INCOMPLETE = 1, 2, 3, 4
SEPARATOR = '\x01END\x01'  # row_to_json escapes control characters, so no row line can start with this
SESSION_OPTIONS = ' '.join('-c ' + setting for setting in (
    'default_transaction_read_only=on', 'TimeZone=UTC', 'DateStyle=ISO,YMD', 'IntervalStyle=postgres',
    'extra_float_digits=3', 'bytea_output=hex', 'search_path=pg_catalog', 'statement_timeout=0',
    'lc_messages=C',
))
MANIFEST, COMPLETE = 'MANIFEST.json', 'COMPLETE'


class Refused(Exception):
    pass


class Failed(Exception):
    pass


# --- output -----------------------------------------------------------------

def private_output(path):
    out = Path(path)
    parent = out.parent.resolve(strict=True)
    info = parent.stat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) & 0o077:
        raise Refused('output directory must be owned by you with mode 0700: ' + str(parent))
    if out.exists() or out.is_symlink():
        raise Refused('refusing to replace existing evidence: ' + str(out))
    return out


def write_json(out, value):
    fd = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write('\n')


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')


# --- PostgreSQL access ------------------------------------------------------

class Cluster:
    def __init__(self, psql, socket, port, user):
        self.psql = psql
        self.socket = socket
        self.port = str(port)
        self.user = user

    def env(self):
        env = {k: v for k, v in os.environ.items() if not k.startswith('PG')}
        env['PGOPTIONS'] = SESSION_OPTIONS
        env['PGAPPNAME'] = 'rei-mori-migration'
        env['PGCONNECT_TIMEOUT'] = '5'
        return env

    def base(self, database):
        return [*self.psql, '-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1',
                '-h', self.socket, '-p', self.port, '-U', self.user, '-d', database]

    def json_rows(self, database, sql):
        """Run a query returning one json column; return the decoded values."""
        result = subprocess.run(self.base(database) + ['-c', sql], capture_output=True, text=True, env=self.env())
        if result.returncode:
            raise Failed('psql failed on ' + database + ': ' + result.stderr.strip())
        return [json.loads(line) for line in result.stdout.splitlines() if line]

    def json_one(self, database, sql):
        """Run a query returning one json value; json_agg output may span lines."""
        result = subprocess.run(self.base(database) + ['-c', sql], capture_output=True, text=True, env=self.env())
        if result.returncode:
            raise Failed('psql failed on ' + database + ': ' + result.stderr.strip())
        return json.loads(result.stdout)

    def stream_copies(self, database, statements, capture=()):
        """Run COPY (statement) TO STDOUT for each (key, statement) in one
        repeatable-read snapshot; return (key, row count, sha256, lines) with
        the raw lines kept only for keys in capture."""
        with tempfile.NamedTemporaryFile('w', suffix='.sql', delete=False) as script:
            os.chmod(script.name, 0o600)
            script.write('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;\n')
            for index, (_, statement) in enumerate(statements):
                script.write('COPY (' + statement + ') TO STDOUT;\n')
                script.write('\\echo ' + SEPARATOR + str(index) + '\n')
            script.write('COMMIT;\n')
        try:
            process = subprocess.Popen(self.base(database) + ['-f', script.name], stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, env=self.env())
            digest, count, results, kept = hashlib.sha256(), 0, [], []
            marker = SEPARATOR.encode()
            for line in process.stdout:
                if line.startswith(marker):
                    index = int(line[len(marker):].strip())
                    results.append((statements[index][0], count, digest.hexdigest(), kept))
                    digest, count, kept = hashlib.sha256(), 0, []
                else:
                    digest.update(line)
                    count += 1
                    if statements[len(results)][0] in capture:
                        kept.append(line.decode())
            stderr = process.stderr.read().decode(errors='replace')
            if process.wait():
                raise Failed('snapshot read failed on ' + database + ': ' + stderr.strip())
            if len(results) != len(statements):
                raise Failed('snapshot read of ' + database + ' ended early')
            return results
        finally:
            os.unlink(script.name)


def server_identity(cluster):
    return cluster.json_one('postgres', """
        SELECT json_build_object(
          'system_identifier', (SELECT system_identifier::text FROM pg_control_system()),
          'server_version', current_setting('server_version'),
          'data_directory', current_setting('data_directory'),
          'port', current_setting('port'),
          'listen_addresses', current_setting('listen_addresses'),
          'archive_mode', current_setting('archive_mode'),
          'wal_level', current_setting('wal_level'))""")


def check_identity(identity, args):
    if args.expect_system_identifier and identity['system_identifier'] != args.expect_system_identifier:
        raise Refused('wrong cluster: system identifier ' + identity['system_identifier']
                      + ' is not the expected ' + args.expect_system_identifier)
    if args.expect_data_directory and identity['data_directory'] != args.expect_data_directory:
        raise Refused('wrong cluster: data directory ' + identity['data_directory']
                      + ' is not the expected ' + args.expect_data_directory)


# --- inventory --------------------------------------------------------------

CLUSTER_INVENTORY = """
SELECT json_build_object(
  'databases', (SELECT json_agg(json_build_object(
      'name', d.datname, 'owner', pg_get_userbyid(d.datdba), 'encoding', pg_encoding_to_char(d.encoding),
      'collate', d.datcollate, 'ctype', d.datctype, 'locale_provider', d.datlocprovider,
      'allow_connections', d.datallowconn, 'connection_limit', d.datconnlimit,
      'tablespace', t.spcname, 'size_bytes', pg_database_size(d.oid),
      'settings', (SELECT json_agg(s.setconfig) FROM pg_db_role_setting s WHERE s.setdatabase = d.oid),
      'xact_commit', sd.xact_commit, 'xact_rollback', sd.xact_rollback,
      'stats_reset', sd.stats_reset) ORDER BY d.datname)
    FROM pg_database d JOIN pg_tablespace t ON t.oid = d.dattablespace
    LEFT JOIN pg_stat_database sd ON sd.datid = d.oid WHERE NOT d.datistemplate),
  'roles', (SELECT json_agg(json_build_object(
      'name', r.rolname, 'superuser', r.rolsuper, 'login', r.rolcanlogin, 'createdb', r.rolcreatedb,
      'createrole', r.rolcreaterole, 'replication', r.rolreplication, 'bypassrls', r.rolbypassrls,
      'has_password', r.rolpassword IS NOT NULL,
      'member_of', (SELECT json_agg(g.rolname ORDER BY g.rolname) FROM pg_auth_members m
                    JOIN pg_roles g ON g.oid = m.roleid WHERE m.member = r.oid),
      'settings', (SELECT json_agg(s.setconfig) FROM pg_db_role_setting s WHERE s.setrole = r.oid))
      ORDER BY r.rolname)
    FROM pg_authid r WHERE r.rolname !~ '^pg_'),
  'tablespaces', (SELECT json_agg(json_build_object('name', spcname, 'location', pg_tablespace_location(oid)))
    FROM pg_tablespace),
  'activity', (SELECT json_agg(json_build_object('database', datname, 'user', usename,
      'application', application_name, 'state', state, 'backend_type', backend_type, 'count', n))
    FROM (SELECT datname, usename, application_name, state, backend_type, count(*) AS n
          FROM pg_stat_activity WHERE pid <> pg_backend_pid()
          GROUP BY 1, 2, 3, 4, 5 ORDER BY 1, 2, 3, 4, 5) a),
  'prepared_transactions', (SELECT count(*) FROM pg_prepared_xacts),
  'replication_slots', (SELECT json_agg(json_build_object('name', slot_name, 'type', slot_type,
      'database', database, 'active', active)) FROM pg_replication_slots),
  'shared_preload_libraries', current_setting('shared_preload_libraries'))"""

DATABASE_INVENTORY = """
SELECT json_build_object(
  'extensions', (SELECT json_agg(json_build_object('name', extname, 'version', extversion,
      'schema', extnamespace::regnamespace::text, 'config_tables', extconfig::regclass[]::text[])
      ORDER BY extname) FROM pg_extension),
  'schemas', (SELECT json_agg(json_build_object('name', nspname, 'owner', pg_get_userbyid(nspowner))
      ORDER BY nspname) FROM pg_namespace
      WHERE nspname !~ '^pg_' AND nspname <> 'information_schema'),
  'relations', (SELECT json_agg(json_build_object('schema', n.nspname, 'name', c.relname,
      'kind', c.relkind, 'partition', c.relispartition, 'owner', pg_get_userbyid(c.relowner),
      'estimated_rows', c.reltuples, 'size_bytes', pg_total_relation_size(c.oid),
      'extension_member', EXISTS (SELECT 1 FROM pg_depend d WHERE d.classid = 'pg_class'::regclass
                                  AND d.objid = c.oid AND d.deptype = 'e'))
      ORDER BY n.nspname, c.relname)
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind IN ('r', 'p', 'S', 'm', 'f') AND n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'),
  'large_objects', (SELECT count(*) FROM pg_largeobject_metadata),
  'publications', (SELECT json_agg(pubname) FROM pg_publication),
  'subscriptions', (SELECT json_agg(subname) FROM pg_subscription WHERE subdbid =
      (SELECT oid FROM pg_database WHERE datname = current_database())),
  'event_triggers', (SELECT json_agg(evtname) FROM pg_event_trigger))"""


def command_inventory(args):
    out = private_output(args.out)
    cluster = Cluster(args.psql, args.socket, args.port, args.user)
    identity = server_identity(cluster)
    check_identity(identity, args)
    inventory = cluster.json_one('postgres', CLUSTER_INVENTORY)
    databases = {}
    for database in inventory['databases'] or []:
        if not database['allow_connections']:
            databases[database['name']] = {'skipped': 'connections not allowed'}
            continue
        databases[database['name']] = cluster.json_one(database['name'], DATABASE_INVENTORY)
    write_json(out, {'kind': 'inventory', 'role': args.role, 'collected_at': now(), 'server': identity,
                     'cluster': inventory, 'per_database': databases})
    print('inventory [' + args.role + '] cluster ' + identity['system_identifier'] + ' (PostgreSQL '
          + identity['server_version'] + '): ' + str(len(databases)) + ' databases, '
          + str(len(inventory['roles'] or [])) + ' roles, ' + str(inventory['prepared_transactions'])
          + ' prepared transactions, ' + str(sum(a['count'] for a in inventory['activity'] or [])
                                              ) + ' other sessions')
    for name, database in sorted(databases.items()):
        relations = database.get('relations') or []
        print('  ' + name + ': ' + (database.get('skipped') or (
            str(sum(1 for r in relations if r['kind'] == 'r')) + ' tables, '
            + str(sum(1 for r in relations if r['kind'] == 'S')) + ' sequences, '
            + str(database['large_objects']) + ' large objects, extensions '
            + ', '.join(e['name'] for e in database['extensions'] or []))))
    print('wrote ' + str(out))
    return 0


# --- fingerprint ------------------------------------------------------------

USER_RELATIONS = """
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema'"""

# Leaf tables only: a partitioned parent has no rows of its own, so scanning it
# would count each partition's rows twice.
TABLE_STATEMENTS = """
SELECT json_build_object('key', n.nspname || '.' || c.relname, 'statement',
  format('SELECT row_to_json(t)::text AS r FROM ONLY %I.%I AS t ORDER BY row_to_json(t)::text COLLATE "C"',
         n.nspname, c.relname))
""" + USER_RELATIONS + " AND c.relkind = 'r' ORDER BY n.nspname, c.relname"

SEQUENCE_STATEMENTS = """
SELECT json_build_object('key', n.nspname || '.' || c.relname, 'statement',
  format('SELECT json_build_object(''last_value'', last_value, ''is_called'', is_called)::text FROM %I.%I',
         n.nspname, c.relname))
""" + USER_RELATIONS + " AND c.relkind = 'S' ORDER BY n.nspname, c.relname"

LARGE_OBJECTS = ("SELECT json_build_object('oid', oid, 'owner', pg_get_userbyid(lomowner), 'acl', lomacl,"
                 " 'sha256', encode(sha256(lo_get(oid)), 'hex'))::text FROM pg_largeobject_metadata ORDER BY oid")

# Definitions of every user object that is not an extension member, one text
# line each, so a changed column, index, constraint, function, trigger, view,
# owner, or grant changes the schema digest.
SCHEMA_OBJECTS = """
WITH ext AS (SELECT classid, objid FROM pg_depend WHERE deptype = 'e'),
user_ns AS (SELECT oid, nspname FROM pg_namespace WHERE nspname !~ '^pg_' AND nspname <> 'information_schema')
SELECT line FROM (
  SELECT 'schema ' || nspname || ' owner ' || pg_get_userbyid(nspowner) || ' acl ' || coalesce(nspacl::text, '')
    AS line FROM pg_namespace WHERE oid IN (SELECT oid FROM user_ns)
  UNION ALL
  SELECT 'relation ' || n.nspname || '.' || c.relname || ' kind ' || c.relkind::text || ' owner '
    || pg_get_userbyid(c.relowner) || ' acl ' || coalesce(c.relacl::text, '') || ' persistence '
    || c.relpersistence::text || ' partbound ' || coalesce(pg_get_expr(c.relpartbound, c.oid), '')
    FROM pg_class c JOIN user_ns n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f', 'c')
      AND NOT EXISTS (SELECT 1 FROM ext WHERE classid = 'pg_class'::regclass AND objid = c.oid)
  UNION ALL
  SELECT 'column ' || n.nspname || '.' || c.relname || '.' || a.attname || ' ' || format_type(a.atttypid, a.atttypmod)
    || ' notnull ' || a.attnotnull || ' default ' || coalesce(pg_get_expr(ad.adbin, ad.adrelid), '')
    || ' identity ' || a.attidentity::text || ' generated ' || a.attgenerated::text || ' acl ' || coalesce(a.attacl::text, '')
    FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN user_ns n ON n.oid = c.relnamespace
    LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
    WHERE a.attnum > 0 AND NOT a.attisdropped AND c.relkind IN ('r', 'p', 'v', 'm', 'f', 'c')
      AND NOT EXISTS (SELECT 1 FROM ext WHERE classid = 'pg_class'::regclass AND objid = c.oid)
  UNION ALL
  SELECT 'index ' || pg_get_indexdef(i.indexrelid) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
    JOIN user_ns n ON n.oid = c.relnamespace
  UNION ALL
  SELECT 'constraint ' || conrelid::regclass::text || ' ' || conname || ' ' || pg_get_constraintdef(oid)
    FROM pg_constraint WHERE connamespace IN (SELECT oid FROM user_ns)
  UNION ALL
  SELECT 'function ' || p.oid::regprocedure::text || ' owner ' || pg_get_userbyid(p.proowner) || ' acl '
    || coalesce(p.proacl::text, '') || ' md5 ' || md5(CASE WHEN p.prokind IN ('f', 'p')
         THEN pg_get_functiondef(p.oid) ELSE p.prosrc END)
    FROM pg_proc p WHERE p.pronamespace IN (SELECT oid FROM user_ns)
      AND NOT EXISTS (SELECT 1 FROM ext WHERE classid = 'pg_proc'::regclass AND objid = p.oid)
  UNION ALL
  SELECT 'view ' || c.oid::regclass::text || ' ' || md5(pg_get_viewdef(c.oid))
    FROM pg_class c WHERE c.relkind IN ('v', 'm') AND c.relnamespace IN (SELECT oid FROM user_ns)
  UNION ALL
  SELECT 'trigger ' || pg_get_triggerdef(t.oid) FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
    WHERE NOT t.tgisinternal AND c.relnamespace IN (SELECT oid FROM user_ns)
  UNION ALL
  SELECT 'type ' || t.oid::regtype::text || ' ' || t.typtype::text || ' owner ' || pg_get_userbyid(t.typowner)
    || ' labels ' || coalesce((SELECT string_agg(enumlabel, ',' ORDER BY enumsortorder) FROM pg_enum
                               WHERE enumtypid = t.oid), '')
    FROM pg_type t WHERE t.typnamespace IN (SELECT oid FROM user_ns) AND t.typtype IN ('e', 'd', 'c', 'r')
      AND NOT EXISTS (SELECT 1 FROM pg_class c WHERE c.oid = t.typrelid AND c.relkind <> 'c')
      AND NOT EXISTS (SELECT 1 FROM ext WHERE classid = 'pg_type'::regclass AND objid = t.oid)
  UNION ALL
  SELECT 'extension ' || extname || ' ' || extversion || ' schema ' || extnamespace::regnamespace::text
    FROM pg_extension
  UNION ALL
  SELECT 'default_acl ' || coalesce(pg_get_userbyid(defaclrole), '') || ' ' || defaclobjtype::text || ' '
    || coalesce(defaclnamespace::regnamespace::text, '') || ' ' || defaclacl::text FROM pg_default_acl
) objects ORDER BY line COLLATE "C"
"""

DATABASE_METADATA = """
SELECT json_build_object('owner', pg_get_userbyid(d.datdba), 'encoding', pg_encoding_to_char(d.encoding),
  'collate', d.datcollate, 'ctype', d.datctype, 'connection_limit', d.datconnlimit,
  'allow_connections', d.datallowconn, 'acl', d.datacl::text,
  'settings', (SELECT json_agg(s.setconfig ORDER BY s.setrole) FROM pg_db_role_setting s
               WHERE s.setdatabase = d.oid))
FROM pg_database d WHERE d.datname = current_database()"""


def fingerprint_database(cluster, database):
    tables = [(row['key'], row['statement']) for row in cluster.json_rows(database, TABLE_STATEMENTS)]
    sequences = [(row['key'], row['statement']) for row in cluster.json_rows(database, SEQUENCE_STATEMENTS)]
    statements = [('table:' + k, s) for k, s in tables] + [('sequence:' + k, s) for k, s in sequences]
    statements.append(('large_objects', LARGE_OBJECTS))
    statements.append(('schema', SCHEMA_OBJECTS))
    # Sequence values are state, not content: record them exactly, from the
    # same snapshot as the rows.
    sequence_keys = {'sequence:' + k for k, _ in sequences}
    results = cluster.stream_copies(database, statements, capture=sequence_keys)
    table_results, sequence_values, extra = {}, {}, {}
    for key, count, digest, lines in results:
        if key.startswith('table:'):
            table_results[key[len('table:'):]] = {'rows': count, 'sha256': digest}
        elif key in sequence_keys:
            sequence_values[key[len('sequence:'):]] = json.loads(lines[0]) if count == 1 else None
        else:
            extra[key] = {'rows': count, 'sha256': digest}
    return {
        'metadata': cluster.json_one(database, DATABASE_METADATA),
        'tables': table_results,
        'sequences': sequence_values,
        'large_objects': extra['large_objects'],
        'schema': extra['schema'],
    }


def command_fingerprint(args):
    out = private_output(args.out)
    cluster = Cluster(args.psql, args.socket, args.port, args.user)
    identity = server_identity(cluster)
    check_identity(identity, args)
    databases = {}
    for database in args.databases:
        databases[database] = fingerprint_database(cluster, database)
    write_json(out, {'kind': 'fingerprint', 'role': args.role, 'label': args.label, 'collected_at': now(),
                     'server': identity, 'databases': databases})
    print('fingerprint [' + args.role + (' ' + args.label if args.label else '') + '] cluster '
          + identity['system_identifier'])
    for name, value in databases.items():
        print('  ' + name + ': ' + str(len(value['tables'])) + ' tables, '
              + str(sum(t['rows'] for t in value['tables'].values())) + ' rows, '
              + str(len(value['sequences'])) + ' sequences, ' + str(value['large_objects']['rows'])
              + ' large objects, ' + str(value['schema']['rows']) + ' schema objects')
    print('wrote ' + str(out))
    return 0


def sqlite_fingerprint(path):
    source = Path(path).resolve(strict=True)
    connection = sqlite3.connect(source.as_uri() + '?mode=ro', uri=True)
    try:
        integrity = connection.execute('PRAGMA integrity_check').fetchall()
        foreign_keys = connection.execute('PRAGMA foreign_key_check').fetchall()
        objects = connection.execute(
            "SELECT type, name, tbl_name, coalesce(sql, '') FROM sqlite_schema ORDER BY type, name").fetchall()
        tables = {}
        for kind, name, _, _ in objects:
            if kind != 'table' or name.startswith('sqlite_'):
                continue
            quoted = '"' + name.replace('"', '""') + '"'
            columns = [row[1] for row in connection.execute('PRAGMA table_info(' + quoted + ')')]
            rows = connection.execute(
                'SELECT json_array(' + ', '.join(
                    "CASE typeof(" + '"' + c.replace('"', '""') + '"' + ") WHEN 'blob' THEN hex("
                    + '"' + c.replace('"', '""') + '"' + ") ELSE " + '"' + c.replace('"', '""') + '"' + " END"
                    for c in columns) + ') AS r FROM ' + quoted + ' ORDER BY r').fetchall()
            digest = hashlib.sha256()
            for (row,) in rows:
                digest.update(row.encode() + b'\n')
            tables[name] = {'rows': len(rows), 'sha256': digest.hexdigest()}
        schema = hashlib.sha256('\n'.join('|'.join(o) for o in objects).encode()).hexdigest()
        return {'integrity_check': [r[0] for r in integrity], 'foreign_key_violations': len(foreign_keys),
                'schema': {'rows': len(objects), 'sha256': schema}, 'tables': tables,
                'user_version': connection.execute('PRAGMA user_version').fetchone()[0]}
    finally:
        connection.close()


def command_sqlite(args):
    out = private_output(args.out)
    value = sqlite_fingerprint(args.db)
    write_json(out, {'kind': 'sqlite', 'role': args.role, 'label': args.label, 'collected_at': now(),
                     'path': str(Path(args.db).resolve()), 'database': value})
    ok = value['integrity_check'] == ['ok'] and value['foreign_key_violations'] == 0
    print('sqlite [' + args.role + '] ' + ('integrity ok' if ok else 'INTEGRITY FAILED') + ', '
          + str(len(value['tables'])) + ' tables, ' + str(sum(t['rows'] for t in value['tables'].values()))
          + ' rows')
    print('wrote ' + str(out))
    return 0 if ok else MISMATCH


# --- compare ----------------------------------------------------------------

def diff_maps(prefix, left, right, differences):
    for key in sorted(set(left) | set(right)):
        if key not in left:
            differences.append(prefix + key + ': only in second')
        elif key not in right:
            differences.append(prefix + key + ': only in first')
        elif left[key] != right[key]:
            if isinstance(left[key], dict) and isinstance(right[key], dict) and 'sha256' not in left[key]:
                diff_maps(prefix + key + '.', left[key], right[key], differences)
            elif isinstance(left[key], dict) and 'rows' in left[key] and left[key]['rows'] == right[key].get('rows'):
                differences.append(prefix + key + ': same row count, different content')
            elif isinstance(left[key], dict) and 'rows' in left[key]:
                differences.append(prefix + key + ': ' + str(left[key]['rows']) + ' rows vs '
                                   + str(right[key].get('rows')))
            else:
                differences.append(prefix + key + ': differs')


def compare(first, second, ignore=()):
    if first.get('kind') != second.get('kind'):
        raise Refused('cannot compare a ' + str(first.get('kind')) + ' with a ' + str(second.get('kind')))
    differences = []
    if first['kind'] == 'sqlite':
        diff_maps('', first['database'], second['database'], differences)
        return differences
    left, right = first['databases'], second['databases']
    for database in sorted(set(left) | set(right)):
        if database not in left or database not in right:
            differences.append(database + ': present in only one fingerprint')
            continue
        a, b = dict(left[database]), dict(right[database])
        a['metadata'], b['metadata'] = dict(a['metadata']), dict(b['metadata'])
        for field in ignore:
            a['metadata'].pop(field, None)
            b['metadata'].pop(field, None)
        diff_maps(database + '.', a, b, differences)
    return differences


def load(path):
    with open(path) as handle:
        return json.load(handle)


def command_compare(args):
    first, second = load(args.first), load(args.second)
    ignore = ['allow_connections'] if args.ignore_allow_connections else []
    differences = compare(first, second, ignore)
    if differences:
        print('DIFFERENT: ' + str(len(differences)) + ' differences')
        for line in differences[:200]:
            print('  ' + line)
        return MISMATCH
    print('MATCH: ' + args.first + ' and ' + args.second)
    return 0


def command_conflicts(args):
    cluster = Cluster(args.psql, args.socket, args.port, args.user)
    identity = server_identity(cluster)
    check_identity(identity, args)
    existing = {row for row in cluster.json_rows('postgres', 'SELECT to_json(datname) FROM pg_database')}
    conflicts = sorted(set(args.databases) & existing)
    if conflicts:
        print('CONFLICT: cluster ' + identity['system_identifier'] + ' already has ' + ', '.join(conflicts))
        return MISMATCH
    print('NO CONFLICT: cluster ' + identity['system_identifier'] + ' has none of ' + ', '.join(args.databases))
    return 0


# --- bundles ----------------------------------------------------------------

def bundle_entries(root):
    entries = {}
    for directory, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames.sort()
        for name in sorted(filenames) + [d for d in dirnames if os.path.islink(os.path.join(directory, d))]:
            path = Path(directory) / name
            relative = path.relative_to(root).as_posix()
            if relative in (MANIFEST, COMPLETE):
                continue
            info = path.lstat()
            entry = {'mode': oct(stat.S_IMODE(info.st_mode))}
            if stat.S_ISLNK(info.st_mode):
                entry['symlink'] = os.readlink(path)
            else:
                digest = hashlib.sha256()
                with open(path, 'rb') as handle:
                    for chunk in iter(lambda: handle.read(1 << 20), b''):
                        digest.update(chunk)
                entry.update(size=info.st_size, sha256=digest.hexdigest())
            entries[relative] = entry
    return entries


def sha256_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def command_manifest(args):
    root = Path(args.root).resolve(strict=True)
    info = root.stat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) & 0o077:
        raise Refused('bundle directory must be owned by you with mode 0700: ' + str(root))
    if (root / COMPLETE).exists() or (root / MANIFEST).exists():
        raise Refused('bundle is already sealed; seal a new bundle instead: ' + str(root))
    entries = bundle_entries(root)
    if not entries:
        raise Refused('bundle is empty: ' + str(root))
    write_json(root / MANIFEST, {'kind': 'bundle-manifest', 'label': args.label, 'sealed_at': now(),
                                 'files': entries})
    # COMPLETE goes last, atomically: a bundle without it was interrupted.
    temporary = root / (COMPLETE + '.tmp')
    temporary.write_text(sha256_file(root / MANIFEST) + '\n')
    os.chmod(temporary, 0o400)
    os.rename(temporary, root / COMPLETE)
    os.chmod(root / MANIFEST, 0o400)
    print('sealed ' + str(root) + ': ' + str(len(entries)) + ' files, '
          + str(sum(e.get('size', 0) for e in entries.values())) + ' bytes')
    return 0


def command_verify_bundle(args):
    root = Path(args.root).resolve(strict=True)
    if not (root / COMPLETE).exists() or not (root / MANIFEST).exists():
        print('INCOMPLETE: ' + str(root) + ' was never sealed or its sealing was interrupted')
        return INCOMPLETE
    if (root / COMPLETE).read_text().strip() != sha256_file(root / MANIFEST):
        print('CORRUPT: manifest does not match its COMPLETE marker')
        return MISMATCH
    expected = load(root / MANIFEST)['files']
    actual = bundle_entries(root)
    problems = []
    for name in sorted(set(expected) | set(actual)):
        if name not in actual:
            problems.append(name + ': missing')
        elif name not in expected:
            problems.append(name + ': not in manifest')
        elif expected[name] != actual[name]:
            fields = [f for f in ('sha256', 'size', 'mode', 'symlink') if expected[name].get(f) != actual[name].get(f)]
            problems.append(name + ': ' + ', '.join(fields) + ' differ')
    if problems:
        print('FAILED: ' + str(len(problems)) + ' problems in ' + str(root))
        for line in problems:
            print('  ' + line)
        return MISMATCH
    print('VERIFIED: ' + str(root) + ': ' + str(len(expected)) + ' files')
    return 0


# --- command line -----------------------------------------------------------

def default_psql():
    return ['pg18', 'psql'] if shutil.which('pg18') else ['psql']


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)

    def database_command(name, help_text):
        command = commands.add_parser(name, help=help_text)
        command.add_argument('--socket', required=True, help='explicit PostgreSQL socket directory')
        command.add_argument('--role', required=True, choices=('source', 'destination', 'rehearsal', 'restore-proof'))
        command.add_argument('--port', default='5432')
        command.add_argument('--user', default='shinzui')
        command.add_argument('--psql', default=None, help='psql command, split on spaces (default: pg18 psql)')
        command.add_argument('--expect-system-identifier', help='refuse unless the server has this identifier')
        command.add_argument('--expect-data-directory', help='refuse unless the server uses this data directory')
        return command

    inventory = database_command('inventory', 'cluster inventory')
    inventory.add_argument('--out', required=True)
    fingerprint = database_command('fingerprint', 'content fingerprint of selected databases')
    fingerprint.add_argument('--out', required=True)
    fingerprint.add_argument('--label', default='')
    fingerprint.add_argument('databases', nargs='+')
    conflicts = database_command('conflicts', 'check a destination for existing databases')
    conflicts.add_argument('databases', nargs='+')

    sqlite = commands.add_parser('sqlite', help='fingerprint a SQLite file, read-only')
    sqlite.add_argument('--db', required=True)
    sqlite.add_argument('--role', required=True, choices=('source', 'destination', 'rehearsal', 'backup'))
    sqlite.add_argument('--label', default='')
    sqlite.add_argument('--out', required=True)

    compare_command = commands.add_parser('compare', help='compare two fingerprints')
    compare_command.add_argument('first')
    compare_command.add_argument('second')
    compare_command.add_argument('--ignore-allow-connections', action='store_true',
                                 help='ignore datallowconn, which the source fence changes after export')

    manifest = commands.add_parser('manifest', help='seal a bundle directory')
    manifest.add_argument('--root', required=True)
    manifest.add_argument('--label', default='')
    verify = commands.add_parser('verify-bundle', help='verify a sealed bundle')
    verify.add_argument('--root', required=True)

    args = parser.parse_args(argv)
    if getattr(args, 'psql', 'unset') is None:
        args.psql = default_psql()
    elif isinstance(getattr(args, 'psql', None), str):
        args.psql = shlex.split(args.psql)
    handlers = {'inventory': command_inventory, 'fingerprint': command_fingerprint, 'sqlite': command_sqlite,
                'compare': command_compare, 'conflicts': command_conflicts, 'manifest': command_manifest,
                'verify-bundle': command_verify_bundle}
    try:
        return handlers[args.command](args)
    except Refused as exc:
        print('REFUSED: ' + str(exc), file=sys.stderr)
        return REFUSED
    except (Failed, OSError, sqlite3.Error, json.JSONDecodeError) as exc:
        print('FAILED: ' + str(exc), file=sys.stderr)
        return MISMATCH


if __name__ == '__main__':
    sys.exit(main())
