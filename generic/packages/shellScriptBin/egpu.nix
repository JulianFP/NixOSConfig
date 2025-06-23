{ pkgs }:

# This script is heavily inspired by the all-ways-egpu project:
# https://github.com/ewagner12/all-ways-egpu

# Removes integrated graphics completely
# very effective, maximum performance. However integrated display doesn't work anymore
pkgs.writeShellScriptBin "SwitchGPUs" ''
  #check if it runs as root. Elevates to root if not
  if [ "$(whoami)" != "root" ]; then
    echo "You need to run the script with root privileges. Attempting to raise via sudo:"
    sudo "$0" "$@"
    exit $?
  fi

  ( trap "" SIGHUP SIGTERM SIGINT SIGABRT
    GPU_COUNT=$(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | wc -l)
    if [ $GPU_COUNT -gt 1 ]; then
      #if more than one gpu is detected, then we disable the intel gpu

      #disable framebuffers and wait before disabling gpu
      set -- /sys/class/vtconsole/vtcon*/bind
      for VT in "$@"; do
        echo 0 > "$VT"
      done
      echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind
      echo "vesa-framebuffer.0" > /sys/bus/platform/drivers/vesa-framebuffer/unbind
      sleep 1

      #find intel gpu
      for CARD in $(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | awk -F' ' '{print $1}'); do
        DRIVER=$(${pkgs.pciutils}/bin/lspci -D -k | grep -A 3 $CARD | awk -F': ' 'index($1, "Kernel driver") { print $2 }')
        if [ $DRIVER = "i915" ]; then

          #disable gpu
          echo "$CARD" > /sys/bus/pci/drivers/"$DRIVER"/unbind
          echo 1 > /sys/bus/pci/devices/"$CARD"/remove

        fi
      done

      #enable framebuffers again
      set -- /sys/class/vtconsole/vtcon*/bind
      for VT in "$@"; do
        echo 1 > "$VT"
      done
      echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
      echo "vesa-framebuffer.0" > /sys/bus/platform/drivers/vesa-framebuffer/bind

    else
      #if only one gpu is detected, then we check if it is the AMD gpu and if it is, then we add the internal again
      #find amd gpu and set variable
      AMDGPU=0
      for CARD in $(${pkgs.pciutils}/bin/lspci -D -d ::0300 -n | awk -F' ' '{print $1}'); do
        DRIVER=$(${pkgs.pciutils}/bin/lspci -D -k | grep -A 3 $CARD | awk -F': ' 'index($1, "Kernel driver") { print $2 }')
        if [ $DRIVER = "amdgpu" ]; then
          AMDGPU=1
          echo 1 > /sys/bus/pci/rescan
        fi
      done
      if [ $AMDGPU -eq 0 ]; then
        echo "no egpu detected and internal gpu already active. Plug in eGPU first"
      fi
    fi
  )
''
