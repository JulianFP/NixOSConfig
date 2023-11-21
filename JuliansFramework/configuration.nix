/*
main configuration file of JuliansFramework
structure:
- imports (networking and basic hardware stuff gets imported here)
- nix
- boot 
- hardware
- services 
- programs 
- environment (e.g. systemPackages)
- users
- security & virtualisation
- misc 
*/

{ lib, pkgs, inputs, ... }:

{
  /* -- imports -- */
  imports =
    [ 
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./networking.nix # import networking settings
    ];



  /* -- nix -- */
  # enable flakes and nix-command
  nix = {
    settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };



  /* -- boot -- */
  # config for bootloader and secure boot (refer to nixos.wiki/wiki/Secure_Boot)
  boot = {
    #use newest stable kernel instead of LTS (6.6 currently doesn't boot on my system)
    kernelPackages = pkgs.linuxPackages_6_5;

    #egpu set to PCIe 3.0 speed
    extraModprobeConfig = "options amdgpu pcie_gen_cap=0x40000";

    # Star Citizen tweaks
    kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };
  };



  /* -- hardware -- */
  hardware = {
    opengl = {
      # enable Vulkan (32- and 64-bit), Hardware Video encoding/decoding is done in nixos-hardware
      enable = true;
      driSupport = true;
      driSupport32Bit = true;

      # enable rocm support
      extraPackages = with pkgs.rocmPackages; [
        clr 
        clr.icd
      ];
    };

    bluetooth.enable = true;
    opentabletdriver.enable = true; #setup driver for wacom tablet
    xone.enable = true; #enable xone driver for Xbox One Controller Adapter
  };



  /* -- services -- */
  services = {
    # tlp service, power management (see powerManagement in misc for more)
    tlp = {
      enable = true;
      settings = {
        PCIE_ASPM_ON_BAT = "powersupersave";
      };
    };

    #logind disable lidSwitch and PowerButtoon (managed by wm)
    logind = {
      lidSwitch = "ignore";
      extraConfig = "HandlePowerKey=ignore";
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    #setup pipewire audio server (see environment and security for more)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # yubikey setup
    udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;

    fwupd.enable = true; #for Firmware updates
    flatpak.enable = true; #enable flatpak
    hardware.bolt.enable = true; #enable Thunderbolt Device management
  };



  /* -- programs -- */
  programs = {
    adb.enable = true; #android adb setup. See users user permission (adbusers group)
    virt-manager.enable = true; #to run qemu/kvm VMs. See virtualisation for more
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    partition-manager.enable = true; #enable kde partitionmanager (can't be done in HM, requires services)
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };



  /* -- environment (e.g. systemPackages) -- */
  environment = {
    #pipewire wireplumber bluetooth setup
    etc."wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      bluez_monitor.properties = {
        ["bluez5.enable-sbc-xq"] = true,
        ["bluez5.enable-msbc"] = true,
        ["bluez5.enable-hw-volume"] = true,
        ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
      }
    '';

    #env variables for qt theming stuff. See more in qt in misc
    variables = {
      QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
      RADV_PERFTEST = "nosam"; #performance improvement for eGPUs
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      intel-media-driver
      intel-gpu-tools
      bluez
      libsForQt5.frameworkintegration
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
      qt5.qtwayland
      qt6.qtwayland
      qt6ct

      # networking stuff
      networkmanager-l2tp

      (import ./shellScriptBin/egpu.nix {inherit pkgs;} )
      (import ./shellScriptBin/egpu2.nix {inherit pkgs;} )
      (import ./shellScriptBin/vlan.nix {inherit pkgs;} )

      #rocm stuff
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
    ];
  };



  /* -- users -- */
  users = {
    # Define julian account. Don't forget to set a password with ‘passwd’.
    users.julian = {
      isNormalUser = true;

      /*
      user groups:
        wheel: sudo/admin rights 
        networkmanager: network settings access 
        adbusers: adb/fastboot for android devices stuff 
        video, render: rocm support
      */
      extraGroups = [ "wheel" "networkmanager" "adbusers" "video" "render" ];

      packages = with pkgs; [
        rofi-wayland
      ];
    };
  };



  /* -- security & virtualisation -- */
  security = {
    # rtkit is recommended for pipewire 
    rtkit.enable = true;

    #enable polkit. polkit-kde-agent needs to be installed and started at boot seperately (will be done with Hyprland)
    polkit.enable = true;  

    # Swaylock needs an entry in PAM to proberly unlock
    pam.services.swaylock.text = ''
      # PAM configuration file for the swaylock screen locker. By default, it includes
      # the 'login' configuration file (see /etc/pam.d/login)
      auth include login
    '';
  };

  virtualisation = {
    waydroid.enable = true; #waydroid to run android apps
    libvirtd.enable = true; #for qemu/kvm VMs in virt-manager
    spiceUSBRedirection.enable = true; #for virt-manager usb forwarding
  };



  /* -- misc -- */
  # power usage optimization
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Set hardware clock behavior
  time.hardwareClockInLocalTime = true;

  #enable xdg desktop integration (mainly for flatpaks)
  xdg.portal.enable = true; 

  # qt theming stuff (has to be done on system level to proberly work because it uses qts plugin system)
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
