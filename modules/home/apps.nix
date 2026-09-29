{ pkgs, ... }:

{
  home.packages = with pkgs; [
    swaybg
    nodejs
    wl-clipboard
  ];
}
