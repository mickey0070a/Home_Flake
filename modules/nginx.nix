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

        # OctoPrint at /octoprint
        "/octoprint/" = {
          proxyPass = "http://127.0.0.1:5000/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Needed for subpath
            proxy_redirect off;
            sub_filter_types *;
            sub_filter_once off;
            sub_filter 'href="/' 'href="/octoprint/';
            sub_filter 'src="/' 'src="/octoprint/';
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
