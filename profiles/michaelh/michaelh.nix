{ config, pkgs, lib, pkgs-unstable,  ... }:

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
  
  #xsession.enable = true;
  #xsession.windowManager.awesome.enable = true;

  nixpkgs.overlays = [
	(self: super: {
		awesome = super.awesome.override {
			lua = self.lua53Packages.lua;
		};
	})
  ]; 

  xsession ={
	enable = true;
        windowManager.awesome = {
		enable = true;
                #luaModules = with pkgs.lua53Packages; [
                     #luarocks
                     #luadbi-mysql
                     #vicious
                #];
               # package = 54awesome;
	};
  };

  
    #home.activation.copyAwesomeConfig = lib.hm.dag.entryAfter #["writeBoundary"] ''
    #rm -rf ~/.config/awesome
    #cp -r ${../modules/awesomewm} ~/.config/awesome
    #'';

  xdg.configFile."awesome".source = ./awesomewm;
     
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
