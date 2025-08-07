# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../profiles/users.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/mmcblk0";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos-aspire"; # Define your hostname.
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

  services.xserver.enable = true;

  services.xserver.displayManager = {
          session = [
              {
              manage = "desktop";
              name = "Xsession";
              start = ''
                      ${pkgs.runtimeShell} $HOME/.xsession &
                       waitPID=$!
              '';
              }
          ];
  };

  # Enable the Enlightenment Desktop Environment.
  services.xserver.displayManager.lightdm.enable = false;
  services.displayManager.sddm.enable = true;

# services.xserver.desktopManager.enlightenment.enable = true;

  #nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable acpid
  services.acpid.enable = true;

# # Automount Drive
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  fileSystems."/home/shared" = {
    device = "//192.168.86.148/public";  # Replace with your actual Samba server IP/share
    fsType = "cifs";
    options = [
      "guest"
      "nofail"
      "_netdev"
    ];
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };
  
  #services.logind.lidSwitch = "ignore";

  # Enable automatic login for the user.
  #services.getty.autologinUser = "ender3";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  ];

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
  #networking.firewall.allowedTCPPorts = [ 80 7125 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
