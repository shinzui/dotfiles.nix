# 
final: prev:

{
  trurl = prev.trurl.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [] ++ [(prev.fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/curl/trurl/pull/240.patch";
      sha256 = "0hcrjp11m07m797hzcfvnba8ph7b14csmf1hx423y6zcfgm3lnpy"; # Replace with the actual sha256 value
    })];
  });
}

