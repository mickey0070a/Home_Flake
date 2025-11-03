services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  virtualHosts."local.tailscale" = {
    locations = {
      "/trilium" = {
        proxyPass = "http://127.0.0.1:8080/";
      };
      "/octoprint" = {
        proxyPass = "http://127.0.0.1:YOUR_OCTOPRINT_PORT/";
      };
    };
  };
};

networking.tailscale = {
  enable = true;
  authKey = "tsauth-yourkey";
  # Set advertise routes or tags as needed.
};

systemd.services.nginx = {
  # Nginx runs under sandbox by default, can add or tweak here if needed
  User = "nginx";
  Group = "nginx";
  PrivateTmp = true;
  ProtectHome = true;
  ProtectSystem = "strict";
  ReadOnlyPaths = [ "/etc/nginx" "/srv/nginx" ];
  ReadWritePaths = [ "/tmp" "/var/tmp" ];
  CapabilityBoundingSet = [];
};