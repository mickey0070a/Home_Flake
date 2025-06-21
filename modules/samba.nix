{ pkgs, ... }:

{

 {
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/a195148e-9531-4520-b483-0f429fb5a8bb";  # or use the actual UUID
    fsType = "ext4";
    options = [ "defaults" ];
  };
}

 environment.systemPackages = with pkgs; [
        samba
  ];
  services.samba = {
  enable = true;
  openFirewall = true;
  settings = {
    #global = {
      #workgroup = "WORKGROUP";
      #"disable netbios" = "yes";
      #"unix extensions" = "yes";
      #"map to guest" = "Bad User";
      #server.string = "Nix file server";
    };
    public = {
      path = "/mnt/network";
      browseable = yes;
      "guest ok" = yes;
      "read only" = no;
      "create mask" = "0664";
      "directory mask" = "0775";
      "force user" = "server";
      "force group" = server;
    };
  };
};

}
