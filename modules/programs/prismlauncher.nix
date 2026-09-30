{ delib, ... }:

delib.module {
  name = "programs.prismlauncher";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.prismlauncher.enable = true;
}
