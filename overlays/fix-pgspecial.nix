final: prev: {
  # Pin pgcli to last working nixpkgs-unstable revision
  pgcli = let
    workingNixpkgs = import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/32f313e49e42f715491e1ea7b306a87c16fe0388.tar.gz";
      sha256 = "1z4ga87qla5300qwib3dnjnkaywwh8y1qqsb8w2mrsrw78k9xmlw";
    }) {
      system = prev.stdenv.system;
      config = { allowUnfree = true; };
    };
  in workingNixpkgs.pgcli;
}