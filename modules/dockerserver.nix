{ config, inputs, pkgs, unstable, ... }:

{
  # Enable Tailscale globally
  services.tailscale.enable = true;
  #services.tailscale.stateDir = "/var/lib/tailscale";
  #services.tailscale.authKey = "tskey-auth-kwe8SMWkSX11CNTRL-pFb7GKB1Xu7zT8d6ARpLv7WZzpuBCBNYd"; # Replace with your actual auth key

  # Ensure Docker is enabled
  virtualisation.docker.enable = true;

  virtualisation.oci-containers.containers = {
    trilium = {
      image = "zadam/trilium:latest";
      ports = [ "127.0.0.1:8080:8080" ]; # Expose only to localhost
      volumes = [ "trilium-data:/home/node/trilium-data" ];
      environment = {
        TAILSCALE_AUTHKEY = "${config.services.tailscale.authKey}"; # Use the global auth key
      };
      entrypoint = "sh -c 'tailscaled & sleep 3 && tailscale up --authkey=$TAILSCALE_AUTHKEY && trilium'"; # Start Tailscale and then Trilium
    };
  };

  # You might need to set up Docker volumes manually
  system.activationScripts.createDockerVolumes.text = ''
    docker volume create trilium-data || true
  '';

# You might need to set up Docker volumes manually
#system.activationScripts.createDockerVolumes.text = ''
  #docker volume create trilium-data || true
  #docker volume create tailscale-state || true
#'';

# Define a systemd service for the tailscale container

  # Optional firewall config
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ]; # Or 8080 if you want to expose Trilium directly

}
