{ ... }:

{
  imports = [
    ../../modules/home/apps.nix
    ../../modules/home/cursor.nix
    ../../modules/home/programs.nix
    ../../modules/home/spicetify.nix
    ../../modules/home/shell.nix
    ../../modules/home/dotfiles.nix
  ];

  home.username = "kumar";
  home.homeDirectory = "/home/kumar";
  home.stateVersion = "26.05";
}
