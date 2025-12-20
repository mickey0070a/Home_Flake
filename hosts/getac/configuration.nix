
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../profiles/users.nix
    ];
  
  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.supportedFilesystems = [ "ntfs" ];

  boot.kernelParams = [
  "psmouse.synaptics_intertouch=1"
  ];

  # tlp Power Saving Settings
  services.thermald.enable = true;
  services.tlp.enable = true;

  networking.hostName = "nixos-getac"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  services.connman.enable = false;

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.extraConfig = ''
    Section "Monitor"
      Identifier "eDP-1"
      Option "Primary" "true"
    EndSection

    Section "Monitor"
      Identifier "HDMI-1-1"
      Option "RightOf" "eDP-1"
    EndSection

    Section "Monitor"
      Identifier "HDMI-1-2"
      Option "RightOf" "HDMI-1-1"
    EndSection
  '';

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

  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];

# services.xserver.desktopManager.enlightenment.enable = true;
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  #sound.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = false;
    alsa.enable = false;
    alsa.support32Bit = false;
    pulse.enable = false;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Service to allow touchpad usage after sleep state
  systemd.services.touchpadrestart = {
  	description = "Fixes the touchpad from not working after sleep state";
	wantedBy = [ "sleep.target" ];
  	serviceConfig.ExecStart = ''
		#!/bin/bash
		sudo modprobe -r psmouse
		sudo modprobe psmouse synaptics_intertouch=1
	'';
	serviceConfig.Type = "oneshot";
  };

  # Install firefox.
  programs.firefox.enable = false;

  # Allow AppImage
  programs.appimage = {
	enable = true;
	binfmt = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  	displaylink
  ];

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

  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
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
