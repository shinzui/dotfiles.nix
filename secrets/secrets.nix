let
  shinzui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFr90yzWnHzUraT2owYt2MR9snqFNhVcP33l4agGJZ7R";
  sungkyung = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItAXkqDeYi7Ipxhfu0Q2gIjS4EI6FOupN7JSJ4DJjma";
  yujin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEwUtr7HH6Or2TZz+2PvrSnrvUhf8tU4/rOaMXkjikVh shinzui@yujin-agenix";
  workstationRecipients = [ shinzui sungkyung yujin ];
in
{
  "sesh.toml.age".publicKeys = workstationRecipients;
  "mori-rei-app-webhook-secret.age".publicKeys = workstationRecipients;
  "rei-api-tokens.age".publicKeys = workstationRecipients;
}
