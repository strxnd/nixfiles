{ delib, pkgs, ... }:
let
  settings.fonts.packages = with pkgs; [
    iosevka
    nerd-fonts.iosevka
  ];
in
delib.module {
  name = "system.fonts";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = settings;
  darwin.ifEnabled = settings;
}
