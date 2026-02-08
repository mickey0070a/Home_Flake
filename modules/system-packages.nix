{ pkgs, ... }:

{
  home.packages = with pkgs; [
	xorg.xauth
        xorg.xinit
        alacritty

	# Thunar program and plugins
	xfce.thunar
	xfce.thunar-volman
	xfce.thunar-dropbox-plugin
	xfce.thunar-archive-plugin
	xfce.thunar-media-tags-plugin
	mucommander

	# Drive/File Managements
	syncthing
	git
	gh
	mc
	gparted
	zip
	unzip
	cifs-utils

	# Other system tools
	htop
	neovim
	pkgs.kdePackages.kate
	#ventoy
	pacman
	python312Packages.pyqt6
	nmap
	pulseaudioFull
	pavucontrol
	openjdk11
 	gearlever
	gnome-screenshot
	libinput

	# Display Driver for Splitter
	#displaylink
  ];


}
