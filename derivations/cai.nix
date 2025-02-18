{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "cai";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "ad-si";
    repo = "cai";
    rev = "v${version}";
    sha256 = "sha256-MO0JB1cYx/FBvYgRxpkIfa95281CZ1kmpvDY+p95YiI=";
  };

  cargoHash = "sha256-mUyXOPE9knLvRsfXND+PMVR2vLeRUUXhPcbganHyL+I=";
  useFetchCargoVendor = true;

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
