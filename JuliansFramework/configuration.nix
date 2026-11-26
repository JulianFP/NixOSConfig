{ pkgs, hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
    ./robotics_practical.nix
  ];

  # FZI ssh private key
  sops.secrets."prakti_ws26_max" = {
    sopsFile = ../secrets/${hostName}/privatekey.yaml;
    owner = "julian";
    group = "users";
    mode = "0400";
    path = "/home/julian/.ssh/prakti_ws26_max";
  };

  #opencode API keys
  sops.secrets.kit-toolbox-api-key = {
    sopsFile = ../secrets/${hostName}/opencode.yaml;
    key = "api_keys/kit_toolbox";
    owner = "julian";
    group = "users";
    mode = "0400";
  };

  boot = {
    #egpu set to PCIe 3.0 speed
    extraModprobeConfig = "options amdgpu pcie_gen_cap=0x40000";
  };

  services = {
    # tlp service, power management (see powerManagement in misc for more)
    tlp = {
      enable = true;
      settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        PCIE_ASPM_ON_BAT = "powersupersave";
      };
    };

    fwupd.enable = true; # for Firmware updates
    hardware.bolt.enable = true; # enable Thunderbolt Device management

    automatic-timezoned.enable = true; # automatic timezone switcher
    geoclue2.geoProviderUrl = "https://api.beacondb.net/v1/geolocate"; # mozilla's service is deprecated
  };

  programs.zoom-us.enable = true;

  environment = {
    variables = {
      RADV_PERFTEST = "nosam"; # performance improvement for eGPUs
    };

    systemPackages = with pkgs; [
      intel-media-driver
      intel-gpu-tools

      (import ../generic/packages/shellScriptBin/egpu.nix { inherit pkgs; })
      (import ../generic/packages/shellScriptBin/egpu2.nix { inherit pkgs; })
    ];

    persistence."/persist".directories = [
      "/var/lib/boltd"
      "/var/lib/fprint"
    ];
  };

  # power usage optimization
  powerManagement = {
    enable = true;
    #disable powertop for now since it messes up my usb devices
    #powertop.enable = true;
  };
}
