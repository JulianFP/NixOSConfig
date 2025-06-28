#!/usr/bin/env bash
show_help() {
	printf "general usage: createNebulaDevice <flakeInstallHostName> <nebula ip> [<options>]\n\n"
	printf "flakeInstallHostName:\n"
	printf "   name of machine that the interface will be created for (i.e. will be using that interface)\n"
	printf "   also used as device name for the nebula certificate\n"
	printf "   for example: Nextcloud\n\n"
	printf "nebula ip:\n"
	printf "   ip of device in nebula network in CIDR notation (with prefix length)\n"
	printf "   for example: 48.42.1.130/16\n\n"
	printf "option -i <flakeSecretHostName>:\n"
	printf "   name of machine that should have access to the key and crt (i.e. be able to decrypt it using sops-nix)\n"
	printf "   if not specified this will be the same as flakeInstallHostName (which you should leave it at unless you are creating this certificate for a container)\n"
	printf "   for example: mainserver\n\n"
	printf "option -g <nebula groups>:\n"
	printf "   groups of device in nebula network\n"
	printf "   mandatory. pass an empty string if you don't want the target to be in any group\n"
	printf "   for example: \"server,edge\"\n\n"
	printf "option -s <nebula subnets>:\n"
	printf "   ip addresses and networks in cidr notation that this host should be able to forward traffic to\n"
	printf "   mandatory. pass an empty string if you don't want the target to have any unsafe routes\n"
	printf "   for example: \"192.168.3.0/24,192.168.1.0/24\"\n"
}

#define function make error output easier
echoerr() { echo "$@" 1>&2; }

luksUSBDevice="/dev/disk/by-uuid/66f96bfc-45f0-4436-81a1-8a07a548a5bb" #path to device which contains nebula crt (should be reproducible, i.e. relient on uuid or label)
#luksUSBNebulaPath is not allowed to begin or end with '/', './' or similar
luksUSBNebulaPath="nebula" #path to directory in which nebula crt is stored relative from root of usb device

#init variables and populate with default values
flakeInstallHostName="$1"
nebulaIP="$2"
flakeSecretHostName="$flakeInstallHostName"
nebulaGroups=""
nebulaSubnets=""
mounted=false
unlocked=false

shift 2
while getopts ":hi:g:s:" opt; do
	case ${opt} in
	h)
		show_help
		exit 0
		;;
	i)
		flakeSecretHostName="${OPTARG}"
		;;
	g)
		nebulaGroups="${OPTARG}"
		;;
	s)
		nebulaSubnets="${OPTARG}"
		;;
	\?)
		echoerr "Unrecognized option ${OPTARG}. Use -h to see all available options"
		exit 1
		;;
	:)
		echoerr "Missing option argument for ${OPTARG}"
		exit 1
		;;
	*)
		echoerr "Unrecognized option ${opt}. Use -h to see all available options"
		exit 1
		;;
	esac
done

if [[ ${flakeInstallHostName} == "" || ${nebulaIP} == "" ]]; then
	echoerr "You need to provide at least <flakeInstallHostName> and <nebula ip> to this script!"
	echoerr "Use the -h option for help"
	exit 1
fi

#check if we are in root of git repository
if ! [[ -d ./.git ]]; then
	echoerr "you need to execute this script in the root of the NixOSConfig repository!"
	exit 1
fi

#exit handling
set -eE #exit on any kind of error
trap unmounting ERR

function unmounting() {
	if $mounted; then
		echo "Unmounting usb device...."
		until sudo umount /mnt; do
			sleep 1
		done
	fi
	if $unlocked; then
		echo "Closing luks device..."
		until sudo cryptsetup close /dev/mapper/luksUSBDeviceNebula; do
			sleep 1
		done
	fi
}

#wait until usb stick with ca.key is present
until [[ -e $luksUSBDevice ]]; do
	echo "configured usb device not found"
	read -r -p "plug in usb device with nebula cert and then press enter"
done
#unlock and mount usb stick
sudo cryptsetup open $luksUSBDevice luksUSBDeviceNebula
unlocked=true
mkdir -p /mnt
sudo mount /dev/mapper/luksUSBDeviceNebula /mnt
mounted=true
echo "usb device decrypted and mounted successfully"

#find free filename for crt file on usb stick
nebname="$flakeInstallHostName"
fileNum=2
while sudo test -e "/mnt/${luksUSBNebulaPath}/${nebname}.crt"; do
	nebname="$flakeInstallHostName-$fileNum"
	((++fileNum))
done

#check if files are already there and handle these cases
if [[ ! (-e "./secrets/${flakeSecretHostName}") ]]; then
	mkdir "./secrets/${flakeSecretHostName}"
	printf "nebula:\n" >"./secrets/${flakeSecretHostName}/nebula.yaml"
elif grep -q "$flakeInstallHostName" "./secrets/${flakeInstallHostName}/nebula.yaml"; then
	echoerr "nebula key for hostName ${flakeInstallHostName} already exists for this device (${flakeSecretHostName})."
	unmounting
	exit 1
else
	sops --config "./.sops.yaml" -d -i "./secrets/${flakeSecretHostName}/nebula.yaml"
fi

nebula_cmd="sudo nebula-cert sign -ca-crt '/mnt/${luksUSBNebulaPath}/ca.crt' -ca-key '/mnt/${luksUSBNebulaPath}/ca.key' -out-crt '/mnt/${luksUSBNebulaPath}/${nebname}.crt' -out-key '/mnt/${luksUSBNebulaPath}/${nebname}.key' -name '${flakeInstallHostName}' -ip '${nebulaIP}'"
if ! [ "$nebulaGroups" = "" ]; then
	nebula_cmd+=" -groups '${nebulaGroups}'"
fi
if ! [ "$nebulaSubnets" = "" ]; then
	nebula_cmd+=" -subnets '${nebulaSubnets}'"
fi
eval "${nebula_cmd}"

#generate yaml file to store secrets
# the file shouldn't be opened with sudo privileges, so this is correct as is. We can savely disable the shellcheck warning here
# shellcheck disable=SC2024
sudo printf "    %s.key: |\n        %s\n    %s.crt: |\n        %s" "${flakeInstallHostName}" "$(sudo sed ':a;N;$!ba;s/\n/\n        /g' "/mnt/${luksUSBNebulaPath}/${nebname}.key")" "${flakeInstallHostName}" "$(sudo sed ':a;N;$!ba;s/\n/\n        /g' "/mnt/${luksUSBNebulaPath}/${nebname}.crt")" >>"./secrets/${flakeSecretHostName}/nebula.yaml"
sops --config "./.sops.yaml" -e -i "./secrets/${flakeSecretHostName}/nebula.yaml"

#add device to nebula.nix module
readarray -d "/" -t ip_array <<<"$nebulaIP"
sed -i "/ipMap = {/a \ \ \ \ \ \ ${flakeInstallHostName} = \"${ip_array[0]}\";" "./generic/nebula.nix"

#remove private key from usb stick
sudo rm "/mnt/$luksUSBNebulaPath/${nebname}.key"

#umount and lock usb stick (try again if still busy)
unmounting
