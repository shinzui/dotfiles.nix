# Single source of truth for the rei CLI's runtime environment.
#
# Anything that shells out to `rei` outside an interactive login shell — the
# rei launchd agents in home/rei.nix, and the mina web server's global mode in
# home/mina.nix, which spawns `rei` to resolve intention details — needs the
# same PostgreSQL connection string and keiro routing variables that
# home/rei.nix exports for interactive shells via programs.zsh.sessionVariables.
#
# Without REI_PG_CONNECTION_STRING the spawned rei cannot connect; without
# REI_KIROKU_CONTEXTS it reads the frozen message-db instead of the kiroku
# event store (EP-24 cutover) and returns stale/missing data. Keeping these in
# one importable file prevents the contexts list from drifting between modules.
{ pkgs, lib, pgSocket }:

let
  connStr = "host=${pgSocket} dbname=rei";
  kirokuMetricsPort = "9091";
  kirokuRemoteUrl = "http://localhost:${kirokuMetricsPort}";

  # keiro migration cutover (EP-24, docs/plans/100 in the rei repo): the
  # comma-separated set of every routed bounded context. When set, the rei CLI
  # routes reads/writes to the kiroku event store and message-db is frozen.
  # Unset/"" = message-db.
  reiKirokuContexts = builtins.concatStringsSep "," [
    "agent_memory" "agent_schedule" "agent_session" "blocker" "category" "collection"
    "custom_property" "custom_property_assignment" "cycle" "delegation" "disruption"
    "disruption_action" "edge" "focus" "guidance" "habit" "habit_blocker" "int_view"
    "intention" "journal_entry" "knowledge" "link" "note" "playbook_execution"
    "predicate" "reflection" "reminder" "review" "task"
  ];
in
{
  inherit connStr kirokuMetricsPort kirokuRemoteUrl reiKirokuContexts;

  binDir = "${pkgs.rei}/bin";

  # Minimal environment a non-interactive spawner (e.g. mina web --global)
  # must set so the `rei` it execs reads current data. Intentionally excludes
  # the OTEL_* tracing vars: a web server may invoke rei frequently, and trace
  # export is not needed for correctness.
  cliEnv = {
    REI_PG_CONNECTION_STRING = connStr;
    KIROKU_REMOTE_URL = kirokuRemoteUrl;
    REI_KIROKU_CONTEXTS = reiKirokuContexts;
  };
}
