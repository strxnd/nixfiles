{ ... }:

{
  programs.pi-coding-agent.enable = true;
  programs.git = {
    enable = true;
    settings.user = {
      name = "Kumar Aarav";
      email = "kumar@kumaraarav.dev";
    };
  };
  programs.lazygit.enable = true;
  programs.librewolf.enable = true;
  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
  };
  programs.nnn.enable = true;
  programs.fastfetch.enable = true;
  programs.quickshell.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.kitty = {
    enable = true;
    shellIntegration.mode = null;
    extraConfig = builtins.readFile ../../home/kumar/config/kitty/kitty.conf;
  };
}
