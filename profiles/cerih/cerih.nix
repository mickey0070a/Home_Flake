{ config, pkgs, lib, pkgs-unstable,  ... }:

{
    imports = [
        ../../modules/system-packages.nix
        ../../modules/office.nix
  ];

  home.username = "cerih";
  home.homeDirectory = "/home/cerih";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;

  xsession ={
	enable = true;
    windowManager.awesome = {
		enable = true;
		package =  (import <nixpkgs> { 
			overlays = [
				(self: super: {
					awesome = super.awesome.override {
						lua = self.lua53Packages.lua;
					};
				})
  			];
		}).awesome;
    };
  };
 
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
