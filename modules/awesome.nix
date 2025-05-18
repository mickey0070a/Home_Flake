{ pkgs, ... }:

{
  home.packages = with pkgs; [
	# AwesomeWM
	awesome
	alsa-utils
	curl
	dmenu
	mpc-cli
	mpd
	scrot
	unclutter
	xorg.xbacklight
	xsel
	slock
	lua
	lua54Packages.luarocks
 lua54Packages.Vicious

	# Awesome-Copycats
	tamsyn
	font-awesome
	roboto
  ];
}
