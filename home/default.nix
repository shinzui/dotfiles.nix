{ config, pkgs, lib, ... }:

let
  myNodePackages = import ../packages/node {
    inherit pkgs;
    system = pkgs.stdenv.hostPlatform.system;
  };
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
    ./navi.nix
    ./btop.nix
    ./cachix.nix
    ./pay-respects.nix
    ./carapace.nix
    ./external-configs.nix
    ./television.nix
    ./nix-search-tv.nix
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
    enable = false;
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
    # curl-impersonate
    (trurl.overrideAttrs (oldAttrs: { doCheck = false; })) # url parsing & manipulation (tests disabled)
    hurl #run & test http requests
    openapi-tui #OpenAPI TUI
    oq #OpenAPI spec viewer
    httpstat # output curl statistics 
    lychee #link checker
    caddy #web server with automatic HTTPS
    dateutils
    uuinfo #debug unique identifiers (UUID, ULID, Snowflake, etc)
    ck #semantic code search
    moreutils #collection of unix tools
    dust #Fancy `du` https://github.com/bootandy/dust
    eza #fancy `ls`
    lstr # tree viewer
    fdupes # find & delete duplicate files
    difftastic # syntax-aware diff tool
    lazydocker #docker terminal UI https://github.com/jesseduffield/lazydocker
    hyperfine #benchmarking
    xh #xh http tool
    websocat #WebSocket CLI client (curl for WebSockets)
    k6 # load testing tool
    trippy # network dianostic tool
    snitch #inspect network connections
    fd #fancy `find`
    miller #like awk, sed, cut, join, and sort for CSV and tabular JSON
    parqeye #Parquet file viewer for the terminal
    procs #fancy `ps`
    ripgrep
    ripgrep-all
    pspg #pager for psql
    jacinda # functional data processing
    ast-grep 
    hwatch
    biff
    ffmpeg
    exiftool
    silicon # Create beautiful image of your source code

    retry #https://github.com/minfrin/retry
    gnused
    sd # `sed` and `awk` replacement
    tree
    tealdeer #fasts impl of tldr in rust
    watchexec
    watchman
    viddy # modern watch
    vivid #A themeable LS_COLORS generator 
    xan # csv power tool
    wget
    imagemagick
    jpegoptim
    rnr #cli to batch rename files and dirs
    pigz # modern gzip
    kondo # clean software project files
    yt-dlp
    jujutsu # git-compatible VCS
    worktrunk # git worktree management for AI agents
    _1password-cli #1password cli
    duti # select default apps for file types
    sesh # smart session manager for tmux
    tmuxp # tmux session manager

    pandoc
    glow #cli markdown viewer
    presenterm #markdown terminal slideshow tool
    # monolith # CLI tool for saving complete web pages

    #人工知能
    # aider-chat.withPlaywright #AI pair programming
    repomix
    claude-code
    goose-cli
    tmuxai

    #desktop apps
    element-desktop

    # Dev packages
    angle-grinder #Fast log processor
    git-extras
    git-absorb
    mergiraf # syntax-aware git merge driver
    gh-dash # enhanced gh
    # gitui #terminal git UI written in rust (disabled due to build failures on ARM64)
    zsh-forgit #zsh plugin to load forgit via `git forgit`
    (google-cloud-sdk.withExtraComponents ([ google-cloud-sdk.components.gke-gcloud-auth-plugin google-cloud-sdk.components.alpha google-cloud-sdk.components.beta google-cloud-sdk.components.log-streaming ]))
    google-cloud-sql-proxy
    dhall
    dhall-json
    nickel
    docker
    colima #containers in Lima
    hadolint #dockerfile linter
    sops
    just
    postgresql_17
    treefmt
    pgformatter
    pgcli
    harlequin # DB client that supports duckdb and postgresql
    nodePackages.prettier
    # nodePackages.graphql-language-service-cli
    nodePackages.pnpm
    lazygit
    # duckdb
    devenv
    uv
    
    #record cli session
    asciinema
    asciinema-agg

    ##terminfo
    wezterm.terminfo

    ## Haskell
    ghc
    hlint
    pkgs.hackage-diff
    haskellPackages.cabal-install
    haskellPackages.hoogle
    # haskellPackages.ormolu
    haskellPackages.implicit-hie
    haskellPackages.cabal-fmt
    # haskellPackages.cabal-plan
    # haskellPackages.cabal-hoogle

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
    nodejs_22
    bun
    jq
    yq-go #jq for yaml
    gron #make json greppaple
    yamllint
    yamlfmt

    ## kubernetes
    kubectl
    kubernetes-helm
    kustomize
    krew
    k9s
    argocd
    argocd-autopilot
    stern
    kubetail
    kubefwd
    gonzo # log analysis

    ## Language servers
    haskell-language-server
    dhall-lsp-server
    nls # nickel language server
    nodePackages.typescript-language-server
    nil #nix language server
    terraform-ls
    ocamlPackages.ocaml-lsp
    lua-language-server
    yaml-language-server
    nodePackages.vscode-langservers-extracted
    myNodePackages."@tailwindcss/language-server"
    myNodePackages.ls_emmet

    #Nix related tools
    cachix
    comma #run anything from nixpkgs without installing it
    statix 
    deadnix
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
