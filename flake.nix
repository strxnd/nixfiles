{
	description = "MangoWC on NixOS";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, ... }: {
		nixosConfigurations.nix-pc = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./hosts/nix-pc
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.kumar = import ./home/kumar;
						backupFileExtension = "backup";
					};
				}
			];
		};
	};
}
