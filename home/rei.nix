{ config, pkgs, lib, ... }:

let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  reiBin = "${pkgs.rei}/bin/rei";
  reiLogDir = "${config.home.homeDirectory}/.rei/logs";

  # Shared rei CLI runtime environment (connection string + keiro routing),
  # also consumed by home/mina.nix so mina's spawned `rei` reads current data.
  reiCli = import ./rei-cli-env.nix { inherit pkgs lib pgSocket; };
  connStr = reiCli.connStr;
  kirokuMetricsPort = reiCli.kirokuMetricsPort;
  kirokuRemoteUrl = reiCli.kirokuRemoteUrl;
  rei-cli-wrapper = pkgs.writeShellScriptBin "rei" ''
    set -euo pipefail

    if [ "$#" -ge 3 ] \
      && [ "$1" = "kiroku" ] \
      && { [ "$2" = "subscriptions" ] || [ "$2" = "subscription" ]; } \
      && [ "$3" = "status" ]; then
      shift 3

      format="table"
      remoteUrl="''${KIROKU_REMOTE_URL:-${kirokuRemoteUrl}}"

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --format)
            format="$2"
            shift 2
            ;;
          --format=*)
            format="''${1#--format=}"
            shift
            ;;
          --remote-url)
            remoteUrl="$2"
            shift 2
            ;;
          --remote-url=*)
            remoteUrl="''${1#--remote-url=}"
            shift
            ;;
          -h|--help)
            exec ${reiBin} kiroku subscriptions status --help
            ;;
          *)
            exec ${reiBin} kiroku subscriptions status "$@"
            ;;
        esac
      done

      json="$(${pkgs.curl}/bin/curl -fsS "$remoteUrl/subscriptions")"
      case "$format" in
        json)
          printf '%s\n' "$json"
          ;;
        table)
          printf 'SUBSCRIPTION\tPHASE\tGLOBAL_POSITION\tMEMBER\n'
          printf '%s\n' "$json" \
            | ${pkgs.jq}/bin/jq -r '.[] | [.subscription, .phase, (.global_position | tostring), (.member | tostring)] | @tsv'
          ;;
        *)
          printf 'rei: invalid --format %s (expected table or json)\n' "$format" >&2
          exit 1
          ;;
      esac
      exit 0
    fi

    exec ${reiBin} "$@"
  '';
  otelEnv = serviceName: {
    OTEL_SDK_DISABLED = "false";
    OTEL_TRACES_EXPORTER = "otlp";
    OTEL_SERVICE_NAME = serviceName;
    # hs-opentelemetry's HTTP exporter appends /v1/traces to
    # OTEL_EXPORTER_OTLP_ENDPOINT. Point the base endpoint at VictoriaTraces'
    # OpenTelemetry insert prefix so the final request goes to
    # /insert/opentelemetry/v1/traces.
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:10428/insert/opentelemetry";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
    REI_DEPLOYMENT_ENVIRONMENT = "local";
  };
  otelExports = serviceName:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: value: ''
        export ${name}="${value}"
      '')
      (otelEnv serviceName));

  # keiro migration cutover (EP-24): the comma-separated set of every routed
  # bounded context. Sourced from ./rei-cli-env.nix (shared with home/mina.nix).
  reiKirokuContexts = reiCli.reiKirokuContexts;

  waitForPg = ''
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done
  '';

  rei-subscription-wrapper = pkgs.writeShellScript "rei-subscription" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"
    ${otelExports "rei-subscription"}

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    ${waitForPg}

    exec ${reiBin} subscription run all
  '';

  rei-worker-wrapper = pkgs.writeShellScript "rei-worker" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"
    ${otelExports "rei-worker"}

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    ${waitForPg}

    exec ${reiBin} worker all
  '';

  rei-worker-git-sync-wrapper = pkgs.writeShellScript "rei-worker-git-sync" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"
    ${otelExports "rei-worker-git-sync"}

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    ${waitForPg}

    exec ${reiBin} worker git-sync
  '';

  # keiro migration: hosts the keiro reactive layer (inline+async projections, Routers,
  # process managers, durable timers, git side-effect legs) for every flipped context.
  # Replaces the message-db polling subscriber + the conflicting pgmq processors.
  rei-worker-kiroku-wrapper = pkgs.writeShellScript "rei-worker-kiroku" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"
    export REI_KIROKU_CONTEXTS="${reiKirokuContexts}"
    export REI_KIROKU_METRICS_PORT="${kirokuMetricsPort}"
    ${otelExports "rei-worker-kiroku"}

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    ${waitForPg}

    exec ${reiBin} worker kiroku
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
    rei-cli-wrapper
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
  #
  # IMPORTANT: Only bootout if the plist actually changed. setupLaunchAgents
  # skips unchanged plists, so booting out unconditionally leaves them unloaded.
  home.activation.rei-stop-agents = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
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
        # NOTE: home-manager runs activation blocks under `set -euo pipefail`.
        # A loaded-but-not-running agent (e.g. one crash-looping in "spawn
        # scheduled", with no `pid = ` line) makes a `grep 'pid ='` exit 1,
        # which pipefail propagates and set -e turns into an aborted switch —
        # leaving the profile bumped but launchd plists + current-system stale.
        # Use awk alone (exits 0 on no match) and guard with `|| true`.
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
      fi
    }

    stop_and_wait "com.shinzui.rei-worker"
    stop_and_wait "com.shinzui.rei-subscription"
    stop_and_wait "com.shinzui.rei-worker-git-sync"
    stop_and_wait "com.shinzui.rei-worker-kiroku"
  '';

  programs.zsh.sessionVariables = {
    REI_PG_CONNECTION_STRING = connStr;
    KIROKU_REMOTE_URL = kirokuRemoteUrl;
    # keiro migration cutover: route the interactive rei CLI to kiroku. Takes effect in
    # NEW login shells (run `exec zsh` after switching). See EP-24 (rei docs/plans/100).
    REI_KIROKU_CONTEXTS = reiKirokuContexts;
  } // otelEnv "rei";

  # keiro migration cutover (EP-24): the message-db polling subscriber is obsolete once
  # message-db is frozen — inline keiro projections keep read models current in-transaction.
  # Disabled (not deleted) so it can be re-enabled for a rollback. Re-home: rei worker kiroku.
  launchd.agents.rei-subscription = {
    enable = false;
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
      } // otelEnv "rei-subscription";
    };
  };

  # keiro migration cutover (EP-24): `rei worker all` runs pgmq processors now owned
  # or superseded by keiro durable timers/reactors. Running it post-flip would double-act
  # and append to the frozen message-db. Keep it disabled; host the surviving pgmq
  # workspace git side-effect via the dedicated git-sync agent below.
  launchd.agents.rei-worker = {
    enable = false;
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
      } // otelEnv "rei-worker";
    };
  };

  # Drains workspace_git_sync only. This intentionally runs beside `rei worker kiroku`:
  # the kiroku worker observes note events and enqueues pgmq payloads, while this worker
  # commits them asynchronously. Do not replace this with `rei worker all`.
  launchd.agents.rei-worker-git-sync = {
    enable = true;
    config = {
      Label = "com.shinzui.rei-worker-git-sync";
      ProgramArguments = [ "${rei-worker-git-sync-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${reiLogDir}/worker-git-sync.stdout.log";
      StandardErrorPath = "${reiLogDir}/worker-git-sync.stderr.log";
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = connStr;
        PG_CONNECTION_STRING = connStr;
      } // otelEnv "rei-worker-git-sync";
    };
  };

  # keiro migration cutover (EP-24): the keiro reactive-layer host. Runs every flipped
  # context's inline/async projections, Routers, process managers, durable timers (reminder
  # fire, dormancy daily-eval), and git side-effect legs. REI_KIROKU_CONTEXTS in the wrapper
  # env gates which legs activate.
  launchd.agents.rei-worker-kiroku = {
    enable = true;
    config = {
      Label = "com.shinzui.rei-worker-kiroku";
      ProgramArguments = [ "${rei-worker-kiroku-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 30;
      StandardOutPath = "${reiLogDir}/worker-kiroku.stdout.log";
      StandardErrorPath = "${reiLogDir}/worker-kiroku.stderr.log";
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = connStr;
        PG_CONNECTION_STRING = connStr;
        REI_KIROKU_CONTEXTS = reiKirokuContexts;
        REI_KIROKU_METRICS_PORT = kirokuMetricsPort;
      } // otelEnv "rei-worker-kiroku";
    };
  };
}
