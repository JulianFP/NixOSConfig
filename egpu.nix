{ pkgs }:

# This script is heavily inspired by the all-ways-egpu project:
# https://github.com/ewagner12/all-ways-egpu
let
  zeroFile = ./0;
  oneFile = ./1;
in
  pkgs.writeShellScriptBin "HyprlandEgpu" ''
    GPU_COUNT=$(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | wc -l)
    if [ $GPU_COUNT -gt 1 ]; then
      for CARD in $(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | awk -F' ' '{print $1}'); do
        set -- /sys/bus/pci/devices/"$CARD"
        for BOOT_VGA_PATH in "$@"; do
          VENDOR=$(cat "$BOOT_VGA_PATH"/vendor)
          if [ $VENDOR = "0x8086" ]; then
            sudo mount -n --bind -o ro ${zeroFile} "$BOOT_VGA_PATH"/boot_vga 
          else 
            sudo mount -n --bind -o ro ${oneFile} "$BOOT_VGA_PATH"/boot_vga
          fi 
        done
      done
      Hyprland 
      for CARD in $(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | awk -F' ' '{print $1}'); do
        set -- /sys/bus/pci/devices/"$CARD"
        for BOOT_VGA_PATH in "$@"; do
          sudo umount -n "$BOOT_VGA_PATH"/boot_vga
        done
      done
    else
      echo "only one gpu detected. Plug in eGPU first"
    fi
  ''
