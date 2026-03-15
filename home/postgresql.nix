{ config, pkgs, lib, ... }:

let
  pg = pkgs.postgresql_18;
  pgDataDir = "${config.home.homeDirectory}/.local/share/postgresql";
  pgData = "${pgDataDir}/data";
  pgStateDir = "${config.home.homeDirectory}/.local/state/postgresql";
  pgSocket = pgStateDir;
  pgLog = "${pgStateDir}/logs";
  pgBackupDir = "${config.home.homeDirectory}/.local/share/postgresql/backups";
  pgArchiveDir = "${config.home.homeDirectory}/.local/share/postgresql/archivelog";

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

  pg-backup = pkgs.writeShellScriptBin "pg-backup" ''
    set -euo pipefail
    PGHOST="${pgSocket}"
    BACKUP_MODE="''${1:-full}"

    if [[ "$BACKUP_MODE" != "full" && "$BACKUP_MODE" != "incremental" ]]; then
      echo "Usage: pg-backup [full|incremental]"
      echo "  full         - Full backup (default)"
      echo "  incremental  - Incremental backup (requires a prior full backup)"
      exit 1
    fi

    if ! ${pg}/bin/pg_isready -h "$PGHOST" > /dev/null 2>&1; then
      echo "Error: PostgreSQL is not running."
      exit 1
    fi

    # Initialize catalog if needed
    if [ ! -f "${pgBackupDir}/pg_rman.ini" ]; then
      echo "Initializing pg_rman backup catalog..."
      ${pkgs.pg_rman}/bin/pg_rman init \
        -B "${pgBackupDir}" \
        -D "${pgData}" \
        -A "${pgArchiveDir}"
    fi

    echo "Starting $BACKUP_MODE backup..."
    ${pkgs.pg_rman}/bin/pg_rman backup \
      -B "${pgBackupDir}" \
      -D "${pgData}" \
      -A "${pgArchiveDir}" \
      -b "$BACKUP_MODE" \
      -d postgres \
      -h "${pgSocket}" \
      --progress

    echo "Validating backup..."
    ${pkgs.pg_rman}/bin/pg_rman validate \
      -B "${pgBackupDir}"

    echo ""
    echo "Backup complete. Recent backups:"
    ${pkgs.pg_rman}/bin/pg_rman show \
      -B "${pgBackupDir}"
  '';

  pg-backup-show = pkgs.writeShellScriptBin "pg-backup-show" ''
    set -euo pipefail
    ${pkgs.pg_rman}/bin/pg_rman show \
      -B "${pgBackupDir}" \
      "$@"
  '';

  pg-backup-purge = pkgs.writeShellScriptBin "pg-backup-purge" ''
    set -euo pipefail
    KEEP_DAYS="''${1:-7}"
    echo "Deleting backups older than $KEEP_DAYS days..."
    ${pkgs.pg_rman}/bin/pg_rman delete \
      -B "${pgBackupDir}" \
      $(date -v-"''${KEEP_DAYS}"d +%Y-%m-%d)
    echo "Done."
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
      pg-backup
      pg-backup-show
      pg-backup-purge
    ];

    home.activation.postgresql-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${pgSocket}" "${pgLog}" "${pgDataDir}" "${pgBackupDir}" "${pgArchiveDir}"
      if [ ! -d "${pgData}" ]; then
        run ${pg}/bin/initdb --auth=trust --no-locale --encoding=UTF8 -D "${pgData}"
      fi

      # Ensure WAL archiving is configured in postgresql.conf (required by pg_rman)
      CONF="${pgData}/postgresql.conf"
      if ! grep -q "# managed by home-manager: pg_rman" "$CONF" 2>/dev/null; then
        cat >> "$CONF" <<PGCONF

# managed by home-manager: pg_rman
wal_level = replica
archive_mode = on
archive_command = 'cp %p ${pgArchiveDir}/%f'
PGCONF
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
