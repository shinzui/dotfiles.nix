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
      bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
      set -g detach-on-destroy off  # don't exit from tmux when closing a session
      set -gu default-command
      set -g default-shell "$SHELL"
      bind-key "T" run-shell "sesh connect $(
        sesh list -tz | fzf-tmux -p 55%,60% \
          --no-sort --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^x zoxide ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)'
      )"
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
      tmuxPlugins.tmux-fzf #Use fzf to manage your tmux work environment!
    ];
  };
}

