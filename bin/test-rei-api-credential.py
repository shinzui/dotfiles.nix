#!/usr/bin/env python3
"""Check private credential selection without reading deployed credentials."""
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).with_name('rei-api-credential.py')


class CredentialSelection(unittest.TestCase):
    def invoke(self, mapping, mode='token', actor='human'):
        with tempfile.TemporaryDirectory(prefix='rei-credential-test-') as directory:
            path = pathlib.Path(directory) / 'mapping'
            path.write_text(mapping)
            args = [sys.executable, str(SCRIPT), mode, str(path)]
            if mode == 'token':
                args.append(actor)
            return subprocess.run(args, text=True, capture_output=True)

    def test_preserves_each_existing_performer(self):
        mapping = 'owner-token=human,mina-token=agent:mina'
        for actor, token in [('human', 'owner-token'), ('agent:mina', 'mina-token')]:
            with self.subTest(actor=actor):
                result = self.invoke(mapping, actor=actor)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, token + '\n')

    def test_only_owner_receives_named_foreground_recorders(self):
        result = self.invoke('owner-token=human,mina-token=agent:mina', mode='policies')
        self.assertEqual(result.returncode, 0)
        policies = json.loads(result.stdout)
        self.assertEqual(len(policies), 1)
        self.assertEqual(policies[0]['token'], 'owner-token')
        self.assertEqual(set(policies[0]['profiles']), {'claude-code', 'codex'})
        self.assertNotIn('mina-token', result.stdout)

    def test_ambiguous_or_malformed_mapping_refuses_without_disclosure(self):
        for mapping in ['bad-secret-value', 'secret=human,secret=agent:mina',
                        'secret-one=human,secret-two=human', ' =human',
                        'secret= ', 'mina-secret=agent:mina']:
            with self.subTest(mapping=mapping):
                result = self.invoke(mapping)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, '')
                self.assertNotIn('secret', result.stderr)


if __name__ == '__main__':
    unittest.main()
