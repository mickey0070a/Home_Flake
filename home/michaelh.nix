{ config, pkgs, lib, pkgs-unstable,  ... }:

{
    imports = [
	../modules/system-packages.nix
  	../modules/awesome.nix
  	../modules/office.nix
  	../modules/engineering.nix
  ];

  home.username = "michaelh";
  home.homeDirectory = "/home/michaelh";

  programs.home-manager.enable = true;
  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;
    
    #home.activation.copyAwesomeConfig = lib.hm.dag.entryAfter #["writeBoundary"] ''
    #rm -rf ~/.config/awesome
    #cp -r ${../modules/awesomewm} ~/.config/awesome
    #'';

  xdg.configFile."awesome".source = ../modules/awesomewm;
     
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];

  home.sessionVariables = {
    LUA_PATH = "$HOME/.luarocks/share/lua/5.3/?.lua;;";
    LUA_CPATH = "$HOME/.luarocks/lib/lua/5.3/?.so;;";
  };

  xsession.enable = true;

  #xsession.windowManager.command = ''
	#if ! luarocks --tree "$HOME/.luarocks" show lain > /dev/null 2>&1; then
	#	luarocks --tree "$HOME/.luarocks" install lain
	#fi
	#if ! luarocks --tree "$HOME/.luarocks" show awesome-freedesktop > /dev/null 2>&1; then
	#	luarocks --true "$HOME/.luarocks" install awesome-freedesktop
	#fi
    #exec awesome
  #'';
  
  xsession.windowManager.awesome.enable = true;

  programs = {
	  git = {
		  enable = true;
		  userName = "mickey0070a";
		  userEmail = "0mike0hall0@gmail.com";
	  };
  };
}
