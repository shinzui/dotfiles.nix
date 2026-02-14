let
  shinzui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFr90yzWnHzUraT2owYt2MR9snqFNhVcP33l4agGJZ7R";
  sungkyung = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItAXkqDeYi7Ipxhfu0Q2gIjS4EI6FOupN7JSJ4DJjma";
  shinzuiAtSungkyung = [ shinzui sungkyung ];
in
{
  "netrc.age".publicKeys = shinzuiAtSungkyung;
  "npmrc.age".publicKeys = shinzuiAtSungkyung;
  "access_tokens.conf.age".publicKeys = shinzuiAtSungkyung;
  "openai.age".publicKeys = shinzuiAtSungkyung;
  "cachix_auth_token.dhall.age".publicKeys = shinzuiAtSungkyung;
  "tableplus_gcp_service_account.json.age".publicKeys = shinzuiAtSungkyung;
  "cai_secrets.yaml.age".publicKeys = shinzuiAtSungkyung;
  "pgpass.age".publicKeys = shinzuiAtSungkyung;
  "aider.conf.yml.age".publicKeys = shinzuiAtSungkyung;
  "llm-keys.json.age".publicKeys = shinzuiAtSungkyung;
  "tmuxai.config.yaml.age".publicKeys = shinzuiAtSungkyung;
  "sesh.toml.age".publicKeys = shinzuiAtSungkyung;
  "cabal.age".publicKeys = shinzuiAtSungkyung;
}
