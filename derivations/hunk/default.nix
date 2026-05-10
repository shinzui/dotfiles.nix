{ lib
, stdenv
, fetchurl
, git
, makeWrapper
}:

let
  version = "0.11.1";
  src = fetchurl {
    url = "https://registry.npmjs.org/hunkdiff/-/hunkdiff-${version}.tgz";
    hash = "sha512-3yI7YLMGSC2k+gj9mOnAhYPKGZCVyQOJ/nGRwKs23VP1ahs2ov1GIX3NwhxxzlT+uftRB1kZeW3CtRAeshKQhw==";
  };

  platformPackages = {
    aarch64-darwin = {
      name = "hunkdiff-darwin-arm64";
      hash = "sha512-0uTuJeB7ZrT999WMcvUU1YvvIgoHIrU5orObKvXc5/Ach+tZWwt85cKD3Sy8sk0QLd/KoGEgRODSKFl5Tjx4+A==";
    };
    x86_64-darwin = {
      name = "hunkdiff-darwin-x64";
      hash = "sha512-vmk97ifp08kVUvuAXluMFT+o3bKDI/H4HVPnEvRe+XINEN2QKJrw8GWQXL2axjy3hPpNKZsstuuAJM+UEfIiIg==";
    };
    aarch64-linux = {
      name = "hunkdiff-linux-arm64";
      hash = "sha512-g+3hs/ffKRL+TVTck1AVKhC3ym0UxMh6yVEXyg/FPnwDOOKgaPMMRpN7HLI6qzgdL7lZBcmXFw/bI6XrP2a93A==";
    };
    x86_64-linux = {
      name = "hunkdiff-linux-x64";
      hash = "sha512-2a0bDS0IbjoLc6zzdK2A/0O73Uhze8/kzXcJyu59meBXnk3hJGZxKuwoFW4v/g0hOnnmvR6OPhmiLEMGV/Jy+Q==";
    };
  };

  platformPackage =
    platformPackages.${stdenv.hostPlatform.system}
      or (throw "hunk: unsupported system ${stdenv.hostPlatform.system}");

  binarySrc = fetchurl {
    url = "https://registry.npmjs.org/${platformPackage.name}/-/${platformPackage.name}-${version}.tgz";
    hash = platformPackage.hash;
  };
in
stdenv.mkDerivation {
  pname = "hunk";
  inherit version src;

  nativeBuildInputs = [
    makeWrapper
  ];

  sourceRoot = "package";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/hunk" "$TMPDIR/hunk-binary"
    cp -R skills "$out/skills"
    install -Dm644 LICENSE "$out/share/doc/hunk/LICENSE"
    install -Dm644 README.md "$out/share/doc/hunk/README.md"
    install -Dm644 package.json "$out/share/hunk/package.json"

    tar -xzf ${binarySrc} -C "$TMPDIR/hunk-binary"
    install -Dm755 "$TMPDIR/hunk-binary/package/bin/hunk" "$out/libexec/hunk/hunk"

    makeWrapper "$out/libexec/hunk/hunk" "$out/bin/hunk" \
      --prefix PATH : ${lib.makeBinPath [ git ]}

    runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    description = "Review-first terminal diff viewer for agentic coders";
    homepage = "https://github.com/modem-dev/hunk";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "hunk";
  };
}
