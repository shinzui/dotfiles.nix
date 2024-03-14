self: super:

{
  sesh = super.sesh.overrideAttrs (oldAttrs: rec {
    version = "0.15.0";
    src = super.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "sesh";
      rev = "v${version}";
      hash = "sha256-vV1b0YhDBt/dJJCrxvVV/FIuOIleTg4mI496n4/Y/Hk=";
    };

    vendorHash = "";
  });
}
