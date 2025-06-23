{ ... }:

{
  imports = [
    ../../generic/valheim.nix
  ];

  myModules.valheim = {
    enable = true;
    serverName = "Esgehtbergab";
  };
}
