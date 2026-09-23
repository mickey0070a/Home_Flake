{ config, inputs, pkgs, unstable, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "_" = {
        basicAuthFile = "/etc/nginx/htpasswd";

        #locations."/" = {
       #   return = "404";
       # };
      };
    };

    appendHttpConfig = ''
      include /var/lib/remote-access/routes/*.conf;
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
