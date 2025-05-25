# Building Go Derivations in Nix

This guide covers best practices for creating Nix derivations for Go programs, based on the official Nixpkgs Go documentation.

## Basic Structure

```nix
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "program-name";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "github-owner";
    repo = "repo-name";
    rev = "v${version}";
    hash = "sha256-...";
  };

  vendorHash = "sha256-...";

  # Optional configurations...

  meta = with lib; {
    description = "Short description of the program";
    homepage = "https://github.com/owner/repo";
    license = licenses.mit; # or appropriate license
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "program-name";
  };
}
```

## Key Components

### 1. Source Fetching

**GitHub repositories:**
```nix
src = fetchFromGitHub {
  owner = "owner-name";
  repo = "repository-name";
  rev = "v${version}";        # Use tags when available
  hash = "sha256-...";        # Content hash
};
```

**Alternative sources:**
```nix
# For GitLab
src = fetchFromGitLab { ... };

# For generic git repos
src = fetchgit { ... };

# For tarballs
src = fetchurl { ... };
```

### 2. Vendor Hash

The `vendorHash` is the hash of the Go module dependencies:

```nix
vendorHash = "sha256-...";  # Hash of go.mod dependencies
```

Special cases:
- `vendorHash = null;` - For programs without dependencies
- `vendorHash = lib.fakeHash;` - Temporary placeholder during development

### 3. Build Configuration

**Build inputs for system dependencies:**
```nix
buildInputs = [ pkg-config openssl ];  # System libraries
nativeBuildInputs = [ pkg-config ];    # Build-time tools
```

**Go-specific build flags:**
```nix
# Linker flags for optimization and version info
ldflags = [
  "-s"                           # Strip symbol table
  "-w"                           # Strip debug info
  "-X main.version=${version}"   # Embed version
  "-X main.commit=${src.rev}"    # Embed commit
];

# Build tags
tags = [ "release" "netgo" ];

# Go build flags
CGO_ENABLED = "0";              # Disable CGO for static builds
```

### 4. Testing and Checks

```nix
# Disable tests (common for network-dependent tests)
doCheck = false;

# Run specific test packages
checkFlags = [ "-run" "TestSpecific" ];

# Skip vendor verification
proxyVendor = true;
```

### 5. Post-installation Steps

```nix
postInstall = ''
  # Install shell completions
  installShellCompletion --cmd program-name \
    --bash <($out/bin/program-name completion bash) \
    --zsh <($out/bin/program-name completion zsh) \
    --fish <($out/bin/program-name completion fish)

  # Install man pages
  installManPage docs/*.1

  # Create additional symlinks or wrappers
  ln -s $out/bin/program-name $out/bin/alias-name
'';
```

## Getting Hash Values

### Method 1: Using lib.fakeHash (Development)

1. Start with fake hashes:
```nix
src = fetchFromGitHub {
  # ...
  hash = lib.fakeHash;
};
vendorHash = lib.fakeHash;
```

2. Build and extract real hashes from error messages:
```bash
nix-build -E "with import <nixpkgs> {}; callPackage ./derivation.nix {}"
```

### Method 2: Using nix-prefetch

```bash
# For GitHub sources
nix-prefetch-github owner repo --rev v1.0.0

# For vendor hash
nix-prefetch '{ fetchgit }: fetchgit { url = "..."; rev = "..."; }'
```

### Method 3: Using nix-shell

```bash
# Calculate source hash
nix-shell -p nix-prefetch-git --run "nix-prefetch-git https://github.com/owner/repo v1.0.0"
```

## Complete Example: tmuxai

```nix
{ lib
, buildGoModule
, fetchFromGitHub
, tmux
}:

buildGoModule rec {
  pname = "tmuxai";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "alvinunreal";
    repo = "tmuxai";
    rev = "v${version}";
    hash = "sha256-V8ShkIJLHU6IsqNqrr2Ty1DmhAkQDF3XXXb2bBHCviw=";
  };

  vendorHash = "sha256-mgWud7Ic6SjiCsKnEbyzd5NZbyq8Cx1c5VIddYyCsfI=";

  buildInputs = [ tmux ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = false;

  postInstall = ''
    if [ -f $out/bin/tmuxai ]; then
      $out/bin/tmuxai completion bash > $out/share/bash-completion/completions/tmuxai 2>/dev/null || true
      $out/bin/tmuxai completion zsh > $out/share/zsh/site-functions/_tmuxai 2>/dev/null || true
      $out/bin/tmuxai completion fish > $out/share/fish/vendor_completions.d/tmuxai.fish 2>/dev/null || true
    fi
  '';

  meta = with lib; {
    description = "Intelligent terminal assistant that lives inside your tmux sessions";
    homepage = "https://github.com/alvinunreal/tmuxai";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "tmuxai";
  };
}
```

## Common Patterns

### Static Binaries
```nix
CGO_ENABLED = "0";
ldflags = [ "-s" "-w" "-extldflags=-static" ];
```

### Cross-compilation
```nix
# Will be handled automatically by buildGoModule
# Just ensure GOOS and GOARCH are set appropriately
```

### Programs with Web Assets
```nix
# If the program embeds web assets
preBuild = ''
  # Build web assets first
  npm install && npm run build
'';
```

### Programs with Git Information
```nix
ldflags = [
  "-s" "-w"
  "-X main.version=${version}"
  "-X main.commit=${src.rev}"
  "-X main.date=1970-01-01T00:00:00Z"  # Reproducible builds
];
```

## Testing Your Derivation

```bash
# Build the derivation
nix-build -E "with import <nixpkgs> {}; callPackage ./your-derivation.nix {}"

# Test the binary
./result/bin/program-name --version

# Check for runtime dependencies
ldd ./result/bin/program-name

# Install temporarily for testing
nix-env -f ./your-derivation.nix -i
```

## Troubleshooting

### Common Issues

1. **Hash mismatches**: Use `lib.fakeHash` and extract real hashes from build errors
2. **Missing dependencies**: Add to `buildInputs` or `nativeBuildInputs`
3. **CGO issues**: Set `CGO_ENABLED = "0"` for pure Go builds
4. **Test failures**: Set `doCheck = false` or fix test environment
5. **Missing licenses**: Check repo and add appropriate license to meta

### Debug Build Issues

```bash
# Verbose build output
nix-build --show-trace

# Drop into build environment
nix-shell -A your-package

# Check what files are included
nix-store -q --tree ./result
```

## References

- [Nixpkgs Go Documentation](https://ryantm.github.io/nixpkgs/languages-frameworks/go/)
- [Nixpkgs Manual - buildGoModule](https://nixos.org/manual/nixpkgs/stable/#ssec-go-modules)
