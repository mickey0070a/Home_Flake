{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
