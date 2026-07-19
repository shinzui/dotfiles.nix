{ pkgs, ... }:

let
  kazuha-zsh-completions = pkgs.runCommand "kazuha-zsh-completions" { } ''
    ${pkgs.kazuha}/bin/kazuha completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.kazuha
  ];

  home.file.".zfunc/_kazuha".source = kazuha-zsh-completions;
}
