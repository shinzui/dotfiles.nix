---
description: Update a Rust derivation to a new version with correct hashes
argument-hint: <derivation-path> <new-version>
---

# Update Rust Derivation

Update the Rust derivation: $ARGUMENTS

## Steps

1. **Read the derivation**: Read the derivation file to understand its current structure, version, and hash fields.

2. **Update the version**: Change the `version` attribute to the new version.

3. **Get the source hash**:
   ```bash
   nix-prefetch-url --unpack "https://github.com/<owner>/<repo>/archive/refs/tags/v<version>.tar.gz"
   ```
   Then convert to SRI format:
   ```bash
   nix hash to-sri --type sha256 <hash>
   ```

4. **Update the source hash**: Replace the `hash` attribute in `fetchFromGitHub` with the new SRI hash.

5. **Set cargoHash to placeholder**: Temporarily set `cargoHash = lib.fakeHash;` to trigger nix to compute the correct hash.

6. **Build to get cargoHash**:
   ```bash
   nix build --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./<path-to-derivation> {}' 2>&1 | grep -A2 "got:"
   ```
   Extract the correct cargoHash from the error output.

7. **Update cargoHash**: Replace `lib.fakeHash` with the actual cargoHash from the build output.

8. **Verify the build**:
   ```bash
   nix build --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./<path-to-derivation> {}'
   ```
   Ensure the build completes successfully.

9. **Summary**: Report the version update (old -> new) and remind to run `darwin-rebuild switch --flake .` to apply changes.

## Notes

- The derivation must use `rustPlatform.buildRustPackage` with `cargoHash`
- If using `cargoLock` instead of `cargoHash`, the process differs (fetch Cargo.lock from repo)
- Some packages may have additional attributes that need updating (e.g., `patches`, `buildInputs`)
