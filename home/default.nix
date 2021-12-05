{ config, pkgs, lib, ... }:

{
  # Import config broken out into files
  imports = [
    ./git.nix
    ./neovim.nix
    ./zsh.nix
    ./shells.nix
  ];


  # Packages with configuration {{{


  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config = {
    style = "plain";
  };

  # Direnv, load and unload environment variables depending on the current directory.
  # https://direnv.net
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  #A command-line fuzzy finder
  #https://github.com/junegunn/fzf
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.fzf.enable
  programs.fzf.enable = true;


  #Github's official cli
  #https://github.com/cli/cli
  #https://rycee.gitlab.io/home-manager/options.html#opt-programs.gh.enable
  programs.gh.enable = true;

  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;



  # }}}

  # Other packages {{{

  home.packages = with pkgs; [
    coreutils
    curl
    du-dust #Fancy `du` https://github.com/bootandy/dust
    exa #fancy `ls`
    procs #fancy `ps`
    ripgrep
    wget

    # Dev packages
    google-cloud-sdk
    cloud-sql-proxy
    haskellPackages.cabal-install
    haskellPackages.hoogle
    tokei #source code line counter
    nixpkgs-fmt #nix formatter

    ## kubernetes
    kubectl
    krew

    ## Language servers
    haskell-language-server
    rnix-lsp
    terraform-lsp




    #Nix related tools
    cachix
  ];

  # }}}
}
