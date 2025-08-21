 { pkgs, system, ... }:

{
 # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.michaelh = {
    isNormalUser = true;
    description = "Michael Hall";
    extraGroups = [ "networkmanager" "wheel" "storage" "docker" "video" ];
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
}
