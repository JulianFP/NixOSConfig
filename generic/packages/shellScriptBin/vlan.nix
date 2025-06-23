{ pkgs }:

# toggles VLAN on and off
pkgs.writeShellScriptBin "toggleVLAN" ''
  # create vlan interface and ip address according to Arch wiki: https://wiki.archlinux.org/title/VLAN#Instant_Configuration

  #set variables to your liking
  vlan=3
  ip=192.168.3.50
  broadcast=192.168.3.255
  gateway=192.168.3.1
  subnet=/24



  #check if it runs as root. Elevates to root if not
  if [ "$(whoami)" != "root" ]; then
  echo "You need to run the script with root privileges. Attempting to raise via sudo:"
  sudo "$0" "$@"
  exit $?
  fi

  # Ask for interface
  PS3="Select desired network interface: "
  select interface in $(ls /sys/class/net)
  do
      vlanLength=''\${#vlan} #get length of vlan
      #interface must have 15 chars max: 5 characters for ".vlan" + vlan + interface
      vlanInterface="''\${interface:0:10-$vlanLength}.vlan$vlan"

      if ip link | grep -q $vlanInterface; then
          #deactivate vlan
          echo $interface | ip link set dev $vlanInterface down
          echo $interface | ip link delete $vlanInterface
          echo "VLAN deactivated"
      else
          #activate vlan
          echo $interface | ip link add link $interface name $vlanInterface type vlan id $vlan
          echo $interface | ip addr add $ip$subnet brd $broadcast dev $vlanInterface
          echo $interface | ip link set dev $vlanInterface up
          echo "VLAN set"
      fi
      break
  done
''
