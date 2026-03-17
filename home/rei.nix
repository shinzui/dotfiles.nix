{ config, pkgs, lib, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  reiBin = "${pkgs.rei}/bin/rei";
  reiLogDir = "${config.home.homeDirectory}/.rei/logs";
  connStr = "host=${pgSocket} dbname=rei";

  waitForPg = ''
    for i in $(seq 1 30); do
      if ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; then break; fi
      sleep 1
    done

    if ! ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; then
      echo "Error: PostgreSQL not ready after 30s" >&2
      exit 1
    fi
  '';

  rei-subscription-wrapper = pkgs.writeShellScript "rei-subscription" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"

    ${waitForPg}

    exec ${reiBin} subscription run all
  '';

  rei-worker-wrapper = pkgs.writeShellScript "rei-worker" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"

    ${waitForPg}

    exec ${reiBin} worker all
  '';

  rei-zsh-completions = pkgs.runCommand "rei-zsh-completions" { } ''
    REI_PG_CONNECTION_STRING="host=localhost dbname=rei" ${reiBin} completions zsh > $out
  '';

  rei-db-setup = pkgs.writeShellScriptBin "rei-db-setup" ''
    set -euo pipefail
    pg-ensure-db rei

    echo ""
    echo "Database ready! Next: run migrations from the rei dev shell:"
    echo "  cd ~/Keikaku/bokuno/rei-project/rei-production"
    echo "  PGHOST=${pgSocket} PGDATABASE=rei just run-migrations"
  '';
in
{
  home.packages = [
    (lib.meta.lowPrio pkgs.rei)
    rei-db-setup
  ];

  home.file.".zfunc/_rei".source = rei-zsh-completions;

  home.activation.rei-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${reiLogDir}"
  '';

  # Stop rei agents and wait for processes to fully exit before home-manager
  # tries to re-register them. Without this, bootout returns before the process
  # terminates, and the subsequent bootstrap fails with I/O error (code 5).
  home.activation.rei-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    stop_and_wait() {
      local label="$1"
      local domain="gui/$(id -u)"

      # Only attempt if the agent is currently loaded
      if /bin/launchctl print "$domain/$label" &>/dev/null; then
        verboseEcho "Stopping $label..."
        /bin/launchctl bootout "$domain/$label" 2>/dev/null || true

        # Wait for the process to fully exit (up to 30s)
        for i in $(seq 1 30); do
          if ! /bin/launchctl print "$domain/$label" &>/dev/null; then
            break
          fi
          sleep 1
        done
      fi
    }

    stop_and_wait "com.shinzui.rei-worker"
    stop_and_wait "com.shinzui.rei-subscription"
  '';

  programs.zsh.sessionVariables = {
    REI_PG_CONNECTION_STRING = connStr;
  };

  launchd.agents.rei-subscription = {
    enable = true;
    config = {
      Label = "com.shinzui.rei-subscription";
      ProgramArguments = [ "${rei-subscription-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${reiLogDir}/subscription.stdout.log";
      StandardErrorPath = "${reiLogDir}/subscription.stderr.log";
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = connStr;
        PG_CONNECTION_STRING = connStr;
      };
    };
  };

  launchd.agents.rei-worker = {
    enable = true;
    config = {
      Label = "com.shinzui.rei-worker";
      ProgramArguments = [ "${rei-worker-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${reiLogDir}/worker.stdout.log";
      StandardErrorPath = "${reiLogDir}/worker.stderr.log";
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = connStr;
        PG_CONNECTION_STRING = connStr;
      };
    };
  };
}
