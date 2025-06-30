{
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  networking.hosts = {
    #to access Kanidm using it's domain over local container ip
    "10.42.42.137" = [ "account.partanengroup.de" ];

    #to access itself, e.g. for roundcube webmail
    "127.0.0.1" = [ "mail.partanengroup.de" ];
  };

  sops.secrets."ldap_token" = {
    sopsFile = ../../secrets/${hostName}/ldap.yaml;
    owner = config.services.postfix.user;
    group = config.services.dovecot2.group;
  };
  mailserver = {
    enable = true;
    fqdn = "mail.partanengroup.de";
    domains = [ "partanengroup.de" ];

    mailDirectory = "/persist/backMeUp/vmail";
    sieveDirectory = "/persist/backMeUp/sieve";
    dkimKeyDirectory = "/persist/backMeUp/dkim";
    indexDir = "/persist/backMeUp/indexes";

    virusScanning = true;

    certificateScheme = "acme-nginx";

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

    forwards = {
      "postmaster@partanengroup.de" = "julian@partanengroup.de";
      "abuse@partanengroup.de" = "julian@partanengroup.de";
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
    hostName = config.mailserver.fqdn;
    dicts = with pkgs.aspellDicts; [
      en
      de
    ];
    extraConfig = ''
      $config['imap_host'] = 'ssl://${config.mailserver.fqdn}:993';
      $config['username_domain'] = [
        '${config.mailserver.fqdn}' => 'partanengroup.de',
      ];
      $config['smtp_host'] = 'ssl://%h:465';
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';
    '';
  };
  systemd.tmpfiles.settings."10-postgresql"."/persist/backMeUp/roundcube/postgres"."d" = {
    user = "postgres";
    group = "postgres";
    mode = "0700";
  };
  services.postgresql.dataDir = "/persist/backMeUp/roundcube/postgres";

  #access to rspamd web interface
  sops.secrets."rspamd_ui" = {
    sopsFile = ../../secrets/${hostName}/rspamd.yaml;
    owner = "nginx";
  };
  services.nginx = {
    enable = true;
    virtualHosts.rspamd = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.sops.secrets."rspamd_ui".path;
      serverName = "rspamd.mail.partanengroup.de";
      locations = {
        "/" = {
          proxyPass = "http://unix:/run/rspamd/worker-controller.sock:/";
        };
      };
    };
  };

  #for migration
  services.dovecot2.extraConfig = "doveadm_password = Trash-80";

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@partanengroup.de";
  };
}
