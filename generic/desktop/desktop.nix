/*
  shared config file for desktop PCs
  like JuliansPC, JuliansFramework
  structure:
  - imports (networking, impermanence and shared hardware stuff gets imported here)
  - boot
  - hardware
  - services
  - programs
  - environment (e.g. systemPackages)
  - users
  - security & virtualisation
  - misc
*/
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # -- imports --
  imports = [
    ../common.nix
    ../impermanence.nix
    ./networking.nix
    ./vpn-uni-heidelberg.nix
  ];

  # -- boot --
  boot.kernelPackages = pkgs.linuxPackages_6_17;

  # -- hardware --
  # enable Vulkan (32- and 64-bit), Hardware Video encoding/decoding is done in nixos-hardware
  hardware = {
    graphics.enable = true;
    bluetooth.enable = true;
    xone.enable = true; # enable xone driver for Xbox One Controller Adapter
  };

  # -- services --
  services = {
    #logind disable lidSwitch and PowerButtoon (managed by wm)
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandlePowerKey = "ignore";
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

    flatpak.enable = true; # enable flatpak

    nixseparatedebuginfod2.enable = true;

    kanidm = {
      package = pkgs.kanidm_1_8;
      enableClient = true;
      clientSettings.uri = "https://account.partanengroup.de";
    };
  };

  # -- programs --
  programs = {
    adb.enable = true; # android adb setup. See users user permission (adbusers group)
    virt-manager.enable = true; # to run qemu/kvm VMs. See virtualisation for more
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    partition-manager.enable = true; # enable kde partitionmanager (can't be done in HM, requires services)
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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd
      ];
    };
  };

  # -- environment (e.g. systemPackages) --
  environment = {
    variables = {
      #for kde theming support
      QT_PLUGIN_PATH = [
        "${pkgs.kdePackages.qqc2-desktop-style}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}"
      ];
      QML2_IMPORT_PATH = [
        "${pkgs.kdePackages.qqc2-desktop-style}/${pkgs.kdePackages.qtbase.qtQmlPrefix}"
      ];
    };

    systemPackages = with pkgs; [
      bluez

      #for virtualisation virt-manager
      virtiofsd

      #to add compose support to podman
      podman-compose
    ];

    #additional impermanence directories
    persistence."/persist".directories = [
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
      "/var/lib/waydroid"
      "/var/lib/libvirt"
      "/etc/secureboot"
      "/var/cache/nixseparatedebuginfod" # to stop nixseparatedebuginfod to re-index at every reboot
    ];
  };

  # -- users --
  sops.secrets = {
    "users/root" = {
      neededForUsers = true;
      sopsFile = ../../secrets/users.yaml;
    };
    "users/julian" = {
      neededForUsers = true;
      sopsFile = ../../secrets/users.yaml;
    };
  };

  users = {
    users.root.hashedPasswordFile = config.sops.secrets."users/root".path;
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
      extraGroups = [
        "wheel"
        "networkmanager"
        "adbusers"
        "video"
        "render"
        "dialout"
        "wireshark"
        "podman"
      ];

      packages = with pkgs; [
        rofi
      ];

      openssh.authorizedKeys.keyFiles = lib.lists.optional config.services.openssh.enable ../../publicKeys/yubikey-new_ssh.pub;
    };
  };

  # -- security & virtualisation --
  security = {
    # rtkit is recommended for pipewire
    rtkit.enable = true;

    #enable polkit. polkitagent needs to be started separately (will be done in home-manager)
    polkit.enable = true;

    # Hyprlock needs an entry in PAM to properly unlock
    pam.services.hyprlock = { };

    #enable basic tpm2 support for clevis
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  virtualisation = {
    waydroid.enable = true; # waydroid to run android apps
    libvirtd.enable = true; # for qemu/kvm VMs in virt-manager
    spiceUSBRedirection.enable = true; # for virt-manager usb forwarding
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # -- misc --
  #enable xdg desktop integration (mainly for flatpaks)
  xdg.portal.enable = true;

  systemd = {
    #this makes shutdowns and reboots quicker by not waiting nearly as long for services to stop (90s -> 5s)
    settings.Manager.DefaultTimeoutStopSec = "5s";
    user.extraConfig = "DefaultTimeoutStopSec=5s";

    #workaround until https://github.com/nix-community/impermanence/issues/229 is fixed
    suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };

  #workaround until https://github.com/nix-community/impermanence/issues/229 is fixed
  boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];

  #enable cachix for nix-gaming
  nix.settings = {
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  #stylix define system wide theme (can be overwritten on a per-user level in home-manager)
  stylix = {
    enable = true;
    image = pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/4d/wallhaven-4dmxg4.jpg";
      hash = "sha256-TjbV20mckBX4QcvKgzxLaXAZgn0qQvFVtl34csEsm+U=";
      curlOptsList = [ "-HUser-Agent: Wget/1.21.4" ]; # some sides want a valid user agent
    };
    polarity = "dark";
    override = {
      # swap 'cause better. Comments should not be blue
      base03 = config.stylix.base16Scheme.base0D;
      base0D = config.stylix.base16Scheme.base03;
    };
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-soft.yaml";
    fonts = {
      serif = config.stylix.fonts.sansSerif;
      monospace = {
        package = pkgs.nerd-fonts.dejavu-sans-mono;
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
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus";
    };
  };
}
