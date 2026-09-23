{ config, inputs, pkgs, unstable, ... }:

{
  services.nginx = {
  enable = true;

  virtualHosts."_" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 80;
      }
    ];

    serverName = "_";

    basicAuthFile = "/etc/nginx/htpasswd";

    locations."/remote-access/" = {
      proxyPass = "http://127.0.0.1:8787";

      extraConfig = ''
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
      '';
    };

    # The ONLY location /
    locations."/" = {
      extraConfig = ''
        include /var/lib/remote-access/root-route.conf;
      '';
    };

    # OctoPrint and Trilium are generated dynamically by the controller.
    extraConfig = ''
      include /var/lib/remote-access/routes.conf;
    '';
  };
};

  networking.firewall.allowedTCPPorts = [ 80 ];
}
