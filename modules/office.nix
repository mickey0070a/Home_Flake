{ pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
	libreoffice
	pkgs-unstable.trillium-next-desktop
	evolutionWithPlugins
	evolution-ews
	brave
	kmymoney
  ];
}
