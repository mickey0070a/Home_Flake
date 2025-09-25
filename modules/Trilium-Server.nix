{ config, inputs, pkgs, unstable, ... }:

{
  _module.args.unstable = import inputs.nixpkgs-unstable {
	inherit (pkgs.stdenv.hostPlatform) system;
	inherit (config.nixpkgs) config;
  };

  #environment.systemPackages = [
	#unstable.trilium-next-server
  #];

  #services.trilium-server = {
	#enable = true;
 	#package = unstable.trilium-next-server;
	#host = "0.0.0.0";
	#port = 8080;
 # };

  #systemd.services.trilium-server.environment = {
    #TRILIUM_HOST = "0.0.0.0";
    #TRILIUM_PORT = "8080";
  #};

  #virtualisation.docker.enable = true;
  #networking.firewall.allowedTCPPorts = [ 8080 40000 ];


 # --- Enable Docker ---
  virtualisation.docker.enable = true;

  # --- Tailscale ---
 # services.tailscale = {
  #  enable = true;
  #  useRoutingFeatures = "server";  # optional, for subnet routing
 # };

  # --- Trilium container ---
  virtualisation.oci-containers = {
    backend = "docker";
    containers.trilium = {
      image = "zadam/trilium:latest";
      autoStart = true;
      ports = [ "0.0.0.0:8080:8080" ]; # only listen locally
      volumes = [
        "/var/lib/trilium:/home/node/trilium-data"
      ];
      environment = {
        TZ = "UTC"; # or your timezone
      };
    };
  };

  # --- Persistent data directory ---
  systemd.tmpfiles.rules = [
    "d /var/lib/trilium 0755 root root -"
  ];

  # Optional: open firewall if you want LAN access
  #networking.firewall.allowedTCPPorts = [ ];
}
