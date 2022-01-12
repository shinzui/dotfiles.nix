{ config, lib, pkgs, ... }:

let
  brewBinPrefix = if pkgs.system == "aarch64-darwin" then "/opt/homebrew/bin" else "/usr/local/bin";
in

{
  programs.zsh.shellInit = ''
    eval "$(${brewBinPrefix}/brew shellenv)"
  '';

  #https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
  #TODO configure autocompletion

  homebrew.enable = true;
  homebrew.brewPrefix = brewBinPrefix;
  homebrew.autoUpdate = false;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  homebrew.brews = [
    #TODO figure out how to use nix's gnu-sed
    "gnu-sed" # neovim spectre needs gsed in the neovim path
    "pam-reattach"
    #TODO remove after it's fixed in nix
    "ormolu"
  ];

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-drivers"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
  ];

  # Prefer installing application from the Mac App Store
  #
  # Commented apps suffer continual update issue:
  # https://github.com/malob/nixpkgs/issues/9
  #
  # `mas` not working on macOS 12
  # https://github.com/mas-cli/mas/issues/417
  # homebrew.masApps = {
  #   # "1Blocker" = 1365531024;
  #   "1Password" = 1333542190;
  #   Slack = 803453959;
  #   Xcode = 497799835;
  # };

  # If an app isn't available in the Mac App Store install the Homebrew Cask.
  homebrew.casks = [
    "tuple"
    "zoom"
    #TODO fixme by moving conflicting apps
    #"discord"
    #"google-chrome"
  ];
}
