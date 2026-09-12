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
     enable = false;  # Disabled for lazy-loading via socket activation
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
     enable = false;  # Disabled for lazy-loading via socket activation
     openFirewall = true;
     plugins = plugins: with plugins; [ octoklipper themeify psucontrol simpleemergencystop bedlevelvisualizer printtimegenius gcodeeditor ];
     group = "wheel";
     host = "0.0.0.0";
     extraConfig = {
      server = { baseurl = "/octoprint"; };
      webcam = { stream = "http://localhost:40000/?action=stream"; };
      reverseProxy = {
        trustedProxies = [
          "127.0.0.1"
          "192.168.1.0/24"
        ];
      };
     };
   };

   services.mjpg-streamer = {
     enable = false;  # Disabled for lazy-loading via socket activation
     group = "video";  # default; ensure camera permission
     inputPlugin = "input_uvc.so -d /dev/video0 -r 640x480 -f 30 -yuv";
     outputPlugin = "output_http.so -w @www@ -p 40000 -l 0.0.0.0";  # custom port
     # extra arguments can be specified if needed, though not direct option here
     };

   networking.firewall.allowedTCPPorts = [ 40000 5000 ]; # SMB, SSH, etc.

   # 3D Printer Stack (Klipper + Octoprint + MJPG-streamer) lazy-loading via systemd socket activation
   # All three services start together when nginx receives a request to /octoprint/
   systemd.sockets."3d-printer-stack" = {
     description = "3D Printer Stack Socket (Lazy Load)";
     wantedBy = [ "sockets.target" ];
     socketConfig = {
       ListenStream = "127.0.0.1:5000";
       Accept = "no";
       KeepAlive = "yes";
     };
   };

   systemd.services."3d-printer-stack-starter" = {
     description = "Start 3D Printer Stack (Klipper + Octoprint + MJPG-streamer)";
     after = [ "3d-printer-stack.socket" "network-online.target" ];
     requires = [ "3d-printer-stack.socket" ];
     wantedBy = [ ];  # Don't auto-start, only via socket activation

     serviceConfig = {
       Type = "oneshot";
       ExecStart = ''${pkgs.systemd}/bin/systemctl start klipper octoprint mjpg-streamer'';
       RemainAfterExit = true;
     };
   };

   # Monitor nginx access log for 3D printer traffic and reset idle timer
   systemd.services."3d-printer-traffic-check" = {
     description = "Monitor 3D Printer traffic for idle detection";
     after = [ "nginx.service" ];
     wants = [ "3d-printer-idle-shutdown.timer" ];

     serviceConfig = {
       Type = "simple";
       ExecStart = ''${pkgs.bash}/bin/bash -c '
         while true; do
           # Check if octoprint is running
           if ${pkgs.systemd}/bin/systemctl is-active --quiet octoprint; then
             # Check for recent traffic to /octoprint/
             LAST_REQUEST=$(${pkgs.busybox}/bin/tail -1 /var/log/nginx/access.log 2>/dev/null | ${pkgs.busybox}/bin/grep -o "octoprint" || echo "")
             if [ ! -z "$LAST_REQUEST" ]; then
               # Reset the idle timer by touching a file
               ${pkgs.coreutils}/bin/touch /run/3d-printer-last-traffic
             fi
           fi
           # Check every 5 minutes
           sleep 300
         done
       '';
       Restart = "always";
       RestartSec = 5;
     };
   };

   # Auto-stop the 3D printer stack after 1 hour of inactivity
   systemd.timers."3d-printer-idle-shutdown" = {
     description = "Auto-stop 3D Printer Stack after 1 hour of inactivity";
     wantedBy = [ "timers.target" ];
     timerConfig = {
       OnBootSec = "1h";
       OnUnitActiveSec = "10min";
       Persistent = true;
     };
   };

   systemd.services."3d-printer-idle-shutdown" = {
     description = "Stop idle 3D Printer Stack";
     script = ''
       # Check if octoprint is running
       if ${pkgs.systemd}/bin/systemctl is-active --quiet octoprint; then
         # Get last traffic time
         if [ -f /run/3d-printer-last-traffic ]; then
           LAST_TRAFFIC=$(${pkgs.coreutils}/bin/stat -c %Y /run/3d-printer-last-traffic)
           CURRENT_TIME=$(${pkgs.coreutils}/bin/date +%s)
           IDLE_TIME=$((CURRENT_TIME - LAST_TRAFFIC))
           # 3600 seconds = 1 hour
           if [ $IDLE_TIME -gt 3600 ]; then
             echo "3D Printer Stack idle for more than 1 hour, stopping..."
             ${pkgs.systemd}/bin/systemctl stop klipper octoprint mjpg-streamer
             ${pkgs.coreutils}/bin/rm -f /run/3d-printer-last-traffic
           fi
         else
           # No traffic file exists, stop the services
           echo "No traffic detected, stopping 3D Printer Stack..."
           ${pkgs.systemd}/bin/systemctl stop klipper octoprint mjpg-streamer
         fi
       fi
     '';
     serviceConfig = {
       Type = "oneshot";
       User = "root";
     };
   };

}
