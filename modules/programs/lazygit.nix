{ delib, ... }:

delib.module {
  name = "programs.lazygit";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.lazygit.enable = true;
}
