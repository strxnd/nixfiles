{ delib, ... }:

delib.module {
  name = "programs.librewolf";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.librewolf.enable = true;
}
