#!/usr/bin/env python3
"""Check the remote-rei argv encoding end to end with harmless fake executables."""
import base64
import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).absolute().parent
DISPATCH = runpy.run_path(str(HERE / 'rei-ssh-dispatch.py'))
TRICKY = ['note', 'add', '$(touch pwned)', '; rm -rf ~', "it's", '"quoted"', 'a b', '', '*', '\n', '--', 'ünïcode']


def encode(args):
    # The same encoding as the client's remote rei in home/rei-mori-client.nix.
    return 'rei-argv:' + base64.b64encode(json.dumps(args).encode()).decode()


class DecodeTests(unittest.TestCase):
    def test_round_trip_preserves_boundaries(self):
        self.assertEqual(DISPATCH['decode_argv'](encode(TRICKY)), TRICKY)
        self.assertEqual(DISPATCH['decode_argv'](encode([])), [])

    def test_malformed_payloads_rejected(self):
        bad = [
            '', 'rei list', 'rei-argv:', 'rei-argv:!!!!', 'rei-argv:' + base64.b64encode(b'not json').decode(),
            'rei-argv:' + base64.b64encode(b'{"a": 1}').decode(), encode('string'), encode([1, 2]),
            encode([['nested']]), encode([None]), encode(['nul\0byte']),
        ]
        for command in bad:
            with self.assertRaises(ValueError, msg=command):
                DISPATCH['decode_argv'](command)

    def test_managed_rei_must_be_absolute(self):
        self.assertEqual(DISPATCH['rei_executable']({}), 'rei')
        self.assertEqual(DISPATCH['rei_executable']({'REI_SSH_DISPATCH_REI': '/opt/rei'}), '/opt/rei')
        with self.assertRaises(ValueError):
            DISPATCH['rei_executable']({'REI_SSH_DISPATCH_REI': 'bin/rei'})

    def test_main_refuses_without_exec(self):
        calls = []
        with contextlib.redirect_stderr(io.StringIO()):
            status = DISPATCH['main']({'SSH_ORIGINAL_COMMAND': 'rei list'}, calls.append, calls.append)
        self.assertEqual(status, 2)
        self.assertEqual(calls, [])


class EndToEndTests(unittest.TestCase):
    """Run the dispatcher as SSH would, with a fake rei that records its argv."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.record = self.root / 'argv.json'
        self.fake = self.root / 'fake-rei'
        self.fake.write_text('#!' + sys.executable + '\nimport json, sys\n'
                             'json.dump(sys.argv[1:], open(' + repr(str(self.record)) + ', "w"))\n'
                             'sys.exit(int(sys.argv[-1]) if sys.argv[-1].isdigit() else 0)\n')
        self.fake.chmod(0o755)

    def tearDown(self):
        self.tmp.cleanup()

    def dispatch(self, command):
        env = {'SSH_ORIGINAL_COMMAND': command, 'REI_SSH_DISPATCH_REI': str(self.fake),
               'HOME': str(self.root), 'PATH': '/usr/bin:/bin'}
        return subprocess.run([sys.executable, str(HERE / 'rei-ssh-dispatch.py')], env=env,
                              capture_output=True, text=True, cwd=self.root)

    def test_shell_metacharacters_arrive_as_data(self):
        result = self.dispatch(encode(TRICKY))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.record.read_text()), TRICKY)
        self.assertFalse((self.root / 'pwned').exists())

    def test_exit_status_propagates(self):
        self.assertEqual(self.dispatch(encode(['fail', '7'])).returncode, 7)

    def test_malformed_payload_never_runs_rei(self):
        result = self.dispatch('rei-argv:not-base64!')
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.record.exists())

    def test_client_encoder_matches(self):
        # The client's one-liner, run with real argv, must produce what we decode.
        script = 'import base64,json,sys; print(base64.b64encode(json.dumps(sys.argv[1:]).encode()).decode())'
        payload = subprocess.run([sys.executable, '-c', script, *TRICKY], capture_output=True, text=True,
                                 check=True).stdout.strip()
        self.assertEqual(DISPATCH['decode_argv']('rei-argv:' + payload), TRICKY)


if __name__ == '__main__':
    unittest.main()
