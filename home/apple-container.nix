{ config, pkgs, lib, ... }:

# Apple Container's background service.
#
# `container` itself is installed from home/default.nix's `home.packages` list,
# next to docker and colima. This module only makes sure its API server is
# running and registered against the *current* build of the package.
#
# Unlike every other service in this repository, this launch agent is not
# declared through `launchd.agents`. `container system start` registers it
# itself, under the label `com.apple.container.apiserver`, writing its own
# plist to ~/Library/Application Support/com.apple.container/apiserver/ rather
# than ~/Library/LaunchAgents. home-manager therefore never sees it, and the
# usual stop-and-wait / setupLaunchAgents machinery does not apply.
#
# That plist sets RunAtLoad, so once registered the service does come back on
# its own at login and no launchd agent of our own is needed. What it does
# *not* survive is a package upgrade: the plist bakes the Nix store path into
# both ProgramArguments[0] and CONTAINER_INSTALL_ROOT, for example
#
#   ProgramArguments[0] = /nix/store/<hash>-container-1.2.2/bin/container-apiserver
#   CONTAINER_INSTALL_ROOT = /nix/store/<hash>-container-1.2.2
#
# so after the derivation changes, the registration still points at the old
# store path. That path keeps working until it is garbage-collected, at which
# point the agent silently fails to launch at login and the CLI talks to
# nothing. Worse, before collection you get version skew: a new CLI against an
# apiserver still running from the old store path.
#
# The activation hook below closes that gap by comparing the store path
# recorded in the plist against the one this generation installs, and
# re-registering when they differ.

let
  container = pkgs.container;

  apiserverPlist =
    "${config.home.homeDirectory}/Library/Application Support/com.apple.container/apiserver/apiserver.plist";
in
{
  # Runs after writeBoundary so the new generation's store paths exist.
  # Deliberately never fails the switch: the service not starting is an
  # inconvenience, a broken `darwin-rebuild switch` is not.
  home.activation.apple-container-ensure-running =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apiserverPlist="${apiserverPlist}"
      desiredRoot="${container}"

      recordedRoot=""
      if [ -f "$apiserverPlist" ]; then
        # `plutil -extract ... raw` prints the bare value. A plist written by an
        # older container release may not have the key at all, hence `|| true`.
        recordedRoot=$(/usr/bin/plutil -extract \
          EnvironmentVariables.CONTAINER_INSTALL_ROOT raw -o - \
          "$apiserverPlist" 2>/dev/null) || true
      fi

      # `container system status` exits 0 when the apiserver is running and
      # registered, 1 otherwise. It is a cheap, side-effect-free health check.
      if ! ${container}/bin/container system status >/dev/null 2>&1; then
        verboseEcho "Apple Container apiserver is not running; starting it"
        appleContainerNeedsStart=1
      elif [ "$recordedRoot" != "$desiredRoot" ]; then
        verboseEcho "Apple Container apiserver is registered against ''${recordedRoot:-an unknown path}, expected $desiredRoot; re-registering"
        appleContainerNeedsStart=1
      else
        verboseEcho "Apple Container apiserver already running against $desiredRoot"
        appleContainerNeedsStart=0
      fi

      if [ "$appleContainerNeedsStart" = 1 ]; then
        # Stop first even when nothing is running: that is what clears a stale
        # registration pointing at a superseded store path. Both stop and start
        # are safe to call from any state.
        run ${container}/bin/container system stop || true

        # --enable-kernel-install is not optional here. Without it the flag
        # defaults to prompting for whether to install the default Linux
        # kernel, which would block activation forever waiting on stdin.
        if ! run ${container}/bin/container system start --enable-kernel-install; then
          warnEcho "container system start failed; run 'container system start' by hand to inspect it"
        fi
      fi
    '';
}
