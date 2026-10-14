#!/usr/bin/env python3
"""Prepare encrypted Nix authentication before activation and verify its handoff."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile
import urllib.error
import urllib.request

SCHEMA = 1
CONFIG_NAME = "access-tokens.conf"
META_NAME = "metadata.json"
DEFAULT_STATE = Path.home() / ".local/state/dotfiles-bootstrap/nix-auth"


class AuthError(Exception):
    """Only fixed, nonsecret diagnostics may escape this module."""


def validate_host(host):
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,61}[a-z0-9]|[a-z]", host):
        raise AuthError("host must be a lowercase DNS label")


def normalize_config(content):
    try:
        text = content.decode("ascii").strip()
    except UnicodeError:
        raise AuthError("credential must be an ASCII GitHub token configuration") from None
    match = re.fullmatch(r"access-tokens\s*=\s*github\.com=((?:github_pat_|ghp_)[A-Za-z0-9_]{30,})", text)
    if not match:
        raise AuthError("expected exactly one GitHub access-tokens setting; contents suppressed")
    return ("access-tokens = github.com=" + match.group(1) + "\n").encode()


def owned_regular(path, private=False):
    try:
        metadata = path.lstat()
    except OSError:
        raise AuthError("required file is missing or inaccessible") from None
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
        raise AuthError("file must be an owned regular file, not a symlink")
    if private and stat.S_IMODE(metadata.st_mode) != 0o600:
        raise AuthError("credential file must have mode 0600")


def private_directory(path, create=False):
    if create:
        path.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        metadata = path.lstat()
    except OSError:
        raise AuthError("authentication state directory is missing") from None
    if not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != os.getuid():
        raise AuthError("authentication directory must be owned and must not be a symlink")
    if stat.S_IMODE(metadata.st_mode) != 0o700:
        raise AuthError("authentication directory must have mode 0700")


def state_path(host, state_root):
    validate_host(host)
    return state_root / host


def read_state(host, state_root):
    private_directory(state_root)
    directory = state_path(host, state_root)
    private_directory(directory)
    metadata_file = directory / META_NAME
    credential = directory / CONFIG_NAME
    owned_regular(metadata_file, private=True)
    owned_regular(credential, private=True)
    try:
        metadata = json.loads(metadata_file.read_text())
    except (ValueError, OSError):
        raise AuthError("invalid authentication state metadata") from None
    if metadata != {"schema": SCHEMA, "host": host}:
        raise AuthError("authentication state belongs to a different host or schema")
    return directory, credential, normalize_config(credential.read_bytes())


def atomic_write(path, content):
    descriptor, temporary = tempfile.mkstemp(prefix=".nix-auth-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def prepare(host, ciphertext, identity, state_root):
    validate_host(host)
    owned_regular(ciphertext)
    owned_regular(identity, private=True)
    age = shutil.which("age")
    if not age:
        raise AuthError("age is missing; use a standalone nixpkgs age/Python shell, not this flake's dev shell")
    result = subprocess.run([age, "-d", "-i", str(identity), str(ciphertext)], capture_output=True)
    if result.returncode:
        raise AuthError("token decryption failed; diagnostic output suppressed")
    content = normalize_config(result.stdout)
    # Validate existing destinations before writing. Both directories are private.
    private_directory(state_root, create=True)
    directory = state_path(host, state_root)
    private_directory(directory, create=True)
    if any(p.name not in {CONFIG_NAME, META_NAME} for p in directory.iterdir()):
        raise AuthError("unexpected files in authentication state; inspect before continuing")
    if any((directory / name).exists() or (directory / name).is_symlink() for name in (CONFIG_NAME, META_NAME)):
        _, credential, existing = read_state(host, state_root)
        if existing != content:
            raise AuthError("existing bootstrap credential differs; finish its handoff before replacement")
        print("KEPT: matching bootstrap credential")
    else:
        atomic_write(directory / META_NAME, json.dumps({"schema": SCHEMA, "host": host}).encode())
        atomic_write(directory / CONFIG_NAME, content)
        print("PREPARED: bootstrap Nix authentication (credential contents suppressed)")


def command_with_auth(host, state_root, command, use_sudo=False):
    _, credential, _ = read_state(host, state_root)
    if not command:
        raise AuthError("provide a command after --")
    environment = os.environ.copy()
    # NIX_CONFIG is read last and could override this credential.
    environment.pop("NIX_CONFIG", None)
    environment["NIX_USER_CONF_FILES"] = str(credential.absolute())
    if use_sudo:
        command = ["sudo", "env", "-u", "NIX_CONFIG", "NIX_USER_CONF_FILES=" + str(credential.absolute()), *command]
    return command, environment


def token_from_config(content):
    return normalize_config(content).decode().strip().split("github.com=", 1)[1]


def configured_token(environment, use_sudo=False):
    nix = shutil.which("nix")
    if not nix:
        raise AuthError("nix is unavailable")
    command = [nix, "config", "show", "--json"]
    if use_sudo:
        command = ["sudo", "-n", "env", "-u", "NIX_CONFIG", "-u", "NIX_USER_CONF_FILES", *command]
    result = subprocess.run(command, env=environment, capture_output=True)
    if result.returncode:
        raise AuthError("cannot check normal Nix settings; sudo -v may be required (output suppressed)")
    try:
        value = json.loads(result.stdout)["access-tokens"]["value"]
        if isinstance(value, dict):
            token = value.get("github.com")
        else:
            token = next((pair.split("=", 1)[1] for pair in value.split() if pair.startswith("github.com=")), None)
    except (ValueError, KeyError, TypeError, AttributeError):
        raise AuthError("cannot parse Nix authentication settings; output suppressed") from None
    return token


def probe_github(token, repository):
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise AuthError("invalid probe repository")
    request = urllib.request.Request(
        "https://api.github.com/repos/" + repository + "/commits/HEAD",
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json", "User-Agent": "dotfiles-bootstrap"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status != 200:
                raise AuthError("GitHub read probe failed; response suppressed")
    except (OSError, urllib.error.URLError):
        raise AuthError("GitHub read probe failed; response suppressed") from None


def verify_managed(expected, managed_file, repository):
    try:
        metadata = managed_file.stat()  # agenix intentionally installs runtime symlinks.
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid() or stat.S_IMODE(metadata.st_mode) != 0o600:
            raise AuthError("managed credential must be owned by this user with mode 0600")
        managed = normalize_config(managed_file.read_bytes())
    except OSError:
        raise AuthError("managed agenix credential is not installed yet") from None
    if managed != expected:
        raise AuthError("managed credential differs from the bootstrap credential")
    token = token_from_config(expected)
    environment = os.environ.copy()
    for name in ("NIX_CONFIG", "NIX_USER_CONF_FILES"):
        environment.pop(name, None)
    for root in (False, True):
        if configured_token(environment, use_sudo=root) != token:
            raise AuthError("normal user/root Nix configuration has not taken over authentication")
    probe_github(token, repository)


def cleanup(host, state_root, managed_file, repository):
    directory, credential, expected = read_state(host, state_root)
    if any(p.name not in {CONFIG_NAME, META_NAME} for p in directory.iterdir()):
        raise AuthError("unexpected files in authentication state; cleanup refused")
    if managed_file.absolute() == credential.absolute() or managed_file.resolve() == credential.resolve():
        raise AuthError("managed credential cannot be the temporary credential")
    verify_managed(expected, managed_file, repository)
    # Test again with the bootstrap filename unavailable. Restore it on failure.
    pending = directory / ".pending-cleanup"
    credential.rename(pending)
    try:
        verify_managed(expected, managed_file, repository)
    except BaseException:
        pending.rename(credential)
        raise
    pending.unlink()
    (directory / META_NAME).unlink()
    directory.rmdir()
    print("PASS: managed user/root authentication verified; bootstrap credential removed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    for action in ("prepare", "run", "verify", "cleanup"):
        child = sub.add_parser(action)
        child.add_argument("host")
        child.add_argument("--state-dir", type=Path, default=DEFAULT_STATE)
        if action == "prepare":
            child.add_argument("--ciphertext", required=True, type=Path)
            child.add_argument("--identity", type=Path, default=Path.home() / ".ssh/agenix_ed25519")
        elif action == "run":
            child.add_argument("--sudo", action="store_true")
        else:
            child.add_argument("--managed-file", type=Path, default=Path("/run/agenix/access_token"))
            child.add_argument("--probe-repo", default="shinzui/kazuha")
    # Split explicitly so command arguments never become helper options.
    import sys
    arguments = sys.argv[1:]
    command = []
    if "--" in arguments:
        index = arguments.index("--")
        arguments, command = arguments[:index], arguments[index + 1:]
    args = parser.parse_args(arguments)
    try:
        if os.getuid() == 0:
            raise AuthError("run this helper as the workstation owner; use run --sudo for switches")
        if not args.state_dir.is_absolute():
            raise AuthError("state directory must be absolute")
        if args.action == "prepare":
            prepare(args.host, args.ciphertext, args.identity, args.state_dir)
        elif args.action == "run":
            executable, environment = command_with_auth(args.host, args.state_dir, command, args.sudo)
            # Do not run token-printing/debug commands through this wrapper.
            raise SystemExit(subprocess.run(executable, env=environment).returncode)
        elif args.action == "verify":
            _, _, expected = read_state(args.host, args.state_dir)
            verify_managed(expected, args.managed_file, args.probe_repo)
            print("PASS: managed agenix token and normal user/root Nix authentication verified")
        else:
            cleanup(args.host, args.state_dir, args.managed_file, args.probe_repo)
    except AuthError as error:
        parser.exit(1, "CONFLICT: " + str(error) + "\n")
    except (OSError, ValueError, subprocess.SubprocessError):
        parser.exit(1, "CONFLICT: authentication operation failed; diagnostic output suppressed\n")


if __name__ == "__main__":
    main()
