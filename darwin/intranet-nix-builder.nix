{ lib, pkgs, ... }:

# The Nagare intranet's x86_64-linux builder, nix-builder-intranet in tan-ng-labs
# (mori://shinzui/tan-ng-labs, README, "The x86 builder").
#
# It is deliberately not in determinateNix.buildMachines. That list is offered to
# every x86_64-linux build on this machine, so unrelated work could land on the
# intranet's VM. Ask for it per command instead:
#
#   nix build --builders @/etc/nix/intranet-machines ...
#
# It has no tailnet name, so its byte stream goes through an IAP tunnel, which the
# proxy opens on demand. The key is per workstation and is not provisioned here. Its
# path is absolute because the nix-daemon connects as root, whose ~ is /var/root.

let
  proxyScript = import ./gcp-builder-proxy.nix { inherit lib pkgs; } {
    name = "nix-intranet-builder-proxy";
    project = "tan-ng-labs";
    zone = "us-west1-a";
    instance = "nix-builder-intranet";
    # The account that can reach this project, whatever gcloud's active configuration is.
    gcloudConfig = "labs";
  };
in
{
  environment.systemPackages = [ proxyScript ];

  # NIX_BUILDER_HOST_KEY_B64 in tan-ng-labs's contexts/intranet.env, decoded. A recreated
  # VM has a new host key, and connections are refused until this is updated.
  environment.etc."ssh/nix-intranet-builder.known_hosts".text = ''
    nix-intranet-builder ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOjRj9nhBTNor2qRrRik67bP78l3yrDTSbL7GvS4hxH
  '';

  # System-wide so that both root (nix-daemon) and interactive users see it.
  environment.etc."ssh/ssh_config.d/201-nix-intranet-builder.conf".text = ''
    Host nix-intranet-builder
      User builder
      IdentityFile /Users/shinzui/.config/nagare/operator/intranet/builder_ed25519
      IdentitiesOnly yes
      ProxyCommand ${proxyScript}/bin/nix-intranet-builder-proxy
      StrictHostKeyChecking yes
      UserKnownHostsFile /etc/ssh/nix-intranet-builder.known_hosts
      ServerAliveInterval 30
      # Tolerate up to 5 minutes without a reply; see 200-nix-gcp-builder.conf.
      ServerAliveCountMax 10
  '';

  environment.etc."nix/intranet-machines".text = ''
    ssh-ng://builder@nix-intranet-builder x86_64-linux - 4 1 big-parallel,benchmark,kvm,nixos-test - -
  '';
}
