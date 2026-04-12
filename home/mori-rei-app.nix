{ config, pkgs, lib, age, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  logDir = "${config.home.homeDirectory}/.mori-rei-app/logs";
  # The rei event store. REI_PG_CONNECTION_STRING is the same env var
  # the `rei` CLI reads, so both tools share one configuration source.
  reiConnStr = "host=${pgSocket} dbname=rei";
  # Separate operational database for mori-rei-app: owns the
  # public.webhook_delivery idempotency table. Kept out of the rei
  # event store so rei's schema is not coupled to application state.
  appConnStr = "host=${pgSocket} dbname=mori_rei_app";
  secretPath = age.secrets.mori-rei-app-webhook-secret.path;

  mori-rei-app-wrapper = pkgs.writeShellScript "mori-rei-app" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${reiConnStr}"
    export MORI_REI_APP_PG_CONNECTION_STRING="${appConnStr}"
    export WEBHOOK_SECRET="$(cat ${secretPath})"

    # Wait for PostgreSQL to be ready
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done

    # Ensure the operational database exists (idempotent). createdb
    # exits non-zero if the database is already there, which is the
    # steady state after the first successful startup.
    ${pg}/bin/createdb -h "${pgSocket}" mori_rei_app 2>/dev/null || true

    exec ${pkgs.mori-rei-app}/bin/mori-rei-app
  '';
in
{
  home.packages = [
    pkgs.mori-rei-app
  ];

  home.activation.mori-rei-app-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  # Stop mori-rei-app agent and wait for process to fully exit before
  # home-manager tries to re-register it.
  #
  # IMPORTANT: Only bootout if the plist actually changed. setupLaunchAgents
  # skips unchanged plists, so booting out unconditionally leaves them unloaded.
  home.activation.mori-rei-app-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
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

    stop_and_wait "com.shinzui.mori-rei-app"
  '';

  launchd.agents.mori-rei-app = {
    enable = true;
    config = {
      Label = "com.shinzui.mori-rei-app";
      ProgramArguments = [ "${mori-rei-app-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/server.stdout.log";
      StandardErrorPath = "${logDir}/server.stderr.log";
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = reiConnStr;
        MORI_REI_APP_PG_CONNECTION_STRING = appConnStr;
      };
    };
  };
}
