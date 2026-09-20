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
      };
    };

    "trilium.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";

      locations."/" = {
        proxyPass = "http://127.0.0.1:8080/";

        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };

    "octoprint.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";

      locations."/" = {
        proxyPass = "http://127.0.0.1:5000/";

        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Scheme $scheme;

          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection $connection_upgrade;
          proxy_http_version 1.1;
        '';
      };
    };

    "onsdel.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";

      #locations."/" = {
       # proxyPass = "http://127.0.0.1:3001/";

        #extraConfig = ''
         # proxy_set_header Host $host;
          #proxy_set_header X-Real-IP $remote_addr;
          #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          #proxy_set_header X-Forwarded-Proto $scheme;

          #proxy_http_version 1.1;
          #proxy_set_header Upgrade $http_upgrade;
          #proxy_set_header Connection $connection_upgrade;
        #'';
      #};
    };
  };
};

networking.firewall.allowedTCPPorts = [ 80 ];


# ============================================================
# Lens / Onskel lazy loading
#
# Nginx
#   ↓
# 127.0.0.1:3001
#   ↓
# onskel-lens.socket
#   ↓
# onskel-lens.service
#   ↓
# Docker Compose
#   ↓
# Lens frontend :3000
# ============================================================

systemd.sockets.onskel-lens = {
  description = "Onskel Lens Server Socket (Lazy Load)";

  wantedBy = [ "sockets.target" ];

  socketConfig = {
    # IMPORTANT:
    # 3001 belongs to systemd.
    # Lens Docker continues to use 3000.
    ListenStream = "127.0.0.1:3001";

    Accept = false;
    KeepAlive = true;
  };
};

systemd.services.onskel-lens = {
  description = "Onskel Lens Server (Docker Compose)";

  after = [
    "docker.service"
    "network-online.target"
  ];

  requires = [
    "docker.service"
  ];

  # Do not start this service at boot.
  # The socket activates it when Nginx connects.
  wantedBy = [ ];

  serviceConfig = {
    Type = "simple";

    WorkingDirectory = "/home/Docker_Files/Lens";

    # Start the Lens stack in the background.
    #
    # systemd-socket-proxyd will become the main process below.
    
ExecStartPre = pkgs.writeShellScript "onskel-lens-start" ''
  ${pkgs.docker-compose}/bin/docker-compose up -d

  for i in $(seq 1 60); do
    if ${pkgs.curl}/bin/curl -fsS \
      http://127.0.0.1:3000/ \
      >/dev/null 2>&1; then
      exit 0
    fi

    sleep 1
  done

  echo "Lens failed to become ready"
  exit 1
'';

    # Forward the systemd socket (3001) to the
    # actual Lens frontend (3000).
    ExecStart =
      "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd " +
      "127.0.0.1:3000";

    # When systemd stops this service, shut down
    # the entire Lens Compose application.
    ExecStop =
      "${pkgs.docker-compose}/bin/docker-compose down";

    Restart = "on-failure";
    RestartSec = "10s";

    User = "root";
  };
  };
}
