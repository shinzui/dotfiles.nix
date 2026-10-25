{ config, lib, pkgs, ... }:
let
  # One-time client access until the runtime moves from Sungkyung to Yujin.
  # The private socket directory keeps PostgreSQL's trust authentication off TCP.
  clientDir = "${config.home.homeDirectory}/.local/state/sungkyung-clients";
  pgSocket = "${clientDir}/postgresql";
  clientEnv = {
    MORI_PG_CONNECTION_STRING = "host=${pgSocket} dbname=mori user=shinzui connect_timeout=5";
    REI_PG_CONNECTION_STRING = "host=${pgSocket} dbname=rei user=shinzui connect_timeout=5";
    MORI_API_URL = "http://127.0.0.1:18780";
    KIROKU_REMOTE_URL = "http://127.0.0.1:19091";
  };
  tunnel = pkgs.writeShellScript "sungkyung-client-tunnel" ''
    set -euo pipefail
    umask 077
    mkdir -p "${pgSocket}"
    exec /usr/bin/ssh -NT \
      -o BatchMode=yes \
      -o ExitOnForwardFailure=yes \
      -o ServerAliveInterval=15 \
      -o ServerAliveCountMax=3 \
      -o StreamLocalBindUnlink=yes \
      -o StrictHostKeyChecking=yes \
      -o IdentitiesOnly=yes \
      -i "${config.home.homeDirectory}/.ssh/id_ed25519_sungkyung_client" \
      -L "${pgSocket}/.s.PGSQL.5432:/Users/shinzui/.local/state/postgresql/.s.PGSQL.5432" \
      -L 127.0.0.1:18780:127.0.0.1:8780 \
      -L 127.0.0.1:19091:127.0.0.1:9091 \
      shinzui@100.66.155.64
  '';
  remoteRei = pkgs.writeShellScriptBin "rei" ''
    set -euo pipefail
    # Encode argv as data: SSH otherwise joins arguments into a shell command.
    payload="$(${pkgs.python3}/bin/python3 -c \
      'import base64,json,sys; print(base64.b64encode(json.dumps(sys.argv[1:]).encode()).decode())' \
      "$@")"
    tty_args=()
    if [ -t 0 ] && [ -t 1 ]; then tty_args=(-t); fi
    exec /usr/bin/ssh "''${tty_args[@]}" \
      -o BatchMode=yes -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes \
      -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
      -i "${config.home.homeDirectory}/.ssh/id_ed25519_sungkyung_rei" \
      shinzui@100.66.155.64 "rei-argv:$payload"
  '';
  clientIngest = pkgs.writeShellScript "sungkyung-client-ingest" ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") clientEnv)}
    export PATH="${pkgs.git}/bin:/usr/bin:/bin"
    exec ${pkgs.python3}/bin/python3 ${../../bin/mori-client-ingest.py} \
      --mori ${pkgs.mori}/bin/mori
  '';
in
{
  # Prepare this machine without starting the live runtime or its integrations.
  workstation.reiMori.enable = false;

  # Rei's workspace and Git jobs remain together on Sungkyung. This also uses
  # the authoritative host's CLI version for every command.
  home.packages = [ (lib.meta.hiPrio remoteRei) ];

  programs.zsh.sessionVariables = lib.mapAttrs (_: lib.mkForce) clientEnv;

  # Long-lived terminals and coding agents can retain old local endpoints plus
  # Home Manager's exported "already sourced" flags across a rebuild. Refresh
  # the client endpoints on every shell startup, outside that one-time guard.
  programs.zsh.envExtra = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") clientEnv
  );

  # Application workers stay on Sungkyung; the client only collects its Git
  # history through the tunnel. Database access alone cannot discover commits.
  launchd.agents.sungkyung-client-tunnel = {
    enable = true;
    config = {
      Label = "com.shinzui.sungkyung-client-tunnel";
      ProgramArguments = [ "${tunnel}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 15;
      StandardOutPath = "${clientDir}/tunnel.stdout.log";
      StandardErrorPath = "${clientDir}/tunnel.stderr.log";
    };
  };

  launchd.agents.sungkyung-client-ingest = {
    enable = true;
    config = {
      Label = "com.shinzui.sungkyung-client-ingest";
      ProgramArguments = [ "${clientIngest}" ];
      RunAtLoad = true;
      StartInterval = 600;
      StandardOutPath = "${clientDir}/ingest.stdout.log";
      StandardErrorPath = "${clientDir}/ingest.stderr.log";
    };
  };

  home.activation.sungkyung-client-dir = lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
    run install -d -m 700 "${clientDir}" "${pgSocket}"
  '';

  programs.ssh.settings."github.com" = lib.hm.dag.entryBefore [ "*" ] {
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519";
    IdentitiesOnly = true;
    AddKeysToAgent = "yes";
    IgnoreUnknown = "UseKeychain";
    UseKeychain = true;
  };
}
