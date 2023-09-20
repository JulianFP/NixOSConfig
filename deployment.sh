#!/usr/bin/env bash 

# this script automates deployment into the cloud
# Req

#change these variables to make this script work for your setup
githubRepo="JulianFP/LaptopNixOSConfig" #github repo that contains flake config (syntax: '<Github user name>/<repo name>'). Always uses default branch
githubBranch="main" #branch that contains flake config
#the following variables are only required for the nebula option. You don't have to set them if you don't plan on using it
luksUSBDevice="/dev/disk/by-uuid/66f96bfc-45f0-4436-81a1-8a07a548a5bb" #path to device which contains nebula crt (should be reproducible, i.e. relient on uuid or label)
#luksUSBNebulaPath and nebulaFilesPath are not allowed to begin or end with '/', './' or similar
luksUSBNebulaPath="nebula" #path to directory in which nebula crt is stored relative from root of usb device
nebulaFilesPath="nebulaDevice" #path to nebula crt and key (without .crt and .key) from root of github repo (both files should have the same name and path except the ending)



#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "general usage: ./deployment.sh <option> [...]\n\n"
    printf "usage (option: deploy): ./deployment.sh deploy <flakeHostname> <currentTargetIP> <futureTargetIP>\n\n"
    printf "usage (option: deployNebula): ./deployment.sh deployNebula <flakeHostname> <currentTargetIP> <futureTargetIP> <nebula name> <nebula ip> <nebula groups>\n\n"
    printf "usage (option: nebula): ./deployment.sh nebula <currentTargetIP> <nebula name> <nebula ip> <nebula groups>\n\n"
    printf "usage (option: iso): ./deployment.sh iso <flakeHostname>\n\n"
    echo "option:"
    echo "   deploy         deployment without nebula using nixos-anywhere"
    echo "   deployNebula   deployment with nebula using nixos-anywhere"
    echo "   nebula         configure nebula on existing nixos target (no deploy)"
    echo "   iso            just builds an iso containing the config without nebula"
    echo "   Requirements for options deploy and deployNebula:"
    echo "      - x86_64 VM (possibly others, not tested)"
    echo "      - root ssh access (with ssh key)"
    echo "      - configuration for target must be flake with disko and nix-command"
    echo "      - at least 1.5GB RAM (without swap), OR"
    echo "        currently booted from nixos live cd (not running on target drive)"
    echo "   Requirements for option nebula:"
    echo "      - root ssh access (with ssh key)"
    printf "      - target machine runs nixos with flake configured at top of this script and has nebula module already setup\n\n"
    echo "flakeHostname:"
    echo "   name of target machine used for flake url (the part after the '#' in flake url)"
    printf "   for example: NixOSTesting\n\n"
    echo "currentTargetIP:"
    echo "   ip address that the target currently has"
    printf "   the ssh server on the target has to accessible over this ip\n\n"
    echo "futureTargetIP:"
    echo "   ip address that the target will have when configuration is applied"
    echo "   useful if configuration specifies ip different from current ip"
    printf "   will be the same than currentTargetIP in most cases\n\n"
    echo "nebula name:"
    printf "   name of device in nebula network\n\n"
    echo "nebula ip:"
    printf "   ip of device in nebula network (with prefix length)\n\n"
    echo "nebula groups:"
    echo "   groups of device in nebula network"
    echo "   pass an empty string if you don't want the target to be in any group"
}

privileges() {
    # check if the script is run as root
    if [ "$(whoami)" != "root" ]; then
        echo "You need to run the script with root privileges. Attempting to raise via sudo:"
        sudo "${0}" "$@"
        exit $?
    fi
}

#$1: flakehostname, $2: currentTargetIP, $3: futureTargetIP
deploy() {
    #check if enough parameters are provided
    if [[ $# < 3 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #check if device is reachable over ssh and wait until user fixed it
    until ssh -o "StrictHostKeyChecking no" root@$2 true >/dev/null 2>&1; do 
        echo "couldn't connect to target machines root user over ssh."
        read -p "check ssh config and then press enter to try again"
    done

    # run nixos-anywhere
    nix run github:numtide/nixos-anywhere -- --flake "github:$githubRepo/$githubBranch#$1" root@$2

    #delete futureTargetIP ssh known_hosts to prevent error messages in terminal
    ssh-keygen -R "$3"

    #wait until device becomes reachable over ssh with new ip address
    echo "wait for vm to become reachable over ssh and new ip address"
    until ssh -o "StrictHostKeyChecking no" root@$3 true >/dev/null 2>&1; do 
        sleep 1 
    done

    #git clone nix configuration onto target to enable changing configuration directly on target machine
    ssh root@$3 -o "StrictHostKeyChecking no" "nix shell nixpkgs#git -c git clone -b $githubBranch https://github.com/$githubRepo.git /etc/nixos"
}

#$1 flakehostname
iso() {
    #check if enough parameters are provided
    if [[ $# < 1 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #generate iso name for symlink. This takes existing files into consideration:
    #if file "$2.iso" already exists, it will append a number
    #this number will get larger as long as it needs to in order to find an unused file name
    isoname="$1.iso"
    path=$(pwd)
    fileNum=2
    while ls $path | grep -q "$isoname"; do
        isoname="$1-$fileNum.iso"
        ((++fileNum))
    done

    #run generation script and inform user about output file name
    nix run github:nix-community/nixos-generators -- -f iso -o "$path/$isoname" --flake "github:$githubRepo/$githubBranch#$1"
    echo "you can find your iso in $path/$isoname"
}

#$1: currentTargetIP, $2: nebula name, $3: nebula ip, $4: nebula groups
nebula() {
    #check if enough parameters are provided
    if [[ $# < 4 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #get current hostname of target for nebula key name
    hostname=$(ssh root@$1 -o "StrictHostKeyChecking no" "hostnamectl hostname")

    #create .nebula folder in /root (this will also serve as backup for nebula files)
    ssh root@$1 -o "StrictHostKeyChecking no" "mkdir /root/.nebula"
    #generate private/public keypair on target
    ssh root@$1 -o "StrictHostKeyChecking no" "nix shell nixpkgs#nebula -c nebula-cert keygen -out-key /root/.nebula/$nebulaFilesPath.key -out-pub /root/.nebula/$nebulaFilesPath.pub"

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
    while ls "/mnt/$luksUSBNebulaPath" | grep -q "$nebname"; do
        nebname="$hostname-$fileNum"
        ((++fileNum))
    done

    #copy public key from target machine and sign it locally with ca.key from usb stick
    scp root@$1:/root/.nebula/$nebulaFilesPath.pub "/mnt/$luksUSBNebulaPath/$nebname.pub"
    nix shell nixpkgs\#nebula -c nebula-cert sign -ca-crt "/mnt/$luksUSBNebulaPath/ca.crt" -ca-key "/mnt/$luksUSBNebulaPath/ca.key" -in-pub "/mnt/$luksUSBNebulaPath/$nebname.pub" -out-crt "/mnt/$luksUSBNebulaPath/$nebname.crt" -name $2 -ip $3 -groups $4

    #copy crt file to target machine and also copy them into place in /etc/nixos 
    scp "/mnt/$luksUSBNebulaPath/$nebname.crt" root@$1:/root/.nebula/$nebulaFilesPath.crt
    ssh root@$1 -o "StrictHostKeyChecking no" "cat /root/.nebula/$nebulaFilesPath.crt > /etc/nixos/$nebulaFilesPath.crt"
    ssh root@$1 -o "StrictHostKeyChecking no" "cat /root/.nebula/$nebulaFilesPath.key > /etc/nixos/$nebulaFilesPath.key"

    #apply nebula config and configure git to ignore changed keyfiles to prevent them from being overriden or pushed to github
    ssh root@$1 -o "StrictHostKeyChecking no" "nixos-rebuild switch"
    ssh root@$1 -o "StrictHostKeyChecking no" "nix shell nixpkgs#git -c sh -c 'cd /etc/nixos && git update-index --skip-worktree $nebulaFilesPath.*'"

    #unmount and lock usb stick again
    umount /mnt 
    cryptsetup close /dev/mapper/luksUSBDeviceNebula
}

case $1 in 
    deploy)
    privileges "$@"
    deploy "$2" "$3" "$4"
    echo "deployment completed"
    exit 0
        ;;
    deployNebula)
    privileges "$@"
    deploy "$2" "$3" "$4"
    nebula "$3" "$5" "$6" "$7"
    echo "deployment with nebula completed"
    exit 0
        ;;
    nebula)
    privileges "$@"
    nebula "$2" "$3" "$4" "$5"
    echo "nebula configured"
    exit 0
        ;;
    iso)
    iso "$2"
    exit 0
        ;;
    *)
    help 
    exit 0
        ;;
esac
