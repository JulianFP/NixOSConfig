{
  description = "NixOS config of my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
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
        };
        overlays = [
          nur.overlay
        ];
      };
      modules = [
        #./genericNixOS/systemd-boot.nix
        ./generic/lanzaboote.nix #(imports lanzaboote module)
        ./generic/nebula.nix#requires working /root/.gnupg! (imports sops module)
        ./JuliansFramework/configuration.nix
        ./JuliansFramework/nebulaAdd.nix
        nixos-hardware.nixosModules.framework-12th-gen-intel
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              #pass nixneovim as additional Arg to home-manager config
              inherit nixvim;  
            };
            users = {
              julian = import ./JuliansFramework/home-manager/julian/home.nix;
              root = import ./JuliansFramework/home-manager/root/home.nix;
            };
          };
        }
      ];
      specialArgs = {
        hostName = "JuliansFramework"; 
        inherit inputs;
      };
    };
    nixosConfigurations.blankISO = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./blankISO/configuration.nix
      ];
    };
    nixosConfigurations.NixOSTesting = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./generic/proxmoxVM.nix #requires vmID!
        ./generic/nebula.nix#requires working /root/.gnupg! (imports sops module)
        ./generic/gnupg-server.nix
      ];
      specialArgs = { 
        hostName = "NixOSTesting"; 
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
        ./Nextcloud/configuration.nix
        disko.nixosModules.disko
      ];
    };
    nixosConfigurations.IonosVPS = nixpkgs-stable.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = import nixpkgs-stable {
        inherit system;
      };
      modules = [
        ./IonosVPS/configuration.nix
      ];
    };
  };
}
