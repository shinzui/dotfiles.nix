{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.8.5";

  src = fetchFromGitHub {
    owner = "max-sixty";
    repo = "worktrunk";
    rev = "v${version}";
    hash = "sha256-O0Bea8RrwNVwBwFYSzr0Q111KFot0IdGKfofTfYIy0M=";
  };

  cargoHash = "sha256-cz9WzsZu8bAOXMnrCQ9kj5S8fIM5455IhX+Hc/7wEs4=";

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
