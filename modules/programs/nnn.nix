{ delib, ... }:

delib.module {
  name = "programs.nnn";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.nnn.enable = true;
}
