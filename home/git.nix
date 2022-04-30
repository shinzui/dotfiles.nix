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



    extraConfig = {
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
      apply.whitespace = "nowarn";
      url = {
        "https://github.com/" = { insteadOf = "gh:"; };
        "ssh://git@github.com/" = { insteadOf = "sgh:"; };
      };
      init.defaultBranch = "master";
      diff = {
        tool = "difftastic";
      };

      difftool = {
        prompt = false;

        difftastic = {
          cmd = ''difft "$LOCAL" "$REMOTE"'';
        };
      };

      pager = {
        difftool = true;
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
    ];
  };

  # GitHub CLI
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.gh.enable
  programs.gh.enable = true;
  programs.gh.settings.git_protocol = "ssh";
}
