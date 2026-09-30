{ delib, ... }:

delib.module {
  name = "system.mouse";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.environment.etc."libinput/local-overrides.quirks".text = ''
    [Disable mouse button debouncing]
    MatchUdevType=mouse
    ModelBouncingKeys=1
  '';
}
