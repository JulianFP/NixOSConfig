{ ... }:

{
  imports = [
    ../../generic/valheim.nix
  ];

  services.valheim = {
    enable = true;
    serverName = "Esgehtbergab";
  };
}
