{
  description = "Shinzui's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    nix-neovimplugins = { url = "github:jooooscha/nixpkgs-vim-extra-plugins"; };
    moses-lua = { url = "github:Yonaba/Moses"; flake = false; };
    vim-rescript = { url = "github:rescript-lang/vim-rescript"; flake = false; };
    vim-reasonml = { url = "github:jordwalke/vim-reasonml"; flake = false; };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , darwin
    , home-manager
    , flake-utils
    , agenix
    , nix-neovimplugins
    , ...
    }@inputs:
    let
      # Building blocks 
      inherit (darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs-unstable.lib) attrValues makeOverridable optionalAttrs singleton;
      # d = (import ./darwin)  { pkgs=nixpkgs-unstable; inherit nixpkgs-unstable; };

      # Configuration for `nixpkgs` mostly used in personal configs.
      nixpkgsConfig = {
        config = { allowUnfree = true; };
        overlays = attrValues self.overlays;
      };

      # Personal configuration shared between `nix-darwin` and plain `home-manager` configs.

      # This value determines the Home Manager release that your configuration is compatible with. This
      # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
      #
      # You can update Home Manager without changing this value. See the Home Manager release notes for
      # a list of state version changes in each release.
      homeManagerStateVersion = "23.05";

      homeManagerCommonConfig = with self.homeManagerModules; {
        imports = attrValues self.homeManagerModules ++ [
          ./home
          { home.stateVersion = homeManagerStateVersion; }
        ];
      };

      nixDarwinCommonModules = [
        {
          config._module.args = {
            inherit nixpkgs-unstable;
          };
        }
        # Include extra `nix-darwin`
        self.darwinModules.pam
        self.darwinModules.users

        agenix.darwinModules.default

        # Main `nix-darwin` config
        ./darwin

        # `home-manager` module
        home-manager.darwinModules.home-manager
        (
          { config, lib, pkgs, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            # Hack to support legacy worklows that use `<nixpkgs>` etc.
            nix.nixPath = { nixpkgs = "$HOME/.config/dotfiles.nix/nixpkgs.nix"; };
            # `home-manager` config
            users.users.${primaryUser}.home = "/Users/${primaryUser}";
            home-manager.useGlobalPkgs = true;
            home-manager.users.${primaryUser} = homeManagerCommonConfig;

            home-manager.extraSpecialArgs = {
              inherit (config) age;
            };

            # Add a registry entry for this flake
            nix.registry.my.flake = self;
            nix.registry.nixpkgs.flake = nixpkgs-unstable;
          }
        )
      ];

    in
    {
      #Various configs (only Sungkyung for now) 

      #nix-darwin configs
      darwinConfigurations = rec {
        # Mininal configurations to bootstrap systems
        bootstrap-x86 = makeOverridable darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };
        bootstrap-arm = bootstrap-x86.override { system = "aarch64-darwin"; };

        #MacBook Pro M1X
        SungkyungM1X = darwinSystem {
          system = "aarch64-darwin";
          modules = nixDarwinCommonModules ++ [
            {
              users.primaryUser = "shinzui";
              networking.computerName = "sungkyung";
              networking.hostName = "sungkyung";

              #networksetup -listallnetworkservices
              networking.knownNetworkServices = [
                "Wi-Fi"
                "Thunderbolt Bridge"
              ];
            }
          ];
        };
      };

      #

      # Outputs --- 
      overlays = {
        nix-neovimplugins = nix-neovimplugins.overlays.default;

        my-packages = final: prev: {
          cai = final.callPackage (self + "/derivations/cai.nix") {
            inherit (final) lib rustPlatform fetchFromGitHub;
          };
        };

        pkgs-master = final: prev: {
          pkgs-master = import inputs.nixpkgs {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
          };
        };

        pkgs-stable = final: prev: {
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
          };
        };

        pkgs-unstable = final: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
            overlays = [ ];
          };
        };

        # Overlay that adds various additional utility functions to `vimUtils`
        vimUtils = import ./overlays/vimUtils.nix;



        # Overlay that adds some additional Neovim plugins
        vimPlugins = final: prev:
          let
            inherit (self.overlays.vimUtils final prev) vimUtils;
          in
          {
            vimPlugins = prev.vimPlugins.extend (super: self:
              (vimUtils.buildVimPluginsFromFlakeInputs inputs [
                "vim-rescript"
                "vim-reasonml"
              ]) // {
                moses-nvim = vimUtils.buildNeovimLuaPackagePluginFromFlakeInput inputs "moses-lua";
              }
            );
          };

        # Overlay useful on Macs with Apple Silicon
        apple-silicon = final: prev: optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
          # Add access to x86 packages system is running Apple Silicon
          pkgs-x86 = import inputs.nixpkgs-unstable {
            system = "x86_64-darwin";
            inherit (nixpkgsConfig) config;
          };
        };

      };

      darwinModules = {
        users = import ./modules/darwin/users.nix;
        pam = import ./modules/darwin/pam.nix;
      };

      homeManagerModules = {
        configs-git-aliases = import ./home/config/git-aliases.nix;
        configs-gh-aliases = import ./home/config/gh-aliases.nix;
        configs-wezterm = import ./home/wezterm.nix;
        configs-starship-symbols = import ./home/config/starship-symbols.nix;
      };




    } // flake-utils.lib.eachDefaultSystem (system:
    let
      legacyPackages = import inputs.nixpkgs-unstable {
        inherit system;
        inherit (nixpkgsConfig) config;
        overlays = with self.overlays; [
          pkgs-master
          pkgs-stable
          apple-silicon
          my-packages
        ];
      };
      pkgs = legacyPackages;
      agenix = inputs.agenix;
    in
    {
      devShell = import ./shell.nix { inherit pkgs system agenix; };
    });
}
# vim: foldmethod=marker
