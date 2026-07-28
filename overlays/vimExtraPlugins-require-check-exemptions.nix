# nixpkgs' buildNeovimPlugin runs neovimRequireCheckHook, which `require()`s
# every lua module in a plugin. Some modules legitimately can't be required in
# isolation, which fails the build for plugins that work fine at runtime.
#
# This exempts only the plugins that actually fail, so the rest keep the check
# and a genuinely broken plugin still surfaces. Of the 12 vimExtraPlugins used
# in this config, 8 pass unmodified.
#
# Must sort after `nix-neovimplugins` in `attrValues self.overlays`, since that
# overlay is what introduces `vimExtraPlugins`.
final: prev:
let
  # plugin -> list of modules to skip, or `null` to disable the check entirely.
  exemptions = {
    # Optional integration with noice.nvim, which isn't on the rtp here.
    catppuccin-catppuccin = [ "catppuccin.groups.integrations.noice" ];

    # Optional integration with diffview.nvim.
    neogit-NeogitOrg = [ "neogit.integrations.diffview" ];

    # Docs-generation helper, not loaded at runtime.
    trouble-nvim-folke = [ "trouble.docs" ];

    # 24 of lspsaga's 35 modules index `lspsaga.config` at load time, which is
    # nil until setup() runs:
    #   lua/lspsaga/window.lua:3: attempt to index field 'config' (a nil value)
    # That's an artifact of requiring them in isolation, not a runtime failure,
    # and it's too many modules to enumerate meaningfully.
    lspsaga-nvim-nvimdev = null;
  };

  exempt = name: skip:
    prev.vimExtraPlugins.${name}.overrideAttrs (old:
      if skip == null then
        { doCheck = false; }
      else
        { nvimSkipModules = (old.nvimSkipModules or [ ]) ++ skip; }
    );
in
{
  vimExtraPlugins = prev.vimExtraPlugins // prev.lib.mapAttrs exempt exemptions;
}
