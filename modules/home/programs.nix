{ pkgs, ... }:

{
  programs.gh.enable = true;
  programs.btop.enable = true;
  programs.imv.enable = true;
  programs.mpv.enable = true;
  programs.prismlauncher.enable = true;
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
    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
      tree-sitter
      ripgrep
      fd
      biome
      clang-tools
      lua-language-server
      nil
      nixfmt
      stylua
      tailwindcss-language-server
      vscode-langservers-extracted
      vtsls
      vscode-extensions.vadimcn.vscode-lldb.adapter
    ];
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
