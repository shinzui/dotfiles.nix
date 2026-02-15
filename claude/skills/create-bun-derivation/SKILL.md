---
name: create-bun-derivation
description: Create a new Bun/TypeScript derivation using bun2nix from a GitHub URL. Use when the user wants to package a JavaScript/TypeScript npm package as a Nix derivation.
---

# Create Bun Derivation with bun2nix

Create a new bun2nix derivation from: $ARGUMENTS

## Prerequisites

The flake already has `bun2nix` configured as an input with its overlay applied. The `bun2nix` overlay must come before `my-packages` in the `legacyPackages` overlays list.

## Steps

1. **Parse the GitHub URL**: Extract the owner and repo name from the provided GitHub URL (e.g., `https://github.com/owner/repo`).

2. **Fetch repo information**: Use `gh repo view owner/repo --json description,licenseInfo,latestRelease,name` to get:
   - Repository description
   - License information
   - Latest release version
   - Repo name (used as pname)

3. **Inspect package.json**: Fetch the `package.json` from the repo to determine:
   - The package name
   - Whether it has a CLI entry point (`bin` field)
   - Dependencies vs devDependencies
   - The `type` field (module vs commonjs)

   ```bash
   gh api repos/<owner>/<repo>/contents/package.json --jq '.content' | base64 -d
   ```

4. **Determine if a CLI wrapper is needed**: If the package is a library (no `bin` field in package.json), you need to create a `cli.ts` wrapper. If it already has a CLI entry point, note the entry file path.

5. **Get the source hash**:
   ```bash
   nix-prefetch-url --unpack "https://github.com/<owner>/<repo>/archive/refs/tags/<rev>.tar.gz"
   ```
   Then convert to SRI format:
   ```bash
   nix hash to-sri --type sha256 <hash>
   ```
   Check the repo's tags to determine if versions are prefixed with `v` (e.g., `v1.0.0` vs `1.0.0`).

6. **Generate bun.nix**: Clone the repo at the target version, install dependencies, and generate the Nix lockfile:
   ```bash
   cd /tmp/claude
   git clone --branch <tag> --depth 1 https://github.com/<owner>/<repo>.git
   cd <repo>
   bun install
   nix run github:nix-community/bun2nix -- -o bun.nix
   ```
   Copy the generated `bun.nix` to `derivations/<pname>/bun.nix`.

7. **Create CLI wrapper** (if needed): Create `derivations/<pname>/cli.ts` that wraps the library's API. Key considerations:
   - Import from relative source paths (e.g., `"./src/index.ts"`) since we build from within the source tree
   - Wrap all async code in an `async function main()` — top-level await does not work with `bun build --compile`
   - Call `main()` at the end of the file
   - Handle stdin input and file arguments
   - Add `--help` flag support

8. **Create the derivation**: Create `derivations/<pname>/default.nix` using `bun2nix.writeBunApplication`:

   ```nix
   { lib
   , bun2nix
   , fetchFromGitHub
   }:

   let
     version = "<version>";
     src = fetchFromGitHub {
       owner = "<owner>";
       repo = "<repo>";
       rev = "v${version}";
       hash = "<source-hash>";
     };
   in
   bun2nix.writeBunApplication {
     pname = "<pname>";
     inherit version src;

     bunDeps = bun2nix.fetchBunDeps {
       bunNix = ./bun.nix;
     };

     postUnpack = ''
       cp ${./cli.ts} $sourceRoot/cli.ts
     '';

     dontUseBunBuild = true;

     startScript = ''
       bun run cli.ts "$@"
     '';

     doCheck = false;

     meta = with lib; {
       description = "<description>";
       homepage = "https://github.com/<owner>/<repo>";
       license = licenses.<license>;
       maintainers = with maintainers; [ ];
       platforms = platforms.unix;
       mainProgram = "<pname>";
     };
   }
   ```

   **Important notes on the template:**
   - Always use `bun2nix.writeBunApplication`, NOT `bun2nix.mkDerivation` — `bun build --compile` produces 0-byte binaries in the Nix sandbox
   - Always set `dontUseBunBuild = true` — we run the TypeScript source directly with Bun at runtime
   - `bunDeps` must use `bun2nix.fetchBunDeps { bunNix = ./bun.nix; }` — do NOT pass `bunNix` directly
   - `postUnpack` copies the CLI wrapper into the source tree before `bun install` runs
   - `startScript` is the shell command that runs the entry point; Bun is automatically on the PATH
   - If the package already has a CLI (a `bin` field in package.json), adjust `startScript` to run that entry point instead and omit `postUnpack`/`cli.ts`

9. **Stage new files**: New files must be `git add`ed before Nix can see them:
   ```bash
   git add derivations/<pname>
   ```

10. **Build and verify**:
    ```bash
    nix build .#<pname>
    ```
    Ensure the build completes and the binary works.

11. **Add to flake.nix**: Add the package to the `my-packages` overlay:
    ```nix
    <pname> = final.callPackage (self + "/derivations/<pname>") { };
    ```
    Also add to the `packages` output:
    ```nix
    <pname> = pkgs.<pname>;
    ```

12. **Add to home.packages** (if requested): Add `<pname>` to the packages list in `home/default.nix`.

13. **Summary**: Report what was created (package name, version, file path) and remind to run `sudo darwin-rebuild switch --flake .` to apply changes.

## Key Constraints

- `bun build --compile` does NOT work in the Nix sandbox (produces 0-byte binaries). Always use `writeBunApplication` with `dontUseBunBuild = true`
- `writeBunApplication` copies the project to `$out/share/$pname` and creates a shell wrapper at `$out/bin/$pname` that runs with Bun at runtime
- Top-level `await` does not work in compiled Bun binaries — always wrap async code in an `async function main()` and call `main()` at the end
- The `bun2nix` overlay must be listed before `my-packages` in the `legacyPackages` overlays list
- License mapping: use nixpkgs license identifiers (e.g., `mit`, `asl20` for Apache-2.0, `isc`, etc.)
