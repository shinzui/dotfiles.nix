# Debugging and Fixing Broken Transitive Dependencies in Nix

This guide documents how to identify and fix broken transitive dependencies in NixOS/nix-darwin configurations, particularly when a package deep in the dependency tree is marked as broken.

## Table of Contents
1. [Identifying the Problem](#identifying-the-problem)
2. [Tracing Dependencies](#tracing-dependencies)
3. [Finding the Last Working Version](#finding-the-last-working-version)
4. [Solution Strategies](#solution-strategies)
5. [Testing Fixes](#testing-fixes)
6. [Common Commands Reference](#common-commands-reference)
7. [Suspect your own overlays first](#suspect-your-own-overlays-first)

## Identifying the Problem

When you encounter a build error like:
```
error: Package 'postgresql-test-hook' in /nix/store/.../trivial-builders/default.nix:80 is marked as broken, refusing to evaluate.
```

This means a package (possibly a transitive dependency) has been marked as broken in nixpkgs.

## Tracing Dependencies

### Method 1: Using NIXPKGS_ALLOW_BROKEN to trace dependencies

1. First, allow broken packages temporarily to see what depends on the broken package:
```bash
# Get the derivation path of the broken package
NIXPKGS_ALLOW_BROKEN=1 nix build --dry-run --impure .#darwinConfigurations.HOSTNAME.system 2>&1 | grep "postgresql-test-hook"
# Output: /nix/store/dk7c9z50w79ifg3j2n4f2bhbna82ywjc-postgresql-test-hook.drv
```

2. Find what depends on the broken package (reverse dependencies):
```bash
# Find what packages depend on the broken one
NIXPKGS_ALLOW_BROKEN=1 nix-store --query --referrers /nix/store/dk7c9z50w79ifg3j2n4f2bhbna82ywjc-postgresql-test-hook.drv
# Output: /nix/store/9mafhyh00kvkikblp4sirfzmrslicnvy-python3.13-pgspecial-2.2.1.drv
```

3. Continue tracing up the dependency tree:
```bash
# Find what depends on pgspecial
NIXPKGS_ALLOW_BROKEN=1 nix-store --query --referrers /nix/store/9mafhyh00kvkikblp4sirfzmrslicnvy-python3.13-pgspecial-2.2.1.drv
# Output: /nix/store/wwsrpdb0bd9i3xk5ykshy009ri4rb006-python3.13-pgcli-4.3.0.drv
```

In this example, the dependency chain is: `pgcli` → `pgspecial` → `postgresql-test-hook`

### Method 2: Search your configuration for the root package

```bash
rg "pgcli" ~/path/to/dotfiles.nix
```

### Method 3: Check currently installed version (if it was working before)

```bash
# Check if the package is currently installed and working
which pgcli
# Output: /Users/username/.nix-profile/bin/pgcli

# Get the actual store path
readlink -f $(which pgcli)
# Output: /nix/store/ciw87x5zk4ci5v5flrqr28ljfvd8qayh-python3.13-pgcli-4.3.0/bin/pgcli

# Check what version of the dependency it uses
nix-store -q --references /nix/store/ciw87x5zk4ci5v5flrqr28ljfvd8qayh-python3.13-pgcli-4.3.0 | grep pgspecial
# Output: /nix/store/lkzxx0p3qdhrixvg5q62l0vh31mahd6i-python3.13-pgspecial-2.1.3
```

## Finding the Last Working Version

### Method 1: Check git history of flake.lock

1. View recent flake.lock commits:
```bash
git log --oneline -20 flake.lock
```

2. Check the nixpkgs revision from the last working commit:
```bash
# Get nixpkgs revision from current (broken) state
git show HEAD:flake.lock | jq '.nodes.nixpkgs.locked.rev'

# Get nixpkgs revision from a previous commit
git show COMMIT_HASH:flake.lock | jq '.nodes.nixpkgs.locked.rev'

# For nixpkgs-unstable
git show HEAD:flake.lock | jq '.nodes."nixpkgs-unstable".locked.rev'
```

3. Check when a specific revision was introduced:
```bash
# Find when a specific nixpkgs revision was first used
git log -p --follow flake.lock | grep -B5 -A2 'REVISION_HASH'
```

### Method 2: Check flake.lock changes

```bash
# See uncommitted changes to flake.lock
git diff HEAD flake.lock

# Check what changed in nixpkgs-unstable
git diff HEAD flake.lock | grep -A2 -B2 'nixpkgs-unstable'
```

## Solution Strategies

### Strategy 1 (preferred): Take the package from `pkgs-stable`

The `nixpkgs-stable` input is pinned to a release channel and exposed as
`pkgs.pkgs-stable` by the `pkgs-stable` overlay. Pull just the broken package
— or just the toolchain it needs — from there:

```nix
# overlays/harlequin-pin.nix
final: prev: {
  harlequin = final.pkgs-stable.harlequin;
}
```

```nix
# or only the toolchain, leaving the rest of the package on unstable
parqeye = final.callPackage ../derivations/parqeye.nix {
  inherit (final) lib fetchFromGitHub;
  rustPlatform = final.pkgs-stable.rustPlatform;
};
```

This is lock-tracked, so `nix flake update` moves it, and it comes from the
binary cache.

### Anti-pattern: `builtins.fetchTarball` to a hardcoded revision

This repo used to pin packages like so. **Don't.**

```nix
# DON'T: outside flake.lock, never updated, instantiates a whole extra nixpkgs
pgcli = (import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz";
  sha256 = "...";
}) { system = prev.stdenv.system; config.allowUnfree = true; }).pgcli;
```

`nix flake update` cannot move it, so it drifts silently — the harlequin pin sat
on 2.1.2 long after the stable channel had 2.4.1 — and each one pulls an entire
parallel package set into the closure. Removing two such pins in July 2026 cut
~600 MB. Use `pkgs-stable` instead.

### Strategy 2: Override the broken dependency

Override the package to disable tests or remove the broken dependency:

```nix
# historical example -- this overlay has since been retired
final: prev: {
  pgcli = prev.pgcli.override {
    pgspecial = prev.python3Packages.pgspecial.overrideAttrs (oldAttrs: {
      # Disable tests that require the broken package
      doCheck = false;
      nativeCheckInputs = [];
    });
  };
}
```

### Strategy 3: Patch the package

Often the cleanest fix is a small `overrideAttrs` rather than a pin:

```nix
# overlays/httpstat-fix.nix -- setup.py uses ast.Str.s, removed in Python 3.12
final: prev: {
  httpstat = prev.httpstat.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace setup.py \
        --replace-fail 'ast.parse(line).body[0].value.s' \
                       'ast.parse(line).body[0].value.value'
    '';
  });
}
```

Prefer `--replace-fail` over `--replace`: it errors when the pattern stops
matching, which is how you find out nixpkgs fixed the problem upstream and the
overlay can go. (It will break the build when that happens — that's the point.
See the `dateutils-fix` entry below.)

If the failure is a test that can't pass in the sandbox, skip that test rather
than disabling the whole suite:

```nix
# overlays/worktrunk-skip-proc-tests.nix
checkFlags = (old.checkFlags or [ ]) ++ [ "--skip=some::failing::test" ];
```

### Adding the overlay to your flake

1. Add the overlay to `flake-modules/overlays.nix`:
```nix
flake.overlays = {
  # ... other overlays ...

  # Fix httpstat's setup.py to build under Python 3.12+
  httpstat-fix = import ../overlays/httpstat-fix.nix;
};
```

Note: overlays are applied in **alphabetical order of attribute name**, so the
name is load-bearing when one overlay must see another's output. Today
`vimExtraPlugins-require-check-exemptions` must sort after `nix-neovimplugins`.

2. Make sure to stage the overlay file for flakes:
```bash
git add overlays/httpstat-fix.nix
```

## Testing Fixes

### Test if a package builds with a specific nixpkgs revision

```bash
# Test building from a specific nixpkgs commit
nix build github:NixOS/nixpkgs/COMMIT_HASH#pgcli --impure

# Test from a channel
nix build github:NixOS/nixpkgs/nixos-24.11#pgcli --impure
nix build github:NixOS/nixpkgs/nixpkgs-unstable#pgcli --impure

# Test with your overlay
nix build --impure .#darwinConfigurations.HOSTNAME.system
```

### Check package version in different channels

```bash
# Check version in nixpkgs-unstable
nix eval github:NixOS/nixpkgs/nixpkgs-unstable#pgcli.version

# Check what override arguments a package accepts
nix eval --impure --expr 'with import <nixpkgs> {}; builtins.attrNames (lib.functionArgs pgcli.override)'
```

### Verify the fix

After applying the overlay:

```bash
# Rebuild your system (Darwin)
sudo ./bin/darwin-rebuild-sungkyung.sh

# Verify the package works
pgcli --version
```

## Common Commands Reference

### Dependency Analysis
```bash
# Show dependencies of a derivation
nix-store --query --references /nix/store/HASH-package-name

# Show reverse dependencies (what depends on this)
nix-store --query --referrers /nix/store/HASH-package-name

# Show full dependency tree
nix-store --query --tree $(nix-instantiate '<nixpkgs>' -A packageName)

# Why does X depend on Y
nix why-depends --derivation .#darwinConfigurations.HOSTNAME.system nixpkgs#broken-package
```

### Package Information
```bash
# Get store path of installed package
readlink -f $(which COMMAND)

# List all packages in your configuration
nix eval .#darwinConfigurations.HOSTNAME.config.home-manager.users.USERNAME.home.packages --apply 'map (p: p.pname or p.name or "unknown")'

# Search for packages
nix search nixpkgs#pattern
```

### Git and Flake Commands
```bash
# Update flake inputs
nix flake update

# Show flake info
nix flake show

# Check flake metadata
nix flake metadata

# Show what would be built
nix build --dry-run .#darwinConfigurations.HOSTNAME.system
```

### Hash Utilities
```bash
# Get correct hash for fetchTarball (it will error and show the right hash)
nix-instantiate --eval -E 'builtins.fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/COMMIT.tar.gz"; sha256 = "0000000000000000000000000000000000000000000000000000"; }'

# Convert between hash formats
nix hash to-sri --type sha256 HASH
```

## Real-World Example: Fixing pgcli with broken postgresql-test-hook

> **Historical.** This walkthrough is kept for the technique, not the fix. The
> `fix-pgspecial` overlay it produces was retired in July 2026 — `postgresql-test-hook`
> was un-broken upstream long before that, and stock `pgcli` builds fine. Note
> also that it reaches for a `fetchTarball` pin, which this repo no longer does;
> see the anti-pattern above. Read it as "how to trace a broken transitive
> dependency", then apply a current strategy.

### 1. Problem Identification
```bash
$ sudo ./bin/darwin-rebuild-sungkyung.sh
error: Package 'postgresql-test-hook' in .../trivial-builders/default.nix:80 is marked as broken
```

### 2. Dependency Tracing
```bash
# Allow broken packages to trace dependencies
$ NIXPKGS_ALLOW_BROKEN=1 nix build --dry-run --impure .#darwinConfigurations.SungkyungM1X.system 2>&1 | grep postgresql-test-hook
/nix/store/dk7c9z50w79ifg3j2n4f2bhbna82ywjc-postgresql-test-hook.drv

# Find what depends on it
$ NIXPKGS_ALLOW_BROKEN=1 nix-store --query --referrers /nix/store/dk7c9z50w79ifg3j2n4f2bhbna82ywjc-postgresql-test-hook.drv
/nix/store/9mafhyh00kvkikblp4sirfzmrslicnvy-python3.13-pgspecial-2.2.1.drv

# Continue up the chain
$ NIXPKGS_ALLOW_BROKEN=1 nix-store --query --referrers /nix/store/9mafhyh00kvkikblp4sirfzmrslicnvy-python3.13-pgspecial-2.2.1.drv
/nix/store/wwsrpdb0bd9i3xk5ykshy009ri4rb006-python3.13-pgcli-4.3.0.drv
```

Dependency chain: `pgcli` → `pgspecial` → `postgresql-test-hook`

### 3. Find Working Version
```bash
# Check currently installed working version
$ readlink -f $(which pgcli)
/nix/store/ciw87x5zk4ci5v5flrqr28ljfvd8qayh-python3.13-pgcli-4.3.0/bin/pgcli

# Check uncommitted flake.lock changes
$ git diff HEAD flake.lock | grep -A2 -B2 'nixpkgs-unstable'

# Get last working nixpkgs-unstable revision
$ git show HEAD:flake.lock | jq '.nodes."nixpkgs-unstable".locked.rev'
"32f313e49e42f715491e1ea7b306a87c16fe0388"
```

### 4. Create Overlay Fix
```nix
# overlays/fix-pgspecial.nix
final: prev: {
  # Pin pgcli to last working nixpkgs-unstable revision
  pgcli = let
    workingNixpkgs = import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/32f313e49e42f715491e1ea7b306a87c16fe0388.tar.gz";
      sha256 = "1z4ga87qla5300qwib3dnjnkaywwh8y1qqsb8w2mrsrw78k9xmlw";
    }) {
      system = prev.stdenv.system;
      config = { allowUnfree = true; };
    };
  in workingNixpkgs.pgcli;
}
```

### 5. Apply Fix
```nix
# In flake-modules/overlays.nix (this was flake.nix at the time)
flake.overlays = {
  # ... other overlays ...

  # Fix pgspecial to avoid broken postgresql-test-hook dependency (named to apply early)
  aaa-fix-pgspecial = import ../overlays/fix-pgspecial.nix;
};
```

### 6. Test and Verify
```bash
# Stage the overlay
$ git add overlays/fix-pgspecial.nix

# Rebuild
$ nix build --impure .#darwinConfigurations.SungkyungM1X.system

# Apply system changes
$ sudo ./bin/darwin-rebuild-sungkyung.sh

# Verify pgcli works
$ pgcli --version
```

## Suspect your own overlays first

A bump often breaks the *workaround*, not the package. Check whether an existing
overlay is the cause before writing a new one. Both of these happened here:

- **`dateutils-fix`** patched a K&R `yyparse()` prototype. nixpkgs later shipped
  the same upstream patch, so the overlay's `--replace-fail` matched nothing and
  aborted the build. The fix was to delete the overlay — the stock package was
  already correct. This was the first error in a bump that turned out to have
  seven unrelated breakages behind it.
- **`tmux-extrakto-darwin-fix`** existed to keep Linux-only dependencies off
  Darwin. nixpkgs fixed that upstream, and the overlay was left unconditionally
  adding `xclip` — an X11 tool — to the Darwin closure. It had inverted into
  causing the problem it was named after.

When a bump breaks something, test the stock package first:

```bash
nix build github:nixos/nixpkgs/<locked-rev>#<package>
```

If it builds, your overlay is the problem.

## Tips

1. **Test the stock package before writing an overlay** - the workaround may be the bug
2. **Always check if the package is still broken upstream** - Sometimes packages are quickly fixed in nixpkgs
3. **Consider reporting the issue** - Fixes like `httpstat-fix` are real upstream bugs worth a nixpkgs PR
4. **Document your overlays** - Add comments explaining why the overlay exists and when it can be removed
5. **Regularly review overlays** - Periodically check if overlays are still needed
6. **Use temporary allows for debugging** - `NIXPKGS_ALLOW_BROKEN=1` is useful for debugging but never commit it
7. **Check multiple nixpkgs channels** - Sometimes a package is broken in unstable but works in stable

## Example Overlay File Structure

```
dotfiles.nix/
├── flake-modules/
│   └── overlays.nix                 # declares the overlay set
├── overlays/
│   ├── harlequin-pin.nix            # takes harlequin from pkgs-stable
│   ├── httpstat-fix.nix             # patches setup.py for Python 3.12+
│   ├── worktrunk-skip-proc-tests.nix  # skips sandbox-incompatible tests
│   ├── vimExtraPlugins-require-check-exemptions.nix
│   └── vimUtils.nix                 # helper functions, not a fix
```

Each overlay should be self-contained and well-documented with comments explaining:
- What problem it solves
- When it was added
- When it can potentially be removed
- Any upstream issues tracking the problem

## Troubleshooting Common Issues

### Issue: Can't find which package depends on broken package
- Use `NIXPKGS_ALLOW_BROKEN=1` with `--dry-run` to get derivation paths
- Search for packages by category (e.g., Python apps for Python dependencies)
- Check recently added packages to your configuration

### Issue: Hash mismatch when using fetchTarball
- Use a dummy hash first to get the correct one from the error message
- Make sure the URL is correct and accessible

### Issue: Overlay not being applied
- Check overlay naming (alphabetical order matters)
- Ensure the overlay file is staged in git (`git add`)
- Verify the overlay syntax is correct

### Issue: Package still broken after overlay
- Check if you're overriding the right package
- Ensure the pinned revision actually has a working version
- Consider using a different solution strategy
