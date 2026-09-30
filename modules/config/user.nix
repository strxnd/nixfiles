{ delib, pkgs, ... }:
delib.module {
  name = "user";

  nixos.always = { myconfig, ... }: {
    users.users.${myconfig.constants.username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };
  };

  darwin.always = { myconfig, ... }: {
    system.primaryUser = myconfig.constants.username;
    users.users.${myconfig.constants.username} = {
      name = myconfig.constants.username;
      home = "/Users/${myconfig.constants.username}";
      shell = pkgs.zsh;
    };
  };
}
