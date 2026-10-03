{
  delib,
  lib,
  pkgs,
  ...
}:
delib.host {
  name = "macbook";
  type = "laptop";
  system = "aarch64-darwin";

  myconfig = {
    programs = {
      onepassword.enable = true;
      prismlauncher.enable = true;
      spicetify.enable = true;
    };
    system.fonts.enable = true;
  };

  darwin = {
    networking.hostName = "Kumars-MacBook-Air-8";
    networking.localHostName = "Kumars-MacBook-Air-8";
    nix.package = pkgs.lix;
    system.stateVersion = 6;

    homebrew = {
      enable = true;
      enableZshIntegration = true;
      taps = [
        {
          name = "theboredteam/boring-notch";
          trusted = true;
        }
      ];
      brews = [
        "mole"
        "mas"
      ];
      casks = [
        "1password"
        "1password-cli"
        "theboredteam/boring-notch/boring-notch"
        "cloudflare-warp"
        "zen"
      ];
      masApps = {
        WireGuard = 1451685025;
      };
      onActivation = {
        cleanup = "uninstall";
        autoUpdate = false;
        upgrade = false;
      };
    };
  };

  home = {
    home.stateVersion = "26.05";
    home.packages = with pkgs; [
      aerospace
      chatgpt
    ];
    programs.zsh.initContent = lib.mkBefore ''
      typeset -U path
      path=(/etc/profiles/per-user/$USER/bin /run/current-system/sw/bin $path)
    '';
  };
}
