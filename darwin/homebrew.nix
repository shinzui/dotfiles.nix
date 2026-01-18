{ config, lib, pkgs, ... }:

let
  brewBinPrefix = if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then "/opt/homebrew/bin" else "/usr/local/bin";
in

{
  programs.zsh.shellInit = ''
    eval "$(${brewBinPrefix}/brew shellenv)"
  '';

  #https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
  #TODO configure autocompletion

  homebrew.enable = true;
  homebrew.brewPrefix = brewBinPrefix;
  #https://daiderd.com/nix-darwin/manual/index.html#opt-homebrew.onActivation.autoUpdate
  homebrew.onActivation.autoUpdate = true;
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.lockfiles = false;
  #https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.caskArgs.no_quarantine
  homebrew.caskArgs.no_quarantine = true;

  homebrew.brews = [
    "pam-reattach"
    "tidy-html5"
    "xq"
    "duckdb"
    "aider"
    "keyboardSwitcher"
    "steipete/tap/summarize"
    "steipete/tap/bird"
  ];

  homebrew.taps = [
    "homebrew/cask-drivers"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/services"
    "lutzifer/homebrew-tap"
    "txn2/tap"
    "steipete/tap"
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
    "steipete/tap/repobar"
    "tuple"
    "ghostty"
    "zoom"
    "visual-studio-code"
    "discord"
    "microsoft-teams"
    "anki"
    "insomnia"
    "min"
    # "raycast"
    #TODO fixme by moving conflicting apps
    #"google-chrome"
  ];
}
