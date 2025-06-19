{ pkgs, system, ... }:

{
  imports = [
    #./hardware-configuration.nix
  ];

  home.username = "ender3";
  home.homeDirectory = "/home/ender3";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;

  #networking.hostName = "3d-printer-server";
  #networking.networkmanager.enable = true;

  # Enable Klipper or related printer software
  home.packages = with pkgs; [
    klipper
    moonraker
    mainsail 
  ];

}
