{
  delib,
  inputs,
  pkgs,
  ...
}:
delib.module {
  name = "programs.spicetify";
  options = delib.singleEnableOption false;

  myconfig.always.args.shared.spicetifyPkgs =
    inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  home.always.imports = [ inputs.spicetify-nix.homeManagerModules.default ];
  home.ifEnabled.programs.spicetify.enable = true;
}
