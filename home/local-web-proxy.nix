{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.local/state/local-web-proxy";

  # Caddy reverse proxy giving local web tools stable browser names instead of
  # memorized numeric ports. Listens on port 80 and forwards each named host to
  # its existing loopback service:
  #
  #   mina.localhost   -> 127.0.0.1:8765   (mina web --global, home/mina.nix)
  #   reiko.localhost  -> 127.0.0.1:8770   (reiko web, home/reiko.nix)
  #   logs.localhost   -> 127.0.0.1:9428   (VictoriaLogs, home/victorialogs.nix)
  #   traces.localhost -> 127.0.0.1:10428  (VictoriaTraces, home/victoriatraces.nix)
  #   jaeger.localhost -> 127.0.0.1:16686  (Jaeger UI, home/victoriatraces.nix)
  #
  # macOS resolves *.localhost to ::1/127.0.0.1 natively, so no /etc/hosts
  # wiring is needed. Plain HTTP on :80 avoids local CA trust for .localhost.
  #
  # This runs as a user LaunchAgent, not a system LaunchDaemon. macOS does not
  # reserve ports below 1024, so an unprivileged process binds :80 fine, and
  # running in the user domain means `launchctl kickstart` needs no sudo.
  #
  # Nothing else may hold :80. A k3d/Colima cluster publishing 0.0.0.0:80 (e.g.
  # `-p "80:80@loadbalancer"`) will take the port and this agent will fail to
  # bind; map such clusters to a high port and give them a name here instead.
  caddyfile = pkgs.writeText "local-web-proxy.Caddyfile" ''
    http://mina.localhost {
      reverse_proxy 127.0.0.1:8765
    }

    http://reiko.localhost {
      reverse_proxy 127.0.0.1:8770
    }

    http://logs.localhost {
      reverse_proxy 127.0.0.1:9428
    }

    http://traces.localhost {
      reverse_proxy 127.0.0.1:10428
    }

    http://jaeger.localhost {
      reverse_proxy 127.0.0.1:16686
    }
  '';

  # Caddy writes its autosaved config and TLS storage under $XDG_*_HOME, falling
  # back to the working directory. launchd agents start with cwd=/ and no HOME,
  # so without these it tries to mkdir ./caddy on the read-only system volume.
  caddyHome = "${config.home.homeDirectory}/.local/share/caddy";

  caddy-wrapper = pkgs.writeShellScript "local-web-proxy" ''
    set -euo pipefail
    mkdir -p "${logDir}" "${caddyHome}"

    exec ${pkgs.caddy}/bin/caddy run \
      --config ${caddyfile} \
      --adapter caddyfile
  '';
in
{
  home.packages = [ pkgs.caddy ];

  home.activation.local-web-proxy-dirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}" "${caddyHome}"
  '';

  launchd.agents.local-web-proxy = {
    enable = true;
    config = {
      Label = "com.shinzui.local-web-proxy";
      ProgramArguments = [ "${caddy-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/caddy.stdout.log";
      StandardErrorPath = "${logDir}/caddy.stderr.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
        XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
      };
    };
  };
}
