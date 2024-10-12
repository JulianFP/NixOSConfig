{ config, ... }:

{
  imports = [ 
    ./nebulaModule.nix
  ];

  myModules.nebula.interfaces."serverNetwork" = {
    serverFirewallRules = config.services.openssh.enable;
  };
}
