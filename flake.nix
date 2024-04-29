{
  description = "NixOS config of my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
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
    project-W = {
      url = "github:JulianFP/project-W";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    project-W-frontend = {
      url = "github:JulianFP/project-W-frontend";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen = {
      url = "github:LovingMelody/nix-citizen";
      inputs.nix-gaming.follows = "nix-gaming";
    };
    hyprland = {
      #lock at this commit until https://github.com/Alexays/Waybar/pull/3180 is merged and reaches nixpkgs
      url = "github:hyprwm/Hyprland//d20ee312108d0e7879011cfffa3a83d06e48d29e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, ... } @ inputs: 
  with inputs; {
    packages.x86_64-linux = {
      blankISO = nixos-generators.nixosGenerate rec {
        format = "iso";
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
    };
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
          (import ./generic/overlays/qt5ct_with_breeze.nix {pkgs=pkgs;})
        ];
      };
      modules = [
        #./genericNixOS/systemd-boot.nix
        ./generic/lanzaboote.nix #(imports lanzaboote module)
        ./generic/commonHM.nix #imports common settings (including home manager)
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./JuliansFramework/configuration.nix
        nixos-hardware.nixosModules.framework-12th-gen-intel
        #nix-gaming modules
        nix-gaming.nixosModules.pipewireLowLatency
        nix-gaming.nixosModules.platformOptimizations
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
          inherit nix-citizen;
          inherit hyprland;
        };
        stable = false;
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
        overlays = [
          inputs.project-W.overlays.default
        ];
      };
      modules = [
        inputs.project-W.nixosModules.default
        inputs.project-W-frontend.nixosModules.default
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
    nixosConfigurations.Authentik = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID, stable, homeManagerModules!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Authentik/configuration.nix
      ];
      specialArgs = rec { 
        homeManagerModules = {
          root = [ 
            ./genericHM/shell.nix
          ];
        };
        hostName = "Authentik"; 
        homeManagerExtraSpecialArgs = { 
          inherit hostName;
          inherit stable;
        };
        stable = true;
        vmID = "140";
        inherit inputs;
        inherit self;
      };
    };
  };
}
