{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.reiko/logs";

  reiko-zsh-completions = pkgs.runCommand "reiko-zsh-completions" { } ''
    ${pkgs.reiko}/bin/reiko completions zsh > $out
  '';

  reiko-web-wrapper = pkgs.writeShellScript "reiko-web" ''
    set -euo pipefail
    mkdir -p "${logDir}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${pkgs.reiko}/bin/reiko web --host 127.0.0.1 --port 8770 --no-open
  '';
in
{
  home.packages = [
    pkgs.reiko
  ];

  home.file.".zfunc/_reiko".source = reiko-zsh-completions;

  home.activation.reiko-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  launchd.agents.reiko-web = {
    enable = true;
    config = {
      Label = "com.shinzui.reiko-web";
      ProgramArguments = [ "${reiko-web-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
    };
  };
}
