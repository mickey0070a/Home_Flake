{ config, inputs, pkgs, unstable, ... }:

{
  _module.args.unstable = import inputs.nixpkgs-unstable {
	inherit (pkgs.stdenv.hostPlatform) system;
	inherit (config.nixpkgs) config;
  };
  environment.systemPackages = [
	unstable.trilium-next-server
  ];
  services.trilium-server = {
	enable = true;
 	package = unstable.trilium-next-server;
	host = "0.0.0.0";
	port = 8080;
 extraEnvironment = {
    TRILIUM_PORT = "8080";
    TRILIUM_HOST = "0.0.0.0";  # Force binding to all interfaces
  };
  };

  services.tailscale.enable = true;
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
