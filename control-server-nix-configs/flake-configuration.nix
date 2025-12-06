{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./router.nix
  ];

  # Enable Nix Flakes
  experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "connect4server";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Indiana/Indianapolis";

  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  users.users.fizzyapple12 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  services.openssh.enable = true;

  services.control-server.enable = true;

  system.stateVersion = "25.05";
}
