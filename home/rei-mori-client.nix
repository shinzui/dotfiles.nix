{ config, lib, pkgs, ... }:

# Client access from a non-owner workstation to the Rei/Mori runtime owner.
#
# The client opens one SSH connection to the owner (its database tunnel) and
# reaches the owner's services through private local forwards:
#
#   PostgreSQL  <stateDirectory>/postgresql/.s.PGSQL.5432 -> owner's socket
#   Mori API    127.0.0.1:18780 -> 8780
#   Rei API     127.0.0.1:18775 -> 8775
#   metrics     127.0.0.1:19091 -> 9091
#   web         127.0.0.1:80 and [::1]:80 -> 80   (forwardWebPort)
#
# PostgreSQL uses trust authentication on its socket, so the forwarded socket
# carries the owner's full database authority. It stays inside a mode-0700
# directory and never on TCP. SSH permitopen restrictions do not constrain
# Unix socket forwards, so the tunnel key is trusted same-user access.
#
# supportForwards adds a second, independent SSH agent for the support
# services (telemetry and Redpanda) on their own port numbers. Both tunnels use
# ExitOnForwardFailure, so keeping them apart means a busy local port such as
# 9092 cannot take down the database forwards.
#
# The client also gets a high-priority `rei` that runs the owner's managed Rei
# through a forced SSH command, and (gitIngest) a ten-minute agent that records
# this machine's local commits into the owner's Mori store through the tunnel.
let
  cfg = config.workstation.reiMoriClient;
  home = config.home.homeDirectory;
  target = cfg.target;
  sshDestination = "${target.user}@${target.address}";
  pgSocket = "${cfg.stateDirectory}/postgresql";
  pgConn = db: "host=${pgSocket} dbname=${db} user=shinzui connect_timeout=5";

  clientEnv = {
    MORI_PG_CONNECTION_STRING = pgConn "mori";
    REI_PG_CONNECTION_STRING = pgConn "rei";
    NOTION_HUB_PG_CONNECTION_STRING = pgConn "notion_hub";
    MORI_REI_APP_PG_CONNECTION_STRING = pgConn "mori_rei_app";
    MORI_API_URL = "http://127.0.0.1:18780";
    KIROKU_REMOTE_URL = "http://127.0.0.1:19091";
  };

  supportPorts = [ 9428 10428 16686 8080 8081 8082 9092 9644 ];

  # Common hardening for both tunnels. Host keys must already be verified in
  # known_hosts; nothing is forwarded back to the owner.
  # Arguments are kept in groups (an option with its value) so the generated
  # scripts read one option per line.
  option = value: [ "-o" value ];
  knownHostsArgs = lib.optionals (target.knownHostsFile != null) [
    (option "UserKnownHostsFile=${target.knownHostsFile}")
  ];
  sshHardening = map option [
    "BatchMode=yes"
    "ExitOnForwardFailure=yes"
    "ServerAliveInterval=15"
    "ServerAliveCountMax=3"
    "StrictHostKeyChecking=yes"
    "IdentitiesOnly=yes"
    "ForwardAgent=no"
    "ForwardX11=no"
  ] ++ knownHostsArgs ++ [ [ "-i" cfg.tunnelIdentityFile ] ];

  forward = listen: destination: [ [ "-L" "${listen}:${destination}" ] ];
  loopbackForwards = port: destination:
    forward "127.0.0.1:${toString port}" destination
    ++ forward "[::1]:${toString port}" destination;

  tunnelArgs = [ [ "-NT" ] ] ++ sshHardening ++ [ (option "StreamLocalBindUnlink=yes") ]
    ++ forward "${pgSocket}/.s.PGSQL.5432" target.postgresqlSocket
    ++ forward "127.0.0.1:18780" "127.0.0.1:8780"
    ++ forward "127.0.0.1:18775" "127.0.0.1:8775"
    ++ forward "127.0.0.1:19091" "127.0.0.1:9091"
    ++ lib.optionals cfg.forwardWebPort (loopbackForwards 80 "127.0.0.1:80")
    ++ [ [ sshDestination ] ];

  supportTunnelArgs = [ [ "-NT" ] ] ++ sshHardening
    ++ lib.concatMap (port: loopbackForwards port "127.0.0.1:${toString port}") supportPorts
    ++ [ [ sshDestination ] ];

  sshCommand = groups: "exec /usr/bin/ssh "
    + lib.concatMapStringsSep " \\\n  " (lib.concatMapStringsSep " " lib.escapeShellArg) groups;

  tunnel = pkgs.writeShellScript "${target.name}-client-tunnel" ''
    set -euo pipefail
    umask 077
    mkdir -p ${lib.escapeShellArg pgSocket}
    ${sshCommand tunnelArgs}
  '';

  supportTunnel = pkgs.writeShellScript "${target.name}-support-tunnel" ''
    set -euo pipefail
    umask 077
    ${sshCommand supportTunnelArgs}
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
      -o ForwardAgent=no -o ForwardX11=no \
      -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
      ${lib.concatMapStringsSep " " lib.escapeShellArg (lib.flatten knownHostsArgs ++ [ "-i" cfg.reiIdentityFile sshDestination ])} \
      "rei-argv:$payload"
  '';

  clientIngest = pkgs.writeShellScript "${target.name}-client-ingest" ''
    set -euo pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") clientEnv)}
    export PATH="${pkgs.git}/bin:/usr/bin:/bin"
    exec ${pkgs.python3}/bin/python3 ${../bin/mori-client-ingest.py} \
      --mori ${pkgs.mori}/bin/mori
  '';

  tunnelAgent = "${target.name}-client-tunnel";
  ingestAgent = "${target.name}-client-ingest";
  supportAgent = "${target.name}-support-tunnel";
in
{
  options.workstation.reiMoriClient = {
    enable = lib.mkEnableOption "client access to another host's Rei/Mori runtime through an SSH tunnel";

    target = {
      name = lib.mkOption {
        type = lib.types.strMatching "[a-z][a-z0-9-]*";
        example = "yujin";
        description = "The owner's computer name (networking.hostName). Names the agents and state directory.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        description = "The owner's verified tailnet address.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "shinzui";
      };
      postgresqlSocket = lib.mkOption {
        type = lib.types.str;
        default = "/Users/shinzui/.local/state/postgresql/.s.PGSQL.5432";
        description = "The owner's PostgreSQL socket path.";
      };
      knownHostsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "A known_hosts file holding the owner's verified host key; null uses ~/.ssh/known_hosts.";
      };
    };

    tunnelIdentityFile = lib.mkOption {
      type = lib.types.str;
      description = "Private key enrolled on the owner for port forwarding only.";
    };
    reiIdentityFile = lib.mkOption {
      type = lib.types.str;
      description = "Private key enrolled on the owner with the forced rei-ssh-dispatch command.";
    };
    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/state/${target.name}-clients";
      defaultText = lib.literalExpression ''"~/.local/state/''${target.name}-clients"'';
      description = "Mode-0700 directory for the forwarded socket and tunnel logs.";
    };
    forwardWebPort = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Forward loopback port 80 (both 127.0.0.1 and [::1]) to the owner's Caddy. Requires this host's own support services to be off.";
    };
    gitIngest = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Record this machine's local commits into the owner's Mori store every ten minutes through the tunnel.";
    };
    supportForwards = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run a separate SSH agent forwarding the support-service ports to the owner. Requires this host's own support services to be off.";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      internal = true;
      default = {
        tunnel = tunnel.text;
        supportTunnel = supportTunnel.text;
        remoteRei = remoteRei.text;
      };
      description = "Generated script texts, for review through nix eval.";
    };

    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      internal = true;
      default = lib.optionals cfg.enable (
        [ tunnelAgent ]
        ++ lib.optional cfg.gitIngest ingestAgent
        ++ lib.optional cfg.supportForwards supportAgent
      );
      description = "launchd.agents names this client runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.workstation.reiMori.enable;
        message = "workstation.reiMoriClient: the runtime owner must not run a client tunnel.";
      }
      {
        assertion = !((cfg.forwardWebPort || cfg.supportForwards) && config.workstation.supportServices.enable);
        message = "workstation.reiMoriClient: forwardWebPort and supportForwards need workstation.supportServices.enable = false, or the forwards cannot bind.";
      }
    ];

    # Run the owner's Rei, with the owner's CLI version, from this shell.
    home.packages = [ (lib.meta.hiPrio remoteRei) ];

    programs.zsh.sessionVariables = lib.mapAttrs (_: lib.mkForce) clientEnv;

    # Long-lived terminals and coding agents can retain old local endpoints plus
    # Home Manager's exported "already sourced" flags across a rebuild. Refresh
    # the client endpoints on every shell startup, outside that one-time guard.
    programs.zsh.envExtra = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") clientEnv
    );

    launchd.agents = {
      ${tunnelAgent} = {
        enable = true;
        config = {
          Label = "com.shinzui.${tunnelAgent}";
          ProgramArguments = [ "${tunnel}" ];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 15;
          StandardOutPath = "${cfg.stateDirectory}/tunnel.stdout.log";
          StandardErrorPath = "${cfg.stateDirectory}/tunnel.stderr.log";
        };
      };

      # Application workers stay on the owner; the client only collects its Git
      # history through the tunnel. Database access alone cannot discover commits.
      ${ingestAgent} = lib.mkIf cfg.gitIngest {
        enable = true;
        config = {
          Label = "com.shinzui.${ingestAgent}";
          ProgramArguments = [ "${clientIngest}" ];
          RunAtLoad = true;
          StartInterval = 600;
          StandardOutPath = "${cfg.stateDirectory}/ingest.stdout.log";
          StandardErrorPath = "${cfg.stateDirectory}/ingest.stderr.log";
        };
      };

      ${supportAgent} = lib.mkIf cfg.supportForwards {
        enable = true;
        config = {
          Label = "com.shinzui.${supportAgent}";
          ProgramArguments = [ "${supportTunnel}" ];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 15;
          StandardOutPath = "${cfg.stateDirectory}/support-tunnel.stdout.log";
          StandardErrorPath = "${cfg.stateDirectory}/support-tunnel.stderr.log";
        };
      };
    };

    home.activation."${target.name}-client-dir" = lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
      run install -d -m 700 "${cfg.stateDirectory}" "${pgSocket}"
    '';
  };
}
