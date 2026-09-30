{ delib, pkgs, ... }:

delib.module {
  name = "programs.wl-clipboard";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = [ pkgs.wl-clipboard ];
  };
}
