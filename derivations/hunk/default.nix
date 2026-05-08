{ lib
, bun2nix
, fetchFromGitHub
}:

let
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "modem-dev";
    repo = "hunk";
    rev = "v${version}";
    hash = "sha256-S2EuZW5vzyk3FGhUQbyanE3hdlnb9F6GQMtu2k8pjrM=";
  };
in
bun2nix.writeBunApplication {
  pname = "hunk";
  inherit version src;

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  postPatch = ''
    cp ${./package.json} package.json
    cp ${./bun.lock} bun.lock
  '';

  dontUseBunBuild = true;
  dontRunLifecycleScripts = true;

  startScript = ''
    bun run src/main.tsx "$@"
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
