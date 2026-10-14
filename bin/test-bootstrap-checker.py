#!/usr/bin/env python3
"""Exercise checker behavior on synthetic homes; never activates nix-darwin."""
import copy
import json
from pathlib import Path
import runpy
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "bin/check-bootstrap.sh"
MODULE = runpy.run_path(str(ROOT / "bin/check-bootstrap.py"))
PUBLIC = json.loads((ROOT / "config/bootstrap/config-policy.json").read_text())
assert len([e for e in PUBLIC["entries"] if "/" not in e["path"]]) == 70
assert MODULE["REQUIRED_PUBLIC"].issubset({e["path"] for e in PUBLIC["entries"] if e["action"].startswith("public-")})

with tempfile.TemporaryDirectory(prefix="bootstrap-checker-") as temp:
    base = Path(temp)
    home = base / "home"
    source = base / "source"
    policy = base / "policy.json"
    private_policy = base / "private.json"
    fixture = base / "fixture.json"
    home.mkdir()
    source.mkdir()
    (home / ".config").mkdir()
    secret_dir = home / "private-installed"
    secret_dir.mkdir(mode=0o700)
    xdg = source / "config/xdg"
    for e in PUBLIC["entries"]:
        if e["action"] not in ("public-file", "public-directory"):
            continue
        path = xdg / e["path"]
        path.parent.mkdir(parents=True, exist_ok=True)
        if e["action"] == "public-directory":
            path.mkdir()
        else:
            path.write_text("public fixture\n")
    # These must remain outside the selected source set.
    (xdg / "worktrunk").mkdir()
    (xdg / "worktrunk/config.toml").write_text("approval = true\n")
    (xdg / "mori/history.log").write_text("runtime log\n")
    (xdg / "mori/cache").mkdir()
    policy.write_text(json.dumps(PUBLIC))
    secrets = sorted(MODULE["REQUIRED_PRIVATE"])
    private = {"schema_version": 1, "entries": [{"source": str(base / ("source-" + name)), "destination": str(secret_dir / name), "secret_name": name, "recovery_method": "synthetic fixture"} for name in secrets]}
    private_policy.write_text(json.dumps(private))
    flags = {"private access": True, "tailscale enrolled": True}
    fixture.write_text(json.dumps(flags))

    def run(*extra, expect, target_name="yujin"):
        command = [str(CHECKER), target_name, "--home-dir", str(home), "--source-dir", str(source), "--policy", str(policy), "--private-policy", str(private_policy), "--fixture-results", str(fixture), *extra]
        p = subprocess.run(command, capture_output=True, text=True)
        assert p.returncode == expect, (p.returncode, p.stdout, p.stderr)
        assert "approval = true" not in p.stdout + p.stderr
        assert "fixture-token-value" not in p.stdout + p.stderr
        return p

    assert run(expect=0).stdout.count("PASS: source") == len(MODULE["REQUIRED_PUBLIC"])
    assert "Homebrew /opt/homebrew" not in run(expect=0).stdout
    flags["Homebrew /opt/homebrew"] = False
    fixture.write_text(json.dumps(flags))
    assert "MISSING: Homebrew /opt/homebrew" in run(expect=1, target_name="SungkyungM1X").stdout
    assert "Homebrew /opt/homebrew" not in run(expect=0, target_name="yujin").stdout
    assert "Homebrew /opt/homebrew" not in run(expect=0, target_name="bootstrap-arm").stdout
    for target_name in ("yujin", "SungkyungM1X", "bootstrap-arm"):
        assert "MISSING: Homebrew /opt/homebrew" in run("--live", expect=1, target_name=target_name).stdout
    flags["Homebrew /opt/homebrew"] = True
    fixture.write_text(json.dumps(flags))
    assert "PASS: Homebrew /opt/homebrew" in run("--live", expect=0, target_name="bootstrap-arm").stdout
    assert "worktrunk" not in run(expect=0).stdout
    target = home / ".config/nihongo/config.kdl"
    target.parent.mkdir()
    target.write_bytes(b"existing-value")
    assert "CONFLICT: target nihongo/config.kdl" in run(expect=1).stdout
    assert target.read_bytes() == b"existing-value"
    target.unlink()
    outside = base / "outside"
    outside.write_text("fixture-token-value")
    (xdg / "nihongo/config.kdl").unlink()
    (xdg / "nihongo/config.kdl").symlink_to(outside)
    assert "MISSING: source nihongo/config.kdl" in run(expect=1).stdout
    (xdg / "nihongo/config.kdl").unlink()
    (xdg / "nihongo/config.kdl").write_text("public fixture\n")
    target.symlink_to(outside)
    assert "CONFLICT: target nihongo/config.kdl" in run(expect=1).stdout
    target.unlink()
    target.symlink_to("/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-home-manager-files/.config/nihongo/config.kdl")
    assert "PASS: target nihongo/config.kdl" in run(expect=0).stdout
    target.unlink()
    (xdg / "seihou/config.dhall").unlink()
    assert "MISSING: source seihou/config.dhall" in run(expect=1).stdout
    (xdg / "seihou/config.dhall").write_text("public fixture\n")
    assert run(expect=0).returncode == 0
    for bad in ("../escape", "/absolute", "mori/../escape"):
        data = copy.deepcopy(PUBLIC)
        data["entries"][0]["path"] = bad
        policy.write_text(json.dumps(data))
        assert "INVALID policy" in run(expect=2).stdout
    data = copy.deepcopy(PUBLIC)
    data["entries"] = [e for e in data["entries"] if e["path"] != data["audit_top_level"][0]]
    policy.write_text(json.dumps(data))
    assert "policy does not cover all 70" in run(expect=2).stdout
    policy.write_text(json.dumps(PUBLIC))
    flags["private access"] = False
    fixture.write_text(json.dumps(flags))
    assert "MISSING: private Git access" in run(expect=1).stdout
    flags["private access"] = True
    fixture.write_text(json.dumps(flags))
    assert run(expect=0).returncode == 0
    secret_dir.rmdir()
    outside_dir = base / "outside-dir"
    outside_dir.mkdir()
    (outside_dir / "notion-hub-config").write_text("fixture-token-value")
    secret_dir.symlink_to(outside_dir)
    assert "CONFLICT: private target notion-hub-config" in run(expect=1).stdout
    secret_dir.unlink()
    secret_dir.mkdir(mode=0o700)
    (secret_dir / "notion-hub-config").write_bytes(b"existing-private-value")
    assert "CONFLICT: private target notion-hub-config" in run(expect=1).stdout
    assert (secret_dir / "notion-hub-config").read_bytes() == b"existing-private-value"
    (secret_dir / "notion-hub-config").unlink()
    assert run(expect=0).returncode == 0  # before activation no installed secret required
    assert "MISSING: secret notion-hub-config" in run("--live", expect=1).stdout
    for name in secrets:
        dest = secret_dir / name
        dest.write_text("fixture-token-value")
        dest.chmod(0o600)
    (secret_dir / "notion-hub-config").write_text("fixture-token-value")
    (secret_dir / "notion-hub-config").chmod(0o644)
    assert "MISSING: secret notion-hub-config" in run("--live", expect=1).stdout
    (secret_dir / "notion-hub-config").chmod(0o600)
    assert run("--live", expect=0).returncode == 0
    p = subprocess.run([str(CHECKER), "unknown-target", "--fixture-results", str(fixture)], capture_output=True, text=True)
    assert p.returncode == 2 and "invalid choice" in p.stderr
    p = subprocess.run([str(CHECKER), "yujin", "--unknown-option"], capture_output=True, text=True)
    assert p.returncode == 2

print("PASS: policy coverage, safe paths, no link traversal, conflicts, prerequisites, live checks")
