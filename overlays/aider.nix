{ ... }: final: prev:
let
  version = "0.74.1";

  # NLTK data derivations
  punkt_tokenizer = prev.stdenv.mkDerivation {
    name = "nltk-punkt";
    src = prev.fetchurl {
      url = "https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/tokenizers/punkt_tab.zip";
      sha256 = "1vapcvqz71s6j3xj5ycvh6i3phcp2dhammw9azfgpvrqswinrcf2";
    };
    buildInputs = [ prev.unzip ];
    installPhase = ''
      mkdir -p $out/tokenizers
      unzip $src -d $out/tokenizers/
    '';
  };

  stopwords = prev.stdenv.mkDerivation {
    name = "nltk-stopwords";
    src = prev.fetchurl {
      url = "https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/corpora/stopwords.zip";
      sha256 = "1l819c59j87356wrnw0z458dc9wzmf660rf2xldwl9bli1wl3j8m";
    };
    buildInputs = [ prev.unzip ];
    installPhase = ''
      mkdir -p $out/corpora
      unzip $src -d $out/corpora/
    '';
  };

  # Combined NLTK data directory
  nltk_data = prev.symlinkJoin {
    name = "nltk-data";
    paths = [
      punkt_tokenizer
      stopwords
    ];
  };

  python3Override = prev.python3.override {
    packageOverrides = python-final: python-prev: {
      moviepy = final.moviepyOverride python-prev;
    };
  };

  extraDependencies = with python3Override.pkgs; [
    dataclasses-json
    deprecated
    dirtyjson
    filetype
    joblib
    llama-index-core
    llama-index-embeddings-huggingface
    marshmallow
    mpmath
    mypy-extensions
    nest-asyncio
    nltk
    safetensors
    scikit-learn
    sentence-transformers
    sqlalchemy
    sympy
    tenacity
    threadpoolctl
    transformers
    typing-inspect
    wrapt
  ];

  addDeps = pkg: pkg.overridePythonAttrs (oldAttrs: {
    dependencies = oldAttrs.dependencies ++ extraDependencies;
    makeWrapperArgs = (oldAttrs.makeWrapperArgs or [ ]) ++ [
      "--set NLTK_DATA ${nltk_data}"
    ];
  });
in
{
  aider-chat =
    let
      basePackage =
        if prev ? aider-chat && builtins.compareVersions (builtins.parseDrvName prev.aider-chat.name).version version >= 0
        then
          builtins.trace "WARNING: nixpkgs version of aider-chat is now >= ${version}. This overlay can be removed."
            prev.aider-chat.withPlaywright
        else
          builtins.trace "Using override for aider-chat ${version}"
            (prev.aider-chat.withPlaywright.overridePythonAttrs (oldAttrs: {
              inherit version;
              src = prev.fetchFromGitHub {
                owner = "paul-gauthier";
                repo = "aider";
                rev = "v${version}";
                hash = "sha256-JXzkvuSOOEUxNqF6l5USzIPftpnIW+CptEv/0yp0eGM=";
              };
            }));
    in
    addDeps basePackage;
}
