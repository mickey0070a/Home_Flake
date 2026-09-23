{ config, inputs, pkgs, unstable, ... }:

{
services.nginx = {
  enable = true;
  recommendedProxySettings = true;

  virtualHosts = {
    "_" = {
      basicAuthFile = "/etc/nginx/htpasswd";

      locations = {
        "/trilium/" = {
          proxyPass = "http://127.0.0.1:8080/";

          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        "/octoprint/" = {
          proxyPass = "http://127.0.0.1:5000/";

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

        "/onsdel-server/" = {
          proxyPass = "http://127.0.0.1:3000/";
          
        };
    };
  };
};

networking.firewall.allowedTCPPorts = [ 80 ];
};

services.nginx.appendHttpConfig = ''
  include /var/lib/remote-access/routes/*.conf;
'';
}
