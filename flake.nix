{
  description = "NixOS config of my laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
  };


  outputs = { self, nixpkgs, lanzaboote, nixos-hardware, nixvim, home-manager, ...}: 
    let
      system = "x86_64-linux"; #central place where system is defined
      pkgs = import nixpkgs { #central place where pkgs is defined
        inherit system;
        config = {
          allowUnfree = true; #allow Unfree packages
        };
      };
    in {
      nixosConfigurations.JuliansFramework = nixpkgs.lib.nixosSystem {
        inherit system pkgs;
        modules = [
          ./configuration.nix
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
	        julian = import ./home-manager/julianHome.nix;
	        root = import ./home-manager/rootHome.nix;
	      };
	    };
	  }
        ];
      };
    };
}
