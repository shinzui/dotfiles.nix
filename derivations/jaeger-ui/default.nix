{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs_24
}:

buildNpmPackage rec {
  pname = "jaeger-ui";
  version = "1.76.0";

  src = fetchFromGitHub {
    owner = "jaegertracing";
    repo = "jaeger-ui";
    rev = "v${version}";
    hash = "sha256-OSwz8xymYenPMcCQZ5ePP7PSvhtsKl916+0pl90VYfo=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-3RsERTE1coBfck0r0yXl2JjyzxKATvXoVtWKqYsowQI=";

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/jaeger-ui"
    cp -R packages/jaeger-ui/build/. "$out/share/jaeger-ui/"

    runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    description = "Static web UI for querying and visualizing Jaeger-compatible traces";
    homepage = "https://github.com/jaegertracing/jaeger-ui";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
