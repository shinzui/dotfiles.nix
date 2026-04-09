{ config, pkgs, lib, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  nhubBin = "${pkgs.notion-hub}/bin/nhub";
  nhubLogDir = "${config.home.homeDirectory}/.notion-hub/logs";
  connStr = "host=${pgSocket} dbname=notion_hub";

  waitForPg = ''
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done
  '';

  notion-hub-subscription-wrapper = pkgs.writeShellScript "notion-hub-subscription" ''
    set -euo pipefail
    export NOTION_HUB_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"

    ${waitForPg}

    exec ${pkgs.notion-hub-subscriptions}/bin/notion-hub-subscriptions
  '';

  nhub-zsh-completions = pkgs.runCommand "nhub-zsh-completions" { } ''
    NOTION_HUB_PG_CONNECTION_STRING="host=localhost dbname=notion_hub" ${nhubBin} completions zsh > $out
  '';

  nhub-db-setup = pkgs.writeShellScriptBin "nhub-db-setup" ''
    set -euo pipefail
    pg-ensure-db notion_hub

    echo ""
    echo "Database ready! Next: run migrations from the notion-hub dev shell:"
    echo "  cd ~/Keikaku/bokuno/notion-hub"
    echo "  PGHOST=${pgSocket} PGDATABASE=notion_hub just run-migrations"
  '';
in
{
  home.packages = [
    pkgs.notion-hub
    nhub-db-setup
  ];

  home.file.".zfunc/_nhub".source = nhub-zsh-completions;

  home.activation.notion-hub-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${nhubLogDir}"
  '';

  # Stop notion-hub agents and wait for processes to fully exit before home-manager
  # tries to re-register them. Without this, bootout returns before the process
  # terminates, and the subsequent bootstrap fails with I/O error (code 5).
  #
  # IMPORTANT: Only bootout if the plist actually changed. setupLaunchAgents
  # skips unchanged plists, so booting out unconditionally leaves them unloaded.
  home.activation.notion-hub-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
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

    stop_and_wait "com.shinzui.notion-hub-subscription"
  '';

  programs.zsh.sessionVariables = {
    NOTION_HUB_PG_CONNECTION_STRING = connStr;
  };

  launchd.agents.notion-hub-subscription = {
    enable = true;
    config = {
      Label = "com.shinzui.notion-hub-subscription";
      ProgramArguments = [ "${notion-hub-subscription-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${nhubLogDir}/subscription.stdout.log";
      StandardErrorPath = "${nhubLogDir}/subscription.stderr.log";
      EnvironmentVariables = {
        NOTION_HUB_PG_CONNECTION_STRING = connStr;
        PG_CONNECTION_STRING = connStr;
      };
    };
  };
}
