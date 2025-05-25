{ pkgs, ... }:

{
 environment.systemPackages = with pkgs; [
	# AwesomeWM
	#awesome
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
	lua54Packages.lua
        lua54Packages.luarocks
        lua54Packages.vicious
	# Awesome-Copycats
	tamsyn
	font-awesome
	roboto
  ];
}
