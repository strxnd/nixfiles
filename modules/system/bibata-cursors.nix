{ delib, pkgs, ... }:

delib.module {
  name = "system.bibata-cursors";

  options = delib.singleEnableOption false;

  home.ifEnabled.home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Original-Classic";
    size = 24;
  };
}
