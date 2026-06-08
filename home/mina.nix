{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.mina/logs";

  # mina web --global drives its UI by shelling out to sibling CLIs: `mori`
  # (project registry, read from PostgreSQL via MORI_PG_CONNECTION_STRING) and
  # `rei` (intention details, read via REI_PG_CONNECTION_STRING + keiro routing).
  # launchd inherits neither the interactive shell's session variables nor the
  # Nix profile PATH, so without these the spawned tools fail — `mori` with
  # "MORI_PG_CONNECTION_STRING environment variable not set" (every /api/mori/*
  # returns 503, empty project picker) and `rei` with
  # "createProcess: posix_spawnp: does not exist" (ReiBinaryUnavailable).
  moriConnStr = "host=${config.services.postgresql.socketDir} dbname=mori";

  # Shared rei CLI environment (connection string + keiro routing), kept in sync
  # with home/rei.nix via the common import.
  reiCli = import ./rei-cli-env.nix {
    inherit pkgs lib;
    pgSocket = config.services.postgresql.socketDir;
  };

  mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
    ${pkgs.mina}/bin/mina completions zsh > $out
  '';

  mina-web-wrapper = pkgs.writeShellScript "mina-web" ''
    set -euo pipefail
    mkdir -p "${logDir}"

    export MORI_PG_CONNECTION_STRING="${moriConnStr}"
    export REI_PG_CONNECTION_STRING="${reiCli.connStr}"
    export KIROKU_REMOTE_URL="${reiCli.kirokuRemoteUrl}"
    export REI_KIROKU_CONTEXTS="${reiCli.reiKirokuContexts}"
    export PATH="${pkgs.mori}/bin:${reiCli.binDir}:$PATH"

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
      EnvironmentVariables = {
        MORI_PG_CONNECTION_STRING = moriConnStr;
      } // reiCli.cliEnv;
    };
  };
}
