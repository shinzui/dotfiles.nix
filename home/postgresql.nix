{ config, pkgs, lib, ... }:

let
  pg = pkgs.postgresql_18;
  pgDataDir = "${config.home.homeDirectory}/.local/share/postgresql";
  pgData = "${pgDataDir}/data";
  pgStateDir = "${config.home.homeDirectory}/.local/state/postgresql";
  pgSocket = pgStateDir;
  pgLog = "${pgStateDir}/logs";

  pg-ensure-db = pkgs.writeShellScriptBin "pg-ensure-db" ''
    set -euo pipefail
    DBNAME="''${1:?Usage: pg-ensure-db <database-name>}"
    PGHOST="${pgSocket}"

    echo "Waiting for PostgreSQL..."
    for i in $(seq 1 30); do
      if ${pg}/bin/pg_isready -h "$PGHOST" > /dev/null 2>&1; then break; fi
      sleep 1
    done

    if ! ${pg}/bin/pg_isready -h "$PGHOST" > /dev/null 2>&1; then
      echo "Error: PostgreSQL not ready. Check: launchctl list | grep postgresql"
      exit 1
    fi

    if ! ${pg}/bin/psql -h "$PGHOST" -lqt | cut -d \| -f 1 | grep -qw "$DBNAME"; then
      echo "Creating $DBNAME database..."
      ${pg}/bin/createdb -h "$PGHOST" "$DBNAME"
      echo "Database '$DBNAME' created."
    else
      echo "Database '$DBNAME' already exists."
    fi
  '';
in
{
  options.services.postgresql = {
    socketDir = lib.mkOption {
      type = lib.types.str;
      default = pgSocket;
      readOnly = true;
      description = "Path to the PostgreSQL Unix socket directory.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pg;
      readOnly = true;
      description = "The PostgreSQL package used by the shared server.";
    };
  };

  config = {
    home.packages = [
      pg-ensure-db
    ];

    home.activation.postgresql-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${pgSocket}" "${pgLog}" "${pgDataDir}"
      if [ ! -d "${pgData}" ]; then
        run ${pg}/bin/initdb --auth=trust --no-locale --encoding=UTF8 -D "${pgData}"
      fi
    '';

    launchd.agents.postgresql = {
      enable = true;
      config = {
        Label = "com.shinzui.postgresql";
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
  };
}
