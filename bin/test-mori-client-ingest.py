#!/usr/bin/env python3
"""Exercise client ingestion boundaries without connecting to a live store."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('client_ingest', Path(__file__).with_name('mori-client-ingest.py'))
ingest = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ingest)


class ClientIngestTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.repo = self.root / 'checkout with spaces'
        (self.repo / 'mori').mkdir(parents=True)
        (self.repo / 'mori/repo-id').write_text('repo_expected\n')
        self.project = {'namespace': 'example', 'name': 'project', 'repo_id': 'repo_expected', 'path': str(self.repo)}

    def test_identity_mismatch_is_skipped(self):
        self.project['repo_id'] = 'repo_other'
        self.assertIsNone(ingest.eligible_path(self.project, self.root))

    def test_missing_checkout_is_skipped(self):
        self.project['path'] = str(self.root / 'missing')
        self.assertIsNone(ingest.eligible_path(self.project, self.root))

    def test_checkout_outside_root_is_skipped(self):
        self.assertIsNone(ingest.eligible_path(self.project, self.root / 'elsewhere'))

    def run_scan(self, git_root=None, output='Ingested 0 changesets, 0 refs', code=0):
        responses = [
            subprocess.CompletedProcess([], 0, json.dumps([self.project]), ''),
            subprocess.CompletedProcess([], 0, str(git_root or self.repo) + '\n', ''),
            subprocess.CompletedProcess([], code, '', output),
        ]
        with patch.object(ingest.subprocess, 'run', side_effect=responses) as run:
            result = ingest.collect('/mori', self.root)
        return result, run.call_args_list

    def test_client_only_invokes_ingest_with_literal_path(self):
        result, calls = self.run_scan()
        self.assertEqual(result, 0)
        self.assertEqual(calls[2].args[0], ['/mori', 'automate', 'ingest', 'git', '--path', str(self.repo)])
        self.assertFalse(calls[2].kwargs.get('shell', False))

    def test_enclosing_git_repository_is_skipped(self):
        result, calls = self.run_scan(git_root=self.root)
        self.assertEqual((result, len(calls)), (0, 2))

    def test_first_halt_with_success_exit_is_reported(self):
        result, _ = self.run_scan(output='Orphaned checkpoint abc, halting until reset with: ...')
        self.assertEqual(result, 1)

    def test_failed_ingest_is_reported(self):
        result, _ = self.run_scan(output='store unavailable', code=1)
        self.assertEqual(result, 1)


if __name__ == '__main__':
    unittest.main()
