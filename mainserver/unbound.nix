{ pkgs, config, ... }:

let
  #courtesy of https://www.reddit.com/r/NixOS/comments/innzkw/pihole_style_adblock_with_nix_and_unbound/
  blocklistLocalZones = pkgs.stdenv.mkDerivation {
    name = "StevenBlack-blocklist-unbound";

    src = (pkgs.fetchFromGitHub {
      owner = "StevenBlack";
      repo = "hosts";
      rev = "3.15.13";
      sha256 = "sha256-FBq7yonwKPh57ZYI4XUqYZZyxTWON3Ox5i45qYELkSs=";
    } + "/hosts");

    phases = [ "installPhase" ];

    installPhase = ''
      ${pkgs.gawk}/bin/awk '{sub(/\r$/,"")} {sub(/^127\.0\.0\.1/,"0.0.0.0")} BEGIN { OFS = "" } NF == 2 && $1 == "0.0.0.0" { print "local-zone: \"", $2, "\" static"}' $src | tr '[:upper:]' '[:lower:]' | sort -u >  $out
    '';
  };
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
          control-interface = "/run/unbound/unbound.socket";
        };
      };
    };

    prometheus.exporters.unbound = {
      enable = true;
      listenAddress = "localhost";
      unbound.host = "unix:///run/unbound/unbound.socket";
    };
  };

  systemd.tmpfiles.settings."10-unbound"."/persist/unbound"."d" = {
    user = config.services.unbound.user;
    group = config.services.unbound.group;
    mode = "0700";
  };

  networking.firewall = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };
}
