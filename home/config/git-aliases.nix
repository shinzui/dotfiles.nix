{
  programs.git.settings.alias = {
    # Basic commands
    st = "status -sb";
    dc = "diff --cached";

    ls-ignored = "ls-files --exclude-standard --ignored --others";

    po = "push origin";
    lr = "log --name-status -3";

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
