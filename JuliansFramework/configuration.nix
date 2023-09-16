# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./networking.nix # import networking settings

      # choose between the following (exactly one has to be commented out)
      ./lanzaboote.nix # import settings for secureboot enabled bootloader
      #./systemd-boot.nix # import settings for systems without secureboot

      ./nebula.nix # import settings for nebula (comment out if keyfiles not present yet)
    ];

  # config for bootloader and secure boot (refer to nixos.wiki/wiki/Secure_Boot)
  boot = {
    #use newest stable kernel instead of LTS
    kernelPackages = pkgs.linuxPackages_latest;

    #egpu set to PCIe 3.0 speed
    extraModprobeConfig = "options amdgpu pcie_gen_cap=0x40000";

    # Star Citizen tweaks
    kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };
  };

  # power usage optimization
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.tlp = {
    enable = true;
    settings = {
      PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  # enable Vulkan (32- and 64-bit), Hardware Video encoding/decoding is done in nixos-hardware
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  #logind disable lidSwitch and PowerButtoon (managed by wm)
  services.logind = {
    lidSwitch = "ignore";
    extraConfig = "HandlePowerKey=ignore";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    # font = "Lat2-Terminus16";
    keyMap = "de";
    useXkbConfig = false; # use xkbOptions in tty.
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.bluetooth.enable = true;
  # setup pipewire 
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  environment.etc = {
	"wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
		bluez_monitor.properties = {
			["bluez5.enable-sbc-xq"] = true,
			["bluez5.enable-msbc"] = true,
			["bluez5.enable-hw-volume"] = true,
			["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
		}
	'';
  };

  # setup zsh and define it as default shell for every user
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable sudo and network settings for user
    packages = with pkgs; [
      rofi-wayland
    ];
  };

  security.polkit.enable = true; #enable polkit. polkit-kde-agent needs to be installed and started at boot seperately (will be done with Hyprland) 
  programs.hyprland.enable = true; #Hyprland NixOS Module (required)
  programs.dconf.enable = true; #needed for home-manager
  services.fwupd.enable = true; #for Firmware updates
  hardware.opentabletdriver.enable = true; #setup driver for wacom tablet
  hardware.xone.enable = true; #enable xone driver for Xbox One Controller Adapter
  services.flatpak.enable = true; #enable flatpak
  xdg.portal.enable = true; #enable xdg desktop integration (mainly for flatpaks)
  services.hardware.bolt.enable = true; #enable Thunderbolt Device management
  programs.partition-manager.enable = true; #enable kde partitionmanager (can't be done in HM, requires services)
  programs.steam.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    intel-media-driver
    intel-gpu-tools
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
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
  ];

  # yubikey setup
  services.udev.packages = [ pkgs.yubikey-personalization ];
  services.pcscd.enable = true;

  # qt theming stuff (has to be done on system level to proberly work because it uses qts plugin system)
  environment.variables = {
    QT_STYLE_OVERRIDE = "kvantum";
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
    RADV_PERFTEST = "nosam"; #performance improvement for eGPUs
  };
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  # Swaylock needs an entry in PAM to proberly unlock
  security.pam.services.swaylock.text = ''
    # PAM configuration file for the swaylock screen locker. By default, it includes
    # the 'login' configuration file (see /etc/pam.d/login)
    auth include login
  '';

  # enable flakes and nix-command
  nix = {
    package = pkgs.nixFlakes;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}