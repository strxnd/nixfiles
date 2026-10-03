{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "programs.quickshell";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.hardware.i2c.enable = true;

  home.ifEnabled = {
    programs.quickshell.enable = true;
    home.packages = [
      pkgs.wlr-randr
      (pkgs.writeShellApplication {
        name = "display-control";
        runtimeInputs = [
          pkgs.ddcutil
          pkgs.wlr-randr
        ];
        text = ''
          exec ${pkgs.python3}/bin/python3 ${./display-control.py} "$@"
        '';
      })
    ];
    xdg.configFile."quickshell".source = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.difference ./. ./default.nix;
    };
  };
}
