{
  delib,
  spicetifyPkgs,
  pkgs,
  ...
}:
delib.module {
  name = "programs.spicetify";

  home.ifEnabled.programs.spicetify.enabledCustomApps = [
    spicetifyPkgs.apps.ncsVisualizer
    {
      src = pkgs.fetchzip {
        url = "https://github.com/harbassan/spicetify-apps/releases/download/stats-v1.1.1/spicetify-stats.release.zip";
        hash = "sha256-b2QZnKjUnsJ40QM1CZ2Rk7WXPsHmCvBrokKaZN8X3yQ=";
      };
      name = "stats";
    }
  ];
}
