#!/usr/bin/env python3
"""Check enrollment resume/conflict behavior using disposable keys and repositories."""
import contextlib
import io
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).absolute().parent.parent
KEYS = runpy.run_path(str(ROOT / "bin/bootstrap-machine-keys.py"))
RULES = runpy.run_path(str(ROOT / "bin/add-machine-recipient.py"))


class EnrollmentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="machine-enrollment-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.ssh = self.base / "ssh"
        with contextlib.redirect_stdout(io.StringIO()):
            KEYS["prepare_keys"]("atlas", self.ssh)
        self.pub = self.ssh / "agenix_ed25519.pub"
        self.key = RULES["read_public_key"](self.pub)
        old_key = RULES["read_public_key"](self.ssh / "id_ed25519.pub")
        self.original = ('let\n  original = "' + old_key + '";\n'
                         '  workstationRecipients = [ original ];\nin {\n'
                         '  "test.age".publicKeys = workstationRecipients;\n}\n')
        self.public = self.base / "public"
        self.private = self.base / "private"
        for repo in (self.public, self.private):
            (repo / "secrets").mkdir(parents=True)
            (repo / "secrets/secrets.nix").write_text(self.original)

    def enroll(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()):
            RULES["enroll"]("atlas", self.pub, self.public, self.private, **kwargs)

    def test_keys_resume_and_permissions(self):
        before = {p.name: p.read_bytes() for p in self.ssh.iterdir()}
        with contextlib.redirect_stdout(io.StringIO()):
            KEYS["prepare_keys"]("atlas", self.ssh)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.ssh.iterdir()})
        self.assertEqual(self.ssh.stat().st_mode & 0o777, 0o700)
        for name in ("id_ed25519", "agenix_ed25519"):
            self.assertEqual((self.ssh / name).stat().st_mode & 0o777, 0o600)
        self.assertNotEqual(RULES["read_public_key"](self.ssh / "id_ed25519.pub"), self.key)

    def test_partial_pair_validated_before_generation(self):
        target = self.base / "partial"
        target.mkdir()
        (target / "agenix_ed25519.pub").write_bytes(self.pub.read_bytes())
        with self.assertRaises(ValueError):
            KEYS["prepare_keys"]("atlas", target)
        self.assertFalse((target / "id_ed25519").exists())

    def test_symlink_and_invalid_host(self):
        target = self.base / "link"
        target.symlink_to(self.ssh)
        with self.assertRaises(ValueError):
            KEYS["prepare_keys"]("atlas", target)
        with self.assertRaises(ValueError):
            KEYS["prepare_keys"]("../escape", self.ssh)
        public_link = self.base / "pub-link"
        public_link.symlink_to(self.pub)
        with self.assertRaises(ValueError):
            RULES["read_public_key"](public_link)

    def test_existing_shared_key_rejected(self):
        for suffix in ("", ".pub"):
            (self.ssh / ("agenix_ed25519" + suffix)).write_bytes((self.ssh / ("id_ed25519" + suffix)).read_bytes())
        with self.assertRaises(ValueError):
            KEYS["prepare_keys"]("atlas", self.ssh)

    def test_both_tiers_and_resume_and_nix_syntax(self):
        self.enroll()
        paths = [repo / "secrets/secrets.nix" for repo in (self.public, self.private)]
        before = [p.read_bytes() for p in paths]
        self.enroll()
        self.assertEqual(before, [p.read_bytes() for p in paths])
        for p in paths:
            self.assertIn("[ original machine_atlas ]", p.read_text())
            result = subprocess.run(["nix-instantiate", "--eval", "--strict", "--json", str(p)], check=True, capture_output=True, text=True)
            self.assertIn(self.key, result.stdout)

    def test_invalid_private_does_not_mutate_public(self):
        (self.private / "secrets/secrets.nix").write_text("let in {}")
        with self.assertRaises(ValueError):
            self.enroll()
        self.assertEqual((self.public / "secrets/secrets.nix").read_text(), self.original)

    def test_key_reuse_name_collision_and_rotation(self):
        self.enroll()
        contents = (self.public / "secrets/secrets.nix").read_text()
        self.assertEqual(contents, RULES["add_recipient"](contents, "machine_alias", self.key))
        other_key = RULES["read_public_key"](self.ssh / "id_ed25519.pub")
        with self.assertRaises(ValueError):
            RULES["add_recipient"](contents, "machine_atlas", other_key)
        with self.assertRaises(ValueError):
            RULES["add_recipient"](self.original.replace("let\n", "let\n  machine_atlas = 1;\n"), "machine_atlas", self.key)

    def test_reject_private_or_malformed_key(self):
        for value in ("-----BEGIN OPENSSH PRIVATE KEY-----\n", "ssh-ed25519 AAAA\n", "ssh-ed25519 !!!!\n"):
            bad = self.base / "bad.pub"
            bad.write_text(value)
            with self.assertRaises(ValueError):
                RULES["read_public_key"](bad)
        self.pub.write_text(self.pub.read_text().strip() + ' unsafe-${comment}\n')
        self.assertEqual(self.key, RULES["read_public_key"](self.pub))


if __name__ == "__main__":
    unittest.main()
