{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.mori-ui/logs";
  moriUi = import ./mori-ui-env.nix;
  moriApi = import ./mori-api-env.nix;

  # mori-ui reaches registries only over Mori's HTTP API (mori-ui ADR-5), so it
  # needs no database, socket or sibling CLI on PATH -- just the API's address.
  # One connection, id "local", is the global registry; the UI's URLs carry it
  # as /r/local/...
  connections = builtins.toJSON [
    {
      id = "local";
      name = "Global";
      kind = "local";
      baseUrl = moriApi.url;
    }
  ];

  mori-ui-wrapper = pkgs.writeShellScript "mori-ui" ''
    set -euo pipefail
    mkdir -p "${logDir}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    exec ${pkgs.mori-ui}/bin/mori-ui
  '';
in
{
  home.activation.mori-ui-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  # A web tool reading the runtime's API, like mina-web and reiko-web: it is in
  # workstation.reiMori.agents and validationAgents (home/rei-mori-runtime.nix),
  # so it runs only on the host that owns the runtime.
  launchd.agents.mori-ui = {
    enable = true;
    config = {
      Label = "com.shinzui.mori-ui";
      ProgramArguments = [ "${mori-ui-wrapper}" ];
      WorkingDirectory = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
      EnvironmentVariables = {
        HOST = moriUi.host;
        PORT = toString moriUi.port;
        NODE_ENV = "production";
        MORI_UI_CONNECTIONS = connections;
      };
    };
  };
}
