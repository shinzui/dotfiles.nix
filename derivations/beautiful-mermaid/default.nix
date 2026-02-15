{ lib
, bun2nix
, fetchFromGitHub
}:

let
  version = "0.1.3";
  src = fetchFromGitHub {
    owner = "lukilabs";
    repo = "beautiful-mermaid";
    rev = "v${version}";
    hash = "sha256-V1reCHeAKzm+DyTkUBx4zoUIQfDW63qg8Oa/YdTzOQw=";
  };
in
bun2nix.writeBunApplication {
  pname = "beautiful-mermaid";
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
    description = "Render Mermaid diagrams as SVG or ASCII art from the terminal";
    homepage = "https://github.com/lukilabs/beautiful-mermaid";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "beautiful-mermaid";
  };
}
