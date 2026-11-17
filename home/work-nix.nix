{ pkgs, ... }:

# work-nix — run a command that can fetch Nix sources from the work tailnet.
#
# Work flakes fetch TAN package tarballs from the work tailnet (http://*.ts.net).
# The system Tailscale client stays on the personal tailnet, and the work
# tailnet is reached through TailMux's local proxy.
#
# work-nix sets lowercase http_proxy for the wrapped command only. curl uses
# that variable just for plain-http URLs, so GitHub and binary caches (https)
# stay direct. Never export http_proxy shell-wide: TailMux rejects every
# non-work host with a 502.
#
# Private topagentnetwork GitHub repos need no help here: the managed access
# token secret carries a github.com/topagentnetwork= entry (docs/access-tokens.md).
#
# Fetched sources are pinned and cached, so this is only needed after a TAN
# package version changes:
#   work-nix                 # refresh the current directory's direnv dev shell
#   work-nix nix flake update
let
  work-nix = pkgs.writeShellApplication {
    name = "work-nix";
    text = ''
      proxy="''${WORK_NIX_PROXY:-http://127.0.0.1:43100}"

      if ! curl --silent --max-time 2 --output /dev/null "''${proxy}" 2>/dev/null; then
        echo "work-nix: TailMux proxy at ''${proxy} is not answering; start TailMux first." >&2
        exit 1
      fi

      export http_proxy="''${proxy}"

      if [ "$#" -eq 0 ]; then
        set -- direnv exec . true
      fi
      exec "$@"
    '';
  };
in
{
  home.packages = [ work-nix ];
}
