{ config, inputs, pkgs, pkgs-unstable, ... }:

{
  _module.args.unstable = import inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (config.nixpkgs) config;
  };
  home.packages = [
        pkgs.libreoffice
        #pkgs.unstable.trilium-next-desktop
        pkgs.evolutionWithPlugins
        pkgs.evolution-ews
        pkgs.brave
        pkgs.kmymoney
  ];
}