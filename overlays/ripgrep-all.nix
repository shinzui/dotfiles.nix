final : prev:

{
  ripgrep-all = prev.ripgrep-all.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
  });
}
