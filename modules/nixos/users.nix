{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.kumar = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };
}
