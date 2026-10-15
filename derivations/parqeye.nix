{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "parqeye";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "kaushiksrini";
    repo = "parqeye";
    rev = "v${version}";
    hash = "sha256-D/pq9UhB2K76yVIihIBy+47AASe2g5sIA+bW+myI2k0=";
  };

  cargoHash = "sha256-vMYuZiYnuyYcQXLwHLzMYLGPrp6pGp9/Qkx5lmM7/Ik=";

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
