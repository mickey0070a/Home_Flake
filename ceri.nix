{ pkgs, system, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Import any specific user services (e.g., home-manager for dotfiles)
  ];

  # Basic system setup
  networking.hostName = "ceri-laptop";
  users.users.ceri = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };

  # Example: Home Manager for Ceri's dotfiles (if using home-manager)
  home-manager.users.ceri = {
    home.packages = with pkgs; [
      vim
      zsh
      htop
    ];

    programs.zsh.enable = true;
    programs.vim.enable = true;
    programs.htop.enable = true;
  };
}
