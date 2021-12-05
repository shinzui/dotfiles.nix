{ config, pkgs, lib, ... }:

{
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enable
  programs.zsh.enable = true;

  programs.zsh.shellAliases = with pkgs; {
    cat = "${bat}/bin/bat";
    du = "${du-dust}/bin/dust";
    ls = "${exa}/bin/exa";
    tree = "ls -T";
    ps = "${procs}/bin/procs";
  };
}

