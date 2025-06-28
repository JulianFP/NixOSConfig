{
  pkgs,
  envFile,
  oldConfigFile,
}:
let
  unsafeRoutes = {
    "Telgte server network" = {
      route = "192.168.3.0/24";
      via = "48.42.0.2";
    };
    "Telgte home network" = {
      route = "192.168.1.0/24";
      via = "48.42.0.2";
    };
    "Heidelberg home network" = {
      route = "192.168.10.0/24";
      via = "48.42.0.8";
    };
  };

  python-packages =
    ps: with ps; [
      pyyaml
    ];

  nebulaOverwriter = ./nebulaOverwriter.py;

  unsafeRoutesFile = pkgs.writeText "nebulaUnsafeRoutes" (builtins.toJSON unsafeRoutes); # json is also yaml
  workingDirectory = "/persist/nebulaOverwriter";
  newConfigFile = "/persist/nebulaOverwriter/newConfigFile.yml";
in

# toggle the usage of unsafe_routes in nebula overlay network
pkgs.writeShellScriptBin "toggleNebulaUnsafeRoutes" ''
  #check if it runs as root. Elevates to root if not
  if [ "$(whoami)" != "root" ]; then
  echo "You need to run the script with root privileges. Attempting to raise via sudo:"
  sudo "$0" "$@"
  exit $?
  fi

  #ensure dir exists
  mkdir -p "${workingDirectory}"

  ${pkgs.python3.withPackages python-packages}/bin/python "${nebulaOverwriter}" "${oldConfigFile}" "${unsafeRoutesFile}" "${newConfigFile}" "${envFile}"
''
