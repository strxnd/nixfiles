{ delib, ... }:
delib.host {
  name = "nix-pc";
  type = "desktop";
  system = "x86_64-linux";

  myconfig = {
    programs = {
      dconf.enable = true;
      imv.enable = true;
      librewolf.enable = true;
      mango.enable = true;
      mpv.enable = true;
      onepassword.enable = true;
      prismlauncher.enable = true;
      quickshell.enable = true;
      spicetify.enable = true;
      swaybg.enable = true;
      wl-clipboard.enable = true;
    };

    services = {
      networkmanager.enable = true;
      openssh.enable = true;
      pipewire.enable = true;
      xsettingsd.enable = true;
    };

    system = {
      bibata-cursors.enable = true;
      bluetooth.enable = true;
      fonts.enable = true;
      graphics.enable = true;
      grub.enable = true;
      gtk.enable = true;
      mouse.enable = true;
      nvidia.enable = true;
      qt.enable = true;
    };
  };

  nixos = {
    networking.hostName = "nix-pc";
    time.timeZone = "Asia/Singapore";
    system.stateVersion = "26.05";
  };

  home = {
    home.stateVersion = "26.05";

    imports = [
      ({ lib, ... }: {
        home.activation.migrateConfigDirectories =
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
            ''
              for name in mango nvim oh-my-posh; do
                path="$HOME/.config/$name"
                if [ -L "$path" ]; then
                  case "$(readlink "$path")" in
                    "${builtins.storeDir}"/*-home-manager-files/.config/"$name")
                      run rm -- "$path"
                      ;;
                  esac
                fi
              done
            '';
      })
    ];
  };
}
