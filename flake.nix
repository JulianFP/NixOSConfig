{
  description = "NixOS config of my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-stable = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nur.url = "github:nix-community/NUR";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix.url = "github:Mic92/sops-nix";
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
          ];
        };
        overlays = [
          nur.overlay
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
      specialArgs = rec {
        homeManagerModules = {
          julian = [ 
            ./genericHM/shell.nix
            ./genericHM/yubikey.nix
            ./JuliansFramework/home-manager/julian/home.nix  
          ];
          root = [ 
            ./genericHM/shell.nix
            ./genericHM/yubikey.nix
            ./JuliansFramework/home-manager/root/home.nix
          ];
        };
        hostName = "JuliansFramework"; 
        homeManagerExtraSpecialArgs = { 
          inherit nix-colors; 
          inherit hostName;
          inherit stable;
        };
        stable = false;
        inherit inputs;
        inherit self;
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
      specialArgs = rec {
        hostName = "blankISO"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        inherit inputs;
        inherit self;
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
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "NixOSTesting"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "120";
        inherit inputs;
        inherit self;
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
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Nextcloud"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "131";
        inherit inputs;
        inherit self;
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
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Nextcloud-Testing"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "150";
        inherit inputs;
        inherit self;
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
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Jellyfin"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "132";
        inherit inputs;
        inherit self;
      };
    };
    nixosConfigurations.IonosVPS = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/server.nix
        ./generic/commonHM.nix
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./generic/ssh.nix
        ./generic/proxy.nix #requires edge!
        ./generic/wireguard.nix #includes option declaration
        ./IonosVPS/configuration.nix
      ];
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/ssh.nix#requires ./generic/ssh.nix!
          ];
        };
        hostName = "IonosVPS"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        edge = true;
        inherit inputs;
        inherit self;
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
        ./generic/ssh.nix
        ./generic/proxy.nix #requires edge!
        ./LocalProxy/configuration.nix
      ];
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
            ./genericHM/ssh.nix#requires ./generic/ssh.nix!
          ];
        };
        hostName = "LocalProxy"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "130";
        edge = false;
        inherit inputs;
        inherit self;
      };
    };
    nixosConfigurations.Valheim = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Valheim/configuration.nix
      ];
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Valheim"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "135";
        inherit inputs;
        inherit self;
      };
    };
    nixosConfigurations.Project-W = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Project-W/configuration.nix
      ];
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Project-W"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "136";
        inherit inputs;
        inherit self;
      };
    };
  };
}
