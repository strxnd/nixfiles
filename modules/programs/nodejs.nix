{
  delib,
  pkgs,
  ...
}:

delib.module {
  name = "programs.nodejs";
  options = delib.singleEnableOption true;

  home.ifEnabled = {
    home.packages = [ (pkgs.callPackage ../../pkgs/codex { }) ];

    programs.npm = {
      enable = true;
      package = pkgs.nodejs_latest;
      settings.prefix = "\${HOME}/.local";
    };

    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
