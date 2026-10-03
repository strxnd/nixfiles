{ delib, pkgs, ... }:

delib.module {
  name = "programs.python";
  options = delib.singleEnableOption true;

  home.ifEnabled.home.packages = [
    (pkgs.python3.withPackages (ps: [ ps.tkinter ]))
  ];
}
