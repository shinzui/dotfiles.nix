{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "max-sixty";
    repo = "worktrunk";
    rev = "v${version}";
    hash = "sha256-oDDXe+/QOuDzSZxrVf/Uoau114ZAYzHlmjjiqgMZNJI=";
  };

  cargoHash = "sha256-EghciTbB22i/cCOhtoV88Ml7vu+M6d4/HDFc6IkXYIc=";

  # Test fails in sandbox due to time-based assertions
  doCheck = false;

  meta = with lib; {
    description = "CLI for Git worktree management, designed for parallel AI agent workflows";
    homepage = "https://github.com/max-sixty/worktrunk";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "wt";
  };
}
