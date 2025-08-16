{ config, inputs, pkgs, unstable, ... }:

{

  virtualisation.docker.enable = true;

virtualisation.oci-containers.containers = {
  trilium = {
    image = "zadam/trilium:latest";
    ports = [ "127.0.0.1:8080:8080" ]; # Expose only to localhost
    volumes = [ "trilium-data:/home/node/trilium-data" ];
    #restartPolicy = "unless-stopped";
  };

  tailscale = {
    image = "tailscale/tailscale";
    # Host networking so it can route traffic
    extraOptions = [ "--network=host" "--privileged" ];
    volumes = [
      "/dev/net/tun:/dev/net/tun"
      "tailscale-state:/var/lib/tailscale"
    ];
    environment = {
      TAILSCALE_AUTHKEY = "YOUR_AUTH_KEY"; # Replace with your actual auth key
    };
    command = [ "sh" "-c" "tailscaled & sleep 3 && tailscale up --authkey=${config.virtualisation.oci-containers.containers.tailscale.environment.TAILSCALE_AUTHKEY}" ];
  };
};

# You might need to set up Docker volumes manually
system.activationScripts.createDockerVolumes.text = ''
  docker volume create trilium-data || true
  docker volume create tailscale-state || true
'';

# Define a systemd service for the tailscale container
services.tailscale-container = {
  description = "Tailscale Docker Container";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = ''${pkgs.docker}/bin/docker run --name tailscale --network=host --privileged -v /dev/net/tun:/dev/net/tun -v tailscale-state:/var/lib/tailscale -e TAILSCALE_AUTHKEY=${config.virtualisation.oci-containers.containers.tailscale.environment.TAILSCALE_AUTHKEY} tailscale/tailscale sh -c "tailscaled & sleep 3 && tailscale up --authkey=${config.virtualisation.oci-containers.containers.tailscale.environment.TAILSCALE_AUTHKEY}"'';
    Restart = "always";
  };
};

  # Optional firewall config
  networking.firewall.allowedTCPPorts = [ 80 443 ]; # Or 8080 if you want to expose Trilium directly

}