{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "programs.neovim";
  options = delib.singleEnableOption true;

  home.ifEnabled = {
    home.sessionVariables.EDITOR = "nvim";
    xdg.configFile."nvim" = {
      source = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.difference ./. ./default.nix;
      };
      recursive = true;
    };

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
  };

  nixos.ifEnabled.environment.systemPackages = [ pkgs.neovim ];
}
