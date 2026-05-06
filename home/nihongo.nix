{ pkgs, ... }:

let
  nihongo-zsh-completions = pkgs.runCommand "nihongo-zsh-completions" { } ''
    ${pkgs.nihongo}/bin/nihongo completions zsh > $out
  '';
in
{
  home.packages = [
    pkgs.nihongo
    # rsvg-convert: nihongo's `kanji show` shells out to it to rasterize
    # KanjiVG SVGs into the kitty-graphics PNG output. Soft dep — without
    # it, the renderer falls back gracefully but no image is shown.
    pkgs.librsvg
  ];

  home.file.".zfunc/_nihongo".source = nihongo-zsh-completions;
}
