{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.mina/logs";

  mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
    ${pkgs.mina}/bin/mina completions zsh > $out
  '';

  mina-web-wrapper = pkgs.writeShellScript "mina-web" ''
    set -euo pipefail
    mkdir -p "${logDir}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${pkgs.mina}/bin/mina web --global --host 127.0.0.1 --port 8765 --no-open
  '';
in
{
  home.packages = [
    pkgs.mina
  ];

  home.file.".zfunc/_mina".source = mina-zsh-completions;

  home.activation.mina-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  launchd.agents.mina-web = {
    enable = true;
    config = {
      Label = "com.shinzui.mina-web";
      ProgramArguments = [ "${mina-web-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
    };
  };
}
