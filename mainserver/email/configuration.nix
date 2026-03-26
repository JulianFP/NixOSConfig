{
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:

let
  mail_domain = "mail.partanengroup.de";
  rspamd_domain = "rspamd.${mail_domain}";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  #ACME with DNS challenge
  sops.secrets."ionos".sopsFile = ../../secrets/${hostName}/email.yaml;
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@partanengroup.de";
      dnsProvider = "ionos";
      environmentFile = config.sops.secrets."ionos".path;
      extraLegoFlags = [
        "--dns.resolvers=1.1.1.1:53,8.8.8.8:53"
      ];
      group = config.services.nginx.group;
    };
    certs = {
      ${mail_domain} = { };
      ${rspamd_domain} = { };
    };
  };

  sops.secrets."ldap_token" = {
    sopsFile = ../../secrets/${hostName}/ldap.yaml;
    owner = config.services.postfix.user;
    group = config.services.dovecot2.group;
  };
  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = mail_domain;
    domains = [ "partanengroup.de" ];

    mailDirectory = "/persist/backMeUp/vmail";
    sieveDirectory = "/persist/backMeUp/sieve";
    dkimKeyDirectory = "/persist/backMeUp/dkim";
    indexDir = "/persist/backMeUp/indexes";

    virusScanning = true;

    certificateScheme = "acme";

    ldap = {
      enable = true;
      uris = [ "ldaps://account.partanengroup.de:3636" ];
      bind = {
        dn = "dn=token";
        passwordFile = config.sops.secrets."ldap_token".path;
      };
      dovecot = rec {
        passAttrs = "user=mail";
        userFilter = "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(mail=%{user}))";
        passFilter = userFilter;

        #see https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/342
        userAttrs = ''
          =home=${config.mailserver.mailDirectory}/ldap/%{user}
        '';
      };
      postfix.filter = "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(mail=%s))";
      searchBase = "dc=account,dc=partanengroup,dc=de";
      searchScope = "sub";
    };

    #full text search
    fullTextSearch = {
      enable = true;
      autoIndex = true;
      enforced = "body";
      memoryLimit = 2000;
    };

    rejectRecipients = [
      "noreply@partanengroup.de"
    ];
    forwards = {
      "postmaster@partanengroup.de" = "julian@partanengroup.de";
      "abuse@partanengroup.de" = "julian@partanengroup.de";
      "admin@partanengroup.de" = "julian@partanengroup.de";
      "maro@partanengroup.de" = [
        "marvin@partanengroup.de"
        "robin@partanengroup.de"
      ];
    };
  };

  #disable mail rejection
  services.rspamd.extraConfig = ''
    actions {
      reject = null; # Disable rejects, default is 15
      add_header = 6; # Add header when reaching this score
      greylist = 4; # Apply greylisting when reaching this score
    }
  '';

  #webmail
  services.roundcube = {
    enable = true;
    hostName = mail_domain;
    dicts = with pkgs.aspellDicts; [
      en
      de
    ];
    extraConfig = ''
      $config['imap_host'] = 'ssl://${mail_domain}:993';
      $config['username_domain'] = [
        '${mail_domain}' => 'partanengroup.de',
      ];
      $config['smtp_host'] = 'ssl://%h:465';
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';
    '';
  };
  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 02:00:00";
    compression = "zstd";
    location = "/persist/backMeUp/roundcube/postgresqlBackup";
  };

  #access to rspamd web interface
  sops.secrets."rspamd_ui" = {
    sopsFile = ../../secrets/${hostName}/rspamd.yaml;
    owner = "nginx";
  };
  services.nginx = {
    enable = true;
    virtualHosts = {
      ${mail_domain} = {
        # roundcube nginx overwrite
        enableACME = false;
        acmeRoot = null; # DNS challenge
        useACMEHost = mail_domain;
      };
      ${rspamd_domain} = {
        forceSSL = true;
        useACMEHost = rspamd_domain;
        acmeRoot = null;
        basicAuthFile = config.sops.secrets."rspamd_ui".path;
        serverName = rspamd_domain;
        locations = {
          "/" = {
            proxyPass = "http://unix:/run/rspamd/worker-controller.sock:/";
          };
        };
      };
    };
  };

  #for migration
  services.dovecot2.extraConfig = "doveadm_password = Trash-80";
}
