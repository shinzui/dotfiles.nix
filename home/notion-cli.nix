{ pkgs, ... }:

let
  notion-cli-zsh-completions = pkgs.runCommand "notion-cli-zsh-completions" { } ''
    ${pkgs.notion-cli}/bin/notion-cli completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.notion-cli
  ];

  home.file.".zfunc/_notion-cli".source = notion-cli-zsh-completions;
}
