{ lib
, bun2nix
, fetchFromGitHub
}:

let
  version = "0.2.0";
  src = fetchFromGitHub {
    owner = "Michaelliv";
    repo = "markit";
    rev = "v${version}";
    hash = "sha256-tbvZi5PZ44YzAZC6t0q4BW88idBpwvrooQMXYNSSqqg=";
  };
in
bun2nix.writeBunApplication {
  pname = "markit";
  inherit version src;

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  dontUseBunBuild = true;
  dontRunLifecycleScripts = true;

  startScript = ''
    bun run src/main.ts "$@"
  '';

  doCheck = false;

  meta = with lib; {
    description = "Convert anything to markdown - PDF, DOCX, PPTX, XLSX, HTML, EPUB, images, audio, URLs and more";
    homepage = "https://github.com/Michaelliv/markit";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "markit";
  };
}
