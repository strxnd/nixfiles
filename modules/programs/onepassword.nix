{ delib, ... }:
delib.module {
  name = "programs.onepassword";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs._1password.enable = true;
    programs._1password-gui.enable = true;
  };
}
