# Single source of truth for where `mori serve` listens (home/mori.nix).
#
# Consumers of Mori's HTTP API read MORI_API_URL: the rei CLI (`rei project
# sync`, `list --with-mori`, `migrate-local-repos`) and mori-rei-app, which
# resolves each commit's repoId to its project. Both default to
# http://127.0.0.1:8080 when the variable is unset, but :8080 here belongs to
# Redpanda Console (home/redpanda.nix) -- which answers GET /health/ready with
# 200, so a client pointed at the default passes its readiness check and then
# fails on the first /v1 call. Hence a dedicated port, set explicitly.
#
# The server stays on loopback (Mori ADR 0012: a non-loopback bind requires
# MORI_API_TOKEN, and POST /v1/apps returns live webhook signing secrets).
# home/local-web-proxy.nix exposes it as mori.localhost to this machine only.
rec {
  host = "127.0.0.1";
  port = 8780;
  url = "http://${host}:${toString port}";
}
