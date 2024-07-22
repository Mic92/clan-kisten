{ clan-core, lib, ... }:
{
  imports = [
    clan-core.clanModules.sshd
    clan-core.clanModules.root-password
  ];

  clan.core.facts.secretStore = lib.mkForce "password-store";
}
