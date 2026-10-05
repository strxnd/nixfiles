{ delib, pkgs, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      coreutils
      grim
      slurp
      satty
      wl-clipboard
    ];
    text = ''
      capture_args=()
      case "''${1:-region}" in
        region)
          geometry=$(slurp -d -b '#181616aa' -c '#87a987ff' -s '#00000000' -w 2) || exit 0
          [ -n "$geometry" ] || exit 0
          capture_args=(-g "$geometry")
          ;;
        full) ;;
        *) exit 1 ;;
      esac

      mkdir -p "$HOME/Pictures/Screenshots"
      grim "''${capture_args[@]}" - | satty --filename -
    '';
  };
in
delib.module {
  name = "programs.satty";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = [ screenshot ];
    programs.satty = {
      enable = true;
      settings = {
        general = {
          fullscreen = true;
          copy-command = "${pkgs.wl-clipboard}/bin/wl-copy";
          actions-on-enter = [
            "save-to-clipboard"
            "exit"
          ];
          output-filename = "~/Pictures/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png";
          save-after-copy = false;
        };
        font.family = "Iosevka";
        color-palette.palette = [
          "#c5c9c5"
          "#c4746e"
          "#87a987"
          "#c4b28a"
          "#8ba4b0"
          "#a292a3"
        ];
      };
    };
  };
}
