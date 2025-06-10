
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/awesome.nix
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
  # services.xserver.enable = true;

  # Enable the Enlightenment Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
 #  services.xserver.windowManager.awesome.enable = true;	
 # services.xserver.desktopManager.enlightenment.enable = true;
  
 #services.displayManager.enable = false;
  #services.xserver.windowManager.i3.enable = true;

 nixpkgs.overlays = [
	(self: super: {
		awesome = super.awesome.override {
			lua = self.lua53Packages.lua;
		};
	})
 ]; 

 services = {
        xserver ={
            enable = true;
            
            windowManager.awesome = {
                enable = true;
                luaModules = with pkgs.lua53Packages; [
                     luarocks
                     luadbi-mysql
                     vicious
                ];
               # package = 54awesome;
             };
         
         displayManager.lightdm = {
             enable = true;
            # defaultSession = "none+awesome";
         };
       };
  };


  nix.settings.experimental-features = [ "nix-command" ];

  # Enable acpid
  services.acpid.enable = true;

# # Automount Drive
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
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
  services.xserver.libinput.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.michaelh = {
    isNormalUser = true;
    description = "Michael Hall";
    extraGroups = [ "networkmanager" "wheel" "storage" ];
    hashedPassword = "$6$bSnWiQcaHCpYd2qB$8dFX7vGp1TnKm3H/e/NFw/hvOUQ3FooLphnNVZrW4kEwpni910oeSfTo9FZmD5JIHADWV7sAjnYHFZ1/W2feV/";
    packages = with pkgs; [
    #  thunderbird
    ];
  };

    users.users.cerih = {
    isNormalUser = true;
    description = "Ceri Hall";
    extraGroups = [ "networkmanager" "wheel" "storage" ];
    hashedPassword = "$6$Vhoyi8jFQBEzuGZV$IV7cElFLzzVUn8thZ9jrREXssDg7yeE/4U8GyEBBaYPGpqfZZVm7Duczl3gCmqMy3nk8EtXjXRvrCgBiwUzRb0";
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = false;

  # Allow AppImage
  programs.appimage = {
	enable = true;
	binfmt = true;
  };

  # Allow unfree packages
  #nixpkgs.config.allowUnfree = true;

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
  system.stateVersion = "24.11"; # Did you read the comment?

}
