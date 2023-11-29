{
  description = "NixOS config of my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-logseq.url = "github:NixOS/nixpkgs/5363991a6fbb672549b6c379cdc1e423e5bf2d06";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-23.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nur.url = "github:nix-community/NUR";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix.url = "github:Mic92/sops-nix";

    hyprland.url = "github:hyprwm/Hyprland";
  };


  outputs = { self, ... } @ inputs: 
  with inputs; {
    nixosConfigurations.JuliansFramework = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true; #allow Unfree packages
          permittedInsecurePackages = [
            "electron-22.3.27" #needed for freetube until it upgrades its electron package
            "electron-24.8.6" #needed for logseq
          ];
        };
        overlays = [
          nur.overlay
          #use older logseq version (0.9.19) since logseq uses electron 25 since 0.9.20 which crashes on my system
          (self: super: {
            logseq = (import inputs.nixpkgs-logseq {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = [ "electron-24.8.6" ];
              };
            }).logseq;
          })
        ];
      };
      modules = [
        #./genericNixOS/systemd-boot.nix
        ./generic/lanzaboote.nix #(imports lanzaboote module)
        ./generic/commonHM.nix #imports common settings (including home manager)
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./JuliansFramework/configuration.nix
        nixos-hardware.nixosModules.framework-12th-gen-intel
        #nixos-hardware.nixosModules.common-gpu-amd
      ];
      specialArgs = {
        homeManagerModules = {
          julian = [ 
            ./genericHM/terminal.nix
            ./genericHM/yubikey.nix
            ./JuliansFramework/home-manager/julian/home.nix  
          ];
          root = [ 
            ./genericHM/terminal.nix
            ./genericHM/yubikey.nix
            ./JuliansFramework/home-manager/root/home.nix
          ];
        };
        hostName = "JuliansFramework"; 
        stable = false;
        inherit inputs;
      };
    };
    nixosConfigurations.blankISO = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/server.nix
        #don't use ./proxmoxVM.nix because ISO does not support disco and doesn't have vmID
        ./blankISO/configuration.nix 
      ];
      specialArgs = {
        hostName = "blankISO"; 
        inherit inputs;
      };
    };
    nixosConfigurations.NixOSTesting = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./NixOSTesting/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "NixOSTesting"; 
        stable = true;
        vmID = "120";
        inherit inputs;
      };
    };
    nixosConfigurations.Nextcloud = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Nextcloud/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "Nextcloud"; 
        stable = true;
        vmID = "131";
        inherit inputs;
      };
    };
    nixosConfigurations.Nextcloud-Testing = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Nextcloud/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "Nextcloud-Testing"; 
        stable = true;
        vmID = "150";
        inherit inputs;
      };
    };
    nixosConfigurations.Jellyfin = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Jellyfin/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "Jellyfin"; 
        stable = true;
        vmID = "132";
        inherit inputs;
      };
    };
    nixosConfigurations.IonosVPS = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/server.nix
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./generic/proxy.nix #requires edge!
        ./IonosVPS/configuration.nix
      ];
      specialArgs = { 
        hostName = "IonosVPS"; 
        edge = true;
        inherit inputs;
      };
    };
    nixosConfigurations.LocalProxy = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./generic/proxy.nix #requires edge!
        ./LocalProxy/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "LocalProxy"; 
        stable = true;
        vmID = "130";
        edge = false;
        inherit inputs;
      };
    };
    nixosConfigurations.Valheim = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "steamcmd"
        ];
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Valheim/configuration.nix
      ];
      specialArgs = { 
        homeManagerModules = {
          root = [ 
            ./genericHM/terminal.nix
          ];
        };
        hostName = "Valheim"; 
        stable = true;
        vmID = "135";
        inherit inputs;
      };
    };
  };
}
