{ inputs, pkgs, ... }:

{
  imports = [
    inputs.foundryvtt.nixosModules.foundryvtt
  ];

  services.foundryvtt = {
    enable = true;
    package = inputs.foundryvtt.packages.${pkgs.stdenv.hostPlatform.system}.foundryvtt_12;
    hostName = "vtt.partanengroup.de";
    dataDir = "/persist/backMeUp/foundryvtt";
    minifyStaticFiles = true;
    proxyPort = 443;
    proxySSL = true;
    upnp = false;
  };
}
