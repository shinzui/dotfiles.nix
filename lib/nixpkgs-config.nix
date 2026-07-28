# Shared `nixpkgs` configuration used by the nix-darwin and home-manager
# configs. Kept as a plain function (rather than a flake-parts module) so both
# the flake-level and per-system modules can import it without threading it
# through module arguments.
{ self, lib }:
{
  config = { allowUnfree = true; };
  overlays = lib.attrValues self.overlays;
}
