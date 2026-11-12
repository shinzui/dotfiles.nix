# Single source of truth for where mori-ui listens (home/mori-ui.nix).
#
# mori-ui (mori://shinzui/mori-ui) reads the global registry through Mori's
# HTTP API (home/mori-api-env.nix), which has no authentication on loopback
# (Mori ADR 0012), and has none of its own. So it binds loopback only, and
# home/local-web-proxy.nix exposes it as mori-ui.localhost to this machine only.
rec {
  host = "127.0.0.1";
  port = 8785;
  url = "http://${host}:${toString port}";
}
