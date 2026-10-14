#!/usr/bin/env python3
"""Create separate machine keys without replacing existing key pairs."""
import argparse
import os
from pathlib import Path
import re
import stat
import subprocess


def prepare_keys(host, directory, github_passphrase=False):
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]", host):
        raise ValueError("host must be a lowercase DNS label")
    if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
        raise ValueError("SSH directory is a symlink or not a directory")
    pairs = [(directory / "id_ed25519", "github"), (directory / "agenix_ed25519", "agenix")]
    public_keys = []
    # Validate every destination before generating either key.
    for private, _purpose in pairs:
        public = Path(str(private) + ".pub")
        existing = []
        for candidate in (private, public):
            try:
                metadata = candidate.lstat()
            except FileNotFoundError:
                existing.append(False)
                continue
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
                raise ValueError("key destination must be an owned regular file: " + str(candidate))
            existing.append(True)
        if any(existing) and not all(existing):
            raise ValueError("incomplete key pair; inspect it before continuing: " + str(private))
        if all(existing):
            subprocess.run(["ssh-keygen", "-lf", str(public)], check=True, stdout=subprocess.DEVNULL)
            fields = public.read_text().split()
            if len(fields) < 2 or fields[0] != "ssh-ed25519":
                raise ValueError("existing public key must be Ed25519: " + str(public))
            public_keys.append(fields[:2])
    if len(public_keys) == 2 and public_keys[0] == public_keys[1]:
        raise ValueError("GitHub and agenix must have distinct key pairs; inspect existing keys")
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    directory.chmod(0o700)
    for private, purpose in pairs:
        if private.exists():
            print("KEPT: " + str(private))
        else:
            command = ["ssh-keygen", "-q", "-t", "ed25519", "-a", "100", "-C", f"shinzui@{host}-{purpose}", "-f", str(private)]
            if purpose == "agenix" or not github_passphrase:
                command += ["-N", ""]
            subprocess.run(command, check=True)
            print("CREATED: " + str(private))
        private.chmod(0o600)
        subprocess.run(["ssh-keygen", "-lf", str(private) + ".pub"], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host")
    parser.add_argument("--github-passphrase", action="store_true", help="prompt privately for a passphrase when creating the GitHub key")
    parser.add_argument("--ssh-dir", type=Path, default=Path.home() / ".ssh", help="alternate directory for isolated verification")
    args = parser.parse_args()
    try:
        prepare_keys(args.host, args.ssh_dir, args.github_passphrase)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"CONFLICT: {error}\n")


if __name__ == "__main__":
    main()
