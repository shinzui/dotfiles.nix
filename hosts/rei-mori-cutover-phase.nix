# The one setting that moves the Rei/Mori runtime, its PostgreSQL backups and
# the support services between Sungkyung and Yujin: preparation, stopped,
# validation, or active. See home/rei-mori-cutover.nix for what each phase
# means per host, and docs/rei-mori-yujin-migration.md before changing it.
# A change here takes effect on a machine only when that machine is switched.
{
  workstation.reiMoriCutover.phase = "active";
}
