{
  description = "Kumar's NixOS and nix-darwin configuration with Denix";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
      };
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      denix,
      nixpkgs,
      ...
    }@inputs:
    let
      mkConfigurations =
        moduleSystem: hostPaths:
        denix.lib.configurations {
          inherit moduleSystem;
          homeManagerUser = "kumar";
          paths = [ ./modules ] ++ hostPaths;
          extensions = with denix.lib.extensions; [
            args
            (base.withConfig {
              args.enable = true;
              rices.enable = false;
              hosts.features.enable = false;
              hosts.displays.enable = false;
            })
          ];
          specialArgs = { inherit inputs; };
        };
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      nixosConfigurations = mkConfigurations "nixos" [ ./hosts/nix-pc ];
      darwinConfigurations = { };

      formatter.x86_64-linux = pkgs.nixfmt-tree;
      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          nixfmt
          statix
          deadnix
        ];
      };
      checks.x86_64-linux.nix-pc = self.nixosConfigurations.nix-pc.config.system.build.toplevel;
    };
}
