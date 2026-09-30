{ delib, ... }:

delib.module {
  name = "programs.imv";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.imv.enable = true;
}
