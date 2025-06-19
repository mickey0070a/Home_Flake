
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      #../../modules/awesome.nix
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

  networking.hostName = "nixserver"; # Define your hostname.
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
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Required for remote admin
  services.openssh.enable = true;

  # Networking tools
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 445 ]; # SMB, SSH, etc.

  # Avahi (network discovery for SMB)
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.userServices = true;
  };

  # Samba (SMB file share)
  services.samba = {
    enable = true;
    shares = {
      public = {
        path = "/srv/public";
        browseable = true;
        "read only" = false;
        "guest ok" = true;
      };
    };
    extraConfig = ''
      workgroup = WORKGROUP
      server string = nixos
      netbios name = nixserver
      security = user
      map to guest = Bad User
    '';
  };

  # ZFS/Btrfs (if using snapshotting or deduplication)
  #boot.supportedFilesystems = [ "zfs" ]; # or "btrfs" if preferred

  # Optional for remote mounting/automation
  #services.openssh.knownHosts.enable = true;
}
