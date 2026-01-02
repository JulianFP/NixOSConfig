{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/proxyConfig.nix
    ../generic/dnat.nix
  ];

  # set a password for a root user as a fallback if there is no networking
  sops.secrets."users/root" = {
    neededForUsers = true;
    sopsFile = ../secrets/IonosVPS2/users.yaml;
  };
  users.users.root.hashedPasswordFile = config.sops.secrets."users/root".path;

  networking.domain = "";

  zramSwap.enable = true; # enable zram (instead of swap)

  #nebula lighthouse + unsafe_routes settings
  myModules.nebula."serverNetwork".isLighthouse = true;
  services.nebula.networks."serverNetwork".settings.tun.unsafe_routes = [
    {
      route = "192.168.3.0/24";
      via = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    }
    {
      route = "10.42.42.0/24";
      via = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    }
  ];

  #dnat setup
  myModules.dnat = {
    enable = true;
    externalInterface = "ens6";
    portForwards = [
      {
        # SMTP
        sourcePort = 25;
        destinationNebulaHost = "Email";
      }
      {
        # ACME challenge
        sourcePort = 80;
        destinationNebulaHost = "Email";
      }
      /*
        { # POP3 STARTTLS, enable if enablePop3 is set in snm
          sourcePort = 110;
          destinationNebulaHost = "Email";
        }
      */
      {
        # IMAP STARTTLS
        sourcePort = 143;
        destinationNebulaHost = "Email";
      }
      {
        # HTTPS for roundcube and rspamd UI
        sourcePort = 443;
        destinationNebulaHost = "Email";
      }
      {
        # SMTP TLS
        sourcePort = 465;
        destinationNebulaHost = "Email";
      }
      {
        # SMTP STARTTLS
        sourcePort = 587;
        destinationNebulaHost = "Email";
      }
      {
        # IMAP TLS
        sourcePort = 993;
        destinationNebulaHost = "Email";
      }
      /*
        { # POP3 TLS, enable if enablePop3Ssl is set in snm
          sourcePort = 995;
          destinationNebulaHost = "Email";
        }
        { # sieve, enable if enableManageSieve is set in snm
          sourcePort = 4190;
          destinationNebulaHost = "Email";
        }
      */
    ];
  };
}
