{ pkgs, ... }:

let
  ntn-zsh-completions = pkgs.runCommand "ntn-zsh-completions" { } ''
    ${pkgs.notion-cli}/bin/ntn completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.notion-cli
  ];

  home.file.".zfunc/_ntn".source = ntn-zsh-completions;
}
