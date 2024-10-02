{ config, lib, hostName, ...}:

let
  mkNebulaInterface = import ./utils/mkNebulaInterface.nix;
  netName = "serverNetwork";
in 
{
  imports = [
    (mkNebulaInterface {
      inherit lib hostName netName;
      hostConfig = config;
      clientConfig = config;
    })
  ];
}
