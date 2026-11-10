{ lib, ... }:
{
  imports = [ ../rei-mori-cutover-phase.nix ];

  # Yujin is the destination of the runtime move. Until the cutover phase hands
  # it the runtime it is a client of Sungkyung: a private database tunnel, the
  # ten-minute Git ingest into Sungkyung's Mori, and a remote `rei`. The phase
  # decides the runtime, backup, support-service and client flags.
  workstation.reiMoriCutover.role = "destination";
  workstation.reiMori.projectOutcomeWrites = true;

  workstation.reiMoriClient = {
    target = {
      name = "sungkyung";
      address = "100.66.155.64";
    };
    tunnelIdentityFile = "/Users/shinzui/.ssh/id_ed25519_sungkyung_client";
    reiIdentityFile = "/Users/shinzui/.ssh/id_ed25519_sungkyung_rei";
  };

  # Yujin's own recovery chain gets its own mirror: a sibling of Sungkyung's
  # /Volumes/aki-2023/postgresql-backups, never nested in it, because each sync
  # runs rsync --delete against its whole destination.
  services.postgresql.backups.offsiteDirectory = "/Volumes/aki-2023/postgresql-backups-yujin";

  # Interactive SSH uses Yujin's dedicated key; the daemon keeps its root-only key.
  programs.ssh.settings."nix-gcp-builder" = lib.hm.dag.entryBefore [ "*" ] {
    IdentityFile = "~/.ssh/nix-builder-yujin";
    IdentitiesOnly = true;
  };

  programs.ssh.settings."github.com" = lib.hm.dag.entryBefore [ "*" ] {
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519";
    IdentitiesOnly = true;
    AddKeysToAgent = "yes";
    IgnoreUnknown = "UseKeychain";
    UseKeychain = true;
  };
}
