{ config, inputs, pkgs, unstable, ... }:

{
  _module.args.unstable = import inputs.nixpkgs-unstable {
	inherit (pkgs.stdenv.hostPlatform) system;
	inherit (config.nixpkgs) config;
  };
  environment.systemPackages = [
	unstable.trilium-next-server
  ];
  services.nginx.enable = true;
  services.ngix.virtualHosts."trilium.Hall.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://localhost:8080";
      proxyWebsockets = true;
      basicAuthFile = ./trilium.htpasswd;
    };
  };
  security.acme.acceptTerms = true;
  security.acme.email = "0mike0hall0@gmail.com";
}
