{ config, pkgs, lib, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  moriLogDir = "${config.home.homeDirectory}/.mori/logs";

  connStr = "host=${pgSocket} dbname=mori";

  mori-automate-wrapper = pkgs.writeShellScript "mori-automate" ''
    set -euo pipefail
    export MORI_PG_CONNECTION_STRING="${connStr}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    # Wait for PostgreSQL to be ready
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done

    exec ${pkgs.mori}/bin/mori automate daemon --ingest-interval 3600
  '';

  mori-db-setup = pkgs.writeShellScriptBin "mori-db-setup" ''
    set -euo pipefail
    pg-ensure-db mori

    echo ""
    echo "Database ready! Next: run migrations from the mori dev shell:"
    echo "  cd ~/Keikaku/bokuno/mori-project/mori"
    echo "  PGHOST=${pgSocket} PGDATABASE=mori just run-migrations"
  '';
  mori-zsh-completions = pkgs.runCommand "mori-zsh-completions" { } ''
    MORI_PG_CONNECTION_STRING="host=localhost dbname=mori" ${pkgs.mori}/bin/mori completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.mori
    mori-db-setup
  ];

  home.file.".zfunc/_mori".source = mori-zsh-completions;

  home.activation.mori-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${moriLogDir}"
  '';

  # Stop mori agent and wait for process to fully exit before home-manager
  # tries to re-register it. Without this, bootout returns before the process
  # terminates, and the subsequent bootstrap fails with I/O error (code 5).
  #
  # IMPORTANT: Only bootout if the plist actually changed. setupLaunchAgents
  # skips unchanged plists, so booting out unconditionally leaves them unloaded.
  home.activation.mori-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    stop_and_wait() {
      local label="$1"
      local domain="gui/$(id -u)"
      local newPlist="$newGenPath/LaunchAgents/$label.plist"
      local curPlist="$HOME/Library/LaunchAgents/$label.plist"

      # Only stop if the plist is actually changing
      if cmp -s "$newPlist" "$curPlist"; then
        verboseEcho "$label plist unchanged, skipping stop"
        return
      fi

      if /bin/launchctl print "$domain/$label" &>/dev/null; then
        local pid
        pid=$(/bin/launchctl print "$domain/$label" 2>/dev/null \
              | /usr/bin/grep -m1 'pid =' | /usr/bin/awk '{print $NF}')

        verboseEcho "Stopping $label (pid ''${pid:-unknown})..."
        /bin/launchctl bootout "$domain/$label" 2>/dev/null || true

        # Wait for the actual process to die, not just launchd deregistration
        if [ -n "$pid" ]; then
          while kill -0 "$pid" 2>/dev/null; do
            sleep 1
          done
        fi
      fi
    }

    stop_and_wait "com.shinzui.mori-automate"
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
