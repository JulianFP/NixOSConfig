{ ... }:

{
  imports = [
    ../../generic/valheim.nix
  ];

  services.valheim = {
    enable = true;
    port = 2458;
    serverName = "Fulcrum";
  };
}
