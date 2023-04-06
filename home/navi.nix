{ ... }:

{
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.navi.enable
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };

  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.navi.settings
  # https://github.com/denisidoro/navi/blob/master/docs/config_file.md#example
  programs.navi.settings = {
    cheats.paths = [
      "~/Keikaku/bokuno/navi-cheats/"
    ];
  };
}
