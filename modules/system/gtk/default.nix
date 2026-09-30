{ delib, pkgs, ... }:

let
  gtkTheme = pkgs.runCommand "kanagawa-green-dark-dragon-gtk" { } ''
    mkdir -p $out/share/themes
    ln -s ${./themes/Kanagawa-Green-Dark-Dragon} $out/share/themes/Kanagawa-Green-Dark-Dragon
  '';
in
delib.module {
  name = "system.gtk";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
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
  };
}
