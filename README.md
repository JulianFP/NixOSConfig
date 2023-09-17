## About
This is the Nix flake that defines all my NixOS systems. Enter the folders of the individual systems to get more information about them. The following systems are defined here:
- JuliansFramework: This is my Framework laptop 13 12th Gen and my daily driver. This is the system I use the most which is why it has the most complicated configuration.
- NixOSTesting: This is a VM on my Proxmox PVE that I use for testing NixOS deployments to the Cloud

## Deployment 
- Use the deployment.sh script. It has three options. Use the help option to learn how to use the script, but here are some examples:
    - `./deployment.sh iso NixOSTesting` builds and iso based on the specified device configuration name (as in the flake url) and puts it into local directory 
    - `./deployment.sh deploy NixOSTesting 192.168.3.9 192.168.3.120` deploys nixos on machine with first ip address and clones this git repository in it after rebooting (using the second ip address)
    - `./deployment.sh nebula NixOSTesting 192.168.3.9 192.168.3.120 nixostesting 48.42.1.240/16 "server,test"` same as deploy, but additionally also sets up nebula on host machine by creating certificates etc. (flake has to contain nebula config)
- Note for manual deployment: Run `git update-index --skip-worktree nebulaDevice.*` in git root directory to ignore changes to nebula key files and prevent accidental pushs to github. This can be reverted with `git update-index --no-skip-worktree nebulaDevice.*` if needed
