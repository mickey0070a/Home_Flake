{ config, inputs, pkgs, unstable, ... }:

{

services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  virtualHosts."local.tailscale" = {
    basicAuth = {
      Mhall = "password1"; 
      CHall = "password2";
    };
    locations = {
      "/trilium" = {
        proxyPass = "http://127.0.0.1:8080/";
      };
      "/octoprint" = {
        proxyPass = "http://127.0.0.1:5000/";
      };
    };
  };
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

services.fail2ban = {
  enable = true;
  jails.nginx = {
    enabled = true;
    filter = "nginx-http-auth";
    logPath = "/var/log/nginx/access.log";
    maxRetry = 3;
    findTime = 60;
    banTime = 14400;
  };
};
}