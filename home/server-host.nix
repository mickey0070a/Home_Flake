{ pkgs, system, ... }:

{
  # Define system-level options
  imports = [
    ./hardware-configuration.nix
  ];

  # Basic system setup
  networking.hostName = "server-host";
  networking.networkmanager.enable = true;

  # Enable some basic services like SSH, NTP, etc.
  services.openssh.enable = true;
  time.timeZone = "America/New_York";

  # Example: Adding a file-sharing service (e.g., Samba, NFS)
  services.samba.enable = true;

  # Set up a basic user (can be customized for each machine)
  users.users.michael = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];  # if Docker is enabled
  };
}
