{ ... }:

{
  imports = [
    ../../modules/home/apps.nix
    ../../modules/home/appearance.nix
    ../../modules/home/cursor.nix
    ../../modules/home/programs.nix
    ../../modules/home/pi.nix
    ../../modules/home/spicetify.nix
    ../../modules/home/shell.nix
    ../../modules/home/dotfiles.nix
  ];

  home.username = "kumar";
  home.homeDirectory = "/home/kumar";
  home.stateVersion = "26.05";
}
