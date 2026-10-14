#!/usr/bin/env python3
"""Verify credential preservation, redaction and the managed handoff in isolation."""
import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).absolute().parent.parent
M = runpy.run_path(str(ROOT / 'bin/bootstrap-nix-auth.py'))
# Deliberately synthetic; no actual credential is present in this file.
TOKEN = 'github_' + 'pat_' + 'synthetic_' + 'x' * 40
CONTENT = ('access-tokens = github.com=' + TOKEN + '\n').encode()


class BootstrapAuthTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='bootstrap-nix-auth-')
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.state = self.base / 'state'
        self.identity = self.base / 'identity'
        subprocess.run(['ssh-keygen', '-q', '-t', 'ed25519', '-N', '', '-f', str(self.identity)], check=True)
        self.identity.chmod(0o600)
        self.ciphertext = self.base / 'token.age'
        public = Path(str(self.identity) + '.pub').read_text().strip()
        subprocess.run(['age', '-r', public, '-o', str(self.ciphertext)], input=CONTENT, check=True)
        self.output = io.StringIO()

    def prepare(self):
        with contextlib.redirect_stdout(self.output):
            M['prepare']('atlas', self.ciphertext, self.identity, self.state)
        self.assertNotIn(TOKEN, self.output.getvalue())

    def test_prepare_resume_permissions_and_argv(self):
        self.prepare()
        directory, credential, content = M['read_state']('atlas', self.state)
        self.assertEqual(content, CONTENT)
        before = credential.read_bytes()
        self.prepare()
        self.assertEqual(before, credential.read_bytes())
        self.assertEqual(credential.stat().st_mode & 0o777, 0o600)
        self.assertEqual(directory.stat().st_mode & 0o777, 0o700)
        with patch.dict(os.environ, {'NIX_CONFIG': 'unrelated configuration'}):
            command, env = M['command_with_auth']('atlas', self.state, ['nix', 'build'], True)
        self.assertEqual(command[:4], ['sudo', 'env', '-u', 'NIX_CONFIG'])
        self.assertIn('NIX_USER_CONF_FILES=' + str(credential), command)
        self.assertNotIn('NIX_CONFIG', env)
        self.assertEqual(env['NIX_USER_CONF_FILES'], str(credential))
        self.assertNotIn(TOKEN, '\n'.join(command))

    def test_failed_decryption_and_invalid_config_are_redacted(self):
        self.ciphertext.write_bytes(b'invalid ciphertext ' + TOKEN.encode())
        with self.assertRaises(M['AuthError']) as error:
            self.prepare()
        self.assertNotIn(TOKEN, str(error.exception))
        self.assertFalse(self.state.exists())
        for value in (TOKEN.encode(), CONTENT + b'extra-setting = yes\n', b'access-tokens = github.com=bad'):
            with self.assertRaises(M['AuthError']) as error:
                M['normalize_config'](value)
            self.assertNotIn(TOKEN, str(error.exception))

    def test_symlink_and_wrong_host_metadata(self):
        self.state.symlink_to(self.base)
        with self.assertRaises(M['AuthError']):
            self.prepare()
        self.state.unlink()
        self.prepare()
        (self.state / 'atlas/metadata.json').write_text(json.dumps({'schema': 1, 'host': 'other'}))
        with self.assertRaises(M['AuthError']):
            M['read_state']('atlas', self.state)

    def test_different_existing_credential_is_preserved(self):
        self.prepare()
        credential = self.state / 'atlas/access-tokens.conf'
        different = CONTENT.replace(b'synthetic_', b'different_')
        credential.write_bytes(different)
        with self.assertRaises(M['AuthError']):
            self.prepare()
        self.assertEqual(credential.read_bytes(), different)

    def test_cleanup_failure_preserves_or_restores_credential(self):
        self.prepare()
        credential = self.state / 'atlas/access-tokens.conf'
        fake_managed = self.base / 'managed'
        for outcomes in ([M['AuthError']('not activated')], [None, M['AuthError']('still depended on temporary file')]):
            with patch.dict(M['cleanup'].__globals__, {'verify_managed': unittest.mock.Mock(side_effect=outcomes)}):
                with self.assertRaises(M['AuthError']):
                    M['cleanup']('atlas', self.state, fake_managed, 'shinzui/kazuha')
            self.assertEqual(credential.read_bytes(), CONTENT)
            self.assertFalse((credential.parent / '.pending-cleanup').exists())

    def test_successful_cleanup_checks_without_bootstrap_file(self):
        self.prepare()
        credential = self.state / 'atlas/access-tokens.conf'
        observed = []
        def verify(*args):
            observed.append(credential.exists())
        with patch.dict(M['cleanup'].__globals__, {'verify_managed': verify}):
            with contextlib.redirect_stdout(self.output):
                M['cleanup']('atlas', self.state, self.base / 'managed', 'shinzui/kazuha')
        self.assertEqual(observed, [True, False])
        self.assertFalse(credential.parent.exists())
        self.assertNotIn(TOKEN, self.output.getvalue())

    def test_managed_verification_requires_both_nix_users_and_matching_file(self):
        managed = self.base / 'managed'
        managed.write_bytes(CONTENT)
        managed.chmod(0o600)
        flags = []
        def configured(environment, use_sudo=False):
            flags.append(use_sudo)
            self.assertNotIn('NIX_USER_CONF_FILES', environment)
            return TOKEN
        with patch.dict(M['verify_managed'].__globals__, {'configured_token': configured, 'probe_github': lambda *args: None}):
            M['verify_managed'](CONTENT, managed, 'shinzui/kazuha')
        self.assertEqual(flags, [False, True])
        managed.write_bytes(CONTENT.replace(b'synthetic_', b'different_'))
        with self.assertRaises(M['AuthError']):
            M['verify_managed'](CONTENT, managed, 'shinzui/kazuha')

    def test_nix_settings_output_is_captured_and_http_errors_redacted(self):
        data=json.dumps({'access-tokens': {'value': {'github.com': TOKEN}}}).encode()
        with patch.dict(M['configured_token'].__globals__, {'subprocess': unittest.mock.Mock(run=lambda *a, **k: subprocess.CompletedProcess(a, 0, data)), 'shutil': unittest.mock.Mock(which=lambda name: name)}):
            self.assertEqual(M['configured_token']({}, True), TOKEN)
        with patch('urllib.request.urlopen', side_effect=OSError(TOKEN)):
            with self.assertRaises(M['AuthError']) as error:
                M['probe_github'](TOKEN, 'shinzui/kazuha')
        self.assertNotIn(TOKEN, str(error.exception))


if __name__ == '__main__':
    unittest.main()
