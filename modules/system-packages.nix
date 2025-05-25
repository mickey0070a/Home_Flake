{ pkgs, ... }:

{
  home.packages = with pkgs; [
	xorg.xauth
        xorg.xinit
        alacritty
	krusader
	htop
	neovim
	syncthing
	git
	mc
	pkgs.kdePackages.kate
	ventoy
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
