{ pkgs, agenix, system }:
let
  homebrewInstall = pkgs.writeShellScriptBin "homebrewInstall" ''
    ${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  '';
in
pkgs.mkShell {
  buildInputs = [ homebrewInstall ];
  nativeBuildInputs = [ agenix.packages.${system}.agenix ];
}
