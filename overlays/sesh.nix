final: prev:

{
  sesh = prev.sesh.overrideAttrs (oldAttrs: {
    version = "master";
    src = prev.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "sesh";
      rev = "master";
      hash = "sha256-5n2mlTAJKByPyw0VMv+0oJHXka5IoI25RlAm1LJe/nQ=";
    };
    vendorHash = "sha256-IqS8HSrMvD0uJbdndaX7f+2VJfKIRm2+p9NomBoXpyU=";
    proxyVendor = true;
    doCheck = false;
  });
}
