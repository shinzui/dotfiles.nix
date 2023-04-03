let
  shinzui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFr90yzWnHzUraT2owYt2MR9snqFNhVcP33l4agGJZ7R";
  sungkyung = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItAXkqDeYi7Ipxhfu0Q2gIjS4EI6FOupN7JSJ4DJjma";
  shinzuiAtSungkyung = [ shinzui sungkyung ];
in
{
  "netrc.age".publicKeys = shinzuiAtSungkyung;
  "npmrc.age".publicKeys = shinzuiAtSungkyung;
  "access_tokens.conf.age".publicKeys = shinzuiAtSungkyung;
}
