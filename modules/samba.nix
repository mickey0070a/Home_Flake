{ pkgs, ... }:

{
 environment.systemPackages = with pkgs; [
        samba
  ];
  services.samba = {
  enable = true;
  openFirewall = true;
  settings = {
    global = {
      workgroup = "WORKGROUP";
      "disable netbios" = "yes";
      "unix extensions" = "yes";
      "map to guest" = "Bad User";
      server string = "Nix file server";
    };
    public = {
      path = "/srv/public";
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