#!/usr/bin/env python3
"""Exercise rei-mori-migration.py: bundles, comparisons, SQLite, and a throwaway PostgreSQL cluster.

The PostgreSQL tests start a private cluster in a temporary directory with TCP
disabled. They need the server's PostgreSQL 18 build: `pg18` on PATH (from
home/postgresql.nix), or PG18_BIN pointing at its bin directory. Without
either they are skipped, and the skip is reported.
"""
import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import subprocess
import tempfile
import unittest

HELPER = runpy.run_path(str(Path(__file__).absolute().with_name('rei-mori-migration.py')))
MAIN = HELPER['main']


def quiet(argv):
    with contextlib.redirect_stdout(io.StringIO()) as out, contextlib.redirect_stderr(io.StringIO()):
        status = MAIN(argv)
    return status, out.getvalue()


def pg_tool(name):
    if shutil.which('pg18'):
        return ['pg18', name]
    if os.environ.get('PG18_BIN'):
        return [os.path.join(os.environ['PG18_BIN'], name)]
    return None


class PrivateDir:
    def __enter__(self):
        self.tmp = tempfile.TemporaryDirectory()
        path = Path(self.tmp.name)
        path.chmod(0o700)
        return path

    def __exit__(self, *exc):
        self.tmp.cleanup()


class BundleTests(unittest.TestCase):
    def make_bundle(self, root):
        (root / 'rei.dump').write_bytes(b'\x00dump' * 100)
        (root / 'payload').mkdir()
        (root / 'payload' / 'mina.db').write_bytes(b'sqlite')
        (root / 'payload' / 'link').symlink_to('mina.db')
        self.assertEqual(quiet(['manifest', '--root', str(root)])[0], 0)

    def test_sealed_bundle_verifies(self):
        with PrivateDir() as root:
            self.make_bundle(root)
            self.assertEqual(quiet(['verify-bundle', '--root', str(root)])[0], 0)

    def test_corrupted_missing_and_extra_payloads_fail(self):
        for damage in ('corrupt', 'missing', 'extra', 'mode', 'relink'):
            with PrivateDir() as root:
                self.make_bundle(root)
                target = root / 'payload' / 'mina.db'
                if damage == 'corrupt':
                    target.write_bytes(b'sqlitf')
                elif damage == 'missing':
                    target.unlink()
                elif damage == 'extra':
                    (root / 'stray').write_text('x')
                elif damage == 'mode':
                    target.chmod(0o777)
                else:
                    (root / 'payload' / 'link').unlink()
                    (root / 'payload' / 'link').symlink_to('elsewhere')
                status, output = quiet(['verify-bundle', '--root', str(root)])
                self.assertEqual(status, HELPER['MISMATCH'], damage)

    def test_incomplete_or_interrupted_bundle_fails(self):
        with PrivateDir() as root:
            (root / 'rei.dump').write_text('partial')
            self.assertEqual(quiet(['verify-bundle', '--root', str(root)])[0], HELPER['INCOMPLETE'])
            (root / 'COMPLETE.tmp').write_text('interrupted')
            self.assertEqual(quiet(['verify-bundle', '--root', str(root)])[0], HELPER['INCOMPLETE'])

    def test_tampered_manifest_fails(self):
        with PrivateDir() as root:
            self.make_bundle(root)
            manifest = root / 'MANIFEST.json'
            manifest.chmod(0o600)
            manifest.write_text(manifest.read_text().replace('"label"', '"label" ', 1))
            self.assertEqual(quiet(['verify-bundle', '--root', str(root)])[0], HELPER['MISMATCH'])

    def test_sealed_bundle_is_immutable_and_directory_private(self):
        with PrivateDir() as root:
            self.make_bundle(root)
            self.assertEqual(quiet(['manifest', '--root', str(root)])[0], HELPER['REFUSED'])
        with PrivateDir() as root:
            (root / 'x').write_text('x')
            root.chmod(0o755)
            self.assertEqual(quiet(['manifest', '--root', str(root)])[0], HELPER['REFUSED'])


class OutputTests(unittest.TestCase):
    def test_refuses_existing_evidence_and_shared_directories(self):
        with PrivateDir() as root:
            existing = root / 'evidence.json'
            existing.write_text('{}')
            with self.assertRaises(HELPER['Refused']):
                HELPER['private_output'](existing)
            root.chmod(0o750)
            with self.assertRaises(HELPER['Refused']):
                HELPER['private_output'](root / 'new.json')


def fingerprint(tables, sequences=None, allow=True):
    return {'kind': 'fingerprint', 'databases': {'rei': {
        'metadata': {'owner': 'shinzui', 'allow_connections': allow},
        'tables': tables, 'sequences': sequences or {}, 'large_objects': {'rows': 0, 'sha256': 'e'},
        'schema': {'rows': 1, 'sha256': 's'}}}}


class CompareTests(unittest.TestCase):
    def test_same_count_changed_content_is_reported(self):
        a = fingerprint({'public.t': {'rows': 3, 'sha256': 'aaa'}})
        b = fingerprint({'public.t': {'rows': 3, 'sha256': 'bbb'}})
        differences = HELPER['compare'](a, b)
        self.assertEqual(differences, ['rei.tables.public.t: same row count, different content'])

    def test_sequence_drift_and_missing_tables_are_reported(self):
        a = fingerprint({'public.t': {'rows': 1, 'sha256': 'a'}}, {'public.s': {'last_value': 5, 'is_called': True}})
        b = fingerprint({}, {'public.s': {'last_value': 6, 'is_called': True}})
        differences = HELPER['compare'](a, b)
        self.assertIn('rei.sequences.public.s.last_value: differs', differences)
        self.assertIn('rei.tables.public.t: only in first', differences)

    def test_fence_setting_is_ignored_only_on_request(self):
        a, b = fingerprint({}, allow=True), fingerprint({}, allow=False)
        self.assertTrue(HELPER['compare'](a, b))
        self.assertEqual(HELPER['compare'](a, b, ['allow_connections']), [])


class SqliteTests(unittest.TestCase):
    def test_wal_content_is_read_and_changes_detected(self):
        with PrivateDir() as root:
            db = root / 'mina.db'
            writer = sqlite3.connect(db)
            writer.execute('PRAGMA journal_mode=WAL')
            writer.execute('PRAGMA wal_autocheckpoint=0')
            writer.execute('CREATE TABLE items (id INTEGER PRIMARY KEY, title TEXT, data BLOB)')
            writer.executemany('INSERT INTO items (title, data) VALUES (?, ?)',
                               [('a', b'\x00\x01'), ('a', b'\x00\x01'), ('b', None)])
            writer.commit()
            self.assertTrue((root / 'mina.db-wal').stat().st_size > 0)
            first = HELPER['sqlite_fingerprint'](db)
            self.assertEqual(first['tables']['items']['rows'], 3)
            self.assertEqual(first['integrity_check'], ['ok'])
            writer.execute("UPDATE items SET title = 'c' WHERE id = 3")
            writer.commit()
            second = HELPER['sqlite_fingerprint'](db)
            writer.close()
            self.assertEqual(second['tables']['items']['rows'], 3)
            self.assertNotEqual(first['tables']['items']['sha256'], second['tables']['items']['sha256'])


@unittest.skipUnless(pg_tool('initdb'), 'PostgreSQL 18 tools not found: put pg18 on PATH or set PG18_BIN')
class PostgresTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='rmm')
        root = Path(cls.tmp.name)
        root.chmod(0o700)
        cls.root = root
        cls.data = root / 'data'
        cls.socket = root / 's'
        cls.socket.mkdir(mode=0o700)
        cls.evidence = root / 'evidence'
        cls.evidence.mkdir(mode=0o700)
        user = os.environ.get('USER', 'shinzui')
        cls.user = user
        subprocess.run(pg_tool('initdb') + ['--auth=trust', '--no-locale', '--encoding=UTF8', '-U', user,
                                            '-D', str(cls.data)], check=True, capture_output=True)
        subprocess.run(pg_tool('pg_ctl') + ['-D', str(cls.data), '-l', str(root / 'server.log'), '-o',
                                            "-k " + str(cls.socket) + " -c listen_addresses='' -p 5432",
                                            '-w', 'start'], check=True, capture_output=True)
        cls.sql('postgres', 'CREATE DATABASE rei')
        cls.sql('rei', """
            CREATE TABLE notes (id bigserial PRIMARY KEY, body text, blob bytea, at timestamptz);
            INSERT INTO notes (body, blob, at) VALUES ('one', '\\x0001', '2026-11-10 00:00+00'),
              ('two', NULL, '2026-11-10 01:00+00'), ('three', '\\xff', NULL);
            CREATE TABLE dupes (v text);
            INSERT INTO dupes VALUES ('same'), ('same'), ('other');
            CREATE TABLE empty_table (v int);
            CREATE TABLE events (id int, at date) PARTITION BY RANGE (at);
            CREATE TABLE events_2026 PARTITION OF events FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
            CREATE TABLE events_2027 PARTITION OF events FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
            INSERT INTO events VALUES (1, '2026-05-01'), (2, '2026-06-01'), (3, '2027-02-01');
            SELECT lo_from_bytea(424242, '\\x6c6f');
        """)

    @classmethod
    def tearDownClass(cls):
        subprocess.run(pg_tool('pg_ctl') + ['-D', str(cls.data), '-m', 'immediate', '-w', 'stop'],
                       capture_output=True)
        cls.tmp.cleanup()

    @classmethod
    def sql(cls, database, statement):
        subprocess.run(pg_tool('psql') + ['-X', '-q', '-v', 'ON_ERROR_STOP=1', '-h', str(cls.socket),
                                          '-U', cls.user, '-d', database, '-c', statement],
                       check=True, capture_output=True)

    def run_helper(self, *argv):
        return quiet([argv[0], '--socket', str(self.socket), '--role', 'rehearsal', '--user', self.user,
                      '--psql', ' '.join(pg_tool('psql')), *argv[1:]])

    def take(self, name, *extra):
        out = self.evidence / (name + '.json')
        status, output = self.run_helper('fingerprint', '--out', str(out), *extra, 'rei')
        self.assertEqual(status, 0, output)
        return json.loads(out.read_text())

    def test_fingerprint_counts_and_detects_changes(self):
        first = self.take('first')
        rei = first['databases']['rei']
        self.assertEqual(rei['tables']['public.dupes']['rows'], 3)
        self.assertEqual(rei['tables']['public.empty_table']['rows'], 0)
        self.assertNotIn('public.events', rei['tables'])  # partitioned parent is not counted twice
        self.assertEqual(rei['tables']['public.events_2026']['rows'] + rei['tables']['public.events_2027']['rows'], 3)
        self.assertEqual(rei['sequences']['public.notes_id_seq'], {'last_value': 3, 'is_called': True})
        self.assertEqual(rei['large_objects']['rows'], 1)
        self.assertEqual(HELPER['compare'](first, self.take('repeat')), [])

        self.sql('rei', "UPDATE notes SET body = 'TWO' WHERE id = 2")
        self.sql('rei', "SELECT setval('notes_id_seq', 9)")
        self.sql('rei', "SELECT lo_put(424242, 0, '\\x4c')")
        self.sql('rei', 'ALTER TABLE empty_table ADD COLUMN extra text')
        differences = HELPER['compare'](first, self.take('changed'))
        self.assertIn('rei.tables.public.notes: same row count, different content', differences)
        self.assertIn('rei.sequences.public.notes_id_seq.last_value: differs', differences)
        self.assertIn('rei.large_objects: same row count, different content', differences)
        self.assertTrue(any(d.startswith('rei.schema') for d in differences))

    def test_explicit_default_acl_equals_null_acl(self):
        # pg_dump omits a grant equal to the owner's default, so a restore has
        # a NULL ACL where the source had an explicit default one.
        before = self.take('acl-before')
        self.sql('rei', 'GRANT ALL ON dupes TO ' + self.user)
        self.sql('rei', 'GRANT ALL ON SCHEMA public TO pg_database_owner')
        self.assertEqual(HELPER['compare'](before, self.take('acl-default')), [])
        self.sql('rei', 'CREATE ROLE acl_probe')
        self.sql('rei', 'GRANT SELECT ON dupes TO acl_probe')
        self.assertTrue(any(d.startswith('rei.schema') for d in HELPER['compare'](before, self.take('acl-real'))))
        self.sql('rei', 'REVOKE SELECT ON dupes FROM acl_probe')
        self.sql('rei', 'DROP ROLE acl_probe')

    def test_wrong_socket_identity_is_refused(self):
        out = self.evidence / 'wrong.json'
        status, _ = self.run_helper('fingerprint', '--out', str(out), '--expect-system-identifier', '1', 'rei')
        self.assertEqual(status, HELPER['REFUSED'])
        self.assertFalse(out.exists())
        status, _ = self.run_helper('fingerprint', '--out', str(out), '--expect-data-directory', '/nowhere', 'rei')
        self.assertEqual(status, HELPER['REFUSED'])

    def test_destination_conflicts_are_reported(self):
        self.assertEqual(self.run_helper('conflicts', 'rei', 'mori')[0], HELPER['MISMATCH'])
        self.assertEqual(self.run_helper('conflicts', 'mori', 'notion_hub')[0], 0)

    def test_inventory_and_read_only_sessions(self):
        out = self.evidence / 'inventory.json'
        status, output = self.run_helper('inventory', '--out', str(out))
        self.assertEqual(status, 0, output)
        inventory = json.loads(out.read_text())
        self.assertIn('rei', [d['name'] for d in inventory['cluster']['databases']])
        cluster = HELPER['Cluster'](pg_tool('psql'), str(self.socket), '5432', self.user)
        with self.assertRaises(HELPER['Failed']):
            cluster.json_one('rei', 'CREATE TABLE written_by_helper (v int)')


if __name__ == '__main__':
    unittest.main()
