{ config, lib, pkgs, hostName, ... }:

{
  services.prometheus = {
    enable = true;
    listenAddress = "localhost";

    #set scrape_interval to be the same for all jobs for grafana. See https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/
    globalConfig.scrape_interval = "10s";

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      {
        job_name = "cadvisor";
        static_configs = [{
          targets = [ "localhost:${toString config.services.cadvisor.port}" ];
        }];
      }
      { #configured in ./unbound.nix
        job_name = "unbound";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.unbound.port}" ];
        }];
      }
    ];

    #exporters that should run locally on host machine
    exporters = {
      node = {
        enable = true;
        listenAddress = "localhost";
        enabledCollectors = [
          #these are used by the Grafana dashboard below
          "systemd"
          "processes"
        ];
      };
    };
  };

  #cadvisor is often used for docker/kubernetes, but since systemd puts services in cgroups too this works with systemd as well
  services.cadvisor = {
    enable = true;
    listenAddress = "localhost";
  };

  #grafana for nice dashboards
  sops.secrets."grafana/admin" = {
    mode = "0440";
    owner = "grafana";
    sopsFile = ../secrets/${hostName}/grafana.yaml;
  };
  services.grafana = {
    enable = true;
    dataDir = "/persist/grafana";
    settings = {
      server = {
        http_addr = "48.42.0.2";
        enable_gzip = true;
      };
      security = {
        admin_email = "admin@partanengroup.de";
        admin_password = "$__file{${config.sops.secrets."grafana/admin".path}}";
      };
    };
    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          uid = "PBFA97CFB590B2093"; #this is referenced in some of my dashboards, so I make it declarative
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
          jsonData.timeInterval = config.services.prometheus.globalConfig.scrape_interval;
        }
      ];

      dashboards.settings.providers = [{
        name = "My declarative dashboards";
        options.path = "/etc/grafana-dashboards";
      }];
    };
  };

  #define grafana dashboards (obtained from https://grafana.com/grafana/dashboards)
  environment.etc = let
    grafana-dashboards = {
      "grafana-dashboards/node.json" = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
        hash = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
      };
      "grafana-dashboards/cadvisor.json" = ./grafana-dashboards/cadvisor.json;
      "grafana-dashboards/zfs.json" = ./grafana-dashboards/zfs.json;
      "grafana-dashboards/unbound.json" = pkgs.stdenv.mkDerivation {
        name = "unbound-dashboard";
        src = pkgs.fetchurl {
          url = "https://grafana.com/api/dashboards/21006/revisions/2/download";
          hash = "sha256-5hAlTsOj+Nb5KBSzYpZkr283TWW3xzEY7XiEkZyfcl8=";
        };
        phases = [ "installPhase" ];
        installPhase = ''
          ${pkgs.gnused}/bin/sed 's/\''${DS_PROMETHEUS}/PBFA97CFB590B2093/g' $src > $out
        '';
      };
    };  
  in lib.mapAttrs (_: value: {
    source = value;
    mode = "0440";
    user = "grafana";
    group = "grafana";
  }) grafana-dashboards;

  environment.persistence."/persist".directories = [
    "/var/lib/${config.services.prometheus.stateDir}"
  ];

  networking.firewall.allowedTCPPorts = [ 
    config.services.grafana.settings.server.http_port
  ];
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "${toString config.services.grafana.settings.server.http_port}";
      proto = "tcp";
      group = "admin";
    }
  ];
}
