{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "cai";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "ad-si";
    repo = "cai";
    rev = "v${version}";
    sha256 = "sha256-exdBfZk2jco6XGbAUO669mDXzmZPUrg1/beCYj2SUS4=";
  };

  cargoSha256 = "sha256-6Wp5ccfjpCuF0kGg5MCmacxEF/7d8Th0dn+3CbpQWs0=";

  # Disable running tests
  # Tests are writing to the fs 
  # Couldn't create configuration directory: Os { code: 30, kind: ReadOnlyFilesystem, message: "Read-only file system" }
  doCheck = false;

  meta = with lib; {
    description = "CLI tool for prompting LLMs.";
    homepage = "https://github.com/ad-si/cai";
    license = licenses.isc;
    maintainers = with maintainers; [ ad-si ];
  };
}
