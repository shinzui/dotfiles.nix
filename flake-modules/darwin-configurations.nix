# nix-darwin system configurations.
{ self, inputs, lib, ... }:
let
  inherit (inputs.darwin.lib) darwinSystem;

  nixpkgsConfig = import ../lib/nixpkgs-config.nix { inherit self lib; };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home
  # Manager release notes for a list of state version changes in each release.
  homeManagerStateVersion = "26.05";

  homeManagerCommonConfig = {
    imports = lib.attrValues self.homeManagerModules ++ [
      ../home
      { home.stateVersion = homeManagerStateVersion; }
    ];
  };

  nixDarwinCommonModules = [
    {
      config._module.args = {
        inherit (inputs) nixpkgs-unstable;
      };
    }
    # Include extra `nix-darwin`
    self.darwinModules.pam
    self.darwinModules.users
    self.darwinModules.accessibility

    inputs.agenix.darwinModules.default

    # Determinate Nix integration
    inputs.determinate.darwinModules.default

    # Main `nix-darwin` config
    ../darwin

    # `home-manager` module
    inputs.home-manager.darwinModules.home-manager
    (
      { config, ... }:
      let
        inherit (config.users) primaryUser;
      in
      {
        nixpkgs = nixpkgsConfig;
        # `home-manager` config
        users.users.${primaryUser}.home = "/Users/${primaryUser}";
        home-manager.useGlobalPkgs = true;
        # Rename any file home-manager would otherwise clobber to
        # <name>.backup; preserves manual state without forcing
        # --force on every individual file option.
        home-manager.backupFileExtension = "backup";
        home-manager.users.${primaryUser} = homeManagerCommonConfig;

        home-manager.extraSpecialArgs = {
          inherit (config) age;
        };

        # Add a registry entry for this flake
        determinateNix.registry.my.flake = self;
        determinateNix.registry.nixpkgs.flake = inputs.nixpkgs-unstable;
      }
    )
  ];
in
{
  flake.darwinConfigurations = {
    # Mininal configuration to bootstrap systems
    bootstrap-arm = darwinSystem {
      system = "aarch64-darwin";
      modules = [ ../darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
    };

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
      specialArgs = { inherit (inputs) private-fonts; };
    };
  };
}
