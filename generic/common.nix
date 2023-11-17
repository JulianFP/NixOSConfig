{ config, pkgs, inputs, homeManagerModules, hostName, ...}:

{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  #define hostname 
  networking.hostName = hostName;

  #remove everything in /tmp directory at boot time
  boot.tmp.cleanOnBoot = true;

  #install some basic packages
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
  ];

  #set zsh as default shell
  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # nix settings
  nix = {
    #enable flakes and nix-command
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  #internationalisation properties and timezone
  time.timeZone = "Europe/Berlin"; #set timezone
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
    };
  };
  console = {
    keyMap = "de";
    useXkbConfig = false; # use xkbOptions in tty.
  };

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
    users = builtins.mapAttrs ( userName: value:
      {
        imports = value;

        home.username = userName;
        home.homeDirectory = if userName == "root" then "/root" else "/home/${userName}";

        programs.home-manager.enable = true;
        home.stateVersion = config.system.stateVersion;
      }
    ) homeManagerModules;
  };
}
