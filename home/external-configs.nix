{ config, ... }: {
  home.file.".psqlrc".source = ../config/psqlrc;
  home.file."${config.xdg.configHome}/yamllint/config".source=../config/yamllint;
  home.file."${config.xdg.configHome}/pspg/pspgconf".source=../config/pspg/pspgconf;
  home.file."${config.xdg.configHome}/pspg/.pspg_theme_onenord".source=../config/pspg/pspg_theme_onenord;
  home.file."${config.xdg.configHome}/pgcli/config".source=../config/pgcli;
  home.file."${config.xdg.configHome}/bird/config.json5".source=../config/bird.json5;
}
