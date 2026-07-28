# Reusable nix-darwin and home-manager modules exported by this flake.
{ ... }:
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
  };
}
