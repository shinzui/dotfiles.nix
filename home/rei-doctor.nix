{ config, pkgs, lib, ... }:

# rei-doctor — health check + auto-heal watchdog for the rei action-recording
# pipeline (commits -> mori-automate -> mori-rei-app -> pgmq -> rei actions).
#
# The recurring failure: a transient *system-wide* FD exhaustion poisons the
# long-lived DB connection pools inside the mori-automate / rei-subscription
# daemons. The OS processes stay alive, so launchd KeepAlive never restarts
# them, and every hourly ingest then fails with AcquisitionTimeoutUsageError —
# silently, for hours. This module gives:
#   * `rei-doctor`            — one-shot health report (run it anytime)
#   * `com.shinzui.rei-watchdog` — every 5 min, kickstarts wedged daemons and
#                                  fires a macOS notification when it heals.
let
  pg = config.services.postgresql.package;
  pgSocket = config.services.postgresql.socketDir;
  logDir = "${config.home.homeDirectory}/.rei-doctor/logs";

  # Tools the script shells out to. macOS system bins (launchctl, osascript,
  # ps, sysctl, id) come from /usr/bin:/bin:/usr/sbin; the rest are pinned.
  binPath = lib.makeBinPath [ pg pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.gnused pkgs.mori ];
  fullPath = "${binPath}:/usr/bin:/bin:/usr/sbin:/sbin";

  rei-doctor = pkgs.writeShellScriptBin "rei-doctor" ''
    export PATH="${fullPath}"
    export REI_DOCTOR_SOCKET="${pgSocket}"
    exec ${pkgs.bash}/bin/bash ${./rei-doctor.sh} "$@"
  '';
in
{
  home.packages = [ rei-doctor ];

  home.activation.rei-doctor-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  # Bootout the watchdog before re-registering, but only if the plist changed
  # (setupLaunchAgents skips unchanged plists; unconditional bootout would
  # leave it unloaded). Mirrors the pattern in mori.nix / rei.nix.
  home.activation.rei-watchdog-stop-agent = lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
    label="com.shinzui.rei-watchdog"
    domain="gui/$(id -u)"
    newPlist="$newGenPath/LaunchAgents/$label.plist"
    curPlist="$HOME/Library/LaunchAgents/$label.plist"
    if ! cmp -s "$newPlist" "$curPlist"; then
      if /bin/launchctl print "$domain/$label" &>/dev/null; then
        /bin/launchctl bootout "$domain/$label" 2>/dev/null || true
      fi
    fi
  '';

  # Periodic task (NOT KeepAlive — it's a cron-style check, not a daemon).
  launchd.agents.rei-watchdog = {
    enable = true;
    config = {
      Label = "com.shinzui.rei-watchdog";
      ProgramArguments = [ "${rei-doctor}/bin/rei-doctor" "--heal" "--notify" "--quiet" ];
      RunAtLoad = true;
      StartInterval = 300; # every 5 minutes
      StandardOutPath = "${logDir}/watchdog.stdout.log";
      StandardErrorPath = "${logDir}/watchdog.stderr.log";
      EnvironmentVariables = {
        PATH = fullPath;
        REI_DOCTOR_SOCKET = pgSocket;
      };
    };
  };
}
