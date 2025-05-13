{ pkgs, lib, ... }:

{
  # Git
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.git.enable
  # Aliases config imported in flake.
  programs.git.enable = true;

  programs.git = {
    userEmail = "nadeem@gmail.com";
    userName = "Nadeem Bitar";

    delta = {
      enable = true;
      options = {
        dark = true;
        syntax-theme = "Nord";
      };
    };
    lfs.enable = true;

    includes = [
      {
        condition = "gitdir:~/Keikaku/work/";
        contents.user = {
          email = "nadeem@topagentnetwork.com";
        };
      }
    ];

    extraConfig = {
      alias = {
        dft = "difftool";
        fpush = "push --force-with-lease";
      };
      credential.helper =
        if pkgs.stdenvNoCC.isDarwin then
          "osxkeychain"
        else
          "cache --timeout=1000000000";
      core = {
        editor = "nvim";
        ignorecase = false;
      };
      rerere.enabled = true;
      push = {
        default = "tracking";
        followTags = true;
      };
      pull = {
        rebase = true;
      };

      rebase = {
        # stash before rebase then pop the stash after
        autostash = true;
        # --autosquash always gets passed automatically to git rebase
        autosquash = true;
      };
      apply.whitespace = "nowarn";
      url = {
        "https://github.com/" = { insteadOf = "gh:"; };
        "ssh://git@github.com/" = { insteadOf = "sgh:"; };
      };
      init.defaultBranch = "master";
      diff = {
        tool = "difftastic";
        algorithm = "histogram";
      };

      difftool = {
        prompt = false;

        difftastic = {
          cmd = ''difft "$LOCAL" "$REMOTE"'';
        };
      };
      branch = {
        sort = "-committerdate";
      };
      

      pager = {
        difftool = true;
      };
      blame = {
        # can't set globally since it would break git blame if the file is missing
        #ignoreRevsFile = ".git-blame-ignore-revs";
        # Mark any lines that have had a commit skipped using --ignore-rev with a `?`
        markIgnoredLines = true;
        # Mark any lines that were added in a skipped commit and can not be attributed with a `*`
        markUnblamableLines = true;
      };
    };

    ignores = [
      ".DS_STORE"
      ".DS_Store"
      "*~"
      "*.bak"
      "*.log"
      "*.swp"
      "node_modules"
      ".direnv/"
      ".vim-bookmarks"
      ".devenv/"
    ];
  };

  # GitHub CLI
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.gh.enable
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      # Workaround for https://github.com/nix-community/home-manager/issues/4744
      version = 1;
    };
  };
}
