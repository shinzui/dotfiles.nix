{ ... }:

# The proxy script and the Host alias for `nix-gcp-builder` are
# installed system-wide in darwin/gcp-nix-builder.nix so the
# nix-daemon (running as root) can resolve them. This file just
# preserves the colima ssh include that the hand-rolled ~/.ssh/config
# used to provide.

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*".extraOptions.Include = "/Users/shinzui/.colima/ssh_config";
  };
}
