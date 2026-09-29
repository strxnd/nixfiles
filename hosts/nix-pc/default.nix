{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/services.nix
    ../../modules/nixos/users.nix
  ];

  networking.hostName = "nix-pc";
  time.timeZone = "Asia/Singapore";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  system.stateVersion = "26.05";
}
