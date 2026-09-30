{ delib, pkgs, ... }:

delib.module {
  name = "programs.nodejs";
  options = delib.singleEnableOption true;

  home.ifEnabled = {
    home.packages = [ pkgs.nodejs ];
  };
}
