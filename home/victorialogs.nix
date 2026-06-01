{ config, pkgs, lib, ... }:

let
  vl = pkgs.victorialogs;
  vlBase = "${config.home.homeDirectory}/.local/share/victoria-logs";
  dataDir = "${vlBase}/data";
  logDir = "${vlBase}/logs";
  port = 9428;
  homeDir = config.home.homeDirectory;

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

  # Tail one log file and push every new line to VictoriaLogs as ndjson.
  # Args: <app> <stream> <file>. Uses tail -F -n0 so existing history is
  # not re-shipped on shipper restart; KeepAlive handles transient crashes.
  shipper-wrapper = pkgs.writeShellScript "victorialogs-shipper" ''
    set -euo pipefail
    app="$1"; stream="$2"; file="$3"

    until [ -e "$file" ]; do sleep 5; done
    until ${pkgs.curl}/bin/curl -fsS http://localhost:${toString port}/health >/dev/null 2>&1; do
      sleep 2
    done

    # jq buffers stdout when piped (4KB block buffer). Without --unbuffered,
    # single log lines sit in jq's stdio buffer indefinitely on quiet daemons,
    # so they never reach VictoriaLogs in real time. The flag forces a flush
    # after each output record.
    ${pkgs.coreutils}/bin/tail -n0 -F "$file" \
      | ${pkgs.jq}/bin/jq -Rc --unbuffered \
          --arg app "$app" --arg stream "$stream" \
          '{_msg: ., _time: "0", app: $app, stream: $stream}' \
      | while IFS= read -r line; do
          printf '%s\n' "$line" \
            | ${pkgs.curl}/bin/curl -fsS -X POST \
                -H 'Content-Type: application/stream+json' \
                --data-binary @- \
                'http://localhost:${toString port}/insert/jsonline?_stream_fields=app,stream&_msg_field=_msg&_time_field=_time' \
            || true
        done
  '';

  # Single source of truth for the apps we ship logs for. Each entry expands
  # into a launchd agent below and contributes a label to the stop-agents
  # activation hook so rebuilds restart shippers cleanly.
  shippers = [
    { app = "rei-worker";              stream = "stdout"; file = "${homeDir}/.rei/logs/worker.stdout.log"; }
    { app = "rei-worker";              stream = "stderr"; file = "${homeDir}/.rei/logs/worker.stderr.log"; }
    { app = "rei-worker-git-sync";     stream = "stdout"; file = "${homeDir}/.rei/logs/worker-git-sync.stdout.log"; }
    { app = "rei-worker-git-sync";     stream = "stderr"; file = "${homeDir}/.rei/logs/worker-git-sync.stderr.log"; }
    { app = "rei-subscription";        stream = "stdout"; file = "${homeDir}/.rei/logs/subscription.stdout.log"; }
    { app = "rei-subscription";        stream = "stderr"; file = "${homeDir}/.rei/logs/subscription.stderr.log"; }
    { app = "mori-automate";           stream = "stdout"; file = "${homeDir}/.mori/logs/automate.stdout.log"; }
    { app = "mori-automate";           stream = "stderr"; file = "${homeDir}/.mori/logs/automate.stderr.log"; }
    { app = "mori-rei-app";            stream = "stdout"; file = "${homeDir}/.mori-rei-app/logs/server.stdout.log"; }
    { app = "mori-rei-app";            stream = "stderr"; file = "${homeDir}/.mori-rei-app/logs/server.stderr.log"; }
    { app = "notion-hub-subscription"; stream = "stdout"; file = "${homeDir}/.notion-hub/logs/subscription.stdout.log"; }
    { app = "notion-hub-subscription"; stream = "stderr"; file = "${homeDir}/.notion-hub/logs/subscription.stderr.log"; }
    { app = "postgresql";              stream = "stdout"; file = "${homeDir}/.local/state/postgresql/logs/postgres.stdout.log"; }
    { app = "postgresql";              stream = "stderr"; file = "${homeDir}/.local/state/postgresql/logs/postgres.stderr.log"; }
  ];

  shipperKey  = s: "victorialogs-shipper-${s.app}-${s.stream}";
  shipperLabel = s: "com.shinzui.${shipperKey s}";

  shipperAgent = s: lib.nameValuePair (shipperKey s) {
    enable = true;
    config = {
      Label = shipperLabel s;
      ProgramArguments = [
        "${shipper-wrapper}"
        s.app
        s.stream
        s.file
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardErrorPath = "${logDir}/shipper.${s.app}.${s.stream}.stderr.log";
    };
  };

  allLabels = [ "com.shinzui.victorialogs" ] ++ map shipperLabel shippers;
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
        # awk-only (exits 0 on no match) + `|| true`: a loaded-but-not-running
        # agent (crash-looping / mid-restart, no `pid = ` line) makes grep exit 1,
        # which home-manager's `set -euo pipefail` would turn into an aborted switch.
        pid=$(/bin/launchctl print "$domain/$label" 2>/dev/null \
              | /usr/bin/awk '/[[:space:]]pid = /{print $NF; exit}') || true

        verboseEcho "Stopping $label (pid ''${pid:-unknown})..."
        /bin/launchctl bootout "$domain/$label" 2>/dev/null || true

        if [ -n "$pid" ]; then
          while kill -0 "$pid" 2>/dev/null; do
            sleep 1
          done
        fi
      fi
    }

    ${lib.concatMapStringsSep "\n" (label: ''stop_and_wait "${label}"'') allLabels}
  '';

  launchd.agents = {
    victorialogs = {
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
  } // lib.listToAttrs (map shipperAgent shippers);

  # Useful LogsQL queries (run via VLUI at http://localhost:9428/select/vmui/
  # or `just logs-query 'QUERY'`):
  #
  #   _time:5m AND _msg:~"error|panic"        # any error/panic in last 5min
  #   app:rei-worker | head 100                # last 100 lines from rei-worker
  #   _time:1h | stats by (app, stream) count() # message volume per app/stream
  #   app:postgresql AND _msg:~"FATAL|PANIC"   # postgres fatal log lines
  #   _stream:{app="mori-automate", stream="stderr"} _time:1d
}
