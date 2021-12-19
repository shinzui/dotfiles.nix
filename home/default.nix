{ config, pkgs, lib, ... }:

{
  # Import config broken out into files
  imports = [
    ./git.nix
    ./neovim.nix
    ./zsh.nix
    ./shells.nix
    ./tmux.nix
  ];


  # Packages with configuration {{{


  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config.theme = "Nord";

  # Direnv, load and unload environment variables depending on the current directory.
  # https://direnv.net
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  #A command-line fuzzy finder
  #https://github.com/junegunn/fzf
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.fzf.enable
  programs.fzf.enable = true;


  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;


  #Broot. Better directory navigation
  #https://github.com/Canop/broot
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.broot.enable
  programs.broot = {
    enable = true;
    modal = true;
  };

  #Broken on aarch64-darwin
  #programs.atuin = {
  #  enable = true;
  #};



  # }}}

  # Other packages {{{

  home.packages = with pkgs; [
    bottom #Fancy `top`
    #coreutils
    curl
    #dateutils
    du-dust #Fancy `du` https://github.com/bootandy/dust
    exa #fancy `ls`
    hyperfine #benchmarking
    fd #fancy `find`
    procs #fancy `ps`
    ripgrep
    sd # `sed` and `awk` replacement
    rargs # `xargs` + `awk`
    #watchexec
    wget
    xsv

    # Dev packages
    angle-grinder #Fast log processor
    git-extras
    google-cloud-sdk
    cloud-sql-proxy
    dhall
    dhall-json

    ## Haskell
    haskellPackages.cabal-install
    haskellPackages.hoogle
    haskellPackages.implicit-hie

    ## OCaml
    ocaml
    dune-release
    opam

    ## Rust
    cargo

    tokei #source code line counter
    nixpkgs-fmt #nix formatter
    stylua #lua formatter
    nodePackages.typescript
    nodejs
    jq

    ## kubernetes
    kubectl
    kubernetes-helm
    krew

    ## Language servers
    haskell-language-server
    dhall-lsp-server
    nodePackages.typescript-language-server
    rnix-lsp
    terraform-lsp
    ocamlPackages.ocaml-lsp

    #Nix related tools
    cachix
    manix #nix documentation lookup
    nix-prefetch-git
  ];

  # }}}

}
# vim: foldmethod=marker
