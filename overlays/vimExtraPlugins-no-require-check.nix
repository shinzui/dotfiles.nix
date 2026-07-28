# nixpkgs' buildNeovimPlugin runs vimCommandCheckHook + neovimRequireCheckHook
# (via nativeCheckInputs, gated on doCheck). The hook `require()`s every lua
# module in the plugin, which fails for modules that are optional integrations
# with *other* plugins — e.g. catppuccin's `groups.integrations.noice`, or
# lspsaga's internal modules. Those plugins work fine at runtime.
#
# vimExtraPlugins comes from NixNeovimPlugins, which auto-generates packages
# from upstream repos and can't annotate nvimSkipModules per plugin, so
# fixing this one plugin at a time is endless. Disable the check for the
# whole generated set.
#
# Must sort after `nix-neovimplugins` in `attrValues self.overlays`, since
# that overlay is what introduces `vimExtraPlugins`.
final: prev: {
  vimExtraPlugins = prev.vimExtraPlugins // (
    prev.lib.mapAttrs
      (_name: plugin:
        if prev.lib.isDerivation plugin
        then plugin.overrideAttrs (_: { doCheck = false; })
        else plugin)
      prev.vimExtraPlugins
  );
}
