{ config, lib, pkgs, ... }:

# System-level wiring for the on-demand x86_64-linux Nix remote builder
# in GCP (tan-nb-exp / us-west1-a).
#
# Why this lives in the darwin layer (not just home-manager): the
# nix-daemon runs as root and is what invokes `ssh` for remote builds.
# That ssh resolves `Host` aliases from /etc/ssh/ssh_config (+ drop-ins)
# and /var/root/.ssh/config — NOT from any user's ~/.ssh/config. So the
# Host alias and the ProxyCommand binary both have to be visible system
# wide.
#
# Why the wrapper sudo's to the interactive user for gcloud: gcloud
# stores credentials in $HOME/.config/gcloud. The interactive user is
# already authenticated there. Running gcloud as root would either ask
# for a fresh login or require a service-account key — both worse than
# a sudo drop.

let
  REAL_USER = "shinzui";

  proxyScript = pkgs.writeShellApplication {
    name = "nix-gcp-builder-proxy";
    runtimeInputs = [ pkgs.google-cloud-sdk pkgs.coreutils pkgs.socat pkgs.netcat ];
    text = ''
      set -euo pipefail
      PROJECT=tan-nb-exp
      ZONE=us-west1-a
      INSTANCE=nix-builder-x86
      # The builder's tailnet name. The byte stream goes over Tailscale; the
      # gcloud IAP tunnel is only a fallback. A long remote build lost its IAP
      # websocket on 2026-10-05 and gcloud failed to reconnect, which killed
      # the build.
      TAILNET_HOST=nix-builder-x86.tail8ed053.ts.net

      # Drop to the interactive user for gcloud calls so the auth in
      # /Users/${REAL_USER}/.config/gcloud is used. Root running sudo -u
      # never prompts for a password.
      if [ "$(id -un)" = "root" ]; then
        gc() { sudo -u ${REAL_USER} -- gcloud "$@"; }
      else
        gc() { gcloud "$@"; }
      fi

      STATUS=$(gc --project="$PROJECT" compute instances describe "$INSTANCE" \
                 --zone="$ZONE" --format='value(status)' 2>/dev/null || echo MISSING)
      if [[ "$STATUS" != "RUNNING" ]]; then
        gc --project="$PROJECT" compute instances start "$INSTANCE" \
          --zone="$ZONE" --quiet >/dev/null 2>&1
      fi

      # Prefer the tailnet: wait up to 120 s for sshd there (a cold VM needs
      # ~30 s to boot and rejoin), then hand the stream to socat directly.
      TUNNEL_LOG="/tmp/nix-gcp-builder-proxy-$(id -un).log"
      for _ in $(seq 1 60); do
        if nc -z -w 2 "$TAILNET_HOST" 22 2>/dev/null; then
          printf '%s pid %s: tailnet %s\n' "$(date -u +%FT%TZ)" "$$" "$TAILNET_HOST" >>"$TUNNEL_LOG"
          exec socat - "TCP:$TAILNET_HOST:22"
        fi
        sleep 2
      done
      printf '%s pid %s: tailnet unreachable, falling back to IAP\n' "$(date -u +%FT%TZ)" "$$" >>"$TUNNEL_LOG"

      # --local-host-port + socat, not --listen-on-stdin. The latter has
      # a kex-handshake-eating timing race with OpenSSH 10.x clients on
      # macOS when used as a ProxyCommand.
      PORT=$(( RANDOM % 10000 + 20000 ))
      # Keep the tunnel's stderr (one file per invoking user, since root runs
      # this for the nix-daemon) so a stalled or reconnecting IAP tunnel
      # leaves evidence instead of a bare "server not responding".
      printf '%s port %s pid %s: opening IAP tunnel\n' "$(date -u +%FT%TZ)" "$PORT" "$$" >>"$TUNNEL_LOG"
      gc --project="$PROJECT" compute start-iap-tunnel "$INSTANCE" 22 \
        --zone="$ZONE" --local-host-port="127.0.0.1:$PORT" --quiet 2>>"$TUNNEL_LOG" &
      tunnel_pid=$!
      socat_pid=""
      cleanup() {
        if [ -n "$socat_pid" ]; then
          kill "$socat_pid" 2>/dev/null || true
        fi
        kill "$tunnel_pid" 2>/dev/null || true
      }
      # ssh ends its ProxyCommand with SIGHUP. Untrapped, that kills bash
      # outright and skips the EXIT trap, orphaning the IAP tunnel under
      # launchd. Convert the fatal signals into a normal exit so cleanup runs.
      trap cleanup EXIT
      trap 'exit 129' HUP
      trap 'exit 130' INT
      trap 'exit 143' TERM

      # Wait up to 90s for the local tunnel listener (and the VM) to be
      # ready. A cold-started VM needs ~30s to be SSH-able.
      for _ in $(seq 1 90); do
        if (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
          break
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
  };
in
{
  environment.systemPackages = [ proxyScript ];

  # System-wide SSH client config drop-in. Both root (nix-daemon) and
  # interactive users see Host nix-gcp-builder.
  environment.etc."ssh/ssh_config.d/200-nix-gcp-builder.conf".text = ''
    Host nix-gcp-builder
      User builder
      IdentityFile /etc/nix/builder_ed25519
      ProxyCommand ${proxyScript}/bin/nix-gcp-builder-proxy
      StrictHostKeyChecking accept-new
      ServerAliveInterval 30
      # 30 s x 10: tolerate up to 5 minutes without a reply. With the
      # default count (3, i.e. 90 s) remote builds died twice on
      # 2026-10-05 while the builder VM (n2-standard-16) was healthy and
      # its SSH sessions outlived the client's timeout by 5-10 minutes:
      # the stall was in the IAP tunnel path, not the builder.
      ServerAliveCountMax 10
  '';
}
