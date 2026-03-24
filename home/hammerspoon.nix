{ config, lib, ... }:

let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";
  hsCliPath = "/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs";
in
{
  home.file.".hammerspoon".source = mkOutOfStoreSymlink "${nixConfigDir}/config/hammerspoon";

  home.activation.hammerspoon-reload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if /usr/bin/pgrep -x Hammerspoon > /dev/null 2>&1; then
      if [ -x "${hsCliPath}" ]; then
        verboseEcho "Reloading Hammerspoon configuration..."
        "${hsCliPath}" -c "hs.reload()" 2>/dev/null || true
      fi
    else
      verboseEcho "Hammerspoon is not running, skipping reload"
    fi
  '';
}
