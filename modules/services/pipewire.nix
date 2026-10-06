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

      extraConfig = {
        pipewire."10-audio" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
              192000
              384000
            ];
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 128;
            "default.clock.max-quantum" = 128;
          };
        };
        client."10-audio" = {
          "stream.properties"."resample.quality" = 4;
        };
        pipewire-pulse."10-audio" = {
          "pulse.properties" = {
            "pulse.min.req" = "128/48000";
            "pulse.default.req" = "128/48000";
            "pulse.min.quantum" = "128/48000";
          };
          "stream.properties"."resample.quality" = 4;
        };
      };
    };
  };
}
