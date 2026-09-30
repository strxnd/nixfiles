{ delib, ... }:
delib.module {
  name = "system.bluetooth";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.hardware.bluetooth.enable = true;
}
