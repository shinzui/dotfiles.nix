#!/usr/bin/env python3
"""Feed this client's observed Git checkouts into the authoritative Mori store.

Uses mori://shinzui/mori's CLI and the client's existing database tunnel. It
starts no automation, webhook, subscription, or Rei workers and never registers
projects or changes their authoritative host/path. Requires Mori's observed-HEAD
guard so an older client checkout cannot halt a newer shared cursor.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


def eligible_path(project, root):
    """Only ingest the exact registered repository, already present locally."""
    path = Path(project['path']).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_dir():
        return None
    marker = path / 'mori' / 'repo-id'
    try:
        if marker.read_text().strip() != project['repo_id']:
            return None
    except OSError:
        return None
    return path


def collect(mori, root):
    listing = subprocess.run(
        [mori, 'registry', 'list', '--observed', '--json'],
        check=True, capture_output=True, text=True, timeout=60,
    )
    projects = json.loads(listing.stdout)
    failures = 0
    scanned = 0
    for project in projects:
        path = eligible_path(project, root)
        if path is None:
            continue
        # Check git's actual root as well: a missing nested checkout must not
        # accidentally ingest the enclosing repository under another repo ID.
        git = subprocess.run(
            ['git', '-C', str(path), 'rev-parse', '--show-toplevel'],
            capture_output=True, text=True, timeout=15,
        )
        if git.returncode or Path(git.stdout.strip()).resolve() != path:
            continue
        name = project['namespace'] + '/' + project['name']
        scanned += 1
        try:
            result = subprocess.run(
                [mori, 'automate', 'ingest', 'git', '--path', str(path)],
                capture_output=True, text=True, timeout=180,
            )
            output = (result.stdout + result.stderr).strip()
            # The first rewrite-detection tick can report a halt with exit 0.
            halted = 'halting' in output or 'halted on orphaned checkpoint' in output
            if result.returncode or halted:
                failures += 1
            if output != 'Ingested 0 changesets, 0 refs':
                print(f'{name}: {output}', flush=True)
        except subprocess.TimeoutExpired:
            failures += 1
            print(f'{name}: ingestion timed out; next scan will retry', flush=True)
    print(f'Scanned {scanned} local observed repositories; {failures} need attention', flush=True)
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mori', default='mori')
    parser.add_argument('--root', type=Path, default=Path.home() / 'Keikaku')
    args = parser.parse_args()
    if not os.environ.get('MORI_PG_CONNECTION_STRING'):
        parser.exit(1, 'MORI_PG_CONNECTION_STRING must select the authoritative store\n')
    try:
        return collect(args.mori, args.root)
    except (subprocess.SubprocessError, OSError, ValueError, KeyError):
        print('Client ingestion failed; check the database tunnel and Mori configuration', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
