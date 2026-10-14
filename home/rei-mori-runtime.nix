{ config, lib, ... }:
let
  cfg = config.workstation.reiMori;
in
{
  options.workstation.reiMori = {
    enable = lib.mkEnableOption "the active runtime for mori://shinzui/rei and mori://shinzui/mori";
    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      internal = true;
      default = [
        "mori-automate"
        "mori-serve"
        "mori-rei-app"
        "rei-api"
        "rei-worker"
        "rei-worker-kiroku"
        "rei-subscription"
        "rei-worker-git-sync"
        "rei-watchdog"
        "notion-hub-subscription"
        "mina-web"
        "reiko-web"
      ];
      description = "Runtime agents and integrations which move together during host cutover.";
    };
  };

  # A prepared machine must not consume events, run automations, or heal the
  # active machine's runtime. Packages, configuration and general PostgreSQL
  # remain available independently of this opt-in runtime profile.
  config = lib.mkIf (!cfg.enable) {
    launchd.agents = lib.genAttrs cfg.agents (_: {
      enable = lib.mkForce false;
    });

    # Disable healing before the existing per-application stop hooks run.
    home.activation.rei-mori-stop-watchdog = lib.hm.dag.entryBefore [
      "mori-stop-agents"
      "rei-stop-agents"
      "mori-rei-app-stop-agents"
      "notion-hub-stop-agents"
      "setupLaunchAgents"
    ] ''
      domain="gui/$(id -u)"
      label="com.shinzui.rei-watchdog"
      if /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
        watchdog_pid=$(/bin/launchctl print "$domain/$label" 2>/dev/null \
          | /usr/bin/awk '/[[:space:]]pid = /{print $NF; exit}') || true
        /bin/launchctl bootout "$domain/$label"
        if [ -n "$watchdog_pid" ]; then
          for ((attempt = 0; attempt < 30; attempt++)); do
            if ! kill -0 "$watchdog_pid" 2>/dev/null; then break; fi
            sleep 1
          done
          if kill -0 "$watchdog_pid" 2>/dev/null; then
            echo "Rei watchdog is still running; inactive runtime activation refused." >&2
            exit 1
          fi
        fi
      fi
    '';
  };
}
