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
	lua53Packages.lua
 lua53Packages.luarocks
 lua53Packages.vicious
	# Awesome-Copycats
	tamsyn
	font-awesome
	roboto
  ];
}
