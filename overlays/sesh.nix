final: prev:

{
  sesh = prev.sesh.overrideAttrs (oldAttrs: {
    version = "master";
    src = prev.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "sesh";
      rev = "master";
      hash = "sha256-Dla43xI6y7J9M18IloSm1uDeHAhfslU56Z0Q3nVzjIk=";
    };
    vendorHash = "sha256-feqHV+48OOOR515xo6wyE9RIvYNlp2+k7ckmC7yCv7E=";
    proxyVendor = true;
  });
}
