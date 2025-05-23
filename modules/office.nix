{ config, inputs, pkgs, pkgs-unstable, ... }:

{
  _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
	inherit (pkgs.stdenv.hostPlatform) system;
	inherit (config.nixpkgs) config;
  };
  home.packages = with pkgs; [
	libreoffice
	pkgs-unstable.trillium-next-desktop
	evolutionWithPlugins
	evolution-ews
	brave
	kmymoney
  ];
}
