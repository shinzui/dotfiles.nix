{ config, pkgs, lib, ... }:

let
  myNodePackages = import ../packages/node { pkgs = pkgs; };
  fzfConfig =
    let fd = "${pkgs.fd}/bin/fd"; in
    rec {
      defaultCommand = "${fd} --type f";
      defaultOptions = [ "--height 50%" ];
      fileWidgetCommand = "${defaultCommand}";
      fileWidgetOptions = [
        "--preview '${pkgs.bat}/bin/bat --color=always --plain --line-range=:200 {}'"
      ];
      changeDirWidgetCommand = "${fd} --type d";
      changeDirWidgetOptions =
        [ "--preview '${pkgs.tree}/bin/tree -C {} | head -200'" ];
      historyWidgetOptions = [ ];
    };
in
{
  # Import config broken out into files
  imports = [
    ./git.nix
    ./neovim.nix
    ./zsh.nix
    ./shells.nix
    ./tmux.nix
  ];


  # Packages with configuration 


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
  programs.fzf =
    {
      enable = true;
      enableZshIntegration = true;
    } // fzfConfig;


  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;


  #Broot. Better directory navigation
  #https://github.com/Canop/broot
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.broot.enable
  programs.broot = {
    enable = true;
    settings.modal = true;
  };

  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.atuin.enable
  #https://github.com/ellie/atuin/blob/main/docs/config.md
  programs.atuin = {
    enable = true;
    settings = {
      search_mode = "fulltext";
    };
  };



  # Other packages 
  home.packages = with pkgs; [
    bandwhich #bandwidth utilization tool
    bottom #Fancy `top`
    #coreutils
    curl
    dateutils
    du-dust #Fancy `du` https://github.com/bootandy/dust
    exa #fancy `ls`
    difftastic # syntax-aware diff tool
    dogdns # dns client
    lazydocker #docker terminal UI https://github.com/jesseduffield/lazydocker
    hyperfine #benchmarking
    xh #xh http tool
    fd #fancy `find`
    miller #like awk, sed, cut, join, and sort for CSV and tabular JSON
    navi #interactive cli cheat sheet
    procs #fancy `ps`
    ripgrep
    retry #https://github.com/minfrin/retry
    gnused
    sd # `sed` and `awk` replacement
    tree
    tealdeer #fasts impl of tldr in rust
    rargs # `xargs` + `awk`
    # watchexec
    watchman
    viddy # modern watch
    vivid #A themeable LS_COLORS generator 
    wget
    xsv
    imagemagick
    jpegoptim
    rnr #cli to batch rename files and dirs

    #desktop apps
    element-desktop

    # Dev packages
    angle-grinder #Fast log processor
    git-extras
    git-absorb
    gitui #terminal git UI written in rust
    (google-cloud-sdk.withExtraComponents ([ google-cloud-sdk.components.gke-gcloud-auth-plugin ]))
    cloud-sql-proxy
    dhall
    dhall-json
    docker
    colima #containers in Lima
    hadolint #dockerfile linter
    just
    postgresql_14
    treefmt
    yarn
    # deno
    nodePackages.prettier
    nodePackages.graphql-language-service-cli

    ## Haskell
    ghc
    hlint
    haskellPackages.cabal-install
    haskellPackages.hoogle
    haskellPackages.ormolu
    haskellPackages.implicit-hie
    haskellPackages.cabal-fmt
    haskellPackages.cabal-plan

    ## OCaml
    #ocaml
    #dune-release
    #opam

    ## Rust
    cargo

    tokei #source code line counter
    nixpkgs-fmt #nix formatter
    stylua #lua formatter
    nodePackages.typescript
    nodejs
    bun
    jq

    ## kubernetes
    kubectl
    kubernetes-helm
    krew
    k9s

    ## Language servers
    # haskell-language-server
    dhall-lsp-server
    nodePackages.typescript-language-server
    rnix-lsp
    terraform-ls
    ocamlPackages.ocaml-lsp
    sumneko-lua-language-server
    yaml-language-server
    nodePackages.vscode-langservers-extracted
    myNodePackages.ls_emmet
    #myNodePackages."@idleberg/caniuse-cli"
    # myNodePackages."@tailwindcss/language-server"

    #Nix related tools
    cachix
    hydra-check
    manix #nix documentation lookup
    nix-prefetch-git
    nix-tree
    nodePackages.node2nix
    nix-script
  ];

  # 

}
# vim: foldmethod=marker
