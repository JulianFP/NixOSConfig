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
            "electron-24.8.6" #needed for logseq until it upgrades its electron package
            "electron-22.3.27" #needed for freetube until it upgrades its electron package
          ];
        };
        overlays = [
          nur.overlay
          #use electron 27 for logseq since it keeps crashing with electron 25. graph view doesn't work with this however (since it doesn't match upstream electron version)
          (self: super: {
            logseq = super.logseq.overrideAttrs (old: {
              postFixup = ''
                    # set the env "LOCAL_GIT_DIRECTORY" for dugite so that we can use the git in nixpkgs
                    makeWrapper ${pkgs.electron_27}/bin/electron $out/bin/${old.pname} \
                      --set "LOCAL_GIT_DIRECTORY" ${super.git} \
                      --add-flags $out/share/${old.pname}/resources/app \
                      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
                      --prefix LD_LIBRARY_PATH : "${super.lib.makeLibraryPath [ super.stdenv.cc.cc.lib ]}"
              '';
              });
           })
        ];
      };
      modules = [
        #./genericNixOS/systemd-boot.nix
        ./generic/lanzaboote.nix #(imports lanzaboote module)
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./JuliansFramework/configuration.nix
        nixos-hardware.nixosModules.framework-12th-gen-intel
        #nixos-hardware.nixosModules.common-gpu-amd
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              #pass nixneovim as additional Arg to home-manager config
              inherit nixvim;  
              inherit inputs;
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
        ./generic/proxmoxVM.nix #requires vmID!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./NixOSTesting/configuration.nix
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
        ./generic/proxmoxVM.nix #requires vmID!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Nextcloud/configuration.nix
      ];
      specialArgs = { 
        hostName = "Nextcloud"; 
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
        ./generic/proxmoxVM.nix #requires vmID!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Nextcloud/configuration.nix
      ];
      specialArgs = { 
        hostName = "Nextcloud-Testing"; 
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
        ./generic/proxmoxVM.nix #requires vmID!
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./Jellyfin/configuration.nix
      ];
      specialArgs = { 
        hostName = "Jellyfin"; 
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
        ./generic/proxmoxVM.nix
        ./generic/nebula.nix#take care of .sops.yaml! (imports sops module)
        ./generic/proxy.nix #requires edge!
        ./LocalProxy/configuration.nix
      ];
      specialArgs = { 
        hostName = "LocalProxy"; 
        vmID = "130";
        edge = false;
        inherit inputs;
      };
    };
  };
}
