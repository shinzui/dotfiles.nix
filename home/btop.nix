{ ... }:

{
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.btop.enable
  programs.btop = {
    enable = true;
  };

  # https://github.com/aristocratos/btop#configurability
  programs.btop.settings = {
    color_theme = "nord";
    vim_keys = true;
  };
}
