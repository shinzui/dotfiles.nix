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
    runtimeInputs = [ pkgs.google-cloud-sdk pkgs.coreutils pkgs.socat ];
    text = ''
      set -euo pipefail
      PROJECT=tan-nb-exp
      ZONE=us-west1-a
      INSTANCE=nix-builder-x86

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

      # --local-host-port + socat, not --listen-on-stdin. The latter has
      # a kex-handshake-eating timing race with OpenSSH 10.x clients on
      # macOS when used as a ProxyCommand.
      PORT=$(( RANDOM % 10000 + 20000 ))
      gc --project="$PROJECT" compute start-iap-tunnel "$INSTANCE" 22 \
        --zone="$ZONE" --local-host-port="localhost:$PORT" --quiet 2>/dev/null &
      tunnel_pid=$!
      trap 'kill "$tunnel_pid" 2>/dev/null || true' EXIT

      # Wait up to 90s for the local tunnel listener (and the VM) to be
      # ready. A cold-started VM needs ~30s to be SSH-able.
      for _ in $(seq 1 90); do
        if (exec 3<>"/dev/tcp/localhost/$PORT") 2>/dev/null; then
          break
        fi
        sleep 1
      done
      exec socat - "TCP:localhost:$PORT"
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
  '';
}
