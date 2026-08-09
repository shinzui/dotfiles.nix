# A local Redpanda cluster (Kafka-compatible) running on Apple Container.
#
# The module itself lives in the redpanda-container flake and is registered in
# flake-modules/modules.nix; this file only turns it on. It installs
# redpanda-up / redpanda-down / redpanda-status / redpanda-logs / redpanda-purge
# and a launchd agent (com.shinzui.redpanda) that brings the cluster up at login.
#
# Everything else is left at the module's defaults on purpose: they already
# encode the naming, labelling, and port contract that the rpk profile and the
# runbook depend on, and restating a default here is just something to drift.
# See docs/redpanda.md for operations, and the module's own README for options.
#
#   Kafka            127.0.0.1:9092
#   Admin API        127.0.0.1:9644
#   Schema Registry  127.0.0.1:8081
#   HTTP Proxy       127.0.0.1:8082
#   Console          http://127.0.0.1:8080  (also http://redpanda.localhost)
#
# `services.redpanda-container.package` defaults to `pkgs.container`, which the
# my-packages overlay shadows with the pinned Apple Container build from
# derivations/apple-container.nix.
{ lib, ... }:

{
  services.redpanda-container.enable = true;

  # Ensure an rpk profile pointing at this cluster, so `rpk topic list` works
  # from any directory with no --brokers and no per-project configuration.
  #
  # Created imperatively rather than written declaratively with home.file. rpk
  # owns ~/Library/Application Support/rpk/rpk.yaml -- every `rpk profile`
  # command rewrites it -- so declaring it here would revert any profile the
  # user adds by hand on the next rebuild, and home-manager would rename the
  # existing file to rpk.yaml.backup on first activation. Letting rpk write its
  # own file keeps it the authority on its schema (the file carries a
  # `version:` field that a future rpk could bump). This mirrors how
  # home/postgresql.nix uses initdb and pg-ensure-db rather than declaring a
  # data directory.
  #
  # Only creates the profile when absent, so a profile edited by hand survives.
  # rpk comes from Homebrew, not Nix, so the path is explicit and a missing rpk
  # is skipped rather than failing the switch.
  home.activation.redpanda-rpk-profile =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rpkBin=/opt/homebrew/bin/rpk

      if [ ! -x "$rpkBin" ]; then
        verboseEcho "rpk not found at $rpkBin; skipping rpk profile setup"
      elif "$rpkBin" profile list 2>/dev/null | grep -qE '^local\*?[[:space:]]'; then
        verboseEcho "rpk profile 'local' already exists"
      else
        verboseEcho "Creating rpk profile 'local'"
        # `rpk profile create` also switches to the new profile.
        run "$rpkBin" profile create local \
          --description "Local Redpanda on Apple Container (managed by home/redpanda.nix)" \
          --set kafka_api.brokers=127.0.0.1:9092 \
          --set admin_api.addresses=127.0.0.1:9644 \
          --set schema_registry.addresses=127.0.0.1:8081 \
          || warnEcho "Could not create the rpk profile; create it by hand (see docs/redpanda.md)"
      fi
    '';
}
