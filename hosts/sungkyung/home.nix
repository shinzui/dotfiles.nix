{ ... }:
{
  imports = [ ../rei-mori-cutover-phase.nix ];

  # Sungkyung holds the runtime until the cutover phase hands it to Yujin.
  # The phase decides the runtime, backup, support-service and client flags.
  workstation.reiMoriCutover.role = "source";
  workstation.reiMori.projectOutcomeWrites = true;

  # After the move Sungkyung reaches Yujin's runtime, web routes, telemetry and
  # Redpanda through outgoing tunnels on the same port numbers.
  workstation.reiMoriClient = {
    target = {
      name = "yujin";
      address = "100.105.45.104";
    };
    tunnelIdentityFile = "/Users/shinzui/.ssh/id_ed25519_yujin_client";
    reiIdentityFile = "/Users/shinzui/.ssh/id_ed25519_yujin_rei";
    forwardWebPort = true;
    supportForwards = true;
  };
}
