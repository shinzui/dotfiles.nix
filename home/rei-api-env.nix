# Single source of truth for where rei-api listens (home/rei.nix).
#
# Beside mina (8765), reiko (8770), and mori (8780). Not rei-api's built-in
# default of :8080, which here belongs to Redpanda Console (home/redpanda.nix).
#
# Everyday CLI callers use the local API URL and a bearer loaded privately at
# process startup. home/local-web-proxy.nix also exposes rei.localhost locally.
rec {
  host = "127.0.0.1";
  port = 8775;
  url = "http://${host}:${toString port}";
}
