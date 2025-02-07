{ self, config, pkgs, lib, hostName, ...}:

{
  #some global assertions to make sure to not repeat these mistakes
  assertions = [{
    assertion = if builtins.hasAttr "persistence" config.environment 
      then (lib.attrsets.filterAttrs (name: value: name != "/persist" && name != "/persist/backMeUp") config.environment.persistence) == {}
      else true;
    message = "Custom assertion: Impermanence module cannot add parent directories on its own, only use /persist or /persist/backMeUp as a storage location because of that!";
  }];

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

  #system settings
  system = {
    # get git revision of system with command 'nixos-version --configuration-revision'
    configurationRevision = self.shortRev or self.dirtyShortRev;
    extraSystemBuilderCmds = ''
      ln -s ${pkgs.path} $out/nixpkgs
    '';
  };

  # nix settings
  nix = {
    #enable flakes and nix-command
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };
    nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];
  };

  #nix daemon should be used by the root user as well!
  environment.variables.NIX_REMOTE = "daemon";

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
}
