#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages git sops

# this script automates deployment into the cloud
# for the deploy and deploySops options you need to be able to pull/push from/to the github repository below from the server (e.g. setup ssh agent forwarding for this)
# it can also update sops age keys after doing that. For this the script assumes that your sops config is in the root of the git repository and is named .sops.yaml

#change these variables to make this script work for your setup
githubRepo="JulianFP/LaptopNixOSConfig" #github repo that contains flake config (syntax: '<Github user name>/<repo name>'). Always uses default branch
githubBranch="sops" #branch that contains flake config
#the following option is only needed for the deploySops option 
ageKeyFile="/var/lib/sops-nix/key.txt" #path to ageKeyFile on target machine


#define function make error output easier
echoerr() { echo "$@" 1>&2; }

help() {
    printf "general usage: ./deployment.sh <option> [...]\n\n"
    printf "usage (option: deploy): ./deployment.sh deploy <flakeHostname> <currentTargetIP> <futureTargetIP>\n\n"
    printf "usage (option: deploySops): ./deployment.sh deploySops <flakeHostname> <currentTargetIP> <futureTargetIP>\n\n"
    printf "usage (option: iso): ./deployment.sh iso <flakeHostname>\n\n"
    printf "option:\n"
    printf "   deploy         deployment using nixos-anywhere\n"
    printf "   deploySops     like deploy but also updates the age key in .sops.yaml and takes care of sops key decryption\n"
    printf "   iso            just builds an iso containing the config without nebula\n"
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
    printf "   the ssh server on the target has to accessible over this ip\n\n"
    printf "futureTargetIP:\n"
    printf "   ip address that the target will have when configuration is applied\n"
    printf "   useful if configuration specifies ip different from current ip\n"
    printf "   will be the same than currentTargetIP in most cases\n"
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

#$1: flakehostname, $2: TargetIP
sops() {
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
        sed -i -e '/&yubikey/a\' -e "  - &$1 age$(cat /tmp/$agename | sed ':a;N;$!ba;s/\n//g')" "/tmp/$gitname/.sops.yaml"
        printf "  - path_regex: secrets/$1/[^/]+\\.(yaml|json|env|ini)$\n    key_groups:\n    - pgp:\n      - *yubikey\n      age:\n      - *$1" >> "/tmp/$gitname/.sops.yaml"
    fi

    #reencrypt secrets for new age key 
    sops --config /tmp/$gitname/.sops.yaml updatekeys -y /tmp/$gitname/secrets/general.yaml
    sops --config /tmp/$gitname/.sops.yaml updatekeys -y /tmp/$gitname/secrets/nebula.yaml
    ls -1 "/tmp/$gitname/secrets/$1" | sed -e "s/^/\/tmp\/$gitname\/secrets\/$1\//" | xargs -L1 sops --config /tmp/$gitname/.sops.yaml updatekeys -y

    #add changes to git and push them
    git -C "/tmp/$gitname" add "/tmp/$gitname/*"
    git -C "/tmp/$gitname" add "/tmp/$gitname/.sops.yaml"
    git -C "/tmp/$gitname" commit -m "changed age key of $1"
    git -C "/tmp/$gitname" push origin "$githubBranch"

    #pull changes on target and apply them
    ssh root@$2 -o "StrictHostKeyChecking no" "nix shell nixpkgs#git -c git -C /etc/nixos pull origin $githubBranch"
    ssh root@$2 -o "StrictHostKeyChecking no" "nixos-rebuild switch"
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

set -ex #exit on any kind of error

case $1 in 
    deploy)
    deploy "$2" "$3" "$4"
    echo "deployment completed"
    exit 0
        ;;
    deploySops)
    deploy "$2" "$3" "$4"
    sops "$2" "$4"
    echo "deployment with sops completed"
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
