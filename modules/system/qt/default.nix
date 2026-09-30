{
  delib,
  lib,
  pkgs,
  ...
}:

let
  kvantumTheme = pkgs.runCommand "kanagawa-dragon-kvantum" { } ''
    mkdir -p $out/share/Kvantum
    ln -s ${./themes/Kanagawa-Dragon} $out/share/Kvantum/Kanagawa-Dragon
  '';
in
delib.module {
  name = "system.qt";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
      qt5ctSettings.Appearance.style = "kvantum";
      qt6ctSettings.Appearance.style = "kvantum";
      kvantum = {
        enable = true;
        themes = [ kvantumTheme ];
        settings.General.theme = "Kanagawa-Dragon";
      };
    };

    home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt5ct:qt6ct";
  };
}
