{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, onnxruntime
, apple-sdk_15
, stdenv
}:

rustPlatform.buildRustPackage rec {
  pname = "ck";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "BeaconBay";
    repo = "ck";
    rev = version;
    hash = "sha256-CZsayq1JxOhGaT9iTNVKcyqGGnJlxcjDAbcMKArtR6k=";
  };

  cargoHash = "sha256-+74XPcv/mnG7GAG6H8QJe6EtyO2xWhHXvdyTGSPwZeI=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    onnxruntime
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_15
  ];

  env = {
    ORT_DYLIB_PATH = "${onnxruntime}/lib/libonnxruntime${stdenv.hostPlatform.extensions.sharedLibrary}";
  };

  # Tests require network access for model downloads
  doCheck = false;

  meta = with lib; {
    description = "Local-first semantic and hybrid search tool for code";
    homepage = "https://github.com/BeaconBay/ck";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "ck";
  };
}
