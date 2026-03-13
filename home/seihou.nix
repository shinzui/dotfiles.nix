{ pkgs, ... }:

let
  seihou-zsh-completions = pkgs.runCommand "seihou-zsh-completions" { } ''
    ${pkgs.seihou}/bin/seihou completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.seihou
  ];

  home.file.".zfunc/_seihou".source = seihou-zsh-completions;
}
