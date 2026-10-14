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
    inputs.dotfiles-private.darwinModules.default

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
        users.primaryUser = lib.mkDefault "shinzui";
        # Inspect services with networksetup -listallnetworkservices.
        networking.knownNetworkServices = lib.mkDefault [
          "Wi-Fi"
          "Thunderbolt Bridge"
        ];
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

  mkDarwinHost = { hostModule, system ? "aarch64-darwin" }: darwinSystem {
    inherit system;
    modules = nixDarwinCommonModules ++ [ hostModule ];
    specialArgs = { inherit (inputs) private-fonts; };
  };
in
{
  flake.darwinConfigurations = {
    # Minimal configuration to bootstrap a machine that has no decryptable
    # secrets yet: substituters, trusted users, shells, fd limits.
    #
    # Deliberately does NOT include agenix or secrets.nix — bootstrap.nix must
    # stay free of `config.age.secrets` for exactly that reason. It does need
    # the determinate module (it configures `determinateNix.*` throughout) and
    # the `nixpkgs-unstable` module arg.
    bootstrap-arm = darwinSystem {
      system = "aarch64-darwin";
      modules = [
        {
          config._module.args = {
            inherit (inputs) nixpkgs-unstable;
          };
        }
        inputs.determinate.darwinModules.default
        ../darwin/bootstrap.nix
        { nixpkgs = nixpkgsConfig; }
      ];
    };

    SungkyungM1X = mkDarwinHost { hostModule = ../hosts/sungkyung; };
    yujin = mkDarwinHost { hostModule = ../hosts/yujin; };
  };
}
