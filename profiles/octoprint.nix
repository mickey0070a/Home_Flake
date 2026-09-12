 { pkgs, system, ... }:

{
 users.groups.klipper = {};
 users.groups.octoprint = {};
 users.users.octoprint = {
    isSystemUser = true;
    description = "Octoprint";
	group = "octoprint";
    extraGroups = [ "root" "networkmanager" "wheel" "dialout" "klipper" "octoprint" "users" ];
    packages = with pkgs; [];
  };

  users.users.klipper = {
    isSystemUser = true;
    description = "Klipper";
    group = "klipper";
    extraGroups = [ "root" "networkmanager" "wheel" "dialout" "klipper" "octoprint" " users" ];
  };
  
  security.sudo.extraRules = [
	{
		users = [ "octoprint" ];
		commands = [
			{
			command = "ALL";
			options = [ "SETENV" "NOPASSWD" ];
			}
		];
	}
  ];
}
