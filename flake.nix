{
  description = "A flake for managing multiple systems including server, 3D printer, and user environments.";

  # Define the Nixpkgs and NixOS channels as inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05"; # Can change this to whichever version you're using
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixos.url = "github:NixOS/nixos/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Outputs: Define a set of system configurations (machines)
  outputs = { self, nixpkgs, nixos, flake-utils, home-manager }: flake-utils.lib.eachSystem {
    # For each system, we define specific configurations
    system: let
      pkgs = import nixpkgs {
        system = system;
      };
      # Use the corresponding system configuration based on the architecture
    in {
      # This will include the system configurations for each machine
      nixosConfigurations = {
        serverHost = import ./systems/server-host.nix { inherit pkgs; inherit system; };
        printerServer = import ./systems/3d-printer-server.nix { inherit pkgs; inherit system; };
        michael = import ./systems/michael.nix { inherit pkgs; inherit system; };
        ceri = import ./systems/ceri.nix { inherit pkgs; inherit system; };
      };

      # Optional: Define home-manager configurations if desired for user environments
      homeConfigurations = {
        michael = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./systems/michael.nix { inherit pkgs system; };
        };
        ceri = home-manager.lib.homeManagerConfiguration {
          inherit pkgs system;
          configuration = import ./systems/ceri.nix { inherit pkgs system; };
        };
      };
    }
  };
}
