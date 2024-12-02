self: super: {
  curl = super.curl.overrideAttrs (oldAttrs: rec {
    version = "8.10.1";
    src = super.fetchurl {
      url = "https://curl.se/download/curl-${version}.tar.gz";
      sha256 = "sha256-0V66t2XXk+LpbbCQ8OFy0SeFnXjKb2OR1+r+z9iUu8A=";
    };
  });
}

