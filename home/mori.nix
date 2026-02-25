{ config, pkgs, lib, ... }:

let
  pg = pkgs.postgresql_18;
  moriDir = "${config.home.homeDirectory}/.mori";
  pgData = "${moriDir}/data";
  pgSocket = "${moriDir}/db";
  pgLog = "${moriDir}/logs";

  mori-db-setup = pkgs.writeShellScriptBin "mori-db-setup" ''
    set -euo pipefail
    PGHOST="${pgSocket}"

    echo "Waiting for PostgreSQL..."
    for i in $(seq 1 30); do
      if ${pg}/bin/pg_isready -h "$PGHOST" > /dev/null 2>&1; then break; fi
      sleep 1
    done

    if ! ${pg}/bin/pg_isready -h "$PGHOST" > /dev/null 2>&1; then
      echo "Error: PostgreSQL not ready. Check: launchctl list | grep mori"
      exit 1
    fi

    if ! ${pg}/bin/psql -h "$PGHOST" -lqt | cut -d \| -f 1 | grep -qw mori; then
      echo "Creating mori database..."
      ${pg}/bin/createdb -h "$PGHOST" mori
    else
      echo "Database 'mori' already exists."
    fi

    echo ""
    echo "Database ready! Next: run migrations from the mori dev shell:"
    echo "  cd ~/Keikaku/bokuno/mori-project/mori"
    echo "  PGHOST=$PGHOST PGDATABASE=mori just run-migrations"
  '';
in
{
  home.packages = [
    pkgs.mori
    mori-db-setup
  ];

  programs.zsh.sessionVariables = {
    MORI_PG_CONNECTION_STRING = "host=${pgSocket} dbname=mori";
  };

  home.activation.mori-postgres-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${pgSocket}" "${pgLog}"
    if [ ! -d "${pgData}" ]; then
      run ${pg}/bin/initdb --auth=trust --no-locale --encoding=UTF8 -D "${pgData}"
    fi
  '';

  launchd.agents.mori-postgres = {
    enable = true;
    config = {
      Label = "com.shinzui.mori-postgres";
      ProgramArguments = [
        "${pg}/bin/postgres"
        "-D" pgData
        "-k" pgSocket
        "-c" "listen_addresses="
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${pgLog}/postgres.stdout.log";
      StandardErrorPath = "${pgLog}/postgres.stderr.log";
    };
  };
}
