{ config, pkgs, lib, ... }:

let
  home = config.home.homeDirectory;
  in
{
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enable
  programs.zsh = {
    enable = true;
  };

  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.sessionVariables
  programs.zsh.sessionVariables = {
     EDITOR = "nvim";
     MANPAGER="nvim +Man!";
     #needed by lazydocker to connect to docker daemon managed by colima
     DOCKER_HOST="unix://${home}/.colima/docker.sock";
  };

  programs.zsh.shellAliases = with pkgs; {
    #general 
    ".." = "cd ..";

    #common cli aliases
    v = "nvim";
    view = "v -R";

    ###Kubernetes
    k = "kubectl";
    kg = "kubectl get";
    kd = "kubectl describe";
    kgp = "kg pods";
    kdp = "kd pods";
    kgs = "kg service";
    kds = "kd service";
    kgd = "kg deployment";
    kex = "kubectl exec -it";

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
    lsa = "ll -a";
    tree = "ls -T";
    ps = "${procs}/bin/procs";
    top = "${bottom}/bin/btm";
    watch = "${viddy}/bin/viddy";

    #lazydocker
    lzd = "${lazydocker}/bin/lazydocker";

    ###weather
    laWeather = "noglob curl -4 http://wttr.in/DTLA?m";
    sfWeather = "noglob curl -4 http://wttr.in/SF?m";
    seoulWeather = "noglob curl -4 http://wttr.in/Seoul?m";
    tokyoWeather = "noglob curl -4 http://wttr.in/Tokyo?m";
    nyWeather = "noglob curl -4 http://wttr.in/NY?m";

  };
}

