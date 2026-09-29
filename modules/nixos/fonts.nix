{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    iosevka
    nerd-fonts.iosevka
  ];
}
