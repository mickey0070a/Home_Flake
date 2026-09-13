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

let

  # ------------------------------------------------------------
  # Socket-activated OctoPrint wake/proxy
  #
  # systemd owns 127.0.0.1:5000.
  # OctoPrint itself listens on 127.0.0.1:5001.
  #
  # The proxy receives the socket from systemd as FD 3,
  # starts the printer stack, waits for OctoPrint, then
  # forwards the connection to OctoPrint.
  # ------------------------------------------------------------

  octoprintWakeProxy = pkgs.writeText "octoprint-wake-proxy.py" ''
    import os
    import socket
    import subprocess
    import sys
    import threading
    import time

    LISTEN_FD = 3
    BACKEND_HOST = "127.0.0.1"
    BACKEND_PORT = 5001

    START_SERVICES = [
        "klipper.service",
        "mjpg-streamer.service",
        "octoprint.service",
    ]

    def log(message):
        print(f"[3d-printer-stack] {message}", flush=True)

    def start_stack():
        log("Starting 3D printer stack...")

        for service in START_SERVICES:
            log(f"Starting {service}")
            result = subprocess.run(
                ["/run/current-system/sw/bin/systemctl", "start", service],
                check=False,
            )

            if result.returncode != 0:
                log(f"WARNING: {service} returned {result.returncode}")

    def wait_for_octoprint(timeout=60):
        log("Waiting for OctoPrint on 127.0.0.1:5001...")

        deadline = time.monotonic() + timeout

        while time.monotonic() < deadline:
            try:
                with socket.create_connection(
                    (BACKEND_HOST, BACKEND_PORT),
                    timeout=2,
                ):
                    log("OctoPrint is ready.")
                    return True
            except OSError:
                time.sleep(1)

        log("ERROR: OctoPrint did not become ready.")
        return False

    def relay(source, destination):
        try:
            while True:
                data = source.recv(65536)

                if not data:
                    break

                destination.sendall(data)

        except (BrokenPipeError, ConnectionResetError, OSError):
            pass

        finally:
            try:
                destination.shutdown(socket.SHUT_WR)
            except OSError:
                pass

    def proxy_connection(client):
        backend = None

        try:
            backend = socket.create_connection(
                (BACKEND_HOST, BACKEND_PORT),
                timeout=10,
            )

            backend.settimeout(None)
            client.settimeout(None)

            client_to_backend = threading.Thread(
                target=relay,
                args=(client, backend),
                daemon=True,
            )

            backend_to_client = threading.Thread(
                target=relay,
                args=(backend, client),
                daemon=True,
            )

            client_to_backend.start()
            backend_to_client.start()

            client_to_backend.join()
            backend_to_client.join()

        except Exception as error:
            log(f"Proxy connection error: {error}")

        finally:
            if backend is not None:
                try:
                    backend.close()
                except OSError:
                    pass

            try:
                client.close()
            except OSError:
                pass

    def main():

        if os.environ.get("LISTEN_FDS") != "1":
            log("ERROR: expected exactly one systemd socket.")
            sys.exit(1)

        if os.environ.get("LISTEN_PID") != str(os.getpid()):
            log("ERROR: LISTEN_PID does not match this process.")
            sys.exit(1)

        # systemd has already created and bound the listening socket.
        listener = socket.fromfd(
            LISTEN_FD,
            socket.AF_INET,
            socket.SOCK_STREAM,
        )

        # Start the actual printer services.
        start_stack()

        # Do not accept connections until OctoPrint is actually ready.
        if not wait_for_octoprint():
            log("Printer stack failed to become ready.")
            sys.exit(1)

        log("3D printer stack ready.")

        while True:
            try:
                client, address = listener.accept()
                log(f"Accepted connection from {address}")

                thread = threading.Thread(
                    target=proxy_connection,
                    args=(client,),
                    daemon=True,
                )

                thread.start()

            except KeyboardInterrupt:
                break

            except OSError as error:
                log(f"Listener error: {error}")
                break

        listener.close()


    if __name__ == "__main__":
        main()
  '';

in

{
  # ============================================================
  # KLIPPER
  # ============================================================

  services.klipper = {
    enable = true;

    configFile = "/home/flake/Home_Flake/modules/printer.cfg";

    inputTTY = "/tmp/printer";

    octoprintIntegration = true;

    logFile = "/tmp/klippy.log";

    mutableConfig = true;
  };


  # ============================================================
  # OCTOPRINT
  # ============================================================

  services.octoprint = {
    enable = true;

    # OctoPrint itself listens on 5001.
    # Nginx talks to the wake proxy on 5000.
    port = 5001;
    host = "127.0.0.1";

    # Nginx is the externally accessible interface.
    openFirewall = false;

    plugins = plugins: with plugins; [
      octoklipper
      themeify
      psucontrol
      simpleemergencystop
      bedlevelvisualizer
      printtimegenius
      gcodeeditor
    ];

    group = "wheel";

    extraConfig = {
      server = {
        baseurl = "/octoprint";
      };

      webcam = {
        stream = "http://localhost:40000/?action=stream";
      };

      reverseProxy = {
        trustedProxies = [
          "127.0.0.1"
          "192.168.1.0/24"
        ];
      };
    };
  };


  # ============================================================
  # MJPG-STREAMER
  # ============================================================

  services.mjpg-streamer = {
    enable = true;

    group = "video";

    inputPlugin =
      "input_uvc.so -d /dev/video0 -r 640x480 -f 30 -yuv";

    outputPlugin =
      "output_http.so -w @www@ -p 40000 -l 127.0.0.1";
  };


  # ============================================================
  # DO NOT START THE THREE PRINTER SERVICES AT BOOT
  #
  # enable = true above causes NixOS to generate the services,
  # but mkForce removes their normal multi-user startup.
  # They will instead be started by the wake proxy.
  # ============================================================

  systemd.services.klipper.wantedBy = lib.mkForce [];

  systemd.services.octoprint.wantedBy = lib.mkForce [];

  systemd.services.mjpg-streamer.wantedBy = lib.mkForce [];


  # ============================================================
  # SOCKET-ACTIVATED WAKE PROXY
  #
  # Nginx continues to use:
  #
  #   http://127.0.0.1:5000/
  #
  # This socket exists even while the printer stack is stopped.
  # ============================================================

  systemd.sockets."3d-printer-stack" = {
    description = "3D Printer Stack Wake Socket";

    wantedBy = [ "sockets.target" ];

    socketConfig = {
      ListenStream = "127.0.0.1:5000";
      Accept = "no";
      Backlog = 128;
    };
  };


  systemd.services."3d-printer-stack" = {
    description = "3D Printer Stack Wake Proxy";

    after = [
      "3d-printer-stack.socket"
      "network-online.target"
    ];

    requires = [
      "3d-printer-stack.socket"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart =
        "${pkgs.python3}/bin/python3 ${octoprintWakeProxy}";

      # We don't want this service to respawn by itself.
      # The socket will activate it again when needed.
      Restart = "no";

      User = "root";

      # Give the proxy enough time for OctoPrint to start.
      TimeoutStartSec = "90s";

      # Make sure fd 3 remains available.
      FileDescriptorStoreMax = 1;
    };
  };


  # ============================================================
  # PRINTER ACTIVITY TRACKER
  #
  # This watches the Nginx access log and records the last
  # /octoprint/ request.
  # ============================================================

  systemd.services."3d-printer-traffic-check" = {
    description = "Track OctoPrint Web Traffic";

    after = [
      "nginx.service"
    ];

    wants = [
      "3d-printer-idle-shutdown.timer"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '
          while true; do

            if ${pkgs.systemd}/bin/systemctl is-active --quiet octoprint.service; then

              if ${pkgs.grep}/bin/grep -q "/octoprint/" /var/log/nginx/access.log 2>/dev/null; then
                ${pkgs.coreutils}/bin/touch /run/3d-printer-last-traffic
              fi

            fi

            sleep 60
          done
        '
      '';

      Restart = "always";
      RestartSec = 5;
    };
  };


  # ============================================================
  # IDLE SHUTDOWN TIMER
  #
  # Runs every 10 minutes and shuts down the entire stack
  # after 1 hour without OctoPrint traffic.
  # ============================================================

  systemd.timers."3d-printer-idle-shutdown" = {
    description = "Auto-stop 3D Printer Stack after inactivity";

    wantedBy = [
      "timers.target"
    ];

    timerConfig = {
      OnBootSec = "1h";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };


  systemd.services."3d-printer-idle-shutdown" = {
    description = "Stop Idle 3D Printer Stack";

    script = ''
      if ${pkgs.systemd}/bin/systemctl is-active --quiet octoprint.service; then

        if [ -f /run/3d-printer-last-traffic ]; then

          LAST_TRAFFIC=$(
            ${pkgs.coreutils}/bin/stat -c %Y \
            /run/3d-printer-last-traffic
          )

          CURRENT_TIME=$(
            ${pkgs.coreutils}/bin/date +%s
          )

          IDLE_TIME=$(
            (CURRENT_TIME - LAST_TRAFFIC)
          )

          if [ "$IDLE_TIME" -gt 3600 ]; then

            echo "3D Printer Stack idle for more than 1 hour."

            ${pkgs.systemd}/bin/systemctl stop \
              octoprint.service \
              klipper.service \
              mjpg-streamer.service \
              3d-printer-stack.service

            ${pkgs.coreutils}/bin/rm -f \
              /run/3d-printer-last-traffic

          fi

        else

          echo "No OctoPrint traffic recorded."

          ${pkgs.systemd}/bin/systemctl stop \
            octoprint.service \
            klipper.service \
            mjpg-streamer.service \
            3d-printer-stack.service

        fi
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };


  # ============================================================
  # FIREWALL
  #
  # OctoPrint and MJPG are localhost-only.
  # Nginx is already handling external HTTP on port 80.
  # ============================================================

  networking.firewall.allowedTCPPorts = [];
}