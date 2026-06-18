{ pkgs, ... }:

let
  # Caddy reverse proxy giving local web tools stable browser names instead of
  # memorized numeric ports. Listens on privileged port 80 (system daemon) and
  # forwards each named host to its existing loopback service:
  #
  #   mina.localhost   -> 127.0.0.1:8765   (mina web --global, home/mina.nix)
  #   reiko.localhost  -> 127.0.0.1:8770   (reiko web, home/reiko.nix)
  #   logs.localhost   -> 127.0.0.1:9428   (VictoriaLogs, home/victorialogs.nix)
  #   traces.localhost -> 127.0.0.1:10428  (VictoriaTraces, home/victoriatraces.nix)
  #   jaeger.localhost -> 127.0.0.1:16686  (Jaeger UI, home/victoriatraces.nix)
  #
  # macOS resolves *.localhost to ::1/127.0.0.1 natively, so no /etc/hosts
  # wiring is needed. Plain HTTP on :80 avoids local CA trust for .localhost.
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
in
{
  environment.systemPackages = [ pkgs.caddy ];

  launchd.daemons."shinzui-local-web-proxy" = {
    serviceConfig = {
      Label = "shinzui.local-web-proxy";
      ProgramArguments = [
        "${pkgs.caddy}/bin/caddy"
        "run"
        "--config"
        "${caddyfile}"
        "--adapter"
        "caddyfile"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/shinzui-local-web-proxy.stdout.log";
      StandardErrorPath = "/var/log/shinzui-local-web-proxy.stderr.log";
    };
  };
}
