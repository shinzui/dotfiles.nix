{ pkgs, age, ... }:
{
  home.packages = [ pkgs.cachix ];

  xdg.configFile."cachix/cachix.dhall".text = ''
    { authToken = ${age.secrets.cachix-authtoken.path}
    , hostname = "https://cachix.org"
    , binaryCaches = [] : List { name : Text, secretKey : Text }
    }
  '';
}
