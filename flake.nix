{
  description = "A flake for managing multiple systems including server, 3D printer, and user environments.";

  # Define the Nixpkgs and NixOS channels as inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # Can change this to whichever version you're using
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    #nixos.url = "github:NixOS/nixos/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Outputs: Define a set of system configurations (machines)
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, home-manager }@inputs:
  {
      nixosConfigurations.getac = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/getac/configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.michaelh = import ./profiles/michaelh/michaelh.nix;
              home-manager.users.cerih = import ./profiles/cerih/cerih.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
      };
        nixosConfigurations.aspire = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/aspire/configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.octoprint = import ./profiles/octoprint.nix;
              #home-manager.users.ceri = import ./home/ceri.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
        nixosConfigurations.MikeDesktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/MikeDesktop/configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.michaelh = import ./profiles/michaelh/michaelh.nix;
              home-manager.users.cerih = import ./profiles/cerih/cerih.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
      };
   };
}
