{ lib
, bun2nix
, fetchFromGitHub
}:

let
  version = "0.18.1";
  src = fetchFromGitHub {
    owner = "kepano";
    repo = "defuddle";
    rev = version;
    hash = "sha256-e/+eigIzpP0g+ZqTeyZnF6mloaY6UeKcMWfqryCcLbM=";
  };
in
bun2nix.writeBunApplication {
  pname = "defuddle";
  inherit version src;

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  postPatch = ''
    rm -f package-lock.json
    cp ${./package.json} package.json
    cp ${./bun.lock} bun.lock
  '';

  dontUseBunBuild = true;
  dontRunLifecycleScripts = true;

  startScript = ''
    bun run src/cli.ts "$@"
  '';

  doCheck = false;

  meta = with lib; {
    description = "Extract article content and metadata from web pages";
    homepage = "https://github.com/kepano/defuddle";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "defuddle";
  };
}
