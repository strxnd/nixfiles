{
  delib,
  pkgs,
  ...
}:

let
  zshCustom = pkgs.runCommand "oh-my-zsh-custom" { } ''
    mkdir -p $out/plugins/zsh-completions
    ln -s ${pkgs.zsh-fzf-tab}/share/fzf-tab $out/plugins/fzf-tab
    ln -s ${pkgs.zsh-completions}/share/zsh/site-functions $out/plugins/zsh-completions/completions
    cat > $out/plugins/zsh-completions/zsh-completions.plugin.zsh <<'EOF'
    fpath=("$ZSH_CUSTOM/plugins/zsh-completions/completions" $fpath)
    EOF
  '';
in
delib.module {
  name = "programs.zsh";
  options = delib.singleEnableOption true;

  nixos.ifEnabled.programs.zsh.enable = true;
  darwin.ifEnabled.programs.zsh.enable = true;

  home.ifEnabled = {
    programs.zsh = {
      enable = true;
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
        custom = "${zshCustom}";
        plugins = [
          "git"
          "sudo"
          "zsh-completions"
          "fzf-tab"
        ];
      };

      shellAliases = {
        c = "clear";
        v = "nvim";
      };

      initContent = ''
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --color=always -- $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd --color=always -- $realpath'
      '';
    };
  };
}
