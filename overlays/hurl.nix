self: super:

{
  hurl = super.hurl.overrideAttrs (oldAttrs: rec {
    version = "4.2.0"; # Update the version number if necessary
    src = super.fetchFromGitHub {
      owner = "Orange-OpenSource";
      repo = "hurl";
      rev = version;
      hash = "sha256-77RGS4B5Jwb/J5eOG2A7sdfAU7PnRaxqz5nogpOnj70="; # Update the hash if necessary
    };

    cargoDeps = oldAttrs.cargoDeps.overrideAttrs (self.lib.const {
      name = "hurl-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-uk2kJE5N6tocUNejuB78/AsPY9seI8HnM66y9yqd/l0=";
    });
  });

}
