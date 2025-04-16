{ pkgs, system, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Import any specific user services (e.g., home-manager for dotfiles)
  ];

  # Basic system setup
  networking.hostName = "michael-laptop";
  users.users.michael = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  # Example: Home Manager for Michael's dotfiles (if using home-manager)
  home-manager.users.michael = {
    home.packages = with pkgs; [
      vim
      zsh
      tmux
    ];

    programs.zsh.enable = true;
    programs.vim.enable = true;
    programs.tmux.enable = true;
  };
}
