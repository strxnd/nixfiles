{ delib, ... }:
delib.module {
  name = "system.graphics";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.hardware.graphics.enable = true;
}
