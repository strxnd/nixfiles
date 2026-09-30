{ delib, ... }:

delib.module {
  name = "programs.dconf";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.programs.dconf.enable = true;
}
