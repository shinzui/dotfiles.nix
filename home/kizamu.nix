{ pkgs, ... }:

let
  kizamuBin = "${pkgs.kizamu}/bin/kizamu";

  kizamu-zsh-completions = pkgs.runCommand "kizamu-zsh-completions" { } ''
    ${kizamuBin} completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.kizamu
  ];

  home.file.".zfunc/_kizamu".source = kizamu-zsh-completions;
}
