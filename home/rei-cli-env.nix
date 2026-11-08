# Shared global CLI/API setup. Everyday commands need the API URL and a bearer;
# operator commands retain PostgreSQL configuration. Tokens are read from the
# private agenix mapping only when a process starts. mori://shinzui/mina selects its existing
# agent credential; the workstation and mori://shinzui/reiko use the owner credential.
{ pkgs, lib, pgSocket, topicProfilesEnabled ? false, apiTokenMapPath, apiActor ? "human", projectOutcomeWritesEnabled ? false }:

let
  api = import ./rei-api-env.nix;
  apiExports = ''
    export REI_API_URL="''${REI_API_URL:-${api.url}}"
    if [ -z "''${REI_API_TOKEN:-}" ] && [ "$REI_API_URL" = "${api.url}" ] && [ -r "${apiTokenMapPath}" ]; then
      REI_API_TOKEN="$(${pkgs.python3}/bin/python3 ${../bin/rei-api-credential.py} token "${apiTokenMapPath}" "${apiActor}")"
      export REI_API_TOKEN
    fi
  '';
  client = pkgs.writeShellScriptBin "rei" ''
    set -euo pipefail
    ${apiExports}
    exec ${pkgs.rei}/bin/rei "$@"
  '';
  connStr = "host=${pgSocket} dbname=rei";
  kirokuMetricsPort = "9091";
  kirokuRemoteUrl = "http://localhost:${kirokuMetricsPort}";
  # Enable only with the coordinated reader/catalog rollout recorded by
  # mori://shinzui/rei/masterplans/30-support-user-defined-topic-profiles.
  topicProfileEnv = {
    REI_PROJECT_OUTCOME_WRITES_ENABLED = lib.boolToString projectOutcomeWritesEnabled;
    REI_CLASSIFICATION_WRITES_ENABLED = lib.boolToString topicProfilesEnabled;
    REI_TOPIC_PROFILE_WRITES_ENABLED = lib.boolToString topicProfilesEnabled;
    REI_TOPIC_REVIEW_WRITES_ENABLED = lib.boolToString topicProfilesEnabled;
  };

in
{
  inherit apiExports client connStr kirokuMetricsPort kirokuRemoteUrl topicProfileEnv;

  binDir = "${client}/bin";

  # Minimal environment a non-interactive spawner (e.g. mina web --global)
  # must set so the `rei` it execs reads current data. Intentionally excludes
  # the OTEL_* tracing vars: a web server may invoke rei frequently, and trace
  # export is not needed for correctness.
  cliEnv = {
    REI_API_URL = api.url;
    REI_PG_CONNECTION_STRING = connStr;
    KIROKU_REMOTE_URL = kirokuRemoteUrl;
  } // topicProfileEnv;
}
