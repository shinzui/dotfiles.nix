{ lib, ... }:
{
  # Prepare this machine without starting the live runtime or its integrations.
  workstation.reiMori.enable = false;

  programs.ssh.settings."github.com" = lib.hm.dag.entryBefore [ "*" ] {
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519";
    IdentitiesOnly = true;
    AddKeysToAgent = "yes";
    IgnoreUnknown = "UseKeychain";
    UseKeychain = true;
  };
}
