{ ... }:

{
  programs.zsh = {
      initExtra = ''
        cd /etc/nixos
      '';
  };
}
