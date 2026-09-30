{ delib, pkgs, ... }:
delib.module {
  name = "home";

  home.always = { myconfig, ... }: {
    home = {
      username = myconfig.constants.username;
      homeDirectory =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "/Users/${myconfig.constants.username}"
        else
          "/home/${myconfig.constants.username}";
    };
  };

  nixos.always.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  darwin.always.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };
}
