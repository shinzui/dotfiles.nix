{ lib
, stdenv
, fetchFromGitHub
, postgresql
, zlib
, openssl
, lz4
, zstd
, readline
, libkrb5
}:

let
  pg_config = postgresql.pg_config;
in
stdenv.mkDerivation rec {
  pname = "pg_rman";
  version = "1.3.19";

  src = fetchFromGitHub {
    owner = "ossc-db";
    repo = "pg_rman";
    rev = "V${version}";
    hash = "sha256-ChfjhqNMUg7IKrRGZZZ6Rxa3s5cUoMrVyJm7wUZcdY4=";
  };

  nativeBuildInputs = [
    pg_config
  ];

  buildInputs = [
    postgresql
    zlib
    openssl
    lz4
    zstd
    readline
    libkrb5
  ];

  makeFlags = [
    "USE_PGXS=1"
    "PG_CONFIG=${pg_config}/bin/pg_config"
  ];

  installPhase = ''
    install -Dm755 pg_rman $out/bin/pg_rman
  '';

  meta = with lib; {
    description = "Online backup and restore tool for PostgreSQL";
    homepage = "https://github.com/ossc-db/pg_rman";
    license = licenses.bsd2;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "pg_rman";
  };
}
