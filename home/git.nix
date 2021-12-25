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
      rerere.enabled = 1;
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
    };
  };

  # GitHub CLI
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.gh.enable
  programs.gh.enable = true;
  programs.gh.settings.git_protocol = "ssh";
}
