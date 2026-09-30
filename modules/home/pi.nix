{ pkgs, ... }:
let
  piSetup = pkgs.callPackage ../../pkgs/pi-setup.nix { };
in
{
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [ nodejs git ripgrep fd ];

    settings = {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-6.1-sol";
      defaultThinkingLevel = "medium";
      theme = "kanagawa-dragon";
      quietStartup = true;
      enableInstallTelemetry = false;
      packages = [ "${piSetup}" ];
    };

    context = ../../home/kumar/config/pi/AGENTS.md;
  };
}
