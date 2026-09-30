{ delib, ... }:
delib.module {
  name = "services.pipewire";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
