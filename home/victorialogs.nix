{ config, pkgs, lib, ... }:

let
  vl = pkgs.victorialogs;
  vlBase = "${config.home.homeDirectory}/.local/share/victoria-logs";
  dataDir = "${vlBase}/data";
  logDir = "${vlBase}/logs";
  port = 9428;

  victorialogs-wrapper = pkgs.writeShellScript "victorialogs" ''
    set -euo pipefail
    mkdir -p "${dataDir}" "${logDir}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${vl}/bin/victoria-logs \
      -storageDataPath="${dataDir}" \
      -httpListenAddr=":${toString port}" \
      -loggerOutput=stderr \
      -retentionPeriod=7d
  '';
in
{
  home.packages = [ vl ];

  home.activation.victorialogs-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${dataDir}" "${logDir}"
  '';

  # Stop victorialogs agents and wait for processes to fully exit before
  # home-manager tries to re-register them. Without this, bootout returns
  # before the process terminates, and the subsequent bootstrap fails with
  # I/O error (code 5). Mirrors home/mori.nix:home.activation.mori-stop-agents.
  home.activation.victorialogs-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    stop_and_wait() {
      local label="$1"
      local domain="gui/$(id -u)"
      local newPlist="$newGenPath/LaunchAgents/$label.plist"
      local curPlist="$HOME/Library/LaunchAgents/$label.plist"

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

        if [ -n "$pid" ]; then
          while kill -0 "$pid" 2>/dev/null; do
            sleep 1
          done
        fi
      fi
    }

    stop_and_wait "com.shinzui.victorialogs"
  '';

  launchd.agents.victorialogs = {
    enable = true;
    config = {
      Label = "com.shinzui.victorialogs";
      ProgramArguments = [ "${victorialogs-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${logDir}/victoria-logs.stdout.log";
      StandardErrorPath = "${logDir}/victoria-logs.stderr.log";
    };
  };
}
