#!/usr/bin/env python3
"""Exercise checkout preservation and corpus-wrapper export with local Git repos."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('bootstrap', Path(__file__).with_name('bootstrap-repos.py'))
bootstrap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bootstrap)


class CheckoutTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root / 'source wrapper'
        self.source.mkdir()
        self.run_git('init', '--initial-branch=main', str(self.source))
        self.run_git('-C', str(self.source), 'config', 'user.name', 'Fixture')
        self.run_git('-C', str(self.source), 'config', 'user.email', 'fixture@example.invalid')
        vendor = self.source / 'upstream'
        vendor.mkdir()
        (vendor / 'data.txt').write_text('vendored content\n')
        self.run_git('-C', str(self.source), 'add', '.')
        self.run_git('-C', str(self.source), 'commit', '-m', 'test: seed corpus wrapper')
        self.remote = self.root / 'origin.git'
        self.run_git('clone', '--bare', str(self.source), str(self.remote))
        self.run_git('-C', str(self.source), 'remote', 'add', 'origin', str(self.remote))
        self.destination = self.root / 'destination parent' / 'wrapper'
        self.manifest = {'version': 1, 'checkouts': [{
            'path': str(self.destination), 'url': str(self.remote),
            'projects': ['mori://example/corpus'],
        }]}

    def run_git(self, *args):
        return subprocess.run(['git', *args], check=True, capture_output=True, text=True)

    def clone(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return bootstrap.clone_checkouts(self.manifest, **kwargs)

    def test_real_clone_includes_vendor_and_rerun_preserves_local_changes(self):
        self.assertEqual(self.clone(), 0)
        path = self.destination / 'upstream/data.txt'
        self.assertEqual(path.read_text(), 'vendored content\n')
        path.write_text('local edits\n')
        self.assertEqual(self.clone(), 0)
        self.assertEqual(path.read_text(), 'local edits\n')

    def test_dry_run_does_not_create_parents(self):
        self.assertEqual(self.clone(dry_run=True), 0)
        self.assertFalse(self.destination.parent.exists())

    def test_non_repo_and_wrong_origin_are_preserved(self):
        self.destination.mkdir(parents=True)
        marker = self.destination / 'keep.txt'
        marker.write_text('keep')
        self.assertEqual(self.clone(), 1)
        self.assertEqual(marker.read_text(), 'keep')
        self.run_git('init', str(self.destination))
        self.run_git('-C', str(self.destination), 'remote', 'add', 'origin', '/different/repo')
        self.assertEqual(self.clone(), 1)
        self.assertEqual(marker.read_text(), 'keep')

    def test_worktree_git_file_is_recognized(self):
        self.run_git('-C', str(self.source), 'worktree', 'add', str(self.destination), '-b', 'worktree')
        self.assertTrue((self.destination / '.git').is_file())
        self.assertEqual(self.clone(), 0)

    def test_conflicting_manifest_rejected_before_writes(self):
        self.manifest['checkouts'].append({
            'path': str(self.destination), 'url': '/different/repo',
            'projects': ['mori://example/other'],
        })
        with self.assertRaisesRegex(ValueError, 'conflicting'):
            self.clone()
        self.assertFalse(self.destination.parent.exists())

    def test_export_uses_wrapper_origin_and_deduplicates_fixture(self):
        rows = [
            {'namespace': 'example', 'name': 'corpus', 'path': str(self.source)},
            {'namespace': 'example', 'name': 'fixture', 'path': str(self.source / 'upstream')},
        ]
        original_run = subprocess.run

        def run(args, **kwargs):
            if args[0] == 'mori':
                return subprocess.CompletedProcess(args, 0, json.dumps(rows), '')
            return original_run(args, **kwargs)

        with patch.object(bootstrap.subprocess, 'run', side_effect=run):
            result = bootstrap.export_registry('')
        self.assertEqual(result['projectCount'], 2)
        self.assertEqual(len(result['checkouts']), 1)
        self.assertEqual(result['checkouts'][0]['url'], str(self.remote))
        self.assertEqual(result['checkouts'][0]['path'], str(self.source))

    def test_manifest_written_privately(self):
        path = self.root / 'manifest.json'
        path.write_text('{}')
        path.chmod(0o644)
        bootstrap.write_manifest(path, self.manifest)
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_local_only_checkout_can_be_cloned_from_private_bundle(self):
        bundle = bootstrap.make_bundle(self.source, self.root / 'bundles')
        self.assertEqual(Path(bundle).stat().st_mode & 0o777, 0o600)
        self.manifest['checkouts'][0]['url'] = bundle
        self.assertEqual(self.clone(), 0)
        self.assertEqual((self.destination / 'upstream/data.txt').read_text(), 'vendored content\n')

    def test_ssh_and_https_origins_match_and_credentials_rejected(self):
        self.assertEqual(bootstrap.identity('git@github.com:example/repo.git'),
                         bootstrap.identity('https://github.com/example/repo.git'))
        with self.assertRaises(ValueError):
            bootstrap.identity('https://token@github.com/example/repo.git')


if __name__ == '__main__':
    unittest.main()
