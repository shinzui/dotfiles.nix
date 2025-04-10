{ config, pkgs, lib, ... }:

let
  home = config.home.homeDirectory;
in
{
  #https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable
  programs.zsh = {
    enable = true;
  };

  #https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.sessionVariables
  programs.zsh.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
    #needed by lazydocker to connect to docker daemon managed by colima
    DOCKER_HOST = "unix://${home}/.colima/docker.sock";
    LS_COLORS = "${pkgs.vivid}/bin/vivid generate nord";
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
    PSPG_CONF = "${config.xdg.configHome}/pspg/pspgconf";
    #temp workaround for home-manager generating the config in the wrong location
    NAVI_CONFIG = "/Users/shinzui/Library/Application Support/navi/config.yaml";
    PATH="$HOME/.npm-global/bin:$PATH";
  };

  programs.zsh.initExtra = ''
    ZVM_INIT_MODE=sourcing
    source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    unset ZVM_INIT_MODE
  '';

  programs.zsh.shellAliases = with pkgs; {
    #general 
    ".." = "cd ..";

    #common cli aliases
    v = "nvim";
    view = "v -R";
    vim = "nvim";
    vimdiff = "nvim -d";
    ":q" = "exit";

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

    formatjson = "f() {jq . $1 | sponge $1};f";

    #modern cli tools 
    cat = "${bat}/bin/bat";
    du = "${du-dust}/bin/dust";
    ls = "${eza}/bin/eza";
    ll = "ls -l --time-style long-iso --icons";
    lsa = "ll -a";
    tree = "ls -T";
    ps = "${procs}/bin/procs";
    top = "${btop}/bin/btop";
    watch = "${viddy}/bin/viddy";

    #lazydocker
    lzd = "${lazydocker}/bin/lazydocker";

    ###weather
    laWeather = "noglob curl -4 http://wttr.in/DTLA?m";
    sfWeather = "noglob curl -4 http://wttr.in/SF?m";
    seoulWeather = "noglob curl -4 http://wttr.in/Seoul?m";
    tokyoWeather = "noglob curl -4 http://wttr.in/Tokyo?m";
    nyWeather = "noglob curl -4 http://wttr.in/NY?m";

    ###markdown
    viewMd = "glow -p -w 200";
  };
}

