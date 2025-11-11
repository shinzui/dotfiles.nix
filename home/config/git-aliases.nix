{
  programs.git.settings.alias = {
    # Basic commands
    st = "status -sb";
    dc = "diff --cached";

    ls-ignored = "ls-files --exclude-standard --ignored --others";

    # Commit commands
    amend = "commit --amend -C HEAD";
    c = "commit";
    cm = "commit -m";

    # Rebase commands
    rba = "rebase --abort";
    rbc = "rebase --continue";

    #difftool
    dft = "difftool";
  };
}
