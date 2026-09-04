{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.local/state/local-web-proxy";

  # Caddy reverse proxy giving local web tools stable browser names instead of
  # memorized numeric ports. Listens on port 80 and forwards each named host to
  # its existing loopback service:
  #
  #   mina     -> 127.0.0.1:8765   (mina web --global, home/mina.nix)
  #   reiko    -> 127.0.0.1:8770   (reiko web, home/reiko.nix)
  #   logs     -> 127.0.0.1:9428   (VictoriaLogs, home/victorialogs.nix)
  #   traces   -> 127.0.0.1:10428  (VictoriaTraces, home/victoriatraces.nix)
  #   jaeger   -> 127.0.0.1:16686  (Jaeger UI, home/victoriatraces.nix)
  #   redpanda -> 127.0.0.1:8080   (Redpanda Console, home/redpanda.nix)
  #
  # Plain HTTP on :80 avoids local CA trust for these names.
  #
  # This runs as a user LaunchAgent, not a system LaunchDaemon. macOS does not
  # reserve ports below 1024, so an unprivileged process binds :80 fine, and
  # running in the user domain means `launchctl kickstart` needs no sudo.
  #
  # Nothing else may hold :80. A k3d/Colima cluster publishing 0.0.0.0:80 (e.g.
  # `-p "80:80@loadbalancer"`) will take the port and this agent will fail to
  # bind; map such clusters to a high port and give them a name here instead.
  services = {
    mina = 8765;
    reiko = 8770;
    logs = 9428;
    traces = 10428;
    jaeger = 16686;
    redpanda = 8080;
  };

  # Documentation sites (fumadocs + Vite) under ~/Keikaku/bokuno/<name>-docs.
  # Unlike the services above these are not long-running; each is started by
  # hand with `bun dev` in its repo and the route just sits here waiting.
  #
  # Every site runs `vite dev --host 127.0.0.1 --port <n> --strictPort`:
  #
  #   --host 127.0.0.1  Vite's default host is `localhost`, which on macOS
  #                     binds [::1] ONLY. The routes below dial 127.0.0.1, so
  #                     without this the proxy cannot reach the dev server.
  #   --port <n>        the name here must always reach the same site.
  #   --strictPort      without it Vite walks up from its default when a port
  #                     is busy, and two sites open at once silently swap.
  #
  # To add a site: give it the next free port here, then set the repo's "dev"
  # script to `vite dev --host 127.0.0.1 --port <n> --strictPort`.
  #
  # Vite accepts any *.localhost Host header with no configuration. Reaching a
  # doc site from another device (<name>.lan, <name>.192-168-1-115.sslip.io)
  # additionally needs that hostname in `server.allowedHosts` in the site's
  # vite.config.ts, or Vite answers 403.
  devSites = {
    danwa = 5210;
    en = 5211;
    kawa = 5212;
    keiki = 5213;
    keiro-runtime = 5214;
    kikan = 5215;
    kizashi = 5216;
    kotei = 5217;
    nagare = 5218;
    shikigami = 5219;
    shikumi = 5220;
    shomei = 5221;
  };

  # One namespace for both kinds of route: a name may not be claimed twice, and
  # two upstreams may not share a port, or one route silently shadows the other.
  allRoutes =
    let
      clashingNames = lib.intersectLists (lib.attrNames services) (lib.attrNames devSites);
      merged = services // devSites;
      ports = lib.attrValues merged;
    in
    assert lib.assertMsg (clashingNames == [ ])
      "local-web-proxy: name claimed by both services and devSites: ${lib.concatStringsSep ", " clashingNames}";
    assert lib.assertMsg (lib.length (lib.unique ports) == lib.length ports)
      "local-web-proxy: two routes share a port";
    merged;

  # Each service matches on the FIRST LABEL of the Host header rather than on a
  # fixed site address, so the domain suffix does not matter: mina.localhost
  # from this machine and mina.lan or mina.192-168-1-115.sslip.io from a phone
  # on the LAN all reach the same upstream, with no edit here when the LAN
  # addressing changes.
  #
  # .localhost alone cannot work off-machine: RFC 6761 pins *.localhost to the
  # *client's* loopback, so a phone asking for mina.localhost resolves to
  # itself. Reaching these from another device needs a suffix that real DNS
  # answers with this Mac's LAN address.
  #
  # Caddy binds 0.0.0.0:80, so every name below is reachable from the LAN, and
  # logs/traces/jaeger/redpanda are unauthenticated UIs. To pull one back to
  # this machine only, swap its matcher for an explicit host list:
  #
  #   @jaeger host jaeger.localhost
  route = name: port: ''
      @${name} expression {host}.startsWith("${name}.")
      handle @${name} {
        reverse_proxy 127.0.0.1:${toString port}
      }
  '';

  caddyfile = pkgs.writeText "local-web-proxy.Caddyfile" ''
    :80 {
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList route allRoutes)}
      handle {
        respond "local-web-proxy: no service for host {host}" 404
      }

      # A route whose upstream is not listening fails to dial and Caddy returns
      # a bodyless 502. For a doc site that is the normal state -- the dev
      # server simply is not started -- so say that rather than leaving a blank
      # page to debug.
      handle_errors {
        @dial expression {err.status_code} == 502
        handle @dial {
          respond "local-web-proxy: nothing listening for {host}. Start its dev server." 502
        }
        handle {
          respond "local-web-proxy: {err.status_code} for {host}" {err.status_code}
        }
      }
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
