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
  outputs = { self, nixpkgs, nixpkgs-unstable, nixos, flake-utils, home-manager }: flake-utils.lib.eachSystem {
    # For each system, we define specific configurations
    system: let
      pkgs = import nixpkgs {
        system = system;
      };
      # Use the corresponding system configuration based on the architecture
    in {
      # This will include the system configurations for each machine
      nixosConfigurations = {
        serverHost = import ./hosts/mydesktop/configuration.nix { inherit pkgs; inherit system; };
        printerServer = import ./hosts/asus/configuration.nix { inherit pkgs; inherit system; };
        michael = import ./hosts/getac/configuration.nix { inherit pkgs; inherit system; };
        ceri = import ./hosts/chrome/configuration.nix { inherit pkgs; inherit system; };
      };

      # Optional: Define home-manager configurations if desired for user environments
      homeConfigurations = {
        michael = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./home/michael.nix { inherit pkgs system; };
        };
        ceri = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./home/ceri.nix { inherit pkgs system; };
        };
        ender = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./home/ender.nix
        };
        server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./home/server.nix
        };
      };
    }
  };
}
