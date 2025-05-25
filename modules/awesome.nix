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
	lua
        
	# Awesome-Copycats
	tamsyn
	font-awesome
	roboto
  ];
}
