/*
main configuration file of JuliansFramework
structure:
- imports (networking and basic hardware stuff gets imported here)
- boot 
- hardware
- services 
- programs 
- environment (e.g. systemPackages)
- users
- security & virtualisation
- misc 
*/

{ lib, config, pkgs, inputs, hostName, ... }:

{
  /* -- imports -- */
  imports =
    [ 
      inputs.impermanence.nixosModules.impermanence
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./networking.nix # import networking settings
    ];



  /* -- boot -- */
  # config for bootloader and secure boot (refer to https://wiki.nixos.org/wiki/Secure_Boot)
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    #egpu set to PCIe 3.0 speed
    extraModprobeConfig = "options amdgpu pcie_gen_cap=0x40000";

    # Star Citizen tweaks
    kernel.sysctl = {
      "vm.max_map_count" = lib.mkDefault 16777216; #also set by nix-gaming
      "fs.file-max" = 524288;
    };
  };



  /* -- hardware -- */
  hardware = {
    graphics = {
      # enable Vulkan (32- and 64-bit), Hardware Video encoding/decoding is done in nixos-hardware
      enable = true;

      # enable rocm support
      extraPackages = with pkgs.rocmPackages; [
        clr 
        clr.icd
      ];
    };

    bluetooth.enable = true;
    xone.enable = true; #enable xone driver for Xbox One Controller Adapter
  };



  /* -- services -- */
  services = {
    # tlp service, power management (see powerManagement in misc for more)
    tlp = {
      enable = true;
      settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        PLATFORM_PROFILE_ON_AC="performance";
        PLATFORM_PROFILE_ON_BAT="low-power";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
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
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    #setup pipewire audio server (see environment and security for more)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber = {
        enable = true;
        #pipewire wireplumber bluetooth setup
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
            bluez_monitor.properties = {
              ["bluez5.enable-sbc-xq"] = true,
              ["bluez5.enable-msbc"] = true,
              ["bluez5.enable-hw-volume"] = true,
              ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
            }
          '')
        ];
      };
      #nix-gaming pipewire low latency
      lowLatency.enable = true;
    };

    # yubikey setup
    udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;

    fwupd.enable = true; #for Firmware updates
    flatpak.enable = true; #enable flatpak
    hardware.bolt.enable = true; #enable Thunderbolt Device management
    
    nixseparatedebuginfod.enable = true;
  };



  /* -- programs -- */
  programs = {
    adb.enable = true; #android adb setup. See users user permission (adbusers group)
    virt-manager.enable = true; #to run qemu/kvm VMs. See virtualisation for more
    hyprland.enable = true;
    partition-manager.enable = true; #enable kde partitionmanager (can't be done in HM, requires services)
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      #nix-gaming steam platform optimizations
      platformOptimizations.enable = true;
    };
    gamemode.enable = true;
    noisetorch.enable = true;
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
  };



  /* -- environment (e.g. systemPackages) -- */
  environment = {
    variables = {
      RADV_PERFTEST = "nosam"; #performance improvement for eGPUs
      ESP_PATH = "/boot"; #since with my setup the mount point in fstab is set to /root/boot this variable ensures that sbctl still finds efi partition
    };

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      intel-media-driver
      intel-gpu-tools
      bluez

      # networking stuff
      networkmanager-l2tp

      (import ./shellScriptBin/egpu.nix {inherit pkgs;} )
      (import ./shellScriptBin/egpu2.nix {inherit pkgs;} )
      (import ./shellScriptBin/vlan.nix {inherit pkgs;} )

      #rocm stuff
      rocmPackages.rocminfo
      rocmPackages.rocm-smi

      #for virtualisation virt-manager
      virtiofsd

      #clevis for initrd decryption management
      clevis
    ];

    #impermanence setup
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        "/var/lib/boltd"
        "/var/lib/fprint"
        "/var/lib/waydroid"
        "/etc/secureboot"
      ];
      files = [
        "/etc/machine-id"
      ];
    };
  };



  /* -- users -- */
  sops.secrets."users/julian" = {
    neededForUsers = true;
    sopsFile = ../secrets/${hostName}/users.yaml;
  };

  users = {
    # Define julian account. Don't forget to set a password with ‘passwd’.
    users.julian = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."users/julian".path;

      /*
      user groups:
        wheel: sudo/admin rights 
        networkmanager: network settings access 
        adbusers: adb/fastboot for android devices stuff 
        video, render: rocm support
        dialout: serial device access for arduino-ide
      */
      extraGroups = [ "wheel" "networkmanager" "adbusers" "video" "render" "dialout" "wireshark" ];

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

    #enable basic tpm2 support for clevis
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
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
    #disable powertop for now since it messes up my usb devices
    #powertop.enable = true;
  };

  #enable xdg desktop integration (mainly for flatpaks)
  xdg.portal.enable = true; 

  systemd = let
    shutdownServiceTimout = "DefaultTimeoutStopSec=5s";
  in {
    #this makes shutdowns and reboots quicker by not waiting nearly as long for services to stop (90s -> 5s)
    extraConfig = shutdownServiceTimout;
    user.extraConfig = shutdownServiceTimout;

    #shutdown timer and service
    services."shutdown" = {
      startAt = "*-*-* 00:15:00"; #automatically configures timer for this service
      #shutdown only happens if logFile exists, currentTime is between 00:10 and 00:20 and the logFile was last modified today
      script = ''
        currentTime=$(date +%H:%M)
        currentDay=$(date +%Y%m%d)
        logFile="/home/julian/shutdownFailures.log"
        if [ -f "$logFile" ]; then
            logFileModifyDay=$(date +%Y%m%d -r "$logFile")
            if [[ "$currentTime" > "00:10" ]] && [[ "$currentTime" < "00:20" ]] && [[ "$logFileModifyDay" == "$currentDay" ]]; then
                sed -i '$ d' "$logFile"
                shutdown now
            else
                echo "shutdown.service executed at incorrect time or shutdown-reminder didn't run today" >> "$logFile"
            fi
        else
            echo "$logFile missing, shutdown-reminder didn't run?" >> "$logFile"
            chown julian:users "$logFile"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };

  #enable cachix for nix-gaming
  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org" ];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  #stylix define system wide theme (can be overwritten on a per-user level in home-manager)
  stylix = {
    enable = true;
    image = pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/4d/wallhaven-4dmxg4.jpg";
      hash = "sha256-TjbV20mckBX4QcvKgzxLaXAZgn0qQvFVtl34csEsm+U=";
      curlOptsList = ["-HUser-Agent: Wget/1.21.4"]; #some sides want a valid user agent
    };
    polarity = "dark";
    override = { #swap 'cause better. Comments should not be blue
      base03 = config.stylix.base16Scheme.base0D;
      base0D = config.stylix.base16Scheme.base03;
    };
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";
    fonts = {
      serif = config.stylix.fonts.sansSerif;
      monospace = {
        package = pkgs.nerdfonts;
        name = "DejaVuSansM Nerd Font Mono";
      };
      sizes = {
        applications = 13;
        desktop = 12;
        popups = 14;
      };
    };
    opacity = {
      desktop = 0.6;
      popups = 0.6;
    };
    cursor = {
      package = pkgs.capitaine-cursors;
      name = "capitaine-cursors";
      size = 24;
    };
  };
}
