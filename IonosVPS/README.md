# installation (in Ionos VPS with less than 1.5GB RAM)
- setup some linux image (tested with debian 12)
- install newest updates
- set hostname: `hostnamectl hostname IonosVPS`
- insert ssh public key into `/root/.ssh/authorized_keys` and test it
- reboot
- `wget https://raw.githubusercontent.com/JulianFP/LaptopNixOSConfig/main/IonosVPS/extraInstallConfig.nix`
- `curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIXOS_IMPORT=/root/extraInstallConfig.nix NIX_CHANNEL=nixos-23.05 bash -x`
