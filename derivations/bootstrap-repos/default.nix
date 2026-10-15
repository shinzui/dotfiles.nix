{ lib, writeShellApplication, python3, git }:

writeShellApplication {
  name = "bootstrap-repos";
  runtimeInputs = [ python3 git ];
  text = ''
    exec python3 ${./bootstrap-repos.py} "$@"
  '';

  meta = with lib; {
    description = "Export Mori's local checkouts and clone them on another machine";
    mainProgram = "bootstrap-repos";
    platforms = platforms.unix;
  };
}
