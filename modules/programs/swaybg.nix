{ delib, pkgs, ... }:

delib.module {
  name = "programs.swaybg";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = [ pkgs.swaybg ];
  };
}
