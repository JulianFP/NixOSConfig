{ pkgs, lib, config, ... }:

#Thanks to ar51an for providing this awesome Grafana dashboard and prometheus/loki setup for unbound!
#Most related stuff stolen from https://github.com/ar51an/unbound-dashboard

let
  #courtesy of https://www.reddit.com/r/NixOS/comments/innzkw/pihole_style_adblock_with_nix_and_unbound/
  blocklistLocalZones = pkgs.stdenv.mkDerivation {
    name = "StevenBlack-blocklist-unbound";

    src = (pkgs.fetchFromGitHub {
      owner = "StevenBlack";
      repo = "hosts";
      rev = "3.15.15";
      sha256 = "sha256-wycPhloUQY24wUDFWd/URRlFUiW2hi/wcohrWQ5R8E4=";
    } + "/hosts");

    phases = [ "installPhase" ];

    installPhase = ''
      ${pkgs.gawk}/bin/awk '{sub(/\r$/,"")} {sub(/^127\.0\.0\.1/,"0.0.0.0")} BEGIN { OFS = "" } NF == 2 && $1 == "0.0.0.0" { print "local-zone: \"", $2, "\" always_null"}' $src | tr '[:upper:]' '[:lower:]' | sort -u >  $out
    '';
  };
  unboundSocketPath = "/run/unbound/unbound.socket";
  unboundLogFileDir = "/persist/unbound-log";
  unboundLogFilePath = "${unboundLogFileDir}/unbound.log"; #different from unbound stateDir below because to that only unbound has access and not promtail. Dir also has to already exist
in 
{
  services = {
    unbound = {
      enable = true;
      stateDir = "/persist/unbound";

      settings = {
        server = let
          threads = 16; #power of 2 for slabs
        in {
          interface = [ "192.168.3.10" ];
          
          access-control = [ "192.168.0.0/16 allow" ];

          #security settings
          harden-glue = true;
          harden-dnssec-stripped = true;
          hide-identity = true;
          hide-version = true;
          tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";

          #performance tuning
          #multi-threading
          num-threads = threads;
          msg-cache-slabs = threads;
          rrset-cache-slabs = threads;
          infra-cache-slabs = threads;
          key-cache-slabs = threads;
          so-reuseport = true;

          #cache size
          msg-cache-size = "100m";
          rrset-cache-size = "200m"; #should be roughly double msg-cache-size
          prefetch = true;
          prefetch-key = true;
          cache-min-ttl = 0;
          serve-expired = true;
          serve-expired-reply-ttl = 0;
          serve-expired-client-timeout = 0;

          extended-statistics = true; #for prometheus statistics

          #for loki and fancy Grafana dashboard
          verbosity = 0;
          log-replies = true;
          log-tag-queryreply = true;
          log-local-actions = true;
          logfile = unboundLogFilePath;

          #include blocklist
          include = [ "${blocklistLocalZones}" ];
        };

        forward-zone = [{
          name = ".";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
          forward-tls-upstream = true;
        }];

        #for prometheus exporter
        remote-control = {
          control-enable = true;
          control-interface = unboundSocketPath;
          control-use-cert = false;
        };
      };
    };
  };
  systemd.services."unbound".serviceConfig.ReadWritePaths = [ unboundLogFileDir ];

  services.logrotate = {
    enable = true;
    allowNetworking = true; #required for postrotate script
    settings."${unboundLogFilePath}" = {
      su = "${config.services.unbound.user} ${config.services.unbound.group}";
      frequency = "daily";
      rotate = 7;
      missingok = true;
      compress = true;
      delaycompress = true;
      notifempty = true;
      postrotate = ''
        ${pkgs.unbound}/bin/unbound-control log_reopen
      '';
    };
  };

  services.promtail.configuration.scrape_configs = [{
    job_name = "unbound";
    static_configs = [{
      targets = [ "localhost" ];
      labels = {
        job = "unbound";
        __path__ = unboundLogFilePath;
      };
    }];
    pipeline_stages = [
      {
        labeldrop = [ "filename" ];
      }
      {
        match = {
          selector = ''
            {job="unbound"} |~ " start | stopped |.*in-addr.arpa."
          '';
          action = "drop";
        };
      }
      {
        match = {
          selector = ''
            {job="unbound"} |= "reply:"
          '';
          stages = [{
            static_labels.dns = "reply";
          }];
        };
      }
      {
        match = {
          selector = ''
            {job="unbound"} |~ "always_null|redirect |always_nxdomain"
          '';
          stages = [{
            static_labels.dns = "block";
          }];
        };
      }
    ];
  }];
  users.users.promtail.extraGroups = lib.mkIf config.services.promtail.enable [ config.services.unbound.group ];

  systemd.services."prometheus-unbound-exporter-by-ar51an" = let
    package = (pkgs.callPackage ../generic/packages/prometheus-unbound-exporter-by-ar51an/default.nix {});
  in {
    description = "Prometheus Unbound Exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      User = "root";
      ExecStart = ''
        ${package}/bin/unbound-exporter \
        --web.listen-address 127.0.0.1:9167 \
        --block-file "${blocklistLocalZones}" \
        --unbound.uri "unix://${unboundSocketPath}"
      '';
    };
  };

  systemd.tmpfiles.settings."10-unbound" = {
    "/persist/unbound"."d" = {
      user = config.services.unbound.user;
      group = config.services.unbound.group;
      mode = "0700";
    };
    "/persist/unbound-log"."d" = {
      user = config.services.unbound.user;
      group = config.services.unbound.group;
      mode = "0770";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };
}
