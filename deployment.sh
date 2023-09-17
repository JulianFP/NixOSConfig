#!/usr/bin/env bash 

# this script automates deployment into the cloud
# Req

#change this for different luks device
luksUSBDevice="/dev/disk/by-uuid/66f96bfc-45f0-4436-81a1-8a07a548a5bb"



# get hostname from nix flake url (extracts everything after #)
length=${#2}
hastagPos=$(awk -v a="$2" -v b="#" 'BEGIN{print index(a,b)}')
hostname=${2:$hastagPos:$length}

#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "usage: ./deployment.sh <option> <flakeURL> [<currentTargetIP>] [<futureTargetIP>] [<nebula name>] [<nebula ip>] [<nebula groups>]\n\n"
    echo "option:"
    echo "   deploy   deployment without nebula using nixos-anywhere"
    echo "   nebula   deployment with nebula using nixos-anywhere"
    echo "   iso      just builds an iso containing the config without nebula"
    echo "   Requirements for options deploy and nebula:"
    echo "      - x86_64 VM (possibly others, not tested)"
    echo "      - root ssh access (with ssh key)"
    echo "      - configuration for target must be flake with disko and nix-command"
    echo "      - at least 1.5GB RAM (without swap), OR"
    printf "        currently booted from nixos live cd (not running on target drive)\n\n"
    echo "flakeURL:"
    echo "   flake url to deployment config on local system"
    echo "   most of the time: <path to flake>#<configuration name>"
    printf "   for example: /etc/nixos#NixOSTesting\n\n"
    echo "currentTargetIP:"
    echo "   specify only when using deploy or nebula option"
    echo "   ip address that the target currently has"
    printf "   the ssh server on the target has to accessible over this ip\n\n"
    echo "futureTargetIP:"
    echo "   specify only when using deploy or nebula option"
    echo "   ip address that the target will have when configuration is applied"
    echo "   useful if configuration specifies ip different from current ip"
    printf "   will be the same than currentTargetIP in most cases\n\n"
    echo "nebula name:"
    echo "   specify only when using nebula option"
    printf "   name of device in nebula network\n\n"
    echo "nebula ip:"
    echo "   specify only when using nebula option"
    printf "   ip of device in nebula network (with prefix length)\n\n"
    echo "nebula groups:"
    echo "   specify only when using nebula option"
    echo "   groups of device in nebula network (can be empty)"
}

privileges() {
    # check if the script is run as root
    if [ "$(whoami)" != "root" ]; then
        echo "You need to run the script with root privileges. Attempting to raise via sudo:"
        sudo "${0}" "$@"
        exit $?
    fi
}

deploy() {
    #check if enough parameters are provided
    if [[ $# < 4 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #check if device is reachable over ssh and wait until user fixed it
    until ssh -o "StrictHostKeyChecking no" root@$3 true >/dev/null 2>&1; do 
        echo "couldn't connect to target machines root user over ssh."
        read -p "check ssh config and then press enter to try again"
    done

    # run nixos-anywhere
    nix run github:numtide/nixos-anywhere -- --flake $2 root@$3

    #delete futureTargetIP ssh known_hosts to prevent error messages in terminal
    ssh-keygen -R "$4"

    #wait until device becomes reachable over ssh with new ip address
    echo "wait for vm to become reachable over ssh and new ip address"
    until ssh -o "StrictHostKeyChecking no" root@$4 true >/dev/null 2>&1; do 
        sleep 1 
    done

    #git clone nix configuration onto target to enable changing configuration directly on target machine
    ssh root@$4 -o "StrictHostKeyChecking no" "nix shell nixpkgs#git -c git clone https://github.com/JulianFP/LaptopNixOSConfig.git /etc/nixos"
}

iso() {
    #check if enough parameters are provided
    if [[ $# < 2 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #generate iso name for symlink. This takes existing files into consideration:
    #if file "$hostname.iso" already exists, it will append a number
    #this number will get larger as long as it needs to in order to find an unused file name
    isoname="$hostname.iso"
    path=$(pwd)
    fileNum=2
    while ls $path | grep -q "$isoname"; do
        isoname="$hostname-$fileNum.iso"
        ((++fileNum))
    done

    #run generation script and inform user about output file name
    nix run github:nix-community/nixos-generators -- -f iso -o "$path/$isoname" --flake $2
    echo "you can find your iso in $path/$isoname"
}

nebula() {
    #check if enough parameters are provided
    if [[ $# < 6 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #create .nebula folder in /root (this will also serve as backup for nebula files)
    ssh root@$4 -o "StrictHostKeyChecking no" "mkdir /root/.nebula"
    #generate private/public keypair on target
    ssh root@$4 -o "StrictHostKeyChecking no" "nix shell nixpkgs#nebula -c nebula-cert keygen -out-key /root/.nebula/nebulaDevice.key -out-pub /root/.nebula/nebulaDevice.pub"

    #wait until usb stick with ca.key is present
    until [[ -e "$luksUSBDevice" ]]; do 
        echo "configured usb device not found"
        read -p "plug in usb device with nebula cert and then press enter"
    done
    #unlock and mount usb stick
    cryptsetup open $luksUSBDevice luksUSBDeviceNebula
    mount /dev/mapper/luksUSBDeviceNebula /mnt 

    #similar to iso name generation in iso function: find free filename for crt file on usb stick
    nebname="$hostname"
    fileNum=2
    while ls "/mnt/nebula" | grep -q "$nebname"; do
        nebname="$hostname-$fileNum"
        ((++fileNum))
    done

    #copy public key from target machine and sign it locally with ca.key from usb stick
    scp root@$4:/root/.nebula/nebulaDevice.pub "/mnt/nebula/$nebname.pub"
    nix shell nixpkgs\#nebula -c nebula-cert sign -ca-crt /mnt/nebula/ca.crt -ca-key /mnt/nebula/ca.key -in-pub "/mnt/nebula/$nebname.pub" -out-crt "/mnt/nebula/$nebname.crt" -name $5 -ip $6 -groups $7

    #copy crt file to target machine and also copy them into place in /etc/nixos 
    scp "/mnt/nebula/$nebname.crt" root@$4:/root/.nebula/nebulaDevice.crt
    ssh root@$4 -o "StrictHostKeyChecking no" "cat /root/.nebula/nebulaDevice.crt > /etc/nixos/nebulaDevice.crt"
    ssh root@$4 -o "StrictHostKeyChecking no" "cat /root/.nebula/nebulaDevice.key > /etc/nixos/nebulaDevice.key"

    #apply nebula config and configure git to ignore changed keyfiles to prevent them from being overriden or pushed to github
    ssh root@$4 -o "StrictHostKeyChecking no" "nixos-rebuild switch"
    ssh root@$4 -o "StrictHostKeyChecking no" "nix shell nixpkgs#git -c sh -c 'cd /etc/nixos && git update-index --skip-worktree nebulaDevice.*'"

    #unmount and lock usb stick again
    umount /mnt 
    cryptsetup close /dev/mapper/luksUSBDeviceNebula
}

case $1 in 
    deploy)
    privileges "$@"
    deploy "$@"
    echo "deployment completed"
    exit 0
        ;;
    nebula)
    privileges "$@"
    deploy "$@"
    nebula "$@"
    echo "deployment with nebula completed"
    exit 0
        ;;
    iso)
    iso "$@"
    exit 0
        ;;
    *)
    help 
    exit 0
        ;;
esac
