{pkgs, config,...}: let
   torRc = pkgs.writeText "tor.rc" ''
     DataDirectory /etc/tor
     SOCKSPort 127.0.0.1:9050 IsolateDestAddr
     SOCKSPort 127.0.0.1:9063
     HiddenServiceDir /etc/tor/onion/bootup
     HiddenServicePort 22 127.0.0.1:22
   '';
in {

  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 22;
    authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
    hostKeys = [ config.clan.core.facts.services.initrd-openssh.secret."ssh.id_ed25519".path ];
  };

  clan.core.facts.services.initrd-openssh = {
    secret."ssh.id_ed25519" = { };
    public."ssh.id_ed25519.pub" = { };
    generator.path = [
      pkgs.coreutils
      pkgs.openssh
    ];
    generator.script = ''
      ssh-keygen -t ed25519 -N "" -f $secrets/ssh.id_ed25519
      mv $secrets/ssh.id_ed25519.pub $facts/ssh.id_ed25519.pub
    '';
  };

  # lspci -vvvv
  boot.initrd.availableKernelModules = [ "e1000e" "atlantic" ];
  boot.initrd.secrets = {
    "/etc/tor/onion/bootup/hostname" = config.clan.core.facts.services.initrd-tor.secret.tor-initrd-hostname.path;
    "/etc/tor/onion/bootup/hs_ed25519_public_key" = config.clan.core.facts.services.initrd-tor.secret.tor-initrd-hs_ed25519_public_key.path;
    "/etc/tor/onion/bootup/hs_ed25519_secret_key" = config.clan.core.facts.services.initrd-tor.secret.tor-initrd-hs_ed25519_secret_key.path;
  };

  clan.core.facts.services.initrd-tor = {
    secret.tor-initrd-hostname = { };
    secret.tor-initrd-hs_ed25519_public_key = { };
    secret.tor-initrd-hs_ed25519_secret_key = { };

    generator.path = with pkgs; [ coreutils tor gnused ];
    generator.script = let
      torRc = pkgs.writeText "tor.rc" ''
        DataDirectory /etc/tor
        SOCKSPort 127.0.0.1:9050 IsolateDestAddr
        SOCKSPort 127.0.0.1:9063
        HiddenServiceDir onion-bootup
        HiddenServicePort 22 127.0.0.1:22
        RunAsDaemon 0
      '';
    in ''
      set -xe
      chmod 700 $secrets
      cat ${torRc} | sed -e "s!onion-bootup!$secrets!" > $secrets/torrc
      tor -f $secrets/torrc --verify-config
      tor -f $secrets/torrc &
      for i in hostname hs_ed25519_public_key hs_ed25519_secret_key; do
        until [ -e "$secrets/$i" ]; do
          sleep 1
        done
        mv $secrets/$i $secrets/tor-initrd-$i
      done
    '';
  };

  # copy tor to you initrd
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.tor}/bin/tor
  '';

  # start tor during boot process
  boot.initrd.network.postCommands = ''
    echo "tor: preparing onion folder"
    # have to do this otherwise tor does not want to start
    chmod -R 700 /etc/tor

    echo "make sure localhost is up"
    ip a a 127.0.0.1/8 dev lo
    ip link set lo up

    echo "tor: starting tor"
    tor -f ${torRc} --verify-config
    tor -f ${torRc} &
  '';
}
