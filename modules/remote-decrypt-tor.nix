{pkgs,...}:{
  #boot.initrd.secrets = {
  #  "/etc/tor/onion/bootup" = /home/simon/hiddenservice/onion;
  #};
  #
  ## copy tor to you initrd
  #boot.initrd.extraUtilsCommands = ''
  #  copy_bin_and_libs ${pkgs.tor}/bin/tor
  #'';
  #
  ## start tor during boot process
  #boot.initrd.network.postCommands = let
  #  torRc = (pkgs.writeText "tor.rc" ''
  #    DataDirectory /etc/tor
  #    SOCKSPort 127.0.0.1:9050 IsolateDestAddr
  #    SOCKSPort 127.0.0.1:9063
  #    HiddenServiceDir /etc/tor/onion/bootup
  #    HiddenServicePort 22 127.0.0.1:22
  #  '');
  #in ''
  #  echo "tor: preparing onion folder"
  #  # have to do this otherwise tor does not want to start
  #  chmod -R 700 /etc/tor
  #
  #  echo "make sure localhost is up"
  #  ip a a 127.0.0.1/8 dev lo
  #  ip link set lo up
  #
  #  echo "tor: starting tor"
  #  tor -f ${torRc} --verify-config
  #  tor -f ${torRc} &
  #'';
}
