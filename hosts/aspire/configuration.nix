# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/mmcblk0";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos-ender3-server"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ender3 = {
    isNormalUser = true;
    description = "Ender3";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "ender3";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  git
  gh
  usbutils
  klipper
  klipper-flash
  klipper-firmware
  klipper-genconf
  klipper-estimator
  mainsail
  moonraker
  ];

 services.klipper = {
    enable = true;
    configFile = ./printer.config; 
    #firmwares = {
      #mcu = {
        #enable = true;
        #configFile = /home/ender3/klipper.config;
        #serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
      #};
    #};
    user = "root";
    group = "root";
  };

  # Udev Rule to allow Klipper and other Services to access USB port
  #services.udev.extraRules = ''
    #SUBSYSTEM=="tty", ATTRS{IdVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0660", SYMLINK+="Ender3"
  #'';

  # Enable services like Moonraker (for API)
  services.moonraker = {
    enable = true;
    address = "0.0.0.0";
    allowSystemControl = true;
    settings = {
      authorization = {
        force_logins = true;
        cors_domins = [
          "*.local"
          "*.lan"
        #"*://app.fluidd.xyz"
          "*://my.mainsail.xyz"
        ];
        trusted_clients = [
          "192.168.86.0/24" 
        ];
      };
      server = {
          klippy_uds_address = "/tmp/klipper_uds";
      };
    };
  };

  #Enable Mainsail Services
  services.mainsail.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 7125 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
