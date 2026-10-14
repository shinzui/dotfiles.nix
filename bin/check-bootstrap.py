#!/usr/bin/env python3
"""Read-only new-machine prerequisite and selected-file checker."""
import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys

TARGETS = {"bootstrap-arm", "SungkyungM1X", "yujin"}
ACTIONS = {"managed", "public-file", "public-directory", "private", "reauthenticate", "recreate", "data-export", "exclude"}
REQUIRED_PUBLIC = {"nihongo/config.kdl", "seihou/config.dhall", "mori/config.dhall", "mori/agents"}
REQUIRED_PRIVATE = {"notion-hub-config", "notion-cli-config", "kubectl-config", "gcloud-config-default", "gcloud-config-labs", "gcloud-config-nb-exp", "gcloud-active-config", "nagare-local-context", "nagare-kubeconfig-intranet", "nagare-kubeconfig-tan-nb-exp"}


def safe_relative(value):
    if not isinstance(value, str) or not value or "\\" in value:
        raise ValueError("invalid relative path")
    p = PurePosixPath(value)
    if p.is_absolute() or any(part in ("", ".", "..") for part in value.split("/")):
        raise ValueError("invalid relative path")
    return value


def validate_policy(path):
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or data.get("schema_version") != 1 or not isinstance(data.get("entries"), list) or not isinstance(data.get("audit_top_level"), list):
        raise ValueError("invalid policy schema")
    audited = data["audit_top_level"]
    if len(audited) != 70 or any(not isinstance(p, str) or safe_relative(p) != p or "/" in p for p in audited) or len(set(audited)) != 70:
        raise ValueError("invalid audit inventory")
    seen = set()
    selected = set()
    for entry in data["entries"]:
        if not isinstance(entry, dict) or set(entry) != {"path", "action", "owner", "reason"}:
            raise ValueError("invalid policy entry")
        rel = safe_relative(entry["path"])
        if rel in seen or entry["action"] not in ACTIONS or not all(isinstance(entry[k], str) and entry[k] for k in ("owner", "reason")):
            raise ValueError("invalid or duplicate policy entry")
        seen.add(rel)
        if entry["action"] in ("public-file", "public-directory"):
            selected.add(rel)
    for rel in selected:
        for parent in PurePosixPath(rel).parents:
            if str(parent) in selected and any(e["path"] == str(parent) and e["action"] == "public-file" for e in data["entries"]):
                raise ValueError("public file overlaps selected child")
    if not REQUIRED_PUBLIC.issubset(selected):
        raise ValueError("required public sources missing from policy")
    top = {p for p in seen if "/" not in p}
    if top != set(audited):
        raise ValueError("policy does not cover all 70 audited top-level entries")
    return data


def validate_private(path, home):
    data = json.loads(path.read_text())
    if data.get("schema_version") != 1 or not isinstance(data.get("entries"), list):
        raise ValueError("invalid private policy schema")
    names = set()
    destinations = set()
    for e in data["entries"]:
        if not isinstance(e, dict) or not all(isinstance(e.get(k), str) and e[k] for k in ("source", "destination", "recovery_method")):
            raise ValueError("invalid private policy entry")
        if "secret_name" in e:
            name = e["secret_name"]
            if not isinstance(name, str) or not name or name in names:
                raise ValueError("invalid private secret mapping")
            dest = Path(e["destination"])
            if not dest.is_absolute() or ".." in dest.parts or not dest.is_relative_to(home) or str(dest) in destinations:
                raise ValueError("invalid private secret destination")
            names.add(name)
            destinations.add(str(dest))
    if not REQUIRED_PRIVATE.issubset(names):
        raise ValueError("required private secrets missing from policy")
    return data


def no_link_source(root, relative, desired):
    p = root
    for part in PurePosixPath(relative).parts:
        p = p / part
        try:
            mode = p.lstat().st_mode
        except FileNotFoundError:
            return False
        if stat.S_ISLNK(mode):
            return False
        if p != root / relative and not stat.S_ISDIR(mode):
            return False
    mode = p.lstat().st_mode
    return stat.S_ISREG(mode) if desired == "public-file" else stat.S_ISDIR(mode)


def target_state(home, rel, expected):
    target = home / ".config" / rel
    p = home / ".config"
    try:
        if not stat.S_ISDIR(p.lstat().st_mode):
            return "CONFLICT"
    except FileNotFoundError:
        return "PASS"
    for part in PurePosixPath(rel).parts[:-1]:
        p = p / part
        try:
            mode = p.lstat().st_mode
        except FileNotFoundError:
            break
        if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
            return "CONFLICT"
    try:
        mode = target.lstat().st_mode
    except FileNotFoundError:
        return "PASS"
    if not stat.S_ISLNK(mode):
        return "CONFLICT"
    # Inspect the first hop only. Home Manager installs a store-side files link;
    # its exact relative target is checked without entering /nix/store.
    first_hop = os.readlink(target)
    if first_hop == str(expected):
        return "PASS"
    hm_target = rf"/nix/store/[a-z0-9]{{32}}-home-manager-files/\.config/{re.escape(rel)}"
    return "PASS" if re.fullmatch(hm_target, first_hop) else "CONFLICT"


def private_parent_state(home, dest):
    parent = home
    for part in dest.relative_to(home).parts[:-1]:
        parent = parent / part
        try:
            mode = parent.lstat().st_mode
        except FileNotFoundError:
            return "MISSING"
        if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
            return "CONFLICT"
    return "PASS"


def secret_ready(home, dest):
    if private_parent_state(home, dest) != "PASS":
        return False
    try:
        link_mode = dest.lstat().st_mode
        if stat.S_ISLNK(link_mode):
            # Agenix links to /run/agenix. Reject arbitrary link chains before stat.
            if not os.readlink(dest).startswith("/run/agenix/"):
                return False
        elif not stat.S_ISREG(link_mode):
            return False
        s = dest.stat()
        parent = dest.parent.stat()
        return (stat.S_ISREG(s.st_mode) and stat.S_IMODE(s.st_mode) == 0o600
                and s.st_uid == os.getuid() and os.access(dest, os.R_OK)
                and stat.S_IMODE(parent.st_mode) & 0o077 == 0)
    except OSError:
        return False


def private_target_state(home, dest):
    parent_state = private_parent_state(home, dest)
    if parent_state == "CONFLICT":
        return "CONFLICT"
    if parent_state == "MISSING":
        return "PASS"
    try:
        mode = dest.lstat().st_mode
    except FileNotFoundError:
        return "PASS"
    if stat.S_ISLNK(mode) and os.readlink(dest).startswith("/run/agenix/"):
        return "PASS"
    return "CONFLICT"


def main():
    parser = argparse.ArgumentParser(prog="check-bootstrap.sh")
    parser.add_argument("target", choices=sorted(TARGETS))
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--home-dir", type=Path, default=Path("/Users/shinzui"))
    parser.add_argument("--source-dir", type=Path, default=Path(__file__).resolve().parent.parent, help=argparse.SUPPRESS)
    parser.add_argument("--policy", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--private-policy", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--fixture-results", type=Path, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if not args.home_dir.is_absolute() or not args.source_dir.is_absolute():
        parser.error("home and source directories must be absolute")
    policy_path = args.policy or args.source_dir / "config/bootstrap/config-policy.json"
    try:
        policy = validate_policy(policy_path)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print("INVALID policy:", exc)
        return 2
    fixture = None
    if args.fixture_results:
        try:
            fixture = json.loads(args.fixture_results.read_text())
            if not isinstance(fixture, dict):
                raise ValueError()
        except (OSError, json.JSONDecodeError, ValueError):
            print("INVALID fixture results")
            return 2
        print("CHECKER FIXTURE: synthetic file and prerequisite results only")
    failed = False
    def report(label, status):
        nonlocal failed
        print(f"{status}: {label}")
        if status != "PASS":
            failed = True

    for e in policy["entries"]:
        if e["action"] not in ("public-file", "public-directory"):
            continue
        rel = e["path"]
        source = args.source_dir / "config/xdg" / rel
        report(f"source {rel}", "PASS" if no_link_source(args.source_dir / "config/xdg", rel, e["action"]) else "MISSING")
        report(f"target {rel}", target_state(args.home_dir, rel, source))
    # Private policy is local operational metadata, never an input to Nix evaluation.
    private_path = args.private_policy or args.home_dir / "Keikaku/dotfiles-private.nix/config/bootstrap/private-policy.json"
    try:
        private = validate_private(private_path, args.home_dir)
        report("private recovery policy", "PASS")
    except OSError:
        private = None
        report("private recovery policy", "MISSING")
    except (json.JSONDecodeError, ValueError) as exc:
        print("INVALID private policy:", exc)
        return 2
    if private and not args.live:
        for e in private["entries"]:
            if "secret_name" in e:
                report(f"private target {e['secret_name']}", private_target_state(args.home_dir, Path(e["destination"])))

    if fixture is None:
        report("architecture arm64", "PASS" if os.uname().machine == "arm64" else "MISSING")
        report("login shinzui", "PASS" if subprocess.run(["id", "-un"], capture_output=True, text=True).stdout.strip() == "shinzui" else "MISSING")
        report("public checkout path", "PASS" if args.source_dir == args.home_dir / ".config/dotfiles.nix" else "MISSING")
        for cmd in ("nix", "git", "ssh", "curl", "python3"):
            report(f"command {cmd}", "PASS" if shutil.which(cmd) else "MISSING")
        try:
            result = subprocess.run(["git", "ls-remote", "git@github.com:shinzui/dotfiles-private.nix.git", "HEAD"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=12)
            private_access = result.returncode == 0
        except (OSError, subprocess.TimeoutExpired):
            private_access = False
    else:
        for label in ("architecture arm64", "login shinzui", "public checkout path", "command nix", "command git", "command ssh", "command curl", "command python3"):
            report(label, "PASS" if fixture.get(label, True) else "MISSING")
        private_access = fixture.get("private access", False)
    report("private Git access", "PASS" if private_access else "MISSING")

    if args.live:
        if private:
            for e in private["entries"]:
                if "secret_name" not in e:
                    continue
                name = e["secret_name"]
                dest = Path(e["destination"])
                good = secret_ready(args.home_dir, dest)
                report(f"secret {name}", "PASS" if good else "MISSING")
        if args.target != "bootstrap-arm":
            if fixture is not None:
                tailnet = fixture.get("tailscale enrolled", False)
            else:
                cli = Path("/Applications/Tailscale.app/Contents/MacOS/Tailscale")
                try:
                    tailnet = cli.is_file() and subprocess.run([str(cli), "status", "--json"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=8).returncode == 0
                except (OSError, subprocess.TimeoutExpired):
                    tailnet = False
            report("tailscale enrolled", "PASS" if tailnet else "MISSING")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
