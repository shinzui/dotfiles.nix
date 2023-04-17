# Secrets

The management of secrets is facilitated by the [age NixOS module](https://github.com/ryantm/agenix). This module allows the encryption of secrets using the age tool, and adds them to the Nix store. Upon rebuild, the module automatically decrypts the secrets.

The agenix project provides an additional tool, the agenix cli, which can be used to edit and rekey the secrets, and manage access control. The agenix cli uses [rage](https://github.com/str4d/rage) for encrypting the secrets.

To add a new secret, follow these steps:

1.  Edit the `secrets/secrets.nix` file and configure the new secret as follows:

```nix
{
  ...
  "newsecret.age".publicKeys = [ <publicKeys> ];
}
```

2.  Edit the secret file using the agenix cli:

```
agenix -e newsecret.age
```

3.  Add the secret to the age NixOS module configured in `darwin/secrets.nix`:

```nix
 age.secrets = {
   newsecret = {
    file = ../secrets/newsecret.age;
    path = "";
   }
 }
```

These steps ensure that the new secret is encrypted using age, and that the age NixOS module can decrypt it during rebuild.
