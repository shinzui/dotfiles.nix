# worktrunk's shell-probe tests read the OS process table, which the Nix
# sandbox blocks on Darwin, so they panic with "own pid must be readable from
# the process table" / "child sh must be visible to the probe". The rest of the
# suite (1371 tests) passes; skip just these two.
final: prev: {
  worktrunk = prev.worktrunk.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=shell::utils::tests::test_process_name_and_ppid_self"
      "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
    ];
  });
}
