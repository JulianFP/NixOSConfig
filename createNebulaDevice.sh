#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages git nebula sops

# this script automates creation nebula certificates for a device
# it also adds these certificates automatically to the nix configuration and pushes them to remote origin
# this script does NOT adjust .sops.yaml file. After you run this script you either have to edit it manually or use the deployment.sh script with the deploySops or sops option
# furthermore, this script assumes that you put your sops secrets in the directory secrets and puts the host-specific nebula key into secrets/$1/nebula.yaml

#change these variables to make this script work for your setup
githubRepo="JulianFP/NixOSConfig" #github repo that contains flake config (syntax: '<Github user name>/<repo name>'). Always uses default branch
githubBranch="main" #branch that contains flake config
luksUSBDevice="/dev/disk/by-uuid/66f96bfc-45f0-4436-81a1-8a07a548a5bb" #path to device which contains nebula crt (should be reproducible, i.e. relient on uuid or label)
#luksUSBNebulaPath is not allowed to begin or end with '/', './' or similar
luksUSBNebulaPath="nebula" #path to directory in which nebula crt is stored relative from root of usb device

#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "general usage: ./createNebulaDevice.sh <flakeSecretHostName> <flakeInstallHostName> <nebula ip> <nebula groups> <nebula subnets> [dry-run]\n\n"
    printf "flakeSecretHostName:\n"
    printf "   name of machine that should have access to the key and crt (i.e. be able to decrypt it using sops-nix)\n"
    printf "   for example: NixOSTesting\n\n"
    printf "flakeInstallHostName:\n"
    printf "   name of machine that the interface will be created for (i.e. will be using that interface)\n"
    printf "   if you are not creating this cert for a container then this will probably be the same as flakeSecretHostName\n"
    printf "   also used as device name for the nebula certificate\n"
    printf "   for example: mailServer-container\n\n"
    printf "nebula ip:\n"
    printf "   ip of device in nebula network in CIDR notation (with prefix length)\n"
    printf "   for example: 48.42.1.130/16\n\n"
    printf "nebula groups:\n"
    printf "   groups of device in nebula network\n"
    printf "   mandatory. pass an empty string if you don't want the target to be in any group\n"
    printf "   for example: \"server,edge\"\n\n"
    printf "nebula subnets:\n"
    printf "   ip addresses and networks in cidr notation that this host should be able to forward traffic to\n"
    printf "   mandatory. pass an empty string if you don't want the target to have any unsafe routes\n"
    printf "   for example: \"192.168.3.0/24,192.168.1.0/24\"\n\n"
    printf "dry-run:\n"
    printf "   optional, if added then this script won't add and commit changes automatically\n"
    printf "   but instead just return the path to the tmp git repository for inspection\n"
}

privileges() {
    # check if the script is run as root
    if [ "$(whoami)" != "root" ]; then
        echo "You need to run the script with root privileges. Attempting to raise via sudo:"
        sudo "${0}" "$@"
        exit $?
    fi
}

#store if we need to umount before exit
mounted=false
unlocked=false

addDevice() {
    #check if enough parameters are provided
    if [[ $# -lt 3 ]]; then
        echoerr "Missing parameters. use --help to find out how to use this script"
        exit 1
    fi

    #wait until usb stick with ca.key is present
    until [[ -e "$luksUSBDevice" ]]; do
        echo "configured usb device not found"
        read -r -p "plug in usb device with nebula cert and then press enter"
    done
    #unlock and mount usb stick
    cryptsetup open $luksUSBDevice luksUSBDeviceNebula
    unlocked=true
    mkdir -p /mnt
    mount /dev/mapper/luksUSBDeviceNebula /mnt
    mounted=true


    #find free filename for crt file on usb stick
    nebname="$2"
    fileNum=2
    while ls "/mnt/$luksUSBNebulaPath" | grep -q "$nebname"; do
        nebname="$2-$fileNum"
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
    if [[ ! (-e "/tmp/$gitname/secrets/$1") ]]; then
        mkdir "/tmp/$gitname/secrets/$1"
        printf "nebula:\n" > "/tmp/$gitname/secrets/$1/nebula.yaml"
    elif grep -q "$2" "/tmp/$gitname/secrets/$1/nebula.yaml"; then
        echoerr "nebula key for hostName $2 already exists for this device ($1)."
        exit 1
    else
        sops --config "/tmp/$gitname/.sops.yaml" -d -i "/tmp/$gitname/secrets/$1/nebula.yaml"

    fi

    #generate nebula key and crt
    if [ "$5" = "" ]; then
        nebula-cert sign -ca-crt "/mnt/$luksUSBNebulaPath/ca.crt" -ca-key "/mnt/$luksUSBNebulaPath/ca.key" -out-crt "/mnt/$luksUSBNebulaPath/$nebname.crt" -out-key "/mnt/$luksUSBNebulaPath/$nebname.key" -name $2 -ip $3 -groups $4
    else
        nebula-cert sign -ca-crt "/mnt/$luksUSBNebulaPath/ca.crt" -ca-key "/mnt/$luksUSBNebulaPath/ca.key" -out-crt "/mnt/$luksUSBNebulaPath/$nebname.crt" -out-key "/mnt/$luksUSBNebulaPath/$nebname.key" -name $2 -ip $3 -groups $4 -subnets $5
    fi

    #generate yaml file to store secrets
    printf "    $2.key: |\n        $(sed ':a;N;$!ba;s/\n/\n        /g' /mnt/$luksUSBNebulaPath/$nebname.key)\n    $2.crt: |\n        $(sed ':a;N;$!ba;s/\n/\n        /g' /mnt/$luksUSBNebulaPath/$nebname.crt)" >> "/tmp/$gitname/secrets/$1/nebula.yaml"
    sops --config "/tmp/$gitname/.sops.yaml" -e -i "/tmp/$gitname/secrets/$1/nebula.yaml"

    #add changes to git and push them
    if [ "$6" != "dry-run" ]; then
        git -C "/tmp/$gitname" add "/tmp/$gitname/*"
        git -C "/tmp/$gitname" commit -m "added nebula certificates for $2 to $1"
        git -C "/tmp/$gitname" push origin "$githubBranch"
    else
        echo "You can inspect and manually commit the changes in /tmp/$gitname/"

    fi

    #remove private key from usb stick
    rm /mnt/$luksUSBNebulaPath/$nebname.key

    #umount and lock usb stick (try again if still busy)
    unmounting
}

#exit handling
set -eE #exit on any kind of error
trap unmounting ERR

function unmounting(){
    if $mounted; then
        echo "Unmounting usb device...."
        until umount /mnt; do
            sleep 1
        done
    fi
    if $unlocked; then
        echo "Closing luks device..."
        until cryptsetup close /dev/mapper/luksUSBDeviceNebula; do
            sleep 1
        done
    fi
}

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
