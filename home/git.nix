{ pkgs, lib, ... }:

{
  # Git
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.git.enable
  # Aliases config imported in flake.
  programs.git.enable = true;

  programs.git = {
    userEmail = "nadeem@gmail.com";
    userName = "Nadeem Bitar";

    extraConfig = {
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
}
