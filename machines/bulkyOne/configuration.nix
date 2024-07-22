{ config, ... }:
let
  username = config.networking.hostName;
in {
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/remote-decrypt-tor.nix
  ];

  boot.loader.systemd-boot.enable = true;

  # Locale service discovery and mDNS
  services.avahi.enable = true;
  system.stateVersion = "24.05";
}
