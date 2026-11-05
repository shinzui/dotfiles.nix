{ lib, pkgs }:

# An OpenSSH ProxyCommand for an on-demand Nix builder VM in GCP: it starts the
# VM if needed and opens the byte stream, over the tailnet when `tailnetHost` is
# set and otherwise through an IAP tunnel.
#
# Why the wrapper sudo's to the interactive user for gcloud: gcloud
# stores credentials in $HOME/.config/gcloud. The interactive user is
# already authenticated there. Running gcloud as root would either ask
# for a fresh login or require a service-account key — both worse than
# a sudo drop.

{
  name,
  project,
  zone,
  instance,
  # The builder's tailnet name, or null when it is reachable only through IAP.
  tailnetHost ? null,
  # A named gcloud configuration, for a builder that the default one cannot reach.
  gcloudConfig ? null,
}:

let
  REAL_USER = "shinzui";

  gcloud =
    if gcloudConfig == null then "gcloud" else "env CLOUDSDK_ACTIVE_CONFIG_NAME=${gcloudConfig} gcloud";

  tailnetDeclaration = lib.optionalString (tailnetHost != null) ''
    # The builder's tailnet name. The byte stream goes over Tailscale; the
    # gcloud IAP tunnel is only a fallback. A long remote build lost its IAP
    # websocket on 2026-10-05 and gcloud failed to reconnect, which killed
    # the build.
    TAILNET_HOST=${tailnetHost}
  '';

  tailnetPreferenceComment = lib.optionalString (tailnetHost != null) ''
    # Prefer the tailnet: wait up to 120 s for sshd there (a cold VM needs
    # ~30 s to boot and rejoin), then hand the stream to socat directly.
  '';

  tailnetAttempt = lib.optionalString (tailnetHost != null) ''
    for _ in $(seq 1 60); do
      if nc -z -w 2 "$TAILNET_HOST" 22 2>/dev/null; then
        printf '%s pid %s: tailnet %s\n' "$(date -u +%FT%TZ)" "$$" "$TAILNET_HOST" >>"$TUNNEL_LOG"
        exec socat - "TCP:$TAILNET_HOST:22"
      fi
      sleep 2
    done
    printf '%s pid %s: tailnet unreachable, falling back to IAP\n' "$(date -u +%FT%TZ)" "$$" >>"$TUNNEL_LOG"
  '';
in
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = [ pkgs.google-cloud-sdk pkgs.coreutils pkgs.socat pkgs.netcat ];
  text = ''
    set -euo pipefail
    PROJECT=${project}
    ZONE=${zone}
    INSTANCE=${instance}
    ${tailnetDeclaration}
    # Drop to the interactive user for gcloud calls so the auth in
    # /Users/${REAL_USER}/.config/gcloud is used. Root running sudo -u
    # never prompts for a password.
    if [ "$(id -un)" = "root" ]; then
      gcloud_command=(sudo -u ${REAL_USER} -- ${gcloud})
    else
      gcloud_command=(${gcloud})
    fi
    gc() { "''${gcloud_command[@]}" "$@"; }

    instance_status() {
      gc --project="$PROJECT" compute instances describe "$INSTANCE" \
        --zone="$ZONE" --format='value(status)' 2>/dev/null || echo MISSING
    }
    STATUS=$(instance_status)
    # The builder's idle watchdog powers the VM off from inside. A start
    # sent while it is still STOPPING fails, so wait for it to stop first
    # (2026-10-14: a gate 28 s after a guestTerminate lost its builder).
    for _ in $(seq 1 60); do
      case "$STATUS" in
        STOPPING|SUSPENDING) sleep 2; STATUS=$(instance_status) ;;
        *) break ;;
      esac
    done
    if [[ "$STATUS" != "RUNNING" ]]; then
      gc --project="$PROJECT" compute instances start "$INSTANCE" \
        --zone="$ZONE" --quiet >/dev/null 2>>"/tmp/${name}-$(id -un).log" \
        || printf '%s pid %s: start from %s failed\n' "$(date -u +%FT%TZ)" "$$" "$STATUS" >>"/tmp/${name}-$(id -un).log"
    fi

    ${tailnetPreferenceComment}TUNNEL_LOG="/tmp/${name}-$(id -un).log"
    ${tailnetAttempt}
    # --local-host-port + socat, not --listen-on-stdin. The latter has
    # a kex-handshake-eating timing race with OpenSSH 10.x clients on
    # macOS when used as a ProxyCommand.
    PORT=$(( RANDOM % 10000 + 20000 ))
    # Keep the tunnel's stderr (one file per invoking user, since root runs
    # this for the nix-daemon) so a stalled or reconnecting IAP tunnel
    # leaves evidence instead of a bare "server not responding".
    open_tunnel() {
      printf '%s port %s pid %s: opening IAP tunnel\n' "$(date -u +%FT%TZ)" "$PORT" "$$" >>"$TUNNEL_LOG"
      # Background the command itself, not the gc function. A backgrounded function
      # runs in a subshell, so $! would name the subshell, and killing it would
      # orphan gcloud under launchd.
      "''${gcloud_command[@]}" --project="$PROJECT" compute start-iap-tunnel "$INSTANCE" 22 \
        --zone="$ZONE" --local-host-port="127.0.0.1:$PORT" --quiet 2>>"$TUNNEL_LOG" &
      tunnel_pid=$!
    }
    tunnel_pid=""
    socat_pid=""
    cleanup() {
      if [ -n "$socat_pid" ]; then
        kill "$socat_pid" 2>/dev/null || true
      fi
      if [ -n "$tunnel_pid" ]; then
        kill "$tunnel_pid" 2>/dev/null || true
      fi
    }
    # ssh ends its ProxyCommand with SIGHUP. Untrapped, that kills bash
    # outright and skips the EXIT trap, orphaning the IAP tunnel under
    # launchd. Convert the fatal signals into a normal exit so cleanup runs.
    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # Wait up to 90s for the local tunnel listener (and the VM) to be
    # ready. A cold-started VM needs ~30s to be SSH-able. gcloud tests the
    # backend before it listens and exits if sshd is not up yet (4003), so
    # open the tunnel again whenever it has gone.
    open_tunnel
    for _ in $(seq 1 90); do
      if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
        break
      fi
      if ! kill -0 "$tunnel_pid" 2>/dev/null; then
        open_tunnel
      fi
      sleep 1
    done
    # Keep the shell alive so its EXIT trap stops the IAP tunnel. socat
    # runs in the background under `wait` because bash only runs traps
    # while in `wait`, never while a foreground child is running. The
    # explicit <&0 matters: without job control bash would otherwise
    # point a background job's stdin at /dev/null.
    socat - "TCP:127.0.0.1:$PORT" <&0 &
    socat_pid=$!
    wait "$socat_pid"
  '';
}
