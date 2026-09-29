{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.kumar = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
}
