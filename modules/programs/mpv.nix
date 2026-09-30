{ delib, ... }:

delib.module {
  name = "programs.mpv";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.mpv.enable = true;
}
