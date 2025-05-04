{ config, pkgs, lib,  ... }:

{
    imports = [
	../modules/office-packages.nix
	../modules/system-packages.nix
	../modules/engineering.nix
  ../modules/core.nix
  ../modules/awesome.nix
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

  xsession.enable = true;
  xsession.windowManager.command = "${pkgs.awesome}/bin/awesome";

  programs = {
	  git = {
		  enable = true;
		  userName = "mickey0070a";
		  userEmail = "0mike0hall0@gmail.com";
	  };
  };
}
