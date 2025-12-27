{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "uuinfo";
  version = "0.6.8";

  src = fetchFromGitHub {
    owner = "racum";
    repo = "uuinfo";
    rev = "7b3610f467411c16a6762f9a9fb561f136f5fa62";
    hash = "sha256-p+PdaI9MOHf2M7VTnWR6jHvS2xR3tPnFgSQASxxrcwU=";
  };

  cargoHash = "sha256-6ewiYh2ij5OKlQnBGu32/b36Q7UUEUPIYPE68jeYelc=";

  # Integration tests require the binary to be in PATH
  doCheck = false;

  meta = with lib; {
    description = "CLI tool to debug unique identifiers (UUID, ULID, Snowflake, etc)";
    homepage = "https://github.com/racum/uuinfo";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "uuinfo";
  };
}
