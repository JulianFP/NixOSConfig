{
  ...
}:

{
  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "julian";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADKJhMG7cqws+ITuYwEbcJ1vw3UwfLB25BdyFpXSPDS openpgp:0xF78754DD"
    ];
  };
}
