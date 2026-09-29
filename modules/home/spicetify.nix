{ pkgs, spicetify-nix, ... }:

let
  spicetifyPkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.spicetify = {
    enable = true;
    theme = spicetifyPkgs.themes.text // {
      additionalCss = ''
        :root {
          --font-family: "Iosevka Nerd Font", monospace;
          --font-family-header: "Iosevka Nerd Font";
        }
      '';
    };
    colorScheme = "custom";
    customColorScheme = {
      accent = "87a987";
      accent-active = "87a987";
      accent-inactive = "181616";
      banner = "87a987";
      border-active = "87a987";
      border-inactive = "393836";
      header = "9e9b93";
      highlight = "9e9b93";
      main = "181616";
      notification = "8ba4b0";
      notification-error = "c4746e";
      subtext = "c0c3c0";
      text = "a6a69c";
    };
    enabledCustomApps = [ spicetifyPkgs.apps.ncsVisualizer ];
  };
}
