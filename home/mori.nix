{ config, pkgs, lib, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  moriLogDir = "${config.home.homeDirectory}/.mori/logs";

  connStr = "host=${pgSocket} dbname=mori";

  mori-automate-wrapper = pkgs.writeShellScript "mori-automate" ''
    set -euo pipefail
    export MORI_PG_CONNECTION_STRING="${connStr}"

    # Wait for PostgreSQL to be ready
    for i in $(seq 1 30); do
      if ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; then break; fi
      sleep 1
    done

    if ! ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; then
      echo "Error: PostgreSQL not ready after 30s" >&2
      exit 1
    fi

    exec ${pkgs.mori}/bin/mori automate run
  '';

  mori-db-setup = pkgs.writeShellScriptBin "mori-db-setup" ''
    set -euo pipefail
    pg-ensure-db mori

    echo ""
    echo "Database ready! Next: run migrations from the mori dev shell:"
    echo "  cd ~/Keikaku/bokuno/mori-project/mori"
    echo "  PGHOST=${pgSocket} PGDATABASE=mori just run-migrations"
  '';
in
{
  home.packages = [
    pkgs.mori
    mori-db-setup
  ];

  home.activation.mori-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${moriLogDir}"
  '';

  programs.zsh.sessionVariables = {
    MORI_PG_CONNECTION_STRING = connStr;
  };

  launchd.agents.mori-automate = {
    enable = true;
    config = {
      Label = "com.shinzui.mori-automate";
      ProgramArguments = [ "${mori-automate-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${moriLogDir}/automate.stdout.log";
      StandardErrorPath = "${moriLogDir}/automate.stderr.log";
      EnvironmentVariables = {
        MORI_PG_CONNECTION_STRING = connStr;
      };
    };
  };
}
