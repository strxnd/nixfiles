{ delib, ... }:
delib.module {
  name = "services.networkmanager";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.networking.networkmanager.enable = true;
}
