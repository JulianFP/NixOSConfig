{ inputs, lib, hostName, stateVersion, stable, server, proxmoxVmID, nebula, boot, hasOwnModule, homeManager, systemModules, homeManagerModules, args}: 

let
  self = inputs.self;
  defaultHomeManagerModules = {
    root = [ ../../genericHM/shell.nix ];
  };
in {
  modules = [({...}: {system.stateVersion = stateVersion;})]
    ++ (if (proxmoxVmID != null) then [ ../proxmoxVM.nix ]
    else if server then [ ../server.nix ]
    else [ ../common.nix ])
    ++ lib.lists.optional (boot != 0) (if (boot == 2) then ../lanzaboote.nix else ../systemd-boot.nix)
    ++ lib.lists.optional nebula ../nebula.nix
    ++ lib.lists.optional homeManager ../commonHM.nix
    ++ lib.lists.optional hasOwnModule ../../${hostName}/configuration.nix
    ++ systemModules;
  specialArgs = {
    inherit hostName inputs self stable;
  } // lib.optionalAttrs (proxmoxVmID != null) {
    vmID = proxmoxVmID;
  } // lib.optionalAttrs homeManager {
    homeManagerModules = homeManagerModules // (builtins.mapAttrs (name: value:
      value ++ (lib.attrsets.attrByPath [name] [] homeManagerModules)) defaultHomeManagerModules);
    homeManagerExtraSpecialArgs = {
      inherit hostName stable;
    }
    // (builtins.removeAttrs inputs [ "nixpkgs" "nixpkgs-stable" "home-manager" "home-manager-stable" ])
    // args;
  } // args;
}
