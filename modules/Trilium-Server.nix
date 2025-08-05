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
	port = 8080;
 host = "0.0.0.0";
};

services.tailscale.enable = true;
networking.firewall.allowedTCPPorts = [ 8080 ];

}
