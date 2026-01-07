{ config, inputs, pkgs, unstable, ... }:

{

services.nginx = {
  enable = true;
  recommendedProxySettings = true;

  # Catch-all vhost so Tailscale IP access works
  virtualHosts = {
    "_" = {
      basicAuthFile = "/etc/nginx/htpasswd";

      locations = {
        # Trilium at /trilium
        "/trilium/" = {
          proxyPass = "http://127.0.0.1:8080/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        "/octoprint/" = {
          proxyPass = "http://127.0.0.1:5000/"; # note trailing slash
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            proxy_set_header X-Script-Name /octoprint;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_http_version 1.1;
          '';
        };
      };
    };

    # Optional: explicit MagicDNS vhosts (recommended for clean subdomain access)
    "trilium.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080/";
      };
    };

    "octoprint.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";
      locations."/" = {
        proxyPass = "http://127.0.0.1:5000/";
      };
    };
  };
};

  networking.firewall.allowedTCPPorts = [ 80 ];
#systemd.services.nginx = {
  # Nginx runs under sandbox by default, can add or tweak here if needed
  #User = "nginx";
  #Group = "nginx";
#  PrivateTmp = true;
#  ProtectHome = true;
#  ProtectSystem = "strict";
#  ReadOnlyPaths = [ "/etc/nginx" "/srv/nginx" ];
#  ReadWritePaths = [ "/tmp" "/var/tmp" ];
  #CapabilityBoundingSet = [];
#};

#services.fail2ban = {
#  enable = true;
#  jails.nginx = {
#    enabled = true;
#    filter = "nginx-http-auth";
#    logPath = "/var/log/nginx/access.log";
#    maxRetry = 3;
#    findTime = 60;
#    banTime = 14400;
#  };
#};
}
