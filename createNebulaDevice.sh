#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages git nebula sops

# this script automates creation nebula certificates for a device
# it also adds these certificates automatically to the nix configuration and pushes them to remote origin
# after running this script you have to setup the .sops.yaml file manually (except updating the age public key, the deployment script does that)
# furthermore, this script assumes that you put your sops secrets in the directory secrets and puts the host-specific nebula key into secrets/$1/nebula.yaml

#change these variables to make this script work for your setup
githubRepo="JulianFP/LaptopNixOSConfig" #github repo that contains flake config (syntax: '<Github user name>/<repo name>'). Always uses default branch
githubBranch="sops" #branch that contains flake config
luksUSBDevice="/dev/disk/by-uuid/66f96bfc-45f0-4436-81a1-8a07a548a5bb" #path to device which contains nebula crt (should be reproducible, i.e. relient on uuid or label)
#luksUSBNebulaPath is not allowed to begin or end with '/', './' or similar
luksUSBNebulaPath="nebula" #path to directory in which nebula crt is stored relative from root of usb device

#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "general usage: ./createNebulaDevice.sh <flakeHostname> <nebula ip> <nebula groups>\n\n"
    printf "flakeHostname:\n"
    printf "   name of target machine used for flake url (the part after the '#' in flake url)\n"
    printf "   also used as device name for the nebula certificate\n"
    printf "   for example: NixOSTesting\n\n"
    printf "nebula ip:\n"
    printf "   ip of device in nebula network (with prefix length)\n\n"
    printf "nebula groups:\n"
    printf "   groups of device in nebula network\n"
    printf "   mandatory. pass an empty string if you don't want the target to be in any group\n"
}

privileges() {
    # check if the script is run as root
    if [ "$(whoami)" != "root" ]; then
        echo "You need to run the script with root privileges. Attempting to raise via sudo:"
        sudo "${0}" "$@"
        exit $?
    fi
}

addDevice() {
    #check if enough parameters are provided
    if [[ $# < 3 ]]; then
        echoerr "Missing parameters. use --help to find out how to use this script"
        exit 1
    fi

    #wait until usb stick with ca.key is present
    until [[ -e "$luksUSBDevice" ]]; do 
        echo "configured usb device not found"
        read -p "plug in usb device with nebula cert and then press enter"
    done
    #unlock and mount usb stick
    cryptsetup open $luksUSBDevice luksUSBDeviceNebula
    mount /dev/mapper/luksUSBDeviceNebula /mnt 


    #find free filename for crt file on usb stick
    nebname="$1"
    fileNum=2
    while ls "/mnt/$luksUSBNebulaPath" | grep -q "$nebname"; do
        nebname="$1-$fileNum"
        ((++fileNum))
    done

    #find free dirname for tmp directory for github repo
    gitname="githubRepo"
    gitNum=2
    while ls "/tmp" | grep -q "$gitname"; do
        gitname="githubRepo-$gitNum"
        ((++gitNum))
    done

    #clone github repo and decrypt sops file
    git clone -b "$githubBranch" "git@github.com:$githubRepo.git" "/tmp/$gitname"
    #check if files are already there and handle these cases
    if [[ !(-e "/tmp/$gitname/secrets/$1") ]]; then
        mkdir "/tmp/$gitname/secrets/$1"
    fi
    if [[ -e "/tmp/$gitname/secrets/$1/nebula.yaml" ]]; then
        echoerr "nebula key already exists for this device."
        exit 1
    fi

    #generate nebula key and crt
    nebula-cert sign -ca-crt "/mnt/$luksUSBNebulaPath/ca.crt" -ca-key "/mnt/$luksUSBNebulaPath/ca.key" -out-crt "/mnt/$luksUSBNebulaPath/$nebname.crt" -out-key "/mnt/$luksUSBNebulaPath/$nebname.key" -name $1 -ip $2 -groups $3

    #generate yaml file to store secrets
    printf "nebula:\n    NixOSTesting.key: |\n        $(sed ':a;N;$!ba;s/\n/\n        /g' /mnt/$luksUSBNebulaPath/$nebname.key)\n    NixOSTesting.crt: |\n        $(sed ':a;N;$!ba;s/\n/\n        /g' /mnt/$luksUSBNebulaPath/$nebname.crt)" > "/tmp/$gitname/secrets/$1/nebula.yaml"
    sops --config "/tmp/$gitname/.sops.yaml" -e -i "/tmp/$gitname/secrets/$1/nebula.yaml"

    #add changes to git and push them
    git -C "/tmp/$gitname" add "/tmp/$gitname/*"
    git -C "/tmp/$gitname" commit -m "added nebula certificates to $1"
    git -C "/tmp/$gitname" push origin "$githubBranch"

    #remove private key from usb stick
    rm /mnt/$luksUSBNebulaPath/$nebname.key 

    #umount and lock usb stick (try again if still busy)
    until umount /mnt; do
        sleep 1 
    done
    until cryptsetup close /dev/mapper/luksUSBDeviceNebula; do
        sleep 1 
    done
}

set -e #exit on any kind of error

case $1 in
    "-h"|"--help"|"help"|"")
    help
    exit 0
        ;;
    *)
    privileges "$@"
    addDevice "$@"
    echo "device successfully added to nebula network"
    exit 0
        ;;
esac

