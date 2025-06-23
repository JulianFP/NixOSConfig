{
  description = "NixOS config of my laptop as well as most of my server infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators-stable = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    stylix.url = "github:danth/stylix";
    nur.url = "github:nix-community/NUR";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    project-W = {
      url = "github:JulianFP/project-W";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    foundryvtt.url = "github:reckenrode/nix-foundryvtt";
    systems.url = "github:nix-systems/default";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      eachSystem = inputs.nixpkgs.lib.genAttrs (import inputs.systems);
      pkgsFor = eachSystem (
        system:
        import inputs.nixpkgs {
          inherit system;
        }
      );
      mkSystems = import ./generic/utils/mkSystems.nix inputs;
      genSystems = import ./generic/utils/genSystems.nix inputs;
    in
    with inputs;
    {
      /*
        --- documentation mkSystems and genSystems functions ---
        accepts attribute set with name/value pairs where name is hostName and value is another attribute set with the following options:
        - system (string): platform/architecture. Default: "x86_64-linux"
        - stable (bool): whether to use nixpkgs-stable or not (in which case it uses nixpkgs-unstable). Default: true
        - server (bool): whether this is a server and the ./generic/server.nix module should be applied (which then in turn applies the ./generic/common.nix module). Default: false (in which case only the ./generic/common.nix module gets applied. This module is always used)
        - desktop (bool): Whether this is a desktop system that should share all the common desktop setup
        - proxmoxVmID (uint between 2 and 254 or null): If null: this is not a proxmox VM. If not null: ./generic/proxmoxVM.nix is being included and vmID is set to this value (which is mainly used to set the host ID of the local IP-address (/24) of this VM). Default: null
        - nebula (bool): Whether ./generic/nebula.nix should be included. Default: true
        - boot (0,1 or 2): Whether grub (0), systemd-boot (1) or lanzaboote for secureboot (2) should be used. Default: 0
        - hasOwnModule (bool): Whether a module ./<hostName>/configuration.nix exists and should be included. Default: true
        - homeManager (bool): Whether homeManager should be activated (by including ./generic/commonHM.nix). This also includes the HM-module ./genericHM/shell.nix for the root user. Default: true
        - systemModules (list of paths): List of system modules that should be included in addition to what gets included automatically. Default: []
        - homeManagerModules (attribute set of lists of paths): home manager modules that should be included in addition to what gets included automatically. Each list in this attribute set is for one user (where the names/keys are the user names). Default: {}
        - permittedUnfreePackages (list of strings): List of package names of packages with an unfree license that should be allowed on that system. Default: []
        - permittedInsecurePackages (list of strings): List of package names of packages that are marked as insecure (e.g. because they are EOL) that should be allowed on that system. Default: []
        - overlays (list of overlay definitions): List of overlays that should be activated for that system. Default: []
        - args (attribute set of anything): Variables that should be included as specialArgs for both system modules as well as HM-modules in addition to what gets added automatically (i.e. in addition to self, hostName, stable, vmID, inputs/contents of the inputs)
        - (genSystems only) format (string): output format, see nixos-generators github for all options. No default, always needs to be set
      */

      packages = genSystems {
        "installISO" = {
          format = "install-iso";
          stable = false;
          nebula = false;
          systemModules = [
            ./generic/ssh.nix # for nixos-anywhere installations
          ];
          stateVersion = "25.11";
        };
      };

      devShells = eachSystem (system: {
        default = import ./shell.nix {
          inherit inputs system;
          pkgs = pkgsFor.${system};
        };
      });

      nixosConfigurations = mkSystems {
        "JuliansFramework" = {
          desktop = true;
          stable = false;
          boot = 2;
          systemModules = [
            ./generic/desktop/crazy-bcachefs-hardware-config.nix
            nixos-hardware.nixosModules.framework-12th-gen-intel
            #nixos-hardware.nixosModules.common-gpu-amd
          ];
          permittedUnfreePackages = [
            "steam"
            "steam-unwrapped"
            "corefonts"
            "vista-fonts"
            "xow_dongle-firmware"
            "idea-ultimate"
            "discord"
            "guilded"
          ];
          overlays = [
            nur.overlays.default
            (import ./generic/overlays/clevis_with_fido2.nix)
            (import ./generic/overlays/qtct.nix)
            #(import ./generic/overlays/lyx.nix)
          ];
          stateVersion = "24.11";
        };
        "JuliansPC" = {
          desktop = true;
          stable = false;
          boot = 2;
          systemModules = [
            ./generic/desktop/crazy-bcachefs-hardware-config.nix
            nixos-hardware.nixosModules.common-gpu-amd
            nixos-hardware.nixosModules.common-cpu-amd
          ];
          permittedUnfreePackages = [
            "steam"
            "steam-unwrapped"
            "corefonts"
            "vista-fonts"
            "xow_dongle-firmware"
            "idea-ultimate"
            "discord"
            "guilded"
          ];
          overlays = [
            nur.overlays.default
            (import ./generic/overlays/clevis_with_fido2.nix)
            (import ./generic/overlays/qtct.nix)
          ];
          stateVersion = "25.05";
        };
        "rescueSystem" = {
          stable = false;
          boot = 1;
          nebula = false;
          homeManagerModules = {
            julian = [
              ./genericHM/shell.nix
              ./genericHM/yubikey.nix
              ./genericHM/desktop/neovim/neovim-basic.nix
            ];
          };
          stateVersion = "24.11";
        };
        "mainserver" = {
          server = true;
          boot = 1;
          systemModules = [
            ./generic/ssh-sops-key.nix
          ];
          homeManagerModules.root = [
            ./genericHM/ssh-sops-key.nix
          ];
          overlays = [
            (import ./generic/overlays/caddy-unstable.nix { inherit inputs; })
          ];
          stateVersion = "24.11";
        };
        "IonosVPS" = {
          server = true;
          systemModules = [
            ./generic/ssh-sops-key.nix
            ./generic/wireguard.nix
          ];
          homeManagerModules.root = [
            ./genericHM/ssh-sops-key.nix
          ];
          overlays = [
            (import ./generic/overlays/caddy-unstable.nix { inherit inputs; })
          ];
          stateVersion = "23.11";
        };
        "backupServer" = {
          server = true;
          stateVersion = "25.05";
        };
      };
    };
}
