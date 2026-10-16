#!/usr/bin/env python3
"""Verify repeatable app installation without Spotlight, downloads, or sudo."""
import json
import os
from pathlib import Path
import plistlib
import pwd
import subprocess
import tempfile
import unittest

INSTALLER = Path(__file__).resolve().with_name("install-app-store-apps.sh")


def make_app(path, bundle_id="com.example.App", receipt=True, executable=True):
    contents = path / "Contents"
    contents.mkdir(parents=True, exist_ok=True)
    (contents / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": bundle_id, "CFBundleExecutable": "App",
    }))
    if receipt:
        (contents / "_MASReceipt").mkdir(exist_ok=True)
        (contents / "_MASReceipt/receipt").write_bytes(b"fixture receipt")
    if executable:
        (contents / "MacOS").mkdir(exist_ok=True)
        binary = contents / "MacOS/App"
        binary.write_text("#!/bin/sh\nexit 0\n")
        binary.chmod(0o700)


class AppStoreTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-app-store-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.app = self.root / "Example App.app"
        self.calls = self.root / "calls"
        self.mas = self.root / "mas"
        self.mas.write_text("#!/usr/bin/env python3\n" + '''
import json, os, pathlib, runpy, sys
root = pathlib.Path(__file__).parent
with (root / "calls").open("a") as log:
    log.write(json.dumps(sys.argv[1:]) + "\\n")
if sys.argv[1:] not in (["install", "123"], ["get", "123"]):
    sys.exit("Unexpected command (Spotlight and updates must not be used)")
if os.environ.get("FAIL_INSTALL"):
    sys.exit(1)
if os.environ.get("NEEDS_ACQUISITION") and sys.argv[1] == "install":
    sys.exit(1)
if not os.environ.get("INCOMPLETE_INSTALL"):
    runpy.run_path(os.environ["TEST_MODULE"])["make_app"](root / "Example App.app")
if os.environ.get("FAIL_AFTER_INSTALL"):
    sys.exit(1)
''')
        self.mas.chmod(0o700)

    def run_installer(self, **extra_env):
        return subprocess.run(
            ["/bin/bash", str(INSTALLER), str(self.mas),
             pwd.getpwuid(os.getuid()).pw_name, "Example App", "123",
             str(self.app), "com.example.App"],
            env={**os.environ, "TEST_MODULE": str(Path(__file__).resolve()), **extra_env},
            text=True, capture_output=True,
        )

    def test_existing_app_needs_no_mas_commands_across_rebuilds(self):
        make_app(self.app)
        for _ in range(2):
            result = self.run_installer()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("keeping Example App", result.stdout)
        self.assertFalse(self.calls.exists())

    def test_fresh_machine_installs_once_then_skips(self):
        for _ in range(2):
            result = self.run_installer()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), [json.dumps(["install", "123"])])

    def test_unowned_free_app_falls_back_to_acquisition_once(self):
        for _ in range(2):
            result = self.run_installer(NEEDS_ACQUISITION="1")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), [
            json.dumps(["install", "123"]), json.dumps(["get", "123"]),
        ])

    def test_failure_after_install_does_not_trigger_acquisition(self):
        result = self.run_installer(FAIL_AFTER_INSTALL="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), [json.dumps(["install", "123"])])

    def test_wrong_bundle_is_not_replaced(self):
        make_app(self.app, bundle_id="com.example.Other")
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_non_app_store_installation_is_not_replaced(self):
        make_app(self.app, receipt=False)
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_incomplete_existing_app_is_not_accepted(self):
        make_app(self.app, executable=False)
        self.assertNotEqual(self.run_installer().returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_failed_download_fails_activation(self):
        result = self.run_installer(FAIL_INSTALL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("rerun the rebuild", result.stderr)
        self.assertIn("both mas install and mas get failed", result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), [
            json.dumps(["install", "123"]), json.dumps(["get", "123"]),
        ])

    def test_success_exit_without_installed_app_is_rejected(self):
        result = self.run_installer(INCOMPLETE_INSTALL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not be verified", result.stderr)


if __name__ == "__main__":
    unittest.main()
