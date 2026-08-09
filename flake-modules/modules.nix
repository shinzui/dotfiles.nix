# Reusable nix-darwin and home-manager modules exported by this flake.
{ inputs, ... }:
{
  flake.darwinModules = {
    users = import ../modules/darwin/users.nix;
    pam = import ../modules/darwin/pam.nix;
    accessibility = import ../modules/darwin/accessibility.nix;
  };

  flake.homeManagerModules = {
    configs-git-aliases = import ../home/config/git-aliases.nix;
    configs-gh-aliases = import ../home/config/gh-aliases.nix;
    configs-wezterm = import ../home/wezterm.nix;
    configs-starship-symbols = import ../home/config/starship-symbols.nix;

    # From a foreign flake rather than this repository. Registered here because
    # darwin-configurations.nix imports `lib.attrValues self.homeManagerModules`
    # into the home-manager configuration, and `inputs` is not in scope inside
    # home/*.nix -- extraSpecialArgs passes only `age`. This declares the module;
    # home/redpanda.nix configures it.
    redpanda-container = inputs.redpanda-container.homeManagerModules.default;
  };
}
