{
  delib,
  inputs,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "programs.spicetify";
  options = delib.singleEnableOption false;

  myconfig.always.args.shared.spicetifyPkgs =
    inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  home.always.imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  home.ifEnabled.programs.spicetify = {
    enable = true;
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    spotifyPackage = pkgs.spotify.overrideAttrs {
      version = "1.3.3.264";
      src = pkgs.fetchurl {
        url = "https://download.scdn.co/SpotifyARM64.dmg";
        hash = "sha256-V5R7WMMoIYY3nu+BOC3uoO/sxOPrds6BPqm0U3vBWaM=";
      };
    };
  };
}
