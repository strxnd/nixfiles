{ delib, ... }:
delib.module {
  name = "system.nvidia";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = true;
  };
}
