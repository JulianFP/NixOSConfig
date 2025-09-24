## About
This is the Nix flake that defines all my NixOS systems. Look into the flake.nix and enter the folders of the individual systems to get more information about their config. Any system-specific secrets are stored encrypted in the `secrets/<hostName>` directory. The following systems are defined in this repo:
- **JuliansFramework**: This is my Framework laptop 13 12th Gen and my daily driver. This is the system I use the most which is why it has the most complicated configuration. It shares most of it's config with JuliansPC (can be found under `/generic/desktop` and `/genericHM/desktop`). For more info go to [the desktop README file](generic/desktop/README.md).
- **JuliansPC**: This is my main desktop PC and my second daily driver for when I'm at home (and for gaming!). It shares most of the config with JuliansFramework (can be found under `/generic/desktop` and `/genericHM/desktop`). For more info go to [the desktop README file](generic/desktop/README.md).
- **mainserver**: This is my server machine running in my parents basement. It's an old salvaged and modded Fujitsu workstation with a ZFS data array and a PiKVM attached to it. It runs most of my self-hosting infrastructure, most of it inside NixOS containers.
- **IonosVPS**: Config for my Ionos XS VPS that I use to as an edge server, reverse proxy and NAT which forwards traffic over my nebula overlay network to my containers/services hosted on mainserver and other machines (to have a public, static IPv4 address for all my local servers). This way I don't have to expose the IP address of my parents home network in any DNS records and don't have to do any port forwarding in the routers firewall.
- **IonosVPS2**: Another Ionos VPS that I use as an edge server and NAT, but exclusively for my mailserver. This way my mailserver has it's own IP address and it's http traffic doesn't have to go through a reverse proxy which simplifies things. I'm thinking about merging this with IonosVPS, but on the other hand it is good to have a fallback VPS (to have two nebula lighthouses for example).
- **backupServer**: An old laptop that runs in my parents' garage which serves a my first backup server.
- **backupServerOffsite**: An old ThinkPad that runs in my student dorm room ~400km away and serves as my second backup server (and also it's an offsite backup server). Also runs some services that I want running in my own local network.
- **rescueSystem**, **installISO**: Some utility machines for installation/fallback purposes. installISO is also not really a NixosConfiguration but it's a package that contains an ISO with that machines state.

The following containers are currently hosted on mainserver:
- **Kanidm**: My identity provider for OIDC and LDAP authentication from the other services. PartanenGroup Account!
- **Nextcloud** and **Nextcloud-Testing**: My main and my testing Nextcloud instances
- **Email**: Running my Simple NixOS Mailserver
- **Jellyfin**: Running the Jellyfin mediaserver (and Jellyseerr)
- **Home-Assistant**: Runs Home Assistant for some home automation stuff
- **FoundryVTT**: Runs FoundryVTT, a virtual tabletop software for roleplaying games like DnD
- **ValheimBrueder** and **ValheimMarvin**: Two separate Valheim gaming servers
- More to come, see [here for a full list](mainserver/containers.nix)

## Some noteworthy gems here
- I wrote my own opinionated abstraction layer on top of flake.nix because I didn't like it's repetitive syntax. You can find everything related to that under `generic/utils/`
- I wrote my own container network (which is currently deployed on mainserver) which has some niceties like built-in support for nebula and optionally nebula as the only outgoing network interface (mainly for my mailserver and steam gaming servers) using Linux network namespaces. The module for this can be found [here](generic/containerModule.nix)
- I have a quite complex reverse proxy setup in place running on both mainserver and IonosVPS. It is based on caddy and synchronizes it's HTTPS certs through a shared redis instance so that I can have a second reverse proxy directly on mainserver that accepts local traffic only. mainserver also runs an unbound DNS server (which btw also serves as a custom PiHole replacement) that overwrites my domains DNS records to a local IP address so that traffic doesn't have to go through IonosVPS if you are in the same network as mainserver (also some static route stuff on the IPv6 side of things). This consists of a [proxy module](generic/proxyModule.nix), a [proxy config](generic/proxyConfig.nix) and the [mainserver's unbound config](mainserver/unbound.nix).
- A crazy complicated custom boot setup based on bcachefs with full (native, without LUKS!) disk encryption using clevis framework for automatic decryption using a combination of yubikey, tpm2 and a tang server, impermanence and many custom systemd initrd overwrites can be found [here](generic/desktop/crazy-bcachefs-hardware-config.nix). For more information about the rationale and all it's details go to [the desktop README](generic/desktop/README.md). I use this for both JuliansFramework and JuliansPC, only bricked my laptop twice!
- Monitoring stack with Grafana, Prometheus and Loki, super custom and complex window manager setup with Hyprland on my laptop&desktop, my Neovim setup that I use for development, and much much more....

## Nebula and sops
I use the Nebula overlay network to connect to and between all my servers and machines. I wrote a custom opinionated NixOS module that configures this (under `generc/nebulaModule.nix`) and a shared nebula config that uses it (under `generic/nebula.nix`). Any machine might add stuff for themselves (additional firewall rules, etc.).
The keys and certificates needed for nebula are stored using sops-nix (together with other secrets a machine might need). See `generic/sops.nix`, `.sops.yaml` and the `secrets` directory for info on the general sops setup.
To add new systems to my nebula network quicker and more comfortably I wrote the `createNebulaDevice.sh` script which I also packaged as a Nix package and made available in this repos development shell. Execute `createNebulaDevice -h` in the development shell to get more information about how to use it, but here is an example of its usage:
- `createNebulaDevice mainserver 10.28.128.3/21 -g "server"` -s "192.168.3.0/24"
- `createNebulaDevice Nextcloud-Testing 10.28.129.150/21 -g "server" -i mainserver`
- Don't forget to specify the subnet of the nebula ip address using the CIDR notation (in this example it is /16)

## Deployment
I wrote the `deployment.sh` script to deploy NixOS configurations more easily to machines which I also packaged as a Nix package and made available in this repos development shell. Run the deployment command in the development shell without parameters to get more information about how to use it, but here are some examples of its usage:
- `deployment deploy mainserver 192.168.3.10 10.28.128.3` deploys nixos on the machine with the first ip address (using nixos-anywhere) and clones this git repository onto it after rebooting (using the second ip address)
- `deployment deploySops mainserver 192.168.3.10 10.28.128.3` same as deploy, but additionally also updates the sops config with the new age key of the target system (which gets generated by sops-nix if the system is new) and reencrypts all the secrets that the target system should have access to (this involves updating the .sops.yaml file)
- `deployment sops IonosVPS 82.165.49.241` like deploySops, but without the deploy. Useful if setup the target machine using other methods than this script and nixos-anywhere (for example because the target machine does not fulfill the requirements of nixos-anywhere)
- `deployment.sh iso rescueSystem` builds an iso based on the specified device configuration name (as in the flake url) and puts it into local directory (using nixos-generate)
