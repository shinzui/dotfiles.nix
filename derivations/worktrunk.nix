{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "max-sixty";
    repo = "worktrunk";
    rev = "v${version}";
    hash = "sha256-vocdf+H939urB5l05noU3oCa5YCHODS/Egvev8om2fs=";
  };

  cargoHash = "sha256-6asOGcmX5IKl0Y76rSkqf6ptO4OM4br4ZIG9a/tRoL4=";

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
