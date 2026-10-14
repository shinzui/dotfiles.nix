{ lib, ... }:
{
  programs.ssh.settings."github.com" = lib.hm.dag.entryBefore [ "*" ] {
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519";
    IdentitiesOnly = true;
    AddKeysToAgent = "yes";
    IgnoreUnknown = "UseKeychain";
    UseKeychain = true;
  };
}
