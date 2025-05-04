{ pkgs, ... }:

{
  home.packages = with pkgs; [
	libreoffice
	trillium-next-desktop
	evolutionWithPlugins
	evolution-ews
	brave
	kmymoney
  ];
}
