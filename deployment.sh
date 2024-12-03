#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages git sops

# this script automates deployments onto any remote Linux machine (e.g. Proxmox VMs or the cloud)
# using the deploySops or sops option it can also update sops age keys. For this the script assumes that your sops config is in the root of the git repository and is named .sops.yaml

#change these variables to make this script work for your setup
githubRepo="JulianFP/NixOSConfig" #github repo that contains flake config (syntax: '<Github user name>/<repo name>'). Always uses default branch
githubBranch="main" #branch that contains flake config
#the following option is only needed for the deploySops and sops option 
ageKeyFile="/persist/sops-nix/key.txt" #path to ageKeyFile on target machine


#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "general usage: ./deployment.sh <option> [...]\n\n"
    printf "usage (option: deploy): ./deployment.sh deploy <flakeHostname> <currentTargetIP> <futureTargetIP>\n\n"
    printf "usage (option: deploySops): ./deployment.sh deploySops <flakeHostname> <currentTargetIP> <futureTargetIP>\n\n"
    printf "usage (option: sops): ./deployment.sh sops <flakeHostname> <currentTargetIP>\n\n"
    printf "usage (option: iso): ./deployment.sh iso <flakeHostname>\n\n"
    printf "usage (option: lxc): ./deployment.sh lxc <flakeHostname>\n\n"
    printf "option:\n"
    printf "   deploy         deployment using nixos-anywhere\n"
    printf "   deploySops     like deploy but also updates the age key in .sops.yaml and takes care of sops key decryption\n"
    printf "   sops           does just the sops part of deploySops. Useful for machines that do not fulfill the requirements for deploy/deploySops\n"
    printf "   iso            just builds an iso containing the config\n"
    printf "   lxc            just builds a Proxmox LXC template containing the config\n"
    printf "   Requirements for options deploy and deploySops:\n"
    printf "      - x86_64 VM (possibly others, not tested)\n"
    printf "      - root ssh access (with ssh key)\n"
    printf "      - configuration for target must be flake with disko and nix-command\n"
    printf "      - at least 1.5GB RAM (without swap), OR\n"
    printf "        currently booted from nixos live cd (not running on target drive)\n"
    printf "flakeHostname:\n"
    printf "   name of target machine used for flake url (the part after the '#' in flake url)\n"
    printf "   for example: NixOSTesting\n\n"
    printf "currentTargetIP:\n"
    printf "   ip address that the target currently has\n"
    printf "   the ssh server on the target has to accessible over this ip\n"
    printf "   for example: 192.168.3.200\n\n"
    printf "futureTargetIP:\n"
    printf "   ip address that the target will have when configuration is applied\n"
    printf "   useful if configuration specifies ip different from current ip\n"
    printf "   will be the same than currentTargetIP in most cases\n"
    printf "   for example: 192.168.3.130\n"
}

#$1: flakehostname, $2: currentTargetIP, $3: futureTargetIP
deploy() {
    #check if enough parameters are provided
    if [[ $# -lt 3 ]]; then
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
}

#$1: flakehostname, $2: TargetIP
sopsConfig() {
    #check if device is reachable over ssh and wait until user fixed it
    until ssh -o "StrictHostKeyChecking no" root@$2 true >/dev/null 2>&1; do 
        echo "couldn't connect to target machines root user over ssh."
        read -p "check ssh config and then press enter to try again"
    done

    #find free filename for age public key in /tmp
    agename="ageKey.pub"
    fileNum=2
    while ls "/tmp" | grep -q "$agename"; do
        agename="ageKey-$fileNum.pub"
        ((++fileNum))
    done

    #cut public key (without age prefix) out of keyFile and copy it to localhost
    ssh root@$2 -o "StrictHostKeyChecking no" "awk -F'age|\n' '{print \$2}' $ageKeyFile > $agename"
    scp -o "StrictHostKeyChecking no" "root@$2:$agename" "/tmp/$agename"

    #find free dirname for tmp directory for github repo
    gitname="githubRepo"
    gitNum=2
    while ls "/tmp" | grep -q "$gitname"; do
        gitname="githubRepo-$gitNum"
        ((++gitNum))
    done

    #clone github repo
    git clone -b "$githubBranch" "git@github.com:$githubRepo.git" "/tmp/$gitname"

    #check if sops config is already present for this host
    if cat "/tmp/$gitname/.sops.yaml" | grep -q "&$1"; then
        #it is: just update the age key
        sed -i "/&$1/c\\  - &$1 age$(cat /tmp/$agename | sed ':a;N;$!ba;s/\n//g')" "/tmp/$gitname/.sops.yaml"
    else
        #it is not: add it and its config 
        sed -i -e '/&yubikey/a\' -e "  - &$1 age$(cat /tmp/$agename | sed ':a;N;$!ba;s/\n//g')" "/tmp/$gitname/.sops.yaml" #add age key to keys
        sed -i -e '/- key_groups:/i\' -e "      - *$1" "/tmp/$gitname/.sops.yaml" #add hostname to regex for all general secrets
        sed -i -e '/secrets\/\[/i\' -e "  - path_regex: ^secrets/$1/.*$\n    key_groups:\n    - pgp:\n      - *yubikey\n      age:\n      - *$1" "/tmp/$gitname/.sops.yaml" #add new path_regex for all keys that should only be decrypted by target
    fi

    #reencrypt secrets for new age key 
    sops --config /tmp/$gitname/.sops.yaml updatekeys -y /tmp/$gitname/secrets/*.yaml
    ls -1 "/tmp/$gitname/secrets/$1" | sed -e "s/^/\/tmp\/$gitname\/secrets\/$1\//" | xargs -L1 sops --config /tmp/$gitname/.sops.yaml updatekeys -y

    #add changes to git and push them
    git -C "/tmp/$gitname" add "/tmp/$gitname/*"
    git -C "/tmp/$gitname" add "/tmp/$gitname/.sops.yaml"
    git -C "/tmp/$gitname" commit -m "$1: Changed age key"
    git -C "/tmp/$gitname" push origin "$githubBranch"

    #build changes for target
    nixos-rebuild switch --flake "/tmp/$gitname#$1" --target-host root@$2

    #reboot machine and wait until it becomes reachable again
    ssh root@$2 -o "StrictHostKeyChecking no" "reboot"
    echo "wait for vm to become reachable after restart again"
    until ssh -o "StrictHostKeyChecking no" root@$2 true >/dev/null 2>&1; do 
        sleep 1 
    done

    #remove temp git directory
    rm -fr "/tmp/$gitname"
}

#$1 flakehostname
iso() {
    #check if enough parameters are provided
    if [[ $# -lt 1 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #generate iso name for symlink. This takes existing files into consideration:
    #if file "$1.iso" already exists, it will append a number
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

#$1 flakehostname
lxc() {
    #check if enough parameters are provided
    if [[ $# -lt 1 ]]; then
        echoerr "Missing parameters. use help option to find out how to use this script"
        exit 1
    fi

    #generate lxc name for symlink. This takes existing files into consideration:
    #if file "$1.tar.xz" already exists, it will append a number
    #this number will get larger as long as it needs to in order to find an unused file name
    templateName="$1.tar.xz"
    path=$(pwd)
    fileNum=2
    while ls $path | grep -q "$templateName"; do
        templateName="$1-$fileNum.tar.xz"
        ((++fileNum))
    done

    #run generation script and inform user about output file name
    nix run github:nix-community/nixos-generators -- -f proxmox-lxc -o "$path/$templateName" --flake "github:$githubRepo/$githubBranch#$1"
    echo "you can find your Proxmox LXC template in $path/$templateName"
}

set -e #exit on any kind of error

case $1 in 
    deploy)
    deploy "$2" "$3" "$4"
    echo "deployment completed"
    exit 0
        ;;
    deploySops)
    deploy "$2" "$3" "$4"
    sopsConfig "$2" "$4"
    echo "deployment with sops completed"
    exit 0
        ;;
    sops)
    sopsConfig "$2" "$3"
    echo "sops setup completed"
    exit 0
        ;;
    iso)
    iso "$2"
    exit 0
        ;;
    lxc)
    lxc "$2"
    exit 0
        ;;
    *)
    help 
    exit 0
        ;;
esac
