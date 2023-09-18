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
    nur.url = "github:nix-community/NUR";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };


  outputs = { self, ... } @ inputs: 
    with inputs;
    let
      system = "x86_64-linux"; #define system for all machines at once
    in {
      nixosConfigurations.JuliansFramework = nixpkgs.lib.nixosSystem {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true; #allow Unfree packages
          };
          overlays = [
            nur.overlay
          ];
        };
        inherit system;
        modules = [
          ./JuliansFramework/configuration.nix
          lanzaboote.nixosModules.lanzaboote
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
      };
      nixosConfigurations.NixOSTesting = nixpkgs-stable.lib.nixosSystem {
        pkgs = import nixpkgs-stable {
          inherit system;
        };
        inherit system;
        modules = [
          ./NixOSTesting/configuration.nix
          disko.nixosModules.disko
        ];
      };
      nixosConfigurations.Nextcloud = nixpkgs-stable.lib.nixosSystem {
        pkgs = import nixpkgs-stable {
          inherit system;
        };
        inherit system;
        modules = [
          ./Nextcloud/configuration.nix
          disko.nixosModules.disko
        ];
      };
      nixosConfigurations.IonosVPS = nixpkgs-stable.lib.nixosSystem {
        pkgs = import nixpkgs-stable {
          inherit system;
        };
        inherit system;
        modules = [
          ./IonosVPS/configuration.nix
        ];
      };
    };
}
