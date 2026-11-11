{
  programs.git.settings.alias = {
    # Basic commands
    st = "status -sb";
    dc = "diff --cached";

    ls-ignored = "ls-files --exclude-standard --ignored --others";

    po = "push origin";
    lr = "log --name-status -3";
    lg = "log --graph --oneline --decorate";

    unstage = "restore --staged";

    # Commit commands
    amend = "commit --amend -C HEAD";
    c = "commit";
    cm = "commit -m";
    # Pairs with rebase.autosquash: `git fixup <sha>` then `git rebase -i <sha>~`
    fixup = "commit --fixup";
    # Drop the last commit but keep its changes staged
    undo = "reset --soft HEAD~1";

    # Rebase commands
    rba = "rebase --abort";
    rbc = "rebase --continue";

    #difftool
    dft = "difftool";
    dftc = "difftool --cached";
  };
}
