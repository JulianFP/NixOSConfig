{ config, lib, ... }:

{
  imports = [
    ./nebulaModule.nix
  ];

  myModules.nebula."serverNetwork" = {
    serverFirewallRules = config.services.openssh.enable;
    subnet = "10.28.128.0/21";
    ipMap = {
      #servers
      IonosVPS = "10.28.128.1";
      IonosVPS2 = "10.28.128.2";
      mainserver = "10.28.128.3";
      backupServer = "10.28.128.4";
      backupServerOffsite = "10.28.128.5";
      #containers
      Nextcloud = "10.28.129.131";
      Jellyfin = "10.28.129.132";
      FoundryVTT = "10.28.129.133";
      HomeAssistant = "10.28.129.134";
      ValheimMarvin = "10.28.129.135";
      ValheimBrueder = "10.28.129.136";
      Kanidm = "10.28.129.137";
      Email = "10.28.129.138";
      Nextcloud-Testing = "10.28.129.150";
      #client devices
      JuliansFramework = "10.28.130.1";
      JuliansPC = "10.28.130.2";
    };
    lighthouseMap = {
      IonosVPS = [
        "85.215.33.173:51821"
      ]
      ++ lib.optional config.myModules.nebula."serverNetwork".enableIPv6 "[2a02:247a:23e:d300::1]:51821";
      IonosVPS2 = [
        "82.165.49.241:51821"
      ];
    };
  };
}
