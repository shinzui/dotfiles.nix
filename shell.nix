{ pkgs, agenix, system }:
pkgs.mkShell {
  nativeBuildInputs = [ agenix.packages.${system}.agenix ];
}
