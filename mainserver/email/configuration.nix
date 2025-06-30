{
  config,
  inputs,
  hostName,
  ...
}:

{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  #to access Kanidm using it's domain over local container ip
  networking.hosts."10.42.42.137" = [ "account.partanengroup.de" ];

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
        userFilter = "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(mail=%{user}))";
        passFilter = userFilter;
      };
      postfix.filter = "(&(class=account)(memberof=spn=mail-server@account.partanengroup.de)(mail=%s))";
      searchBase = "dc=account,dc=partanengroup,dc=de";
      searchScope = "sub";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@partanengroup.de";
  };
}
