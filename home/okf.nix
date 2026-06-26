{ pkgs, ... }:

let
  okf-zsh-completions = pkgs.runCommand "okf-zsh-completions" { } ''
    ${pkgs.okf}/bin/okf completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.okf
  ];

  home.file.".zfunc/_okf".source = okf-zsh-completions;
}
