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

	"/Onsdel-Server/" = {
	    proxyPass = "http://127.0.0.1:3000/";
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

    "onsdel.nixserver.tailnet" = {
      basicAuthFile = "/etc/nginx/htpasswd";
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000/";
      };
    };
  };
};

  networking.firewall.allowedTCPPorts = [ 80 ];

  # Onskel FreeCAD Server (Lens) lazy-loading via systemd socket activation
  # The onskel-lens service only starts when nginx tries to connect to port 3000
  systemd.sockets.onskel-lens = {
    description = "Onskel Lens Server Socket (Lazy Load)";
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "127.0.0.1:3000";
      Accept = "no";
      KeepAlive = "yes";
    };
  };

  systemd.services.onskel-lens = {
    description = "Onskel Lens Server (Docker Compose)";
    after = [ "onskel-lens.socket" "docker.service" "network-online.target" ];
    requires = [ "onskel-lens.socket" "docker.service" ];
    wantedBy = [ ];  # Don't auto-start, only via socket activation

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/home/Docker_Files/Lens";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      Restart = "on-failure";
      RestartSec = 10;
      User = "root";
    };
  };

  # Monitor nginx access log for Onskel traffic and reset idle timer
  # This script checks if there has been traffic to port 3000 in the last hour
  systemd.services.onskel-lens-traffic-check = {
    description = "Monitor Onskel Lens traffic for idle detection";
    after = [ "nginx.service" ];
    wants = [ "onskel-lens-idle-shutdown.timer" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.bash}/bin/bash -c '
        while true; do
          # Check if container is running
          if ${pkgs.docker}/bin/docker ps --filter "name=lens-frontend" --quiet 2>/dev/null | grep -q .; then
            # Container is running, check for recent traffic
            LAST_REQUEST=$(${pkgs.busybox}/bin/tail -1 /var/log/nginx/access.log 2>/dev/null | ${pkgs.busybox}/bin/grep -o "Onsdel-Server" || echo "")
            if [ ! -z "$LAST_REQUEST" ]; then
              # Reset the idle timer by touching a file
              ${pkgs.coreutils}/bin/touch /run/onskel-lens-last-traffic
            fi
          fi
          # Check every 5 minutes
          sleep 300
        done
      '';
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Auto-stop the service after 1 hour of inactivity
  systemd.timers.onskel-lens-idle-shutdown = {
    description = "Auto-stop Onskel Lens Server after 1 hour of inactivity";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1h";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };

  systemd.services.onskel-lens-idle-shutdown = {
    description = "Stop idle Onskel Lens Server";
    script = ''
      # Check if container is running
      if ${pkgs.docker}/bin/docker ps --filter "name=lens-" --quiet 2>/dev/null | grep -q .; then
        # Get last traffic time
        if [ -f /run/onskel-lens-last-traffic ]; then
          LAST_TRAFFIC=$(${pkgs.coreutils}/bin/stat -c %Y /run/onskel-lens-last-traffic)
          CURRENT_TIME=$(${pkgs.coreutils}/bin/date +%s)
          IDLE_TIME=$((CURRENT_TIME - LAST_TRAFFIC))
          # 3600 seconds = 1 hour
          if [ $IDLE_TIME -gt 3600 ]; then
            echo "Onskel Lens idle for more than 1 hour, stopping..."
            ${pkgs.systemd}/bin/systemctl stop onskel-lens
            ${pkgs.coreutils}/bin/rm -f /run/onskel-lens-last-traffic
          fi
        else
          # No traffic file exists, stop the service
          echo "No traffic detected, stopping Onskel Lens..."
          ${pkgs.systemd}/bin/systemctl stop onskel-lens
        fi
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

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
