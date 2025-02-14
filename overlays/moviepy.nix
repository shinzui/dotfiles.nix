final: prev: {
  moviepyOverride = python-prev: python-prev.moviepy.overrideAttrs (oldAttrs: {
    doCheck = false;
    doInstallCheck = false;
    pythonImportsCheck = [];
    checkInputs = [];
    nativeCheckInputs = [];
    checkPhase = "true";
    installCheckPhase = "true";
  });

  python3 = prev.python3.override {
    packageOverrides = python-final: python-prev: {
      moviepy = final.moviepyOverride python-prev;
    };
  };
  python3Packages = final.python3.pkgs;
}

