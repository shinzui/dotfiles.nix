{ lib, ... }:

let
  inherit (lib) mkOption types;
in

{
  options = {
    users.primaryUser = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };
}
