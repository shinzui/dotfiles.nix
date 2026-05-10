{ lib
, stdenv
, fetchurl
, git
, makeWrapper
}:

let
  version = "0.10.0";
  src = fetchurl {
    url = "https://registry.npmjs.org/hunkdiff/-/hunkdiff-${version}.tgz";
    hash = "sha512-GfUYNCzEnZ0OTdg340YRFbW1SvvwgRMyQmn44t2GKoSjYqiXGaDCeOG66fpIzU8WRdbUi2uzdGIVkEsCps8TeA==";
  };

  platformPackages = {
    aarch64-darwin = {
      name = "hunkdiff-darwin-arm64";
      hash = "sha512-oJALanUcIFp19LQbTTNKEk/RA0QIeeqwXzUciTzBlze1IA5GPe+rq+OLy66fFUA5tiO6qj6sXf1UqK9cL8o0Mw==";
    };
    x86_64-darwin = {
      name = "hunkdiff-darwin-x64";
      hash = "sha512-5sVwIN7OQ4x6/K1TfP4n0wUZinL9nPKmbZ/oHJWhMD6FScGuOOYYZQtN+q2j3ahzlu36Iio7OXajuyQZulwU4A==";
    };
    aarch64-linux = {
      name = "hunkdiff-linux-arm64";
      hash = "sha512-h3yY1cxEmer3StCppvQ4kZyK10971t6dMO76jMnWNhREWML2H2hCiPrNw5Yjx0tI0AyI1P4D3guNCcvylLmO4A==";
    };
    x86_64-linux = {
      name = "hunkdiff-linux-x64";
      hash = "sha512-me3Pl6Tqb46yoZP930iCUdE3pE5lDOtfsWUcCZXqEpsg0WPbW6PjO6tjX7MRnkLFPacPDrqfPZpEHr2bxK0X9A==";
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
