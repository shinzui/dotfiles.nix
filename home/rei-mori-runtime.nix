{ config, lib, ... }:
let
  cfg = config.workstation.reiMori;

  # The only agents an owner may run at stage "validation": the APIs and the
  # two web tools that read them. Workers, automations, integrations (the
  # mori-rei-app bridge and the Notion Hub consumer) and healing stay off so a
  # freshly restored host can be inspected before it causes any side effect.
  validationAgents = [
    "mori-serve"
    "rei-api"
    "mina-web"
    "reiko-web"
    "mori-ui"
  ];

  # Agents forced off on this host: all of them when it is not the owner, and
  # everything outside validationAgents while the owner is validating.
  forcedOff =
    if !cfg.enable then cfg.agents
    else if cfg.stage == "validation" then lib.subtractLists validationAgents cfg.agents
    else [ ];
in
{
  options.workstation.reiMori = {
    enable = lib.mkEnableOption "the active runtime for mori://shinzui/rei and mori://shinzui/mori";
    stage = lib.mkOption {
      type = lib.types.enum [ "validation" "active" ];
      default = "active";
      description = ''
        How much of the runtime an owner runs. "validation" permits only the
        APIs and web tools (validationAgents) and keeps workers, integrations
        and healing off; "active" keeps each module's own enable value.
        Ignored when enable is false.
      '';
    };
    healing = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      internal = true;
      default = cfg.enable && cfg.stage == "active";
      description = "Whether rei-doctor may heal and the watchdog may bootstrap itself.";
    };
    projectOutcomeWrites = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable project outcome writes after the coordinated reader and ownership reconstruction rollout.";
    };
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
        "mori-ui"
      ];
      description = "Runtime agents and integrations which move together during host cutover.";
    };
    validationAgents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      internal = true;
      default = validationAgents;
      description = "Runtime agents an owner may run at stage validation.";
    };
  };

  # A prepared machine must not consume events, run automations, or heal the
  # active machine's runtime. Packages, configuration and general PostgreSQL
  # remain available independently of this opt-in runtime profile.
  config = lib.mkIf (!cfg.healing) {
    launchd.agents = lib.genAttrs forcedOff (_: {
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
