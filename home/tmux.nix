{ pkgs, lib, ... }:

{
  #tmux
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.tmux.enable

  programs.tmux = {
    prefix = "C-a";
    enable = true;
    clock24 = true;
    historyLimit = 10000; #Maximum number of lines held in window history.
    keyMode = "vi";
    terminal = "screen-256color";
    aggressiveResize = true;
    extraConfig = ''
set-option -g renumber-windows on
set -as terminal-features ',screen-256color:RGB'
    '';

    plugins = with pkgs; [
      tmuxPlugins.sensible #basic tmux settings
      tmuxPlugins.vim-tmux-navigator #Seamless navigation between tmux panes and vim splits
      tmuxPlugins.open # Tmux key bindings for quick opening of a highlighted file or url
      tmuxPlugins.copycat #A plugin that enhances tmux search
      tmuxPlugins.yank # Tmux plugin for copying to system clipboard 
      tmuxPlugins.pain-control #manage panes
      tmuxPlugins.sessionist #Lightweight tmux utils for manipulating sessions
      tmuxPlugins.nord #Nord tmux color theme
    ];
  };
}

