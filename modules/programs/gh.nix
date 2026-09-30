{ delib, ... }:

delib.module {
  name = "programs.gh";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.gh.enable = true;
}
