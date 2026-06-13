{ config, lib, pkgs, ... }:

let
  brewBinPrefix = if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then "/opt/homebrew/bin" else "/usr/local/bin";

  # Homebrew 6.0.0 enabled HOMEBREW_REQUIRE_TAP_TRUST by default, so `brew bundle`
  # refuses to load formulae/casks from third-party (non-`homebrew/*`) taps unless
  # they are explicitly trusted in ~/.homebrew/trust.json. We write that file from
  # an activation script below — it must run *before* the homebrew bundle, which
  # rules out home-manager (it activates after the bundle). The trust list is
  # DERIVED from `homebrew.taps` so the two can never drift.
  #
  # Names are normalized to brew's trust form: official `homebrew/*` taps are
  # dropped (never need trust), and a tap repo `<user>/homebrew-<name>` is
  # referred to by brew as `<user>/<name>` (e.g. `lutzifer/homebrew-tap` ->
  # `lutzifer/tap`).
  trustNameOf = tap:
    let
      parts = lib.splitString "/" tap.name;
      user = builtins.head parts;
      repo = lib.removePrefix "homebrew-" (lib.last parts);
    in
    "${user}/${repo}";

  thirdPartyTaps =
    builtins.filter (t: !(lib.hasPrefix "homebrew/" t.name)) config.homebrew.taps;

  trustedTaps = lib.unique (map trustNameOf thirdPartyTaps);

  trustFileSrc = pkgs.writeText "homebrew-trust.json"
    (builtins.toJSON { trustedtaps = trustedTaps; });

  trustUser = config.system.primaryUser;
  trustHome = config.users.users.${trustUser}.home;
in

{
  programs.zsh.shellInit = ''
    eval "$(${brewBinPrefix}/brew shellenv)"
  '';

  #https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
  #TODO configure autocompletion

  # Install the derived tap-trust file before `brew bundle` runs. preActivation
  # runs as root at the very start of activation, well ahead of the homebrew
  # bundle, so the taps are trusted by the time bundle loads them.
  system.activationScripts.preActivation.text = lib.mkAfter ''
    echo "writing Homebrew tap trust for ${trustUser}..." >&2
    install -d -o ${trustUser} -g staff "${trustHome}/.homebrew"
    install -o ${trustUser} -g staff -m 0600 ${trustFileSrc} "${trustHome}/.homebrew/trust.json"
  '';

  homebrew.enable = true;
  #https://daiderd.com/nix-darwin/manual/index.html#opt-homebrew.onActivation.autoUpdate
  homebrew.onActivation.autoUpdate = true;
  homebrew.onActivation.upgrade = true;
  homebrew.onActivation.cleanup = "zap";
  # Homebrew now requires explicit confirmation before `brew bundle --cleanup`
  # removes unlisted packages. `--force-cleanup` performs it non-interactively.
  homebrew.onActivation.extraFlags = [ "--force-cleanup" ];
  homebrew.global.brewfile = true;
  # no_quarantine removed — Homebrew dropped the --[no-]quarantine switch

  homebrew.brews = [
    "pam-reattach"
    "tidy-html5"
    "xq"
    "duckdb"
    "keyboardSwitcher"
    "mole"
    "redpanda-data/tap/redpanda"
  ];

  homebrew.taps = [
    "homebrew/cask-drivers"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/services"
    "lutzifer/homebrew-tap"
    "txn2/tap"
    "steipete/tap"
    "redpanda-data/tap"
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
    "codex"
    "hammerspoon"
    "insomnia"
    "min"
    "tailscale-app"
    # "raycast"
    #TODO fixme by moving conflicting apps
    #"google-chrome"
  ];
}
