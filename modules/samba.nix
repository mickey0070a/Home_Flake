{ pkgs, ... }:

{

  fileSystems."/mnt/network" = {
    device = "/dev/disk/by-uuid/a195148e-9531-4520-b483-0f429fb5a8bb";  # or use the actual UUID
    fsType = "ext4";
    options = [ "defaults" ];
  };

 environment.systemPackages = with pkgs; [
        samba
  ];

  services.samba = {
  enable = true;
  openFirewall = true;
  settings = {
    global = {
	workgroup = "WORKGROUP";
	"netbios name" = "Nixos";
	"server string" = "NixOS Home Server";
	security = "user";
	"map to guest" = "Bad User";
	"guest account" = "server";
    };
    public = {
      path = "/mnt/network";
      browseable = "yes";
      "guest ok" = "yes";
      "read only" = "no";
      "create mask" = "0664";
      "directory mask" = "0775";
      "force user" = "server";
      "force group" = "server";
    };
  };
};

}
