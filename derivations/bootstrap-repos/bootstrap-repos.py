#!/usr/bin/env python3
"""Clone registered checkouts, including corpus wrapper repositories.

Source:      bootstrap-repos --export /private/path/repos.json
Destination: bootstrap-repos --manifest /private/path/repos.json --dry-run

Only exporting needs Mori and existing source checkouts. Originless checkouts are
saved as private Git bundles beside the export; copy those to the same path too.
Keep the manifest private: it contains repository URLs and local paths. Remote
clones use default branches; local-only bundles contain committed history.
Uncommitted and untracked files and local Git settings are not transferred.
Existing repositories are never fetched, reset or overwritten.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit


def git(*args, check=True):
    return subprocess.run(['git', *args], check=check, capture_output=True, text=True)


def git_root(path):
    result = git('-C', str(path), 'rev-parse', '--show-toplevel', check=False)
    return Path(result.stdout.strip()).resolve() if result.returncode == 0 else None


def identity(url):
    """Compare HTTPS and SSH origins without changing generic Git URLs."""
    match = re.fullmatch(r'git@([^:]+):(.+)', url)
    if match:
        return match[1].lower(), match[2].rstrip('/').removesuffix('.git')
    parsed = urlsplit(url)
    if parsed.hostname and parsed.scheme in ('https', 'http', 'ssh'):
        if parsed.password or (parsed.username and parsed.scheme != 'ssh'):
            raise ValueError('refusing a repository URL containing credentials')
        host = parsed.hostname.lower()
        if parsed.port and parsed.port != {'https': 443, 'http': 80, 'ssh': 22}[parsed.scheme]:
            host += ':' + str(parsed.port)
        return host, parsed.path.strip('/').removesuffix('.git')
    return url


def validate(manifest):
    if not isinstance(manifest, dict) or manifest.get('version') != 1:
        raise ValueError('unsupported checkout manifest; expected version 1')
    if not isinstance(manifest.get('checkouts'), list):
        raise ValueError('manifest checkouts must be a list')
    seen = {}
    for checkout in manifest['checkouts']:
        if not isinstance(checkout, dict):
            raise ValueError('each checkout must be an object')
        path, url, projects = (checkout.get(key) for key in ('path', 'url', 'projects'))
        if not isinstance(path, str) or not Path(path).is_absolute() or '\0' in path:
            raise ValueError('checkout destinations must be absolute paths')
        path = os.path.normpath(path)
        if path == '/' or path == '/nix/store' or path.startswith('/nix/store/'):
            raise ValueError('invalid checkout destination')
        if not isinstance(url, str) or not url or any(c in url for c in '\0\r\n'):
            raise ValueError('invalid repository URL')
        if not isinstance(projects, list) or not projects or not all(
            isinstance(p, str) and re.fullmatch(r'mori://[^/]+/[^/]+', p) for p in projects
        ):
            raise ValueError('checkout projects must be canonical Mori project URIs')
        repo = identity(url)
        if path in seen and seen[path] != repo:
            raise ValueError(f'conflicting repositories for {path}')
        seen[path] = repo
    return manifest


def make_bundle(root, directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    name = root.name + '-' + hashlib.sha256(str(root).encode()).hexdigest()[:12] + '.bundle'
    destination = directory / name
    with tempfile.TemporaryDirectory(dir=directory) as temporary:
        bundle = Path(temporary) / 'checkout.bundle'
        git('-C', str(root), 'bundle', 'create', str(bundle), '--all')
        bundle.chmod(0o600)
        bundle.replace(destination)
    return str(destination)


def export_registry(filter_text, bundle_dir=None):
    try:
        result = subprocess.run(['mori', 'registry', 'list', '--json'],
                                check=True, capture_output=True, text=True)
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        raise ValueError('cannot query Mori; export on the source machine, or use --manifest FILE') from exc
    projects = json.loads(result.stdout)
    checkouts = {}
    errors = []
    for project in projects:
        qname = project['namespace'] + '/' + project['name']
        if filter_text and filter_text not in qname:
            continue
        path = Path(project['path'])
        root = git_root(path)
        if root is None:
            errors.append(f'{qname}: no local Git checkout at {path}')
            continue
        origin = git('-C', str(root), 'remote', 'get-url', 'origin', check=False)
        key = str(root)
        if key not in checkouts:
            if origin.returncode:
                if bundle_dir is None:
                    errors.append(f'{qname}: checkout has no origin; use --export to bundle it: {root}')
                    continue
                url = make_bundle(root, bundle_dir)
                print(f'[bundle] {qname} (local checkout without an origin)', flush=True)
            else:
                url = origin.stdout.strip()
            checkouts[key] = {'path': key, 'url': url, 'projects': []}
        checkouts[key]['projects'].append('mori://' + qname)
    if errors:
        raise ValueError('\n'.join(errors) + '\nExport requires source checkouts; use --manifest on the new machine.')
    return validate({
        'version': 1,
        'generatedAt': datetime.now(timezone.utc).isoformat(),
        'sourceHost': socket.gethostname(),
        'projectCount': sum(len(c['projects']) for c in checkouts.values()),
        'checkouts': sorted(checkouts.values(), key=lambda c: c['path']),
    })


def write_manifest(path, manifest):
    """Publish atomically, with private permissions even when replacing a file."""
    path = Path(path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            json.dump(manifest, output, indent=2, ensure_ascii=False)
            output.write('\n')
        temporary.replace(path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def clone_checkouts(manifest, dry_run=False, use_ssh=False, filter_text=''):
    planned = {}
    for checkout in validate(manifest)['checkouts']:
        if filter_text and not any(filter_text in p.removeprefix('mori://') for p in checkout['projects']):
            continue
        planned[os.path.normpath(checkout['path'])] = checkout['url']
    cloned = skipped = errors = 0
    # Parents first, so recursive clones can create registered submodules.
    for destination, url in sorted(planned.items(), key=lambda item: (len(Path(item[0]).parts), item[0])):
        path = Path(destination)
        repo = identity(url)
        if use_ssh and isinstance(repo, tuple) and repo[0] in ('github.com', 'gitlab.com'):
            url = f'git@{repo[0]}:{repo[1]}.git'
        try:
            if path.exists() and git_root(path) == path.resolve():
                origin = git('-C', destination, 'remote', 'get-url', 'origin', check=False)
                if origin.returncode or identity(origin.stdout.strip()) != repo:
                    raise ValueError('existing repository has a different or missing origin')
                print(f'[skip] {destination} (matching repository already exists)', flush=True)
                skipped += 1
                continue
            if path.is_symlink() or (path.exists() and (not path.is_dir() or any(path.iterdir()))):
                raise ValueError('destination exists and is not an empty directory or matching repository')
            if dry_run:
                print(f'[dry-run] would clone {url} -> {destination}', flush=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                result = git('clone', '--recurse-submodules', '--', url, destination, check=False)
                if result.returncode:
                    raise ValueError(result.stderr.strip() or 'git clone failed')
                print(f'[clone] {url} -> {destination}', flush=True)
            cloned += 1
        except (OSError, ValueError) as exc:
            print(f'[error] {destination}: {exc}', file=sys.stderr, flush=True)
            errors += 1
    suffix = ' (dry-run)' if dry_run else ''
    print(f'Summary: {cloned} cloned, {skipped} skipped, {errors} errors{suffix}', flush=True)
    return 1 if errors else 0


def main():
    parser = argparse.ArgumentParser(prog='bootstrap-repos', description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    source = parser.add_mutually_exclusive_group()
    source.add_argument('--export', metavar='FILE', help='export source checkout origins and paths; do not clone')
    source.add_argument('--manifest', metavar='FILE', help='clone from an export; Mori is not needed')
    parser.add_argument('--dry-run', action='store_true', help='print clone actions without changing files')
    parser.add_argument('--ssh', action='store_true', help='prefer SSH URLs for GitHub and GitLab')
    parser.add_argument('--filter', default='', metavar='SUBSTR', help='only include matching namespace/name values')
    args = parser.parse_args()
    if args.export and args.dry_run:
        parser.error('--export writes a manifest; omit --dry-run')
    try:
        if args.manifest:
            manifest = validate(json.loads(Path(args.manifest).expanduser().read_text()))
        else:
            bundle_dir = Path(args.export).expanduser().absolute().with_suffix('.bundles') if args.export else None
            manifest = export_registry(args.filter, bundle_dir)
        if args.export:
            write_manifest(args.export, manifest)
            print(f'Exported {manifest["projectCount"]} projects in {len(manifest["checkouts"])} checkouts to {args.export}')
            return 0
        return clone_checkouts(manifest, args.dry_run, args.ssh, args.filter)
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f'error: {exc}\n')


if __name__ == '__main__':
    sys.exit(main())
