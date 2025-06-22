{ pkgs, ... }:

{
  home.packages = with pkgs; [
	xorg.xauth
        xorg.xinit
        alacritty
<<<<<<< HEAD

	#File Managers
=======
	mucommander
	# Thunar program and plugins
>>>>>>> c8ccf79 (updated file managers)
	xfce.thunar
	xfce.thunar-volman
	xfce.thunar-dropbox-plugin
	xfce.thunar-archive-plugin
	xfce.thunar-media-tags-plugin
<<<<<<< HEAD
	mucommander
=======
>>>>>>> c8ccf79 (updated file managers)
	
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
