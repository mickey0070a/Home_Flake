 { pkgs, system, ... }:

{
 environment.systemPackages = with pkgs; [
  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  wget
  git
  gh
  htop
  udevil
  usbutils
  klipper
  klipper-flash
  klipper-firmware
  klipper-genconf
  klipper-estimator
  #mainsail
  octoprint 
  moonraker

  # Additional Packages
  python3
  pkgsCross.avr.stdenv.cc
  gcc-arm-embedded
  bintools-unwrapped
  libffi
  libusb1
  avrdude
  stm32flash
  pkg-config
  python313Packages.pyserial
  ncurses
  ];

 services.klipper = {
    enable = true;
    configFile = "/home/flake/Home_Flake/modules/printer.cfg" ; 
   # apiSocket = "/tmp/printer.ser";
    inputTTY = "/tmp/printer";
    octoprintIntegration = true;
    logFile = "/tmp/klippy.log";
    mutableConfig = true;
    #firmwares = {
      #mcu = {
        #enable = true;
        #configFile = /home/ender3/klipper.config;
        #serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
      #};
    #};
   # user = "ender3";
   # group = "wheel";
  };

  services.octoprint = {
    enable = true;
    openFirewall = true;
    plugins = plugins: with plugins; [ octoklipper themeify psucontrol simpleemergencystop bedlevelvisualizer printtimegenius gcodeeditor ];
    group = "wheel";
  };

  services.mjpg-streamer = {
    enable = true;
    group = "video";  # default; ensure camera permission
    inputPlugin = "input_uvc.so";
    outputPlugin = "output_http.so -w @www@ -n -b -p 700 -l 0.0.0.0";  # custom port
    # extra arguments can be specified if needed, though not direct option here
    };

}
