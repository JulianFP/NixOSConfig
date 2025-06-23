{ config, ... }:

{
  imports = [ 
    ./nebulaModule.nix
  ];

  myModules.nebula."serverNetwork" = {
    serverFirewallRules = config.services.openssh.enable;
    ipMap = {
      #servers
      mainserver = "48.42.0.2";
      IonosVPS = "48.42.0.5";
      backupServer = "48.42.0.7";
      #containers
      Nextcloud = "48.42.1.131";
      Nextcloud-Testing = "48.42.1.150";
      Jellyfin = "48.42.1.132";
      FoundryVTT = "48.42.1.133";
      HomeAssistant = "48.42.1.134";
      Valheim = "48.42.1.135";
      #client devices
      JuliansFramework = "48.42.2.1";
      JuliansPC = "48.42.2.3";
    };
  };
}
