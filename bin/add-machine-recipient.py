#!/usr/bin/env python3
"""Enroll a public agenix recipient in both tiers; never rekey or publish."""
import argparse
import base64
from pathlib import Path
import re
import stat
import struct

IDENTIFIER = r"[A-Za-z_][A-Za-z0-9_'-]*"


def read_public_key(path):
    if not stat.S_ISREG(path.lstat().st_mode):
        raise ValueError("public key must be a regular file")
    lines = path.read_text().strip().splitlines()
    fields = lines[0].split() if len(lines) == 1 else []
    if len(fields) < 2 or fields[0] != "ssh-ed25519":
        raise ValueError("expected one Ed25519 public key, never a private key")
    blob = base64.b64decode(fields[1], validate=True)
    expected_prefix = struct.pack(">I", 11) + b"ssh-ed25519" + struct.pack(">I", 32)
    if len(blob) != len(expected_prefix) + 32 or not blob.startswith(expected_prefix):
        raise ValueError("invalid Ed25519 public-key encoding")
    return "ssh-ed25519 " + base64.b64encode(blob).decode()


def add_recipient(contents, name, public_key):
    list_pattern = r"(?m)^([ \t]*workstationRecipients\s*=\s*\[)([^\]]*)(\]\s*;)"
    lists = list(re.finditer(list_pattern, contents))
    if len(lists) != 1:
        raise ValueError("expected exactly one literal workstationRecipients list")
    match = lists[0]
    recipients = match.group(2).split()
    if not recipients or any(not re.fullmatch(IDENTIFIER, value) for value in recipients):
        raise ValueError("recipient list must contain existing named recipients")
    declarations = list(re.finditer(r'(?m)^\s*(' + IDENTIFIER + r')\s*=\s*"(ssh-ed25519 [A-Za-z0-9+/=]+)(?:[^"\n]*)"\s*;', contents))
    same_key = next((entry.group(1) for entry in declarations if entry.group(2) == public_key), None)
    existing_name = next((entry for entry in declarations if entry.group(1) == name), None)
    if len({entry.group(1) for entry in declarations}) != len(declarations):
        raise ValueError("duplicate recipient declarations")
    if len(set(recipients)) != len(recipients) or not set(recipients).issubset({entry.group(1) for entry in declarations}):
        raise ValueError("recipient list must contain unique declared SSH keys")
    if existing_name is None and re.search(r"(?m)^\s*" + re.escape(name) + r"\s*=", contents):
        raise ValueError("recipient name collides with an existing binding")
    if existing_name and existing_name.group(2) != public_key:
        raise ValueError("recipient name already has another key; use --recipient-name for a new enrollment")
    rules = re.findall(r"publicKeys\s*=\s*([^;]+);", contents)
    if not rules or any(value.strip() != "workstationRecipients" for value in rules):
        raise ValueError("all secret rules must use workstationRecipients")
    selected_name = same_key or name
    if selected_name in recipients:
        return contents
    recipients.append(selected_name)
    updated_list = match.group(1) + " " + " ".join(recipients) + " " + match.group(3)
    if same_key is None:
        updated_list = f'  {name} = "{public_key}";\n' + updated_list.lstrip("\n")
    return contents[:match.start()] + updated_list + contents[match.end():]


def enroll(host, public_file, public_repo, private_repo, recipient_name=None):
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]", host):
        raise ValueError("host must be a lowercase DNS label")
    name = recipient_name or "machine_" + host.replace("-", "_")
    if not re.fullmatch(r"machine_[A-Za-z0-9_]+", name):
        raise ValueError("recipient name must start with machine_ and contain letters, digits or underscores")
    public_key = read_public_key(public_file)
    changes = []
    for repository in (public_repo, private_repo):
        rules = repository / "secrets/secrets.nix"
        if not stat.S_ISREG(rules.lstat().st_mode):
            raise ValueError("recipient rules must be regular files")
        old = rules.read_text()
        changes.append((rules, old, add_recipient(old, name, public_key)))
    # Both tiers must validate before either is changed.
    for rules, old, new in changes:
        if old == new:
            print("KEPT: recipient already enrolled in " + str(rules))
        else:
            rules.write_text(new)
            print("UPDATED: " + str(rules))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host")
    parser.add_argument("public_key", type=Path)
    parser.add_argument("--private-repo", type=Path, default=Path.home() / "Keikaku/dotfiles-private.nix")
    parser.add_argument("--recipient-name")
    args = parser.parse_args()
    try:
        enroll(args.host, args.public_key, Path(__file__).absolute().parent.parent, args.private_repo, args.recipient_name)
    except (OSError, ValueError) as error:
        parser.exit(1, f"CONFLICT: {error}\n")


if __name__ == "__main__":
    main()
