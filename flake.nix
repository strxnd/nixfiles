{
  description = "NixOS and nix-darwin configuration with Denix";

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
        moduleSystem: homeManagerUser: hostPaths:
        denix.lib.configurations {
          inherit moduleSystem homeManagerUser;
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
          specialArgs = { inherit inputs homeManagerUser; };
        };
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      nixosConfigurations = mkConfigurations "nixos" "kumar" [ ./hosts/nix-pc ];
      darwinConfigurations = mkConfigurations "darwin" "kumar" [ ./hosts/macbook ];

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nixfmt
              statix
              deadnix
            ];
          };
        }
      );
      checks.x86_64-linux.nix-pc = self.nixosConfigurations.nix-pc.config.system.build.toplevel;
      checks.aarch64-darwin.macbook = self.darwinConfigurations.macbook.config.system.build.toplevel;
    };
}
