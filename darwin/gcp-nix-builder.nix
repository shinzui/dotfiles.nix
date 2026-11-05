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

let
  proxyScript = import ./gcp-builder-proxy.nix { inherit lib pkgs; } {
    name = "nix-gcp-builder-proxy";
    project = "tan-nb-exp";
    zone = "us-west1-a";
    instance = "nix-builder-x86";
    tailnetHost = "nix-builder-x86.tail8ed053.ts.net";
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
