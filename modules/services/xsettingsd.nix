{ delib, ... }:

delib.module {
  name = "services.xsettingsd";

  options = delib.singleEnableOption false;

  home.ifEnabled.services.xsettingsd = {
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
