{ delib, pkgs, ... }:

delib.module {
  name = "programs.wget";
  options = delib.singleEnableOption true;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.wget ];
  };

  darwin.ifEnabled = {
    environment.systemPackages = [ pkgs.wget ];
  };
}
