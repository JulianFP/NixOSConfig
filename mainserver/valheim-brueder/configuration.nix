{ ... }:

{
  imports = [
    ../../generic/valheim.nix
  ];

  myModules.valheim = {
    enable = true;
    port = 2458;
    serverName = "Fulcrum";
  };
}
