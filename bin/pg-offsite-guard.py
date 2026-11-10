#!/usr/bin/env python3
"""Keep one PostgreSQL cluster per offsite mirror directory.

pg-backup-offsite-sync mirrors a pg_rman catalog with rsync --delete, which
replaces whatever the destination holds. A catalog is a byte-level copy of one
specific cluster, so a mirror overwritten by another cluster's catalog is lost.
This guard records the source cluster's system identifier in a marker file and
refuses to let a different cluster sync into a marked or unmarked non-empty
destination.

  check  Pass when the marker matches. Create the directory and marker when the
         destination is missing or empty. Refuse otherwise.
  adopt  Mark an existing, unmarked mirror as this cluster's, after an operator
         has verified that it holds this cluster's chain. Requires --verified.
  show   Print this cluster's system identifier and the destination's marker.

The guard never deletes, moves, or rewrites catalog files.
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

MARKER = '.postgresql-cluster-id'
REFUSED = 3


class GuardError(Exception):
    pass


def system_identifier(pg_controldata, data_dir):
    result = subprocess.run([pg_controldata, '-D', data_dir], capture_output=True, text=True)
    if result.returncode:
        raise GuardError('pg_controldata failed for ' + data_dir + ': ' + result.stderr.strip())
    match = re.search(r'^Database system identifier:\s*(\d+)\s*$', result.stdout, re.MULTILINE)
    if not match:
        raise GuardError('pg_controldata printed no database system identifier')
    return match.group(1)


def read_marker(destination):
    path = destination / MARKER
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise GuardError('marker is not a regular file: ' + str(path))
    if not path.exists():
        return None
    value = path.read_text().strip()
    if not re.fullmatch(r'\d+', value):
        raise GuardError('marker does not hold a system identifier: ' + str(path))
    return value


def write_marker(destination, identifier):
    # O_EXCL: a marker that appeared since we looked is never overwritten.
    fd = os.open(destination / MARKER, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    with os.fdopen(fd, 'w') as handle:
        handle.write(identifier + '\n')
        handle.flush()
        os.fsync(handle.fileno())


def destination_path(raw):
    destination = Path(raw)
    if not destination.is_absolute():
        raise GuardError('destination must be an absolute path')
    if destination.is_symlink():
        raise GuardError('destination is a symlink; refusing: ' + raw)
    if destination.exists() and not destination.is_dir():
        raise GuardError('destination is not a directory: ' + raw)
    return destination


def check(identifier, destination):
    if not destination.exists():
        os.mkdir(destination, 0o755)
        write_marker(destination, identifier)
        return 'created ' + str(destination) + ' for cluster ' + identifier
    marker = read_marker(destination)
    if marker == identifier:
        return 'destination belongs to cluster ' + identifier
    if marker is not None:
        raise GuardError('destination belongs to cluster ' + marker + ', not this cluster ' + identifier
                         + '; refusing to sync into ' + str(destination))
    if any(destination.iterdir()):
        raise GuardError('destination is not empty and has no ' + MARKER + ' marker; inspect it, then run '
                         'pg-backup-offsite-adopt --verified only if it holds this cluster\'s chain')
    write_marker(destination, identifier)
    return 'marked empty destination for cluster ' + identifier


def adopt(identifier, destination, verified):
    if not destination.exists():
        raise GuardError('destination does not exist: ' + str(destination))
    marker = read_marker(destination)
    if marker == identifier:
        return 'destination already belongs to cluster ' + identifier
    if marker is not None:
        raise GuardError('destination belongs to cluster ' + marker + '; adopt never replaces a marker')
    if not (destination / 'pg_rman.ini').is_file():
        raise GuardError('destination is not a pg_rman catalog mirror (no pg_rman.ini)')
    if not verified:
        raise GuardError('adopt requires --verified, after confirming the mirror holds this cluster\'s chain')
    write_marker(destination, identifier)
    return 'adopted ' + str(destination) + ' for cluster ' + identifier


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('command', choices=('check', 'adopt', 'show'))
    parser.add_argument('--pg-controldata', required=True, help='pg_controldata from the server\'s own build')
    parser.add_argument('--data-dir', required=True, help='the source cluster\'s data directory')
    parser.add_argument('--destination', required=True, help='absolute mirror directory')
    parser.add_argument('--verified', action='store_true', help='adopt: the mirror was verified to hold this chain')
    args = parser.parse_args(argv)
    try:
        identifier = system_identifier(args.pg_controldata, args.data_dir)
        destination = destination_path(args.destination)
        if args.command == 'check':
            message = check(identifier, destination)
        elif args.command == 'adopt':
            message = adopt(identifier, destination, args.verified)
        else:
            marker = read_marker(destination) if destination.exists() else None
            message = 'cluster ' + identifier + '; destination marker ' + (marker or 'absent')
    except (GuardError, OSError) as exc:
        print('pg-offsite-guard: REFUSED: ' + str(exc), file=sys.stderr)
        return REFUSED
    print('pg-offsite-guard: ' + message)
    return 0


if __name__ == '__main__':
    sys.exit(main())
