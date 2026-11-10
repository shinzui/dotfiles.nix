{ config, lib, ... }:

# Maps the shared cutover phase to each host's settings for the move of the
# Rei/Mori runtime, its PostgreSQL backups and the support services from the
# source host (Sungkyung) to the destination host (Yujin). See
# docs/plans/8-move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin.md
# and docs/rei-mori-yujin-migration.md.
#
# The phase lives in one file, hosts/rei-mori-cutover-phase.nix, so each
# reviewed revision is a one-word change both hosts read identically. A host
# only takes a phase when it is built and switched, so changing the file in Git
# changes nothing until an operator switches a specific machine.
#
#   phase        source (Sungkyung)                  destination (Yujin)
#   preparation  owner, backups, support services    client of the source (tunnel, ingest, remote rei)
#   stopped      nothing (runtime, backups, support  support services only
#                services and client all off)
#   validation   client of the destination, with     owner at stage validation, backups, support
#                web and support forwards
#   active       same as validation                  owner at stage active, backups, support
let
  cfg = config.workstation.reiMoriCutover;
  isSource = cfg.role == "source";
  isDestination = cfg.role == "destination";
  destinationOwns = builtins.elem cfg.phase [ "validation" "active" ];
  isOwner = (isSource && cfg.phase == "preparation") || (isDestination && destinationOwns);
  isClient = (isDestination && cfg.phase == "preparation") || (isSource && destinationOwns);
in
{
  options.workstation.reiMoriCutover = {
    phase = lib.mkOption {
      type = lib.types.enum [ "preparation" "stopped" "validation" "active" ];
      description = "Shared cutover phase, set once in hosts/rei-mori-cutover-phase.nix.";
    };
    role = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "source" "destination" ]);
      default = null;
      description = "This host's role in the cutover; null leaves the runtime, backup, support and client settings to the host.";
    };
  };

  config = lib.mkIf (cfg.role != null) {
    workstation.reiMori.enable = isOwner;
    workstation.reiMori.stage = if cfg.phase == "validation" then "validation" else "active";
    services.postgresql.backups.enable = isOwner;
    workstation.supportServices.enable = isDestination || cfg.phase == "preparation";
    workstation.reiMoriClient.enable = isClient;
  };
}
