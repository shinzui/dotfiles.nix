{ config, lib, ... }:

let
  cfg = config.security.accessibility;
in

{
  options.security.accessibility = {
    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of application bundle identifiers to grant accessibility access.
        These are added to the system TCC database on each activation.

        Note: the terminal used for `darwin-rebuild switch` may need
        Full Disk Access for this to work (System Settings → Privacy
        & Security → Full Disk Access).
      '';
      example = [ "org.hammerspoon.Hammerspoon" ];
    };
  };

  config = lib.mkIf (cfg.apps != []) {
    system.activationScripts.postActivation.text = let
      tccDb = "/Library/Application Support/com.apple.TCC/TCC.db";
      grantStatements = lib.concatMapStringsSep "\n" (bundleId: ''
        /usr/bin/sqlite3 "''${TCC_DB}" \
          "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, indirect_object_identifier_type, indirect_object_identifier, flags, last_modified) VALUES ('kTCCServiceAccessibility', '${bundleId}', 0, 2, 3, 1, 0, 'UNUSED', 0, CAST(strftime('%s','now') AS INTEGER));" 2>/dev/null && \
          echo "  granted accessibility to ${bundleId}" || \
          echo "  failed to grant accessibility to ${bundleId} (TCC may require Full Disk Access on your terminal)"
      '') cfg.apps;
    in ''
      # Grant accessibility access to configured apps
      TCC_DB="${tccDb}"
      if [ -f "''${TCC_DB}" ]; then
        echo "configuring accessibility permissions..."
      ${grantStatements}
      fi
    '';
  };
}
