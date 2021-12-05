{ config, pkgs, lib, ... }:

{
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enable
  programs.zsh.enable = true;

  programs.zsh.shellAliases = with pkgs; {
    #general 
    ".." = "cd ..";

    #common cli aliases
    v = "${neovim}/bin/nvim";
    view = "v -R";
    vim = "v";



    #nix
    nb = "nix build";
    nd = "nix develop";
    nf = "nix flake";
    nr = "nix run";
    ns = "nix search";

    #modern cli tools 
    cat = "${bat}/bin/bat";
    du = "${du-dust}/bin/dust";
    ls = "${exa}/bin/exa";
    ll = "ls -l --time-style long-iso --icons";
    tree = "ls -T";
    ps = "${procs}/bin/procs";
  };
}

