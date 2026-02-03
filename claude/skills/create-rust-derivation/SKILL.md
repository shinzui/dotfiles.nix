---
name: create-rust-derivation
description: Create a new Rust derivation from a GitHub URL. Use when the user wants to add a new Rust package to their nix derivations.
---

# Create Rust Derivation

Create a new Rust derivation from: $ARGUMENTS

## Steps

1. **Parse the GitHub URL**: Extract the owner and repo name from the provided GitHub URL (e.g., `https://github.com/owner/repo`).

2. **Fetch repo information**: Use `gh repo view owner/repo --json description,licenseInfo,latestRelease,name` to get:
   - Repository description
   - License information
   - Latest release version
   - Repo name (used as pname)

3. **Inspect Cargo.toml**: Fetch the `Cargo.toml` from the repo's default branch to determine:
   - The binary/package name (may differ from repo name)
   - Any notable features or workspace structure

   ```bash
   gh api repos/<owner>/<repo>/contents/Cargo.toml --jq '.content' | base64 -d
   ```

4. **Create the derivation file**: Create `derivations/<pname>.nix` using the standard template:

   ```nix
   { lib
   , rustPlatform
   , fetchFromGitHub
   }:

   rustPlatform.buildRustPackage rec {
     pname = "<package-name>";
     version = "<version>";

     src = fetchFromGitHub {
       owner = "<owner>";
       repo = "<repo>";
       rev = "v${version}";
       hash = "<source-hash>";
     };

     cargoHash = "<cargo-hash>";

     doCheck = false;

     meta = with lib; {
       description = "<description>";
       homepage = "https://github.com/<owner>/<repo>";
       license = with licenses; [ <license> ];
       maintainers = with maintainers; [ ];
       platforms = platforms.unix;
       mainProgram = "<binary-name>";
     };
   }
   ```

   Notes on the template:
   - `rev` may be `"v${version}"` or `version` depending on the repo's tag convention. Check the repo's tags to determine this.
   - Add `nativeBuildInputs`, `buildInputs`, or `env` only if needed (e.g., for openssl, pkg-config, darwin SDKs).
   - Set `doCheck = false;` by default (tests often fail in the nix sandbox).

5. **Get the source hash**:
   ```bash
   nix-prefetch-url --unpack "https://github.com/<owner>/<repo>/archive/refs/tags/<rev>.tar.gz"
   ```
   Then convert to SRI format:
   ```bash
   nix hash to-sri --type sha256 <hash>
   ```
   Update the `hash` in `fetchFromGitHub` with the SRI hash.

6. **Set cargoHash to placeholder**: Set `cargoHash = lib.fakeHash;` to trigger nix to compute the correct hash.

7. **Build to get cargoHash**:
   ```bash
   nix build --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./derivations/<pname>.nix {}' 2>&1 | grep -A2 "got:"
   ```
   Extract the correct cargoHash from the error output.

8. **Update cargoHash**: Replace `lib.fakeHash` with the actual cargoHash from the build output.

9. **Verify the build**:
   ```bash
   nix build --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./derivations/<pname>.nix {}'
   ```
   Ensure the build completes successfully. If it fails due to missing dependencies (e.g., openssl, pkg-config), add the appropriate `nativeBuildInputs`/`buildInputs` and rebuild.

10. **Add to flake.nix**: Add the new package to the `my-packages` overlay in `flake.nix`:
    ```nix
    <pname> = final.callPackage (self + "/derivations/<pname>.nix") { };
    ```
    Also expose it in the flake `packages` output if the other derivations are exposed there.

11. **Summary**: Report what was created (package name, version, file path) and remind to run `darwin-rebuild switch --flake .` to apply changes.

## Notes

- The derivation must use `rustPlatform.buildRustPackage` with `cargoHash`
- All hashes must be in SRI format (e.g., `sha256-...`)
- Check the repo's release tags to determine if versions are prefixed with `v` (e.g., `v1.0.0` vs `1.0.0`)
- If the repo has no releases, use the latest commit hash for `rev` and set `version` to a date or commit-based string
- Some packages may need additional inputs — inspect build errors and add dependencies as needed
- License mapping: use nixpkgs license identifiers (e.g., `mit`, `asl20` for Apache-2.0, `gpl3Only`, etc.)
