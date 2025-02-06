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
          additionalConfig = lib.mkOption {
            type = lib.types.lines;
            default = '''';
            description = "Additional config added to the virtualHosts section (e.g. for adding additional locations)";
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

    sops.secrets."redis/caddy-server" = lib.mkIf cfg.isEdge {
      mode = "0440";
      owner = config.services.redis.servers."caddy-storage".user;
      sopsFile = ../secrets/${hostName}/redis.yaml;
    };
    sops.secrets."redis/caddy-client" = {
      mode = "0440";
      owner = config.services.caddy.user;
      sopsFile = ../secrets/${hostName}/redis.yaml;
    };

    services.redis.servers."caddy-storage" = lib.mkIf cfg.isEdge {
      enable = true;
      port = 7000;
      bind = "127.0.0.1 48.42.0.5";
      requirePassFile = config.sops.secrets."redis/caddy-server".path;
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/pberkel/caddy-storage-redis@v1.4.0" ];
        hash = "sha256-xtg5SH1w99tY2hOdo1hlo6W4zoP8O+q7GimeTfPGqy8=";
      };
      dataDir = "/persist/caddy";
      email = "admin@partanengroup.de";
      globalConfig = ''
        storage redis {
          host ${if cfg.isEdge then "127.0.0.1" else "48.42.0.5"}
          port 7000
          password "{$REDIS_PASSWORD}"
        }
      '';
      virtualHosts = let
        sharedConfig = ''
          #configure hsts
          header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload"
          #compression
          encode zstd gzip
        '';
        domainList = builtins.concatStringsSep ", " (lib.mapAttrsToList (domain: _: "www.${domain}") cfg.proxies);
      in {
        "${domainList}" = {
          logFormat = ''
            output file ${config.services.caddy.logDir}/access-www-redirects.log
          '';
          extraConfig = sharedConfig + ''
              #redirect www domains
              redir https://{labels.1}.{labels.0}{uri}
          '';
        };
      } // builtins.mapAttrs (domain: domCfg: let
        
        forwardURL = if (domCfg.destIPedge != null)
          then "http://${domCfg.destIPedge}:${builtins.toString domCfg.destPort}"
          else "http://${domCfg.destIP}:${builtins.toString domCfg.destPort}";
      in {
        extraConfig = sharedConfig + domCfg.additionalConfig + ''
          #reverse proxy
          reverse_proxy ${forwardURL}
        '';
      }) cfg.proxies;
    };
    systemd.tmpfiles.settings."10-caddy"."/persist/caddy"."d" = {
      user = config.services.caddy.user;
      group = config.services.caddy.group;
      mode = "0700";
    };
    systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets."redis/caddy-client".path;

    #Firewall stuff
    networking.firewall.allowedTCPPorts = [ 80 443 7000 ];
    services.nebula.networks."serverNetwork" = {
      firewall.inbound = [
        { #open up ssh
          port = "22";
          proto = "tcp";
          group = "edge";
        }
      ] ++ lib.optional cfg.isEdge {
          port = "7000";
          proto = "tcp";
          group = "edge";
      };
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
      ) cfg.proxies);
    };
  };
}
