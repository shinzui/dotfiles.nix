{ config, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";
in
{
  home.file.".claude/CLAUDE.md".source =
    mkOutOfStoreSymlink "${nixConfigDir}/config/agents/AGENTS.md";

  home.file.".codex/instructions.md".source =
    mkOutOfStoreSymlink "${nixConfigDir}/config/agents/AGENTS.md";

  home.file.".codex/AGENTS.md".source =
    mkOutOfStoreSymlink "${nixConfigDir}/config/agents/AGENTS.md";
}
