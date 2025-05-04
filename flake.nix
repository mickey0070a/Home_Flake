{
  description = "A flake for managing multiple systems including server, 3D printer, and user environments.";

  # Define the Nixpkgs and NixOS channels as inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05"; # Can change this to whichever version you're using
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixos.url = "github:NixOS/nixos/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Outputs: Define a set of system configurations (machines)
  outputs = { self, nixpkgs, nixpkgs-unstable, nixos, flake-utils, home-manager }: 
  {
      nixosConfigurations.getac = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
          modules = [
            ./hosts/getac/configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useUserPackages = true;
              home-manager.users.michael = import ./home/michaelh.nix;
              #home-manager.users.ceri = import ./home/ceri.nix;
            }
          ];
      };
    };
  }
