{ delib, ... }:

delib.module {
  name = "programs.lsd";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.lsd = {
    enable = true;
    enableZshIntegration = true;
  };
}
