# Per-system outputs: the dev shell and the individually-buildable packages.
#
# Note this deliberately builds its own package set rather than using
# flake-parts' default `pkgs`, and applies only the four overlays the packages
# below actually need — not the full `self.overlays` set used by the darwin
# configs.
{ self, inputs, lib, ... }:
{
  perSystem = { system, ... }:
    let
      nixpkgsConfig = import ../lib/nixpkgs-config.nix { inherit self lib; };
      pkgs = import inputs.nixpkgs-unstable {
        inherit system;
        inherit (nixpkgsConfig) config;
        overlays = with self.overlays; [
          pkgs-stable
          bun2nix
          my-packages
        ];
      };
    in
    {
      devShells.default = import ../shell.nix {
        inherit pkgs system;
        agenix = inputs.agenix;
      };

      packages = {
        inherit (pkgs)
          tmuxai
          oq
          uuinfo
          ck
          container
          parqeye
          beautiful-mermaid
          markit
          defuddle
          hunk
          jaeger-ui
          pg_rman
          bootstrap-repos
          mina
          shiki
          okf
          ;
      };
    };
}
