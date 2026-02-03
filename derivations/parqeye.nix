{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "parqeye";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "kaushiksrini";
    repo = "parqeye";
    rev = "v${version}";
    hash = "sha256-gsH/dSxQRbfTdWeZ8KCTxjQmmD8yfAxrr+WAs/nGtUw=";
  };

  cargoHash = "sha256-Xk1T+1TDMs13y/1ghieiewy2ZwrHZD0U6iZw3n/DMKI=";

  doCheck = false;

  meta = with lib; {
    description = "Peek inside Parquet files right from your terminal";
    homepage = "https://github.com/kaushiksrini/parqeye";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "parqeye";
  };
}
