{ config, pkgs, inputs, lib, builtins, pkgs-unstable,  ... }:

{
    imports = [
  	../../modules/system-packages.nix
  	../../modules/office.nix
  	../../modules/engineering.nix
  ];

  home.username = "michaelh";
  home.homeDirectory = "/home/michaelh";
  
  home.stateVersion = "25.05";
  
  programs.home-manager.enable = true;
  
  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;

  xsession ={
	enable = true;
    windowManager.awesome = {
		enable = true;
		package =  (pkgs.extend (self: super: { 
					awesome = super.awesome.override {
						lua = self.lua53Packages.lua;
					};
		})).awesome;
    };
  };
 
  xdg.configFile."awesome".source = ./awesomewm;
     
  nixpkgs.config.allowUnfree = true;

   programs = {
	  git = {
		  enable = true;
		  userName = "mickey0070a";
		  userEmail = "0mike0hall0@gmail.com";
	  };
  };
}
