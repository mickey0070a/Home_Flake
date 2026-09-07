{ pkgs, ... }:

{

  fileSystems."/mnt/network" = {
    device = "/dev/disk/by-uuid/5c3bcf46-2d5d-427f-9add-f8f3dd71a299";  # or use the actual UUID
    fsType = "btrfs";
    options = [ "defaults" ];
  };

  services.samba = {
  package = pkgs.samba4Full;
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
      "create mask" = "0777";
      "directory mask" = "0777";
      "force user" = "server";
      "force group" = "server";
    };
  };
};

}
