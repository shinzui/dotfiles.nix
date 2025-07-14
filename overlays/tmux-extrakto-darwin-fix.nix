final: prev: {
  tmuxPlugins = prev.tmuxPlugins // {
    extrakto = prev.tmuxPlugins.extrakto.overrideAttrs (oldAttrs: {
      postInstall = ''
        patchShebangs extrakto.py extrakto_plugin.py

        wrapProgram $target/scripts/open.sh \
          --prefix PATH : ${final.fzf}/bin:${final.xclip}/bin${
            # Only include wl-clipboard on Linux
            if final.stdenv.isLinux then ":${final.wl-clipboard}/bin" else ""
          }
      '';
    });
  };
}