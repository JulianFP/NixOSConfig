{ self, pkgs, hostName, ...}:

{
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

  # nix settings
  nix = {
    #enable flakes and nix-command
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # get git revision of system with command 'nixos-version --configuration-revision'
  system.configurationRevision = self.shortRev or self.dirtyShortRev;

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
