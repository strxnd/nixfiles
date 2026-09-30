{ delib, ... }:
delib.module {
  name = "system.grub";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
    efi.canTouchEfiVariables = true;
  };
}
