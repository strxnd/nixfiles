{ lib, pkgs, ... }:

{
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec mango
      fi
    '';

    defaultKeymap = "emacs";
    enableCompletion = true;
    autosuggestion.enable = true;
    fastSyntaxHighlighting.enable = true;

    history = {
      size = 5000;
      save = 5000;
      append = true;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
    };

    shellAliases = {
      c = "clear";
      v = "nvim";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        fpath+=(${pkgs.zsh-completions}/share/zsh/site-functions)
      '')
      (lib.mkOrder 920 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
      (lib.mkOrder 1000 ''
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --color=always -- $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd --color=always -- $realpath'
      '')
      (lib.mkOrder 1500 ''
        fastfetch
      '')
    ];
  };

  programs.zoxide = {
    enable = true;
    options = [ "--cmd" "cd" ];
  };

  programs.oh-my-posh = {
    enable = true;
    configFile = ../../home/kumar/config/oh-my-posh/config.toml;
  };
}
