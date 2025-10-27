{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "oq";
  version = "0.0.20";

  src = fetchFromGitHub {
    owner = "plutov";
    repo = "oq";
    rev = "v${version}";
    hash = "sha256-DVQyiwlUAwdWBBq3Zoto0Mi/vWhC+lMt8KeFBFSVsF8=";
  };

  vendorHash = "sha256-843hhDJXLkqbfuB4CdFl5suLqgsGIAWlk7st46cJp3c=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # Tests may require network access
  doCheck = false;

  meta = with lib; {
    description = "Terminal-based viewer for OpenAPI specifications";
    homepage = "https://github.com/plutov/oq";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "oq";
  };
}
