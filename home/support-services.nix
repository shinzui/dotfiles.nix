{ config, lib, ... }:

# Shared support services: the Caddy proxy behind *.localhost names,
# VictoriaLogs with its shippers, VictoriaTraces with its Jaeger UI, and the
# Redpanda cluster. None of them stores data a host move must preserve, but
# only one machine may run them once the other forwards their ports to it:
# a second copy would hold a port the tunnel needs, or answer a name for the
# wrong machine.
#
# This switch is deliberately separate from workstation.reiMori. It never
# enables or disables a Rei/Mori runtime agent, and no step that reads,
# writes, exports, restores or fences PostgreSQL data depends on it.
#
# Turning it off removes the launch agents only. Packages, the telemetry data
# directories under ~/.local/share and the redpanda-0-data container volume all
# stay. services.redpanda-container.enable = false removes the
# com.shinzui.redpanda login agent, but it does not stop containers that are
# already running, so run `redpanda-down` before switching to a revision that
# turns this off.
let
  cfg = config.workstation.supportServices;
in
{
  options.workstation.supportServices = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the shared support services (Caddy, VictoriaLogs, VictoriaTraces, Redpanda) on this host.";
    };
    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      internal = true;
      default = [
        "local-web-proxy"
        "victorialogs"
        "victoriatraces"
        "victoriatraces-jaeger-ui"
      ] ++ config.services.victorialogs.shipperAgents;
      description = "launchd.agents names owned by the support-service switch, besides Redpanda's.";
    };
  };

  config = lib.mkIf (!cfg.enable) {
    launchd.agents = lib.genAttrs cfg.agents (_: {
      enable = lib.mkForce false;
    });
    services.redpanda-container.enable = lib.mkForce false;
  };
}
