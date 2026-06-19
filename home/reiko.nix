{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.reiko/logs";
  pgSocket = config.services.postgresql.socketDir;
  reiCli = import ./rei-cli-env.nix { inherit pkgs lib pgSocket; };
  connStr = reiCli.connStr;

  reiko-zsh-completions = pkgs.runCommand "reiko-zsh-completions" { } ''
    ${pkgs.reiko}/bin/reiko completions zsh > $out
  '';

  reiko-web-wrapper = pkgs.writeShellScript "reiko-web" ''
    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export KIROKU_REMOTE_URL="${reiCli.kirokuRemoteUrl}"
    export REI_KIROKU_CONTEXTS="${reiCli.reiKirokuContexts}"

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
      WorkingDirectory = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      EnvironmentVariables = {
        REI_PG_CONNECTION_STRING = connStr;
        KIROKU_REMOTE_URL = reiCli.kirokuRemoteUrl;
        REI_KIROKU_CONTEXTS = reiCli.reiKirokuContexts;
      };
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
    };
  };
}
