{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.mina/logs";

  # mina web --global drives its UI by shelling out to sibling CLIs: `mori`
  # (project registry, read from PostgreSQL via MORI_PG_CONNECTION_STRING) and
  # `rei` (intention details, read via REI_PG_CONNECTION_STRING + keiro routing).
  # launchd inherits neither the interactive shell's session variables nor the
  # Nix profile PATH, so without these the spawned tools fail — `mori` with
  # "MORI_PG_CONNECTION_STRING environment variable not set" (every /api/mori/*
  # returns 503, empty project picker) and `rei` with
  # "createProcess: posix_spawnp: does not exist" (ReiBinaryUnavailable).
  moriConnStr = "host=${config.services.postgresql.socketDir} dbname=mori";

  # Shared rei CLI environment (connection string + keiro routing), kept in sync
  # with home/rei.nix via the common import.
  reiCli = import ./rei-cli-env.nix {
    inherit pkgs lib;
    pgSocket = config.services.postgresql.socketDir;
  };

  # OpenTelemetry export to the local VictoriaTraces collector (mina ExecPlan
  # 158). mina reads these standard OTEL_* variables and auto-enables tracing
  # when they are present (no flag). hs-opentelemetry's HTTP exporter appends
  # /v1/traces to the endpoint, so the final request goes to
  # /insert/opentelemetry/v1/traces.
  #
  # The service name is carried in MINA_OTEL_SERVICE_NAME (not OTEL_SERVICE_NAME):
  # home/rei.nix already sets OTEL_SERVICE_NAME=rei in the shared interactive
  # shell, and two modules defining the same OTEL_SERVICE_NAME conflict. mina
  # pins OTEL_SERVICE_NAME from MINA_OTEL_SERVICE_NAME inside its own process, so
  # mina traces land under "mina" / "mina-web" regardless of the shell value.
  # The four shared keys below match rei's values, so co-defining them in the
  # interactive shell is a harmless no-op merge.
  otelEnv = serviceName: {
    OTEL_SDK_DISABLED = "false";
    OTEL_TRACES_EXPORTER = "otlp";
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:10428/insert/opentelemetry";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
    MINA_OTEL_SERVICE_NAME = serviceName;
  };

  mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
    ${pkgs.mina}/bin/mina completions zsh > $out
  '';

  mina-web-wrapper = pkgs.writeShellScript "mina-web" ''
    set -euo pipefail
    mkdir -p "${logDir}"

    export MORI_PG_CONNECTION_STRING="${moriConnStr}"
    export REI_PG_CONNECTION_STRING="${reiCli.connStr}"
    export KIROKU_REMOTE_URL="${reiCli.kirokuRemoteUrl}"
    export REI_KIROKU_CONTEXTS="${reiCli.reiKirokuContexts}"
    export PATH="${pkgs.mori}/bin:${reiCli.binDir}:$PATH"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${pkgs.mina}/bin/mina web --global --host 127.0.0.1 --port 8765 --no-open
  '';
in
{
  home.packages = [
    pkgs.mina
  ];

  # Interactive shells get the OTEL_* vars so a hand-run `mina master-plan show`
  # / `mina exec-plan digest` is traced to VictoriaTraces. Takes effect in NEW
  # shells (run `exec zsh` after switching).
  programs.zsh.sessionVariables = otelEnv "mina";

  home.file.".zfunc/_mina".source = mina-zsh-completions;

  home.activation.mina-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  launchd.agents.mina-web = {
    enable = true;
    config = {
      Label = "com.shinzui.mina-web";
      ProgramArguments = [ "${mina-web-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
      # The background web server exports under its own service name so its
      # digest traces are distinguishable from hand-run CLI traces.
      EnvironmentVariables = {
        MORI_PG_CONNECTION_STRING = moriConnStr;
      } // reiCli.cliEnv // otelEnv "mina-web";
    };
  };
}
