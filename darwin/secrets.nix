{ ... }:

{
  age.identityPaths = [ "/Users/shinzui/.ssh/id_ed25519" ];
  age.secrets.netrc = {
    file = ../secrets/netrc.age;
    path = "/Users/shinzui/.netrc";
    mode = "700";
    owner = "shinzui";
  };
}
