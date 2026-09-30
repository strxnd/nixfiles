{ delib, lib, ... }:
delib.module {
  name = "programs.quickshell";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.quickshell.enable = true;
    xdg.configFile."quickshell".source = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.difference ./. ./default.nix;
    };
  };
}
