{ lib, pkgs, ... }:

let
  gtkTheme = pkgs.runCommand "kanagawa-green-dark-dragon-gtk" { } ''
    mkdir -p $out/share/themes
    ln -s ${../../home/kumar/themes/Kanagawa-Green-Dark-Dragon} $out/share/themes/Kanagawa-Green-Dark-Dragon
  '';
  kvantumTheme = pkgs.runCommand "kanagawa-dragon-kvantum" { } ''
    mkdir -p $out/share/Kvantum
    ln -s ${../../home/kumar/themes/Kanagawa-Dragon} $out/share/Kvantum/Kanagawa-Dragon
  '';
in
{
  gtk = {
    enable = true;
    theme = {
      name = "Kanagawa-Green-Dark-Dragon";
      package = gtkTheme;
    };
    gtk4.theme = {
      name = "Kanagawa-Green-Dark-Dragon";
      package = gtkTheme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Iosevka";
      size = 14;
    };
    colorScheme = "dark";
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 0;
      gtk-menu-images = 0;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.pointerCursor.gtk.enable = true;

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

  services.xsettingsd = {
    enable = true;
    settings = {
      "Net/ThemeName" = "Kanagawa-Green-Dark-Dragon";
      "Net/IconThemeName" = "Papirus";
      "Gtk/CursorThemeName" = "Bibata-Original-Classic";
      "Net/EnableEventSounds" = true;
      "EnableInputFeedbackSounds" = false;
      "Xft/Antialias" = true;
      "Xft/Hinting" = true;
      "Xft/HintStyle" = "hintslight";
      "Xft/RGBA" = "rgb";
    };
  };
}
