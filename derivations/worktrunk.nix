{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "max-sixty";
    repo = "worktrunk";
    rev = "v${version}";
    hash = "sha256-eZpwRM2kx6QzZTkwlIEnVn8cyt+6+L41L0jKAIaJOSM=";
  };

  cargoHash = "sha256-AYrOO1Dkk4uYjKMuILjmjLBpnf+iKNRviJAzLfEmB5Y=";

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
