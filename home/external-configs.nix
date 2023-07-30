{ config, ... }: {
  home.file.".psqlrc".source = ../config/psqlrc;
  home.file."${config.xdg.configHome}/pspg/pspgconf".source=../config/pspg/pspgconf;
  home.file."${config.xdg.configHome}/pspg/.pspg_theme_onenord".source=../config/pspg/pspg_theme_onenord;
}
