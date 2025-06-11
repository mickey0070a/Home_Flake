{
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
  boot.supportedFilesystems = [ "zfs" ]; # or "btrfs" if preferred

  # Optional for remote mounting/automation
  services.openssh.knownHosts.enable = true;
}
