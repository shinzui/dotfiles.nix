{ pkgs, ... }:

let
  reiko-zsh-completions = pkgs.runCommand "reiko-zsh-completions" { } ''
    ${pkgs.reiko}/bin/reiko completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.reiko
  ];

  home.file.".zfunc/_reiko".source = reiko-zsh-completions;
}
