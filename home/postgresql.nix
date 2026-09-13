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
  # Touched after every validated full backup; the scheduler uses its age to pick
  # full vs incremental.
  pgLastFullStamp = "${pgStateDir}/last-full-backup";
  # Held by pg-backup for the whole run so the offsite sync never copies a
  # catalog mid-backup.
  pgBackupLock = "${pgStateDir}/backup.lock";
  pgOffsiteVolume = "/Volumes/aki-2023";
  pgOffsiteDir = "${pgOffsiteVolume}/postgresql-backups";

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

    # Retention. Without these, pg_rman never prunes the WAL archive, and since a
    # full backup copies the whole archive into itself, every backup grows without
    # bound (6.7GB in Jul 2026 -> 32GB in Aug, of which 30GB was archived WAL).
    # 7 days, not 30: this instance writes ~1.2GB/day of WAL, so a 30-day window
    # would keep ~31GB and leave full backups as large as the problem being fixed.
    KEEP_ARCLOG_DAYS="''${PG_KEEP_ARCLOG_DAYS:-7}"
    KEEP_DATA_GENERATIONS="''${PG_KEEP_DATA_GENERATIONS:-3}"

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

    exec 9>"${pgBackupLock}"
    if ! ${pkgs.flock}/bin/flock -n 9; then
      echo "Error: another backup or offsite sync is running."
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
      --keep-arclog-days="$KEEP_ARCLOG_DAYS" \
      --keep-data-generations="$KEEP_DATA_GENERATIONS" \
      --progress

    echo "Validating backup..."
    ${pkgs.pg_rman}/bin/pg_rman validate \
      -B "${pgBackupDir}"

    if [[ "$BACKUP_MODE" == "full" ]]; then
      ${pkgs.coreutils}/bin/touch "${pgLastFullStamp}"
    fi

    echo ""
    echo "Backup complete. Recent backups:"
    ${pkgs.pg_rman}/bin/pg_rman show \
      -B "${pgBackupDir}"
  '';

  # Run daily by launchd. One agent that picks the mode, rather than separate
  # weekly-full and daily-incremental agents: launchd fires missed calendar jobs
  # on wake, so two agents would race after a sleep, and an incremental could run
  # without a recent full behind it.
  pg-backup-scheduled = pkgs.writeShellScriptBin "pg-backup-scheduled" ''
    set -euo pipefail
    FULL_INTERVAL_SECS="''${PG_FULL_BACKUP_INTERVAL_SECS:-561600}" # 6.5 days
    echo "=== $(${pkgs.coreutils}/bin/date -Is) ==="

    # launchd may fire right after wake/login, before postgres is accepting.
    for i in $(${pkgs.coreutils}/bin/seq 1 60); do
      if ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; then break; fi
      sleep 1
    done

    mode=full
    if [ -f "${pgLastFullStamp}" ]; then
      age=$(( $(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/stat -c %Y "${pgLastFullStamp}") ))
      if (( age < FULL_INTERVAL_SECS )); then
        mode=incremental
      fi
    fi

    ${pg-backup}/bin/pg-backup "$mode"
    ${pg-backup-offsite-sync}/bin/pg-backup-offsite-sync
  '';

  # Mirrors the pg_rman catalog to the external drive. Runs after each scheduled
  # backup and on any volume mount, so a backup taken while the drive was
  # unplugged is copied the next time it is attached.
  pg-backup-offsite-sync = pkgs.writeShellScriptBin "pg-backup-offsite-sync" ''
    set -euo pipefail

    # /Volumes/<name> only exists while mounted, but a real mount has its own
    # device id; check that so --delete can never target a stray directory.
    if [ ! -d "${pgOffsiteVolume}" ] || \
       [ "$(${pkgs.coreutils}/bin/stat -c %d "${pgOffsiteVolume}")" = "$(${pkgs.coreutils}/bin/stat -c %d /Volumes)" ]; then
      echo "${pgOffsiteVolume} not mounted; skipping offsite sync."
      exit 0
    fi

    # Guard --delete against an empty or missing source wiping the mirror.
    if [ ! -f "${pgBackupDir}/pg_rman.ini" ]; then
      echo "Error: ${pgBackupDir} is not a pg_rman catalog; refusing to sync."
      exit 1
    fi

    exec 9>"${pgBackupLock}"
    if ! ${pkgs.flock}/bin/flock -w 3600 9; then
      echo "Error: timed out waiting for running backup; skipping offsite sync."
      exit 1
    fi

    echo "=== $(${pkgs.coreutils}/bin/date -Is) offsite sync to ${pgOffsiteDir} ==="
    mkdir -p "${pgOffsiteDir}"
    ${pkgs.rsync}/bin/rsync -a --delete "${pgBackupDir}/" "${pgOffsiteDir}/"
    echo "Offsite sync complete."
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
    # Pinned coreutils: `date -v-Nd` is BSD syntax, but PATH here resolves to GNU
    # coreutils, where it fails outright and takes the script down via pipefail.
    ${pkgs.pg_rman}/bin/pg_rman delete \
      -B "${pgBackupDir}" \
      $(${pkgs.coreutils}/bin/date -d "''${KEEP_DAYS} days ago" +%Y-%m-%d)
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
      pg-backup-scheduled
      pg-backup-offsite-sync
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

    # Stop postgresql and wait for process to fully exit before home-manager
    # tries to re-register it. Without this, bootout returns before the process
    # terminates, and the subsequent bootstrap fails with I/O error (code 5).
    # Also cleans up the stale postmaster.pid that postgres leaves behind when
    # launchd sends SIGTERM during a rebuild.
    home.activation.postgresql-stop = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
      label="com.shinzui.postgresql"
      domain="gui/$(id -u)"
      newPlist="$newGenPath/LaunchAgents/$label.plist"
      curPlist="$HOME/Library/LaunchAgents/$label.plist"

      # Only stop if the plist is actually changing
      if cmp -s "$newPlist" "$curPlist"; then
        verboseEcho "$label plist unchanged, skipping stop"
      elif /bin/launchctl print "$domain/$label" &>/dev/null; then
        # awk-only (exits 0 on no match) + `|| true`: a loaded-but-not-running
        # agent (crash-looping / mid-restart, no `pid = ` line) makes grep exit 1,
        # which home-manager's `set -euo pipefail` would turn into an aborted switch.
        pid=$(/bin/launchctl print "$domain/$label" 2>/dev/null \
              | /usr/bin/awk '/[[:space:]]pid = /{print $NF; exit}') || true

        verboseEcho "Stopping $label (pid ''${pid:-unknown})..."
        /bin/launchctl bootout "$domain/$label" 2>/dev/null || true

        # Wait for the actual process to die, not just launchd deregistration
        if [ -n "$pid" ]; then
          while kill -0 "$pid" 2>/dev/null; do
            sleep 1
          done
        fi

        # Remove stale postmaster.pid left after SIGTERM shutdown
        rm -f "${pgData}/postmaster.pid"
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

    launchd.agents.pg-backup = {
      enable = true;
      config = {
        Label = "com.shinzui.pg-backup";
        ProgramArguments = [ "${pg-backup-scheduled}/bin/pg-backup-scheduled" ];
        # Daily at 03:00; if asleep then, launchd runs it once on wake.
        StartCalendarInterval = [ { Hour = 3; Minute = 0; } ];
        LowPriorityIO = true;
        Nice = 10;
        StandardOutPath = "${pgLog}/pg-backup.stdout.log";
        StandardErrorPath = "${pgLog}/pg-backup.stderr.log";
      };
    };

    launchd.agents.pg-backup-offsite-sync = {
      enable = true;
      config = {
        Label = "com.shinzui.pg-backup-offsite-sync";
        ProgramArguments = [ "${pg-backup-offsite-sync}/bin/pg-backup-offsite-sync" ];
        # Fires on every volume mount; the script exits unless it is the backup drive.
        StartOnMount = true;
        LowPriorityIO = true;
        Nice = 10;
        StandardOutPath = "${pgLog}/pg-backup-offsite-sync.stdout.log";
        StandardErrorPath = "${pgLog}/pg-backup-offsite-sync.stderr.log";
      };
    };
  };
}
