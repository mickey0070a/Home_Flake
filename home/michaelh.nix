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
  
  home.stateVersion = "24.11";
  
  programs.home-manager.enable = true;
  
  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;
  
  #xsession.enable = true;
  #xsession.windowManager.awesome.enable = true;
  
    #home.activation.copyAwesomeConfig = lib.hm.dag.entryAfter #["writeBoundary"] ''
    #rm -rf ~/.config/awesome
    #cp -r ${../modules/awesomewm} ~/.config/awesome
    #'';

  xdg.configFile."awesome".source = ../modules/awesomewm;
     
  nixpkgs.config.allowUnfree = true;

   #home.packages = with pkgs; [
  #];

   programs = {
	  git = {
		  enable = true;
		  userName = "mickey0070a";
		  userEmail = "0mike0hall0@gmail.com";
	  };
  };
}
