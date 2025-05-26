{ pkgs, system, ... }:

{
  imports = [
    #./hardware-configuration.nix
  ];

  networking.hostName = "3d-printer-server";
  networking.networkmanager.enable = true;

  # Enable Klipper or related printer software
  home.systemPackages = with pkgs; [
    klipper
    moonraker
    octoprint
  ];

  # Enable services like Moonraker (for API)
  services.moonraker.enable = true;

  # Set up a user for printer management (can be used for more specific permissions)
  users.users.ender3 = {
    isNormalUser = true;
    extraGroups = [ 
        "wheel"
        "dialout" 
   ];
  };
}
