let
  shinzui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFr90yzWnHzUraT2owYt2MR9snqFNhVcP33l4agGJZ7R";
  sungkyung = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItAXkqDeYi7Ipxhfu0Q2gIjS4EI6FOupN7JSJ4DJjma";
  shinzuiAtSungkyung = [ shinzui sungkyung ];
in
{
  "sesh.toml.age".publicKeys = shinzuiAtSungkyung;
  "mori-rei-app-webhook-secret.age".publicKeys = shinzuiAtSungkyung;
  "rei-api-tokens.age".publicKeys = shinzuiAtSungkyung;
}
