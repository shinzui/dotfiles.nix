# Single source of truth for where rei-api listens (home/rei.nix).
#
# Beside mina (8765), reiko (8770), and mori (8780). Not rei-api's built-in
# default of :8080, which here belongs to Redpanda Console (home/redpanda.nix).
#
# rei-api's reads are unauthenticated (only writes need a bearer token from
# REI_API_TOKENS), so home/local-web-proxy.nix exposes it as rei.localhost to
# this machine only, as it does Mori's API.
rec {
  host = "127.0.0.1";
  port = 8775;
  url = "http://${host}:${toString port}";
}
