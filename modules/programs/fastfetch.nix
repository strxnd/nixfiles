{ delib, ... }:

delib.module {
  name = "programs.fastfetch";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.fastfetch.enable = true;
}
