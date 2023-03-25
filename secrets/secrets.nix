let
  shinzui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFr90yzWnHzUraT2owYt2MR9snqFNhVcP33l4agGJZ7R";
  sungkyung = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItAXkqDeYi7Ipxhfu0Q2gIjS4EI6FOupN7JSJ4DJjma";
in
{
  "netrc.age".publicKeys = [ shinzui sungkyung];
}
