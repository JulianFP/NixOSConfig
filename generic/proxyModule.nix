{ config, lib, pkgs, hostName, ... }:

# This is the setup for all my (reverse) proxies. Currently I have one in the cloud that is exposed to the internet (IonosVPS) and one locally that is not (mainserver)
# for the first one edge is set, for the second not. The first one syncs ssl certs to the second one
let
  cfg = config.myModules.proxy;
in 
{
  options.myModules.proxy = {
    enable = lib.mkEnableOption ("Reverse-Proxy");
    proxies = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          destIP = lib.mkOption {
            type = lib.types.singleLineStr;
            description = "IP address to which this traffic should be forwarded";
          };
          destIPedge = lib.mkOption {
            type = lib.types.nullOr lib.types.singleLineStr;
            default = null;
            description = "Overwrite to destIP if isEdge is set to true.";
          };
          destPort = lib.mkOption {
            type = lib.types.port;
            description = "Port to which this traffic should be forwarded";
          };
          additionalLocations = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Additional entries to nginx's services.nginx.virtualHosts.<name>.locations option for this forward";
          };
        };
      });
    };
    isEdge = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this machine is an edge machine, e.g. accepting internet traffic on a VPS";
    };
    localProxyHostNames = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      description = "IP addresses of all local proxy so that edge server knows where to push certificates to. This requires that ssh is configured with matchBlocks for these hostNames.";
    };
    edgeHostName = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "hostName of edge server so that local proxies know from where to pull certificates. This requires that ssh is configured with a matchBlock for this hostName.";
    };
    localProxyCertDir = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "/persist/sslCerts";
      description = "Where the edge proxy should put SSL certs on the local proxy";
    };
    localDNS = {
      enable = lib.mkEnableOption ("Whether to enable a local DNS server for this machine that serves DNS entries of configured domains");
      localForwardIP = lib.mkOption {
        type = lib.types.singleLineStr;
        description = "IPv4 address to set A DNS entry of configured domains to";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.sops.secrets."openssh/${hostName}" != {};
        message = "Custom assertion: please setup ./generic/ssh-sops-key.nix and ./genericHM/ssh-sops-key.nix to use the proxy module";
      }
      {
        assertion = if cfg.localDNS.enable then config.services.unbound.enable else true;
        message = "Custom assertion: to use localDNS.enable in proxy module please configure unbound elsewhere. This just adds some entries to an existing unbound server";
      }
    ];

    #reverse proxy config
    services.nginx = {
      #boilerplate stuff
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      #hardened security settings
      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      #enable HSTS and other hardening (see nixos wiki)
      appendHttpConfig = ''
        map $scheme $hsts_header {
            https   "max-age=31536000; includeSubdomains; preload";
        }
        more_set_headers 'Strict-Transport-Security: $hsts_header';
        more_set_headers 'Referrer-Policy: strict-origin-when-cross-origin';
        more_set_headers 'X-Frame-Options: SAMEORIGIN';
        more_set_headers 'X-Content-Type-Options: nosniff';
        proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
      '';

      #allow uploads with file sizes up to 10G
      clientMaxBodySize = "10G";

      virtualHosts = lib.mkMerge (lib.mapAttrsToList (domain: domCfg: let
        forwardURL = if (domCfg.destIPedge != null)
          then "http://${domCfg.destIPedge}:${builtins.toString domCfg.destPort}"
          else "http://${domCfg.destIP}:${builtins.toString domCfg.destPort}";
      in {
        "${domain}" = {
          enableACME = lib.mkIf cfg.isEdge true;
          sslCertificate = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/${domain}/fullchain.pem";
          sslCertificateKey = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/${domain}/key.pem";
          sslTrustedCertificate = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/${domain}/chain.pem";
          forceSSL = true;
          http2 = true;
          locations = {
            "/" = {
              proxyPass = forwardURL;
              proxyWebsockets = true;
            };
          } // domCfg.additionalLocations;
        };
        #www redirect
        "www.${domain}" = {
          enableACME = lib.mkIf cfg.isEdge true;
          sslCertificate = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/www.${domain}/fullchain.pem";
          sslCertificateKey = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/www.${domain}/key.pem";
          sslTrustedCertificate = lib.mkIf (!cfg.isEdge) "${cfg.localProxyCertDir}/www.${domain}/chain.pem";
          forceSSL = true;
          http2 = true;
          globalRedirect = "${domain}";
        };
      }) cfg.proxies);
    };

    #setup acme for let's encrypt validation if this is on edge
    security.acme = lib.mkIf cfg.isEdge {
      acceptTerms = true;
      defaults.email = "admin@partanengroup.de";
      #ssh matchBlocks for local proxies have to be setup on edge server
      defaults.postRun = lib.strings.concatMapStrings (proxyHostName: 
        ''
          ${pkgs.openssh}/bin/ssh ${proxyHostName} "mkdir -p ${cfg.localProxyCertDir}"
          ${pkgs.openssh}/bin/scp -r $(pwd) ${proxyHostName}:${cfg.localProxyCertDir}/
          ${pkgs.openssh}/bin/ssh ${proxyHostName} "chown -R nginx:nginx ${cfg.localProxyCertDir}/*"
          ${pkgs.openssh}/bin/ssh ${proxyHostName} "systemctl restart nginx.service"
        ''
      ) cfg.localProxyHostNames;
    };
    #local proxy can also pull certs from IonosVPS if they are missing (e.g. after reinstall)
    systemd.services."pre-nginx" = lib.mkIf (!cfg.isEdge) {
      enable = true;
      script = ''
        mkdir -p ${cfg.localProxyCertDir}
        if ! ls -R ${cfg.localProxyCertDir} | grep -q "cert.pem"; then
            ${pkgs.openssh}/bin/scp -r ${cfg.edgeHostName}:/var/lib/acme/* ${cfg.localProxyCertDir}/
            chown -R nginx:nginx ${cfg.localProxyCertDir}/*
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      wantedBy = [ "nginx.service" ];
    };

    #Firewall stuff
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    services.nebula.networks."serverNetwork" = {
      firewall.inbound = [
        { #open up ssh
          port = "22";
          proto = "tcp";
          group = "edge";
        }
      ];
    };

    services.unbound.settings.server = lib.mkIf cfg.localDNS.enable {
      local-zone = builtins.concatLists (lib.mapAttrsToList (domain: _: 
        [
          "\"${domain}\" transparent"
          "\"www.${domain}\" transparent"
        ]
      ) cfg.proxies);
      local-data = builtins.concatLists (lib.mapAttrsToList (domain: _:
        [
          "\"${domain} 3600 IN A ${cfg.localDNS.localForwardIP}\""
          "\"www.${domain} 3600 IN A ${cfg.localDNS.localForwardIP}\""
        ]
      ) config.services.nginx.virtualHosts);
    };
  };
}
