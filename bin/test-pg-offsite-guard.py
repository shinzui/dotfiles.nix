#!/usr/bin/env python3
"""Exercise pg-offsite-guard.py against temporary directories and a fake pg_controldata."""
import contextlib
import io
from pathlib import Path
import runpy
import tempfile
import unittest

GUARD = runpy.run_path(str(Path(__file__).absolute().with_name('pg-offsite-guard.py')))
MARKER = GUARD['MARKER']


class GuardTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.fake = self.root / 'pg_controldata'
        self.set_identifier('7696681397435454777')
        self.destination = self.root / 'postgresql-backups-yujin'

    def tearDown(self):
        self.tmp.cleanup()

    def set_identifier(self, identifier):
        self.fake.write_text('#!/bin/sh\nprintf "pg_control version number: 1800\\n'
                             'Database system identifier:           %s\\n" "' + identifier + '"\n')
        self.fake.chmod(0o755)

    def run_guard(self, command, *extra, destination=None):
        argv = [command, '--pg-controldata', str(self.fake), '--data-dir', str(self.root),
                '--destination', str(destination or self.destination), *extra]
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return GUARD['main'](argv)

    def marker(self):
        return (self.destination / MARKER).read_text().strip()

    def test_missing_destination_is_created_and_marked(self):
        self.assertEqual(self.run_guard('check'), 0)
        self.assertEqual(self.marker(), '7696681397435454777')

    def test_empty_destination_is_marked(self):
        self.destination.mkdir()
        self.assertEqual(self.run_guard('check'), 0)
        self.assertEqual(self.marker(), '7696681397435454777')

    def test_matching_marker_passes_repeatedly(self):
        self.assertEqual(self.run_guard('check'), 0)
        (self.destination / 'pg_rman.ini').write_text('catalog')
        self.assertEqual(self.run_guard('check'), 0)

    def test_mismatched_marker_refuses_and_keeps_files(self):
        self.assertEqual(self.run_guard('check'), 0)
        (self.destination / 'pg_rman.ini').write_text('catalog')
        self.set_identifier('7400000000000000001')
        self.assertEqual(self.run_guard('check'), GUARD['REFUSED'])
        self.assertEqual(self.marker(), '7696681397435454777')
        self.assertEqual((self.destination / 'pg_rman.ini').read_text(), 'catalog')

    def test_non_empty_destination_without_marker_refuses(self):
        self.destination.mkdir()
        (self.destination / 'pg_rman.ini').write_text('catalog')
        self.assertEqual(self.run_guard('check'), GUARD['REFUSED'])
        self.assertFalse((self.destination / MARKER).exists())

    def test_adopt_requires_verification_and_a_catalog(self):
        self.destination.mkdir()
        (self.destination / 'other').write_text('x')
        self.assertEqual(self.run_guard('adopt', '--verified'), GUARD['REFUSED'])
        (self.destination / 'pg_rman.ini').write_text('catalog')
        self.assertEqual(self.run_guard('adopt'), GUARD['REFUSED'])
        self.assertFalse((self.destination / MARKER).exists())
        self.assertEqual(self.run_guard('adopt', '--verified'), 0)
        self.assertEqual(self.marker(), '7696681397435454777')
        self.assertEqual(self.run_guard('check'), 0)

    def test_adopt_never_replaces_another_marker(self):
        self.assertEqual(self.run_guard('check'), 0)
        (self.destination / 'pg_rman.ini').write_text('catalog')
        self.set_identifier('7400000000000000001')
        self.assertEqual(self.run_guard('adopt', '--verified'), GUARD['REFUSED'])
        self.assertEqual(self.marker(), '7696681397435454777')

    def test_symlinked_or_relative_destination_refuses(self):
        target = self.root / 'real'
        target.mkdir()
        self.destination.symlink_to(target)
        self.assertEqual(self.run_guard('check'), GUARD['REFUSED'])
        self.assertEqual(self.run_guard('check', destination='relative/path'), GUARD['REFUSED'])

    def test_failed_pg_controldata_refuses(self):
        self.fake.write_text('#!/bin/sh\nexit 1\n')
        self.assertEqual(self.run_guard('check'), GUARD['REFUSED'])
        self.assertFalse(self.destination.exists())


if __name__ == '__main__':
    unittest.main()
