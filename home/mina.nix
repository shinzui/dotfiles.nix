{ pkgs, ... }:

let
  mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
    ${pkgs.mina}/bin/mina completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.mina
  ];

  home.file.".zfunc/_mina".source = mina-zsh-completions;
}
