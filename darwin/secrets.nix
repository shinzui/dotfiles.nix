{ ... }:

{
  age.identityPaths = [ "/Users/shinzui/.ssh/id_ed25519" ];
  age.secrets = {
    netrc = {
      file = ../secrets/netrc.age;
      path = "/Users/shinzui/.netrc";
      mode = "700";
      owner = "shinzui";
    };
    npmrc = {
      file = ../secrets/npmrc.age;
      path = "/Users/shinzui/.npmrc";
      mode = "700";
      owner = "shinzui";
    };
    access_token = {
      file = ../secrets/access_tokens.conf.age;
      mode = "700";
      owner = "shinzui";
    };
    openapi_secret = {
      file = ../secrets/openai.age;
      path = "/Users/shinzui/.openapi_secret";
      mode = "700";
      owner = "shinzui";
    };
    cachix-authtoken = {
      file = ../secrets/cachix_auth_token.dhall.age;
      mode = "700";
      owner = "shinzui";
    };
    tableplus-gcp-service-account = {
      file = ../secrets/tableplus_gcp_service_account.json.age;
      path = "/Users/shinzui/.config/gcloud/tableplus_gcp_service_account.json";
      mode = "700";
      owner = "shinzui";
    };
    cai-secrets = {
      file = ../secrets/cai_secrets.yaml.age;
      path = "/Users/shinzui/.config/cai/secrets.yaml";
      mode = "700";
      owner = "shinzui";
    };
    pgpass = {
      file = ../secrets/pgpass.age;
      path = "/Users/shinzui/.pgpass";
      mode = "600";
      owner = "shinzui";
    };
    aider-conf = {
      file = ../secrets/aider.conf.yml.age;
      path = "/Users/shinzui/.aider.conf.yml";
      mode = "600";
      owner = "shinzui";
    };
    datasette-llm-keys = {
      file = ../secrets/llm-keys.json.age;
      path = "/Users/shinzui/Library/Application Support/io.datasette.llm/keys.json";
      mode = "600";
      owner = "shinzui";
    };
  };
}
