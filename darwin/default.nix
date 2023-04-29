{ pkgs, ... }:

{
  imports = [
    # Minimal config of Nix related options and shells
    ./bootstrap.nix

    # Other nix-darwin configuration
    ./homebrew.nix
    ./secrets.nix
    ./mac-defaults.nix
  ];

  networking.dns = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Apps
  # `home-manager` currently has issues adding them to `~/Applications`
  # Issue: https://github.com/nix-community/home-manager/issues/1341
  environment.systemPackages = with pkgs; [
    terminal-notifier
    #kitty
  ];

  programs.nix-index.enable = true;

  # Fonts
  #fonts.enableFontDir = true;
  #fonts.fonts = with pkgs; [
  #   recursive
  #  (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  # ];

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuthCustom = true;
}
