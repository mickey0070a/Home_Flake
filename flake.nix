{
  description = "A flake for managing multiple systems including server, 3D printer, and user environments.";

  # Define the Nixpkgs and NixOS channels as inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  # Outputs: Define a set of system configurations (machines)
  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, home-manager, deploy-rs }@inputs:
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
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;
              home-manager.users.michaelh = import ./profiles/michaelh/michaelh.nix;
              home-manager.users.cerih = import ./profiles/cerih/cerih.nix;
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

      # Deploy-rs configuration for multi-machine deployment
      deploy.nodes = {
        getac = {
          hostname = "nixos-getac.local";  # Change to your actual hostname or IP
          fastConnection = true;
          remoteBuild = true;  # Build on this machine
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.getac;
          };
        };
        aspire = {
          hostname = "nixos-aspire.local";  # Change to your actual hostname or IP
          fastConnection = true;
          remoteBuild = true;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.aspire;
          };
        };
        MikeDesktop = {
          hostname = "nixos-desktop.local";  # Change to your actual hostname or IP
          fastConnection = true;
          remoteBuild = true;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.MikeDesktop;
          };
        };
      };

      # Checks for deploy-rs
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
