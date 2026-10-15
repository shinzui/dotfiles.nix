{ config, lib, pkgs, ... }:

let
  apps = {
    "Adobe Lightroom" = {
      id = 1451544217;
      path = "/Applications/Adobe Lightroom.app";
      bundleId = "com.adobe.mas.lightroomCC";
    };
    Slack = {
      id = 803453959;
      path = "/Applications/Slack.app";
      bundleId = "com.tinyspeck.slackmacgap";
    };
  };
  arguments = lib.concatLists (lib.mapAttrsToList
    (name: app: [ name (toString app.id) app.path app.bundleId ]) apps);
in
{
  programs.mas = {
    enable = true;
    cleanup = false;
    update = false;
    packages = lib.mapAttrs (_: app: app.id) apps;
  };

  assertions = [{
    assertion = config.homebrew.masApps == { };
    message = "Declare App Store apps in darwin/app-store.nix; Homebrew Bundle cleanup can remove unlisted App Store apps.";
  }];

  # The default installer uses Spotlight's app list, which can be empty even
  # with installed apps. Check bundles and receipts directly instead, and leave
  # updates to the App Store so rebuilds only install missing applications.
  system.activationScripts.mas.text = lib.mkForce ''
    /bin/bash ${../bin/install-app-store-apps.sh} \
      ${lib.escapeShellArg (lib.getExe config.programs.mas.package)} \
      ${lib.escapeShellArg config.programs.mas.user} \
      ${lib.escapeShellArgs arguments}
  '';
}
