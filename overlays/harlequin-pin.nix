# Pin harlequin to an older nixpkgs revision to avoid broken textual dependency
final: prev: {
  # Import the old nixpkgs revision from before the flake update
  harlequin = let
    oldNixpkgs = import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/2a2130494ad647f953593c4e84ea4df839fbd68c.tar.gz";
      sha256 = "sha256-Q82Ms+FQmgOBkdoSVm+FBpuFoeUAffNerR5yVV7SgT8=";
    }) {
      system = prev.stdenv.hostPlatform.system;
      config = { allowUnfree = true; };
    };
  in oldNixpkgs.harlequin;
}