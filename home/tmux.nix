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
      # https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6
      set -sg terminal-overrides ",*:RGB"

      set -g mouse on

      # Set terminal title to tmux session name
      set-option -g set-titles on
      set-option -g set-titles-string "#S"

      set-option -g renumber-windows on
      set -as terminal-features ',screen-256color:RGB'
      set -g detach-on-destroy off  # don't exit from tmux when closing a session
      set -gu default-command
      set -g default-shell "$SHELL"

      # Focus on active pane - dim inactive panes
      # Uses Nord-compatible colors: Nord0 (#2E3440) for active, Nord1 (#3B4252) for inactive
      set -g window-style 'fg=colour248,bg=#3B4252'
      set -g window-active-style 'fg=default,bg=#2E3440'

      # Pane borders - Nord3 for inactive, Nord8 (frost blue) for active
      set -g pane-border-style 'fg=#4C566A,bg=default'
      set -g pane-active-border-style 'fg=#88C0D0,bg=default'
      bind-key "T" run-shell "sesh connect \"$(
        sesh list --icons | fzf-tmux -p 80%,70% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
          --preview-window 'right:55%' \
          --preview 'sesh preview {}'
      )\""
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
      tmuxPlugins.extrakto #extract text without using mouse 
    ];
  };
}

