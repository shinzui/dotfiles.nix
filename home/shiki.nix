{ pkgs, ... }:

let
  shiki-zsh-completions = pkgs.runCommand "shiki-zsh-completions" { } ''
    ${pkgs.shiki}/bin/shiki completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.shiki
  ];

  home.file.".zfunc/_shiki".source = shiki-zsh-completions;
}
