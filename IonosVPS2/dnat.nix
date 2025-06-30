{ config, ... }:

{
  networking = {
    nftables.enable = true;
    firewall.allowedTCPPorts = [
      25 # SMTP
      80 # ACME challenge
      #110 #POP3 STARTTLS, enable if enablePop3 is set in snm
      143 # IMAP STARTTLS
      443 # HTTPS for roundcube and rspamd UI
      465 # SMTP TLS
      587 # SMTP STARTTLS
      993 # IMAP TLS
      #995 #POP3 TLS, enable if enablePop3Ssl is set in snm
      #4190 #sieve, enable if enableManageSieve is set in snm
    ];
    nat = {
      enable = true;
      internalInterfaces = [ "neb-serverNetwo" ];
      externalInterface = "ens6";
      forwardPorts = [
        #Email
        rec {
          sourcePort = 25;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 80;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 143;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 443;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 465;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 587;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
        rec {
          sourcePort = 993;
          proto = "tcp";
          destination = "${
            config.myModules.nebula."serverNetwork".ipMap.Email
          }:${builtins.toString sourcePort}";
        }
      ];
    };
  };

  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "any";
      proto = "any";
      group = "server";
    }
  ];
}
