# Single source of truth for the rei CLI's runtime environment.
#
# Anything that shells out to `rei` outside an interactive login shell — the
# rei launchd agents in home/rei.nix, and the mina web server's global mode in
# home/mina.nix, which spawns `rei` to resolve intention details — needs the
# same PostgreSQL connection string that home/rei.nix exports for interactive
# shells via programs.zsh.sessionVariables.
#
# Without REI_PG_CONNECTION_STRING the spawned rei cannot connect. Keeping it in
# one importable file prevents the connection string from drifting between
# modules.
#
# REI_KIROKU_CONTEXTS was the EP-24 cutover gate. rei-core completed that
# migration and removed Rei.Infrastructure.StoreRouter.CutoverConfig; every leg
# now runs unconditionally against kiroku, and no consumer reads the variable
# any more, so it was removed here on 2026-09-09.
{ pkgs, lib, pgSocket }:

let
  connStr = "host=${pgSocket} dbname=rei";
  kirokuMetricsPort = "9091";
  kirokuRemoteUrl = "http://localhost:${kirokuMetricsPort}";

in
{
  inherit connStr kirokuMetricsPort kirokuRemoteUrl;

  binDir = "${pkgs.rei}/bin";

  # Minimal environment a non-interactive spawner (e.g. mina web --global)
  # must set so the `rei` it execs reads current data. Intentionally excludes
  # the OTEL_* tracing vars: a web server may invoke rei frequently, and trace
  # export is not needed for correctness.
  cliEnv = {
    REI_PG_CONNECTION_STRING = connStr;
    KIROKU_REMOTE_URL = kirokuRemoteUrl;
  };
}
