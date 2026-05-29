{ config, pkgs, lib, ... }:

let
  vt = pkgs.victoriatraces;
  vtBase = "${config.home.homeDirectory}/.local/share/victoria-traces";
  dataDir = "${vtBase}/data";
  logDir = "${vtBase}/logs";
  nginxDir = "${vtBase}/nginx";
  port = 10428;
  jaegerPort = 16686;

  victoriatracesStopLabels = [
    "com.shinzui.victoriatraces"
    "com.shinzui.victoriatraces-jaeger-ui"
  ];

  victoriatraces-wrapper = pkgs.writeShellScript "victoriatraces" ''
    set -euo pipefail
    mkdir -p "${dataDir}" "${logDir}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${vt}/bin/victoria-traces \
      -storageDataPath="${dataDir}" \
      -httpListenAddr=":${toString port}" \
      -loggerOutput=stderr \
      -retentionPeriod=7d
  '';

  jaeger-nginx-conf = pkgs.writeText "victoriatraces-jaeger-ui-nginx.conf" ''
    error_log ${logDir}/jaeger-ui-nginx.error.log info;
    pid ${nginxDir}/nginx.pid;

    events {
      worker_connections 128;
    }

    http {
      access_log ${logDir}/jaeger-ui-nginx.access.log;
      include ${pkgs.nginx}/conf/mime.types;
      default_type application/octet-stream;
      sendfile on;

      client_body_temp_path ${nginxDir}/client_body_temp;
      proxy_temp_path ${nginxDir}/proxy_temp;
      fastcgi_temp_path ${nginxDir}/fastcgi_temp;
      uwsgi_temp_path ${nginxDir}/uwsgi_temp;
      scgi_temp_path ${nginxDir}/scgi_temp;

      server {
        listen 127.0.0.1:${toString jaegerPort};
        server_name localhost;

        location / {
          root ${pkgs.jaeger-ui}/share/jaeger-ui;
          try_files $uri $uri/ /index.html;
        }

        location /api {
          proxy_pass http://127.0.0.1:${toString port}/select/jaeger/api;
        }
      }
    }
  '';

  jaeger-ui-wrapper = pkgs.writeShellScript "victoriatraces-jaeger-ui" ''
    set -euo pipefail
    mkdir -p "${logDir}" "${nginxDir}" \
      "${nginxDir}/client_body_temp" \
      "${nginxDir}/proxy_temp" \
      "${nginxDir}/fastcgi_temp" \
      "${nginxDir}/uwsgi_temp" \
      "${nginxDir}/scgi_temp"

    exec ${pkgs.nginx}/bin/nginx -c "${jaeger-nginx-conf}" -p "${nginxDir}" -g "daemon off;"
  '';
in
{
  home.packages = [
    vt
    pkgs.jaeger-ui
  ];

  home.activation.victoriatraces-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${dataDir}" "${logDir}" "${nginxDir}"
  '';

  home.activation.victoriatraces-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
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

    ${lib.concatMapStringsSep "\n" (label: ''stop_and_wait "${label}"'') victoriatracesStopLabels}
  '';

  launchd.agents = {
    victoriatraces = {
      enable = true;
      config = {
        Label = "com.shinzui.victoriatraces";
        ProgramArguments = [ "${victoriatraces-wrapper}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ExitTimeOut = 30;
        StandardOutPath = "${logDir}/victoria-traces.stdout.log";
        StandardErrorPath = "${logDir}/victoria-traces.stderr.log";
      };
    };

    victoriatraces-jaeger-ui = {
      enable = true;
      config = {
        Label = "com.shinzui.victoriatraces-jaeger-ui";
        ProgramArguments = [ "${jaeger-ui-wrapper}" ];
        RunAtLoad = true;
        KeepAlive = true;
        ExitTimeOut = 15;
        StandardOutPath = "${logDir}/jaeger-ui-nginx.stdout.log";
        StandardErrorPath = "${logDir}/jaeger-ui-nginx.stderr.log";
      };
    };
  };

  # Useful trace endpoints:
  #
  #   http://localhost:16686/                         # Jaeger UI
  #   http://localhost:10428/select/vmui/             # VictoriaTraces VMUI
  #   http://localhost:10428/insert/opentelemetry/v1/traces
  #   http://localhost:10428/select/jaeger/api/services
}
