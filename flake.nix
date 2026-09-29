{
	description = "MangoWC on NixOS";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		spicetify-nix = {
			url = "github:Gerg-L/spicetify-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, spicetify-nix, ... }: {
		nixosConfigurations.nix-pc = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./hosts/nix-pc
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.kumar.imports = [
							./home/kumar
							spicetify-nix.homeManagerModules.default
						];
						extraSpecialArgs = { inherit spicetify-nix; };
						backupFileExtension = "backup";
					};
				}
			];
		};
	};
}
