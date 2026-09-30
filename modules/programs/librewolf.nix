{ delib, ... }:
let
  colors = {
    background = "#181616";
    foreground = "#c5c9c5";
    hover = "#282727";
    border = "#393836";
    accent = "#87a987";
  };
in

delib.module {
  name = "programs.librewolf";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.librewolf = {
    enable = true;

    policies.ExtensionSettings = {
      "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
        installation_mode = "force_installed";
      };
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
    };

    profiles.default = {
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.theme.toolbar-theme" = 0;
        "browser.theme.content-theme" = 0;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.offlineApps" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "network.cookie.lifetimePolicy" = 0;
      };

      userChrome = ''
        :root {
          color-scheme: dark !important;
          --lwt-accent-color: ${colors.background} !important;
          --lwt-text-color: ${colors.foreground} !important;
          --toolbar-bgcolor: ${colors.background} !important;
          --toolbar-color: ${colors.foreground} !important;
          --toolbar-field-background-color: ${colors.hover} !important;
          --toolbar-field-color: ${colors.foreground} !important;
          --toolbar-field-border-color: ${colors.border} !important;
          --toolbar-field-focus-background-color: ${colors.hover} !important;
          --toolbar-field-focus-color: ${colors.foreground} !important;
          --toolbar-field-focus-border-color: ${colors.accent} !important;
          --toolbarbutton-hover-background: ${colors.hover} !important;
          --toolbarbutton-active-background: ${colors.border} !important;
          --lwt-tab-text: ${colors.foreground} !important;
          --lwt-selected-tab-background-color: ${colors.hover} !important;
          --tab-selected-bgcolor: ${colors.hover} !important;
          --tab-selected-textcolor: ${colors.foreground} !important;
          --chrome-content-separator-color: ${colors.border} !important;
          --arrowpanel-background: ${colors.background} !important;
          --arrowpanel-color: ${colors.foreground} !important;
          --arrowpanel-border-color: ${colors.border} !important;
          --panel-item-hover-bgcolor: ${colors.hover} !important;
          --panel-item-active-bgcolor: ${colors.border} !important;
        }

        #navigator-toolbox, #sidebar-box, #sidebar-header {
          background-color: ${colors.background} !important;
          color: ${colors.foreground} !important;
        }

        .tab-background[selected] {
          border-top: 2px solid ${colors.accent} !important;
        }

        #urlbar-background, #searchbar {
          background-color: ${colors.hover} !important;
          border-color: ${colors.border} !important;
        }

        #urlbar[focused] > #urlbar-background {
          border-color: ${colors.accent} !important;
        }

        menupopup {
          --panel-background: ${colors.background} !important;
          --panel-color: ${colors.foreground} !important;
          --panel-border-color: ${colors.border} !important;
        }
      '';
    };
  };
}
