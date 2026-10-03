{ delib, pkgs, ... }:
let
  piSetup = pkgs.callPackage ../../../pkgs/pi-setup { };
in
delib.module {
  name = "programs.pi";
  options = delib.singleEnableOption true;

  home.ifEnabled.programs.pi-coding-agent = {
    enable = true;
    package = pkgs.pi-coding-agent;
    extraPackages = with pkgs; [
      nodejs
      git
      ripgrep
      fd
    ];

    settings = {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-6.1-sol";
      defaultThinkingLevel = "medium";
      theme = "kanagawa-dragon";
      quietStartup = "header";
      enableInstallTelemetry = false;
      packages = [ "${piSetup}" ];
    };

    context = ./AGENTS.md;
  };
}
