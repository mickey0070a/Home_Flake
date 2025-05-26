{ pkgs, system, ... }:

{
  imports = [
    #./hardware-configuration.nix
  ];

  #networking.hostName = "3d-printer-server";
  #networking.networkmanager.enable = true;

  # Enable Klipper or related printer software
  home.packages = with pkgs; [
    klipper
    moonraker
    octoprint
  ];

}
