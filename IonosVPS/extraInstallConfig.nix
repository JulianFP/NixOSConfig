{ config, lib, pkgs, ...}:

{
  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "julian";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDG6vrZvvc69df3puZzdOxqxHjH3H6ZVVpysTK4cmR684eZsXF+63WyTMkntuu3LTPQ5ExTDFjZlpZXqaH86Gb5N7c+TkpwCqK7FsVx9oVE44U9L93o87B/LMnk2/o8AZeYgxNo+Jq4cbxXjBT4t5IW2LCsSs1wyo+X/hO/VHmAV/93DvNIIush8ans+mZC5Wv7Mq+mEeF/5x64K/Y15KYDMvqawQlm1ivJpwM0CZjwbz7CH3f7tsIvnJ3hgvsnfNAlu9zBUuBtmLJC3BoAmLgNVi37c8MuCOoZ+R+sTlAfPTuKoYQg2yAhGG7k5Qt0HVQ6ywW5a3PbkzpmAVbXVE4Mx9GNPakdS38QUKVwKOegWxgWNdwwSMdN0kkBSB6/9ktxGsvtCMuPJtZg/iaWxQB19zcow8UDrE9rgbLSytdtdQWHPWo77pJUySkelOx7cyEvNhAcj/3HrhN4OBQdgyKHDpyr7o6SHQeA5eMW2kshVfj7uVysu8KKtTjnJlsLw3l/PxspPP3xU9suKrTSRHEIqiOX6GmWDawtU5EOkqPBRObiY2na4Yjl8otB4+OjTvJunKNyj3xfRmpjA+WmWhhk9VU4E2roi0DwTvIv/Ecf+ynvgngA6J3v849PkkDo2RLQOjlTYKpoHZ/YGzfP8rkZrwQgBM1LqjcxDiRBVWPoHQ== openpgp:0x87894724"
    ];
  };
}
