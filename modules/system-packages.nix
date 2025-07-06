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
	
	htop
	neovim
	syncthing
	git
	mc
	pkgs.kdePackages.kate
	#ventoy
	gparted
	pacman
	python312Packages.pyqt6
	nmap
	pulseaudioFull
	pavucontrol
	zip
	unzip
	openjdk11
  ];
}
