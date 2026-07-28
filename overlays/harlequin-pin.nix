# harlequin still doesn't build against current unstable — its sqlfmt
# dependency fails there — so take it from nixos-25.11 via the `pkgs-stable`
# escape hatch, the same mechanism parqeye uses.
#
# This replaces an ad-hoc `builtins.fetchTarball` pin to a hardcoded nixpkgs
# revision, which sat outside flake.lock (so `nix flake update` never moved
# it), fetched and instantiated a whole extra nixpkgs, and had drifted to
# harlequin 2.1.2. nixos-25.11 has 2.4.1 and comes from the binary cache.
final: prev: {
  harlequin = final.pkgs-stable.harlequin;
}
