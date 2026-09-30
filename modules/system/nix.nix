{ delib, ... }:
let
  settings = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;
  };
in
delib.module {
  name = "system.nix";

  nixos.always = settings;
  darwin.always = settings;
}
