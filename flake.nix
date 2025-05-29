{
  description = "A flake for managing multiple systems including server, 3D printer, and user environments.";

  # Define the Nixpkgs and NixOS channels as inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # Can change this to whichever version you're using
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    #nixos.url = "github:NixOS/nixos/nixos-24.11";
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
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.michaelh = import ./profiles/MichaelH/michaelh.nix;
              #home-manager.users.cerih = import ./profiles/CeriH/cerih.nix;
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
              home-manager.users.ender3 = import ./home/ender3.nix;
              #home-manager.users.ceri = import ./home/ceri.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  }
