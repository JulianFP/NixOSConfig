{ config, pkgs, inputs, homeManagerModules, stable, ...}:

{
  # import common.nix and home manager module depending on if system uses stable or unstable packages
  imports = if stable then [ inputs.home-manager-stable.nixosModules.home-manager ./common.nix ] else [ inputs.home-manager.nixosModules.home-manager ./common.nix ];

  #set zsh as default shell
  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  #home manager setup
  programs.dconf.enable = true;
  home-manager = with inputs; {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      #pass nixneovim as additional Arg to home-manager config
      inherit nixvim;
      inherit inputs;
    };
    /*
      homeManagerModules is a attribute set of users which are lists of paths to import into home manager
      the following will change the users to attribute sets with home manager config
    */
    users = builtins.mapAttrs ( userName: modules:
      {
        imports = if stable then modules ++ [ inputs.nixvim-stable.homeManagerModules.nixvim ] else modules ++ [ inputs.nixvim.homeManagerModules.nixvim ];

        home.username = userName;
        home.homeDirectory = if userName == "root" then "/root" else "/home/${userName}";

        programs.home-manager.enable = true;
        home.stateVersion = config.system.stateVersion;
      }
    ) homeManagerModules;
  };

}
