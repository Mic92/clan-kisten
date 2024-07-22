{
  description = "<Put your description here>";

  inputs.clan-core.url = "https://git.clan.lol/clan/clan-core/archive/rework-installation.tar.gz";

  outputs =
    { self, clan-core, ... }:
    let
      system = "x86_64-linux";
      pkgs = clan-core.inputs.nixpkgs.legacyPackages.${system};
      # Usage see: https://docs.clan.lol
      clan = clan-core.lib.buildClan {
        directory = self;
        meta.name = "kisten";

        # Distributed services, uncomment to enable.
        # inventory = {
        #   services = {
        #     # This example configures a BorgBackup service
        #     # Check: https://docs.clan.lol/reference/clanModules which ones are available in Inventory
        #     borgbackup.instance_1 = {
        #       roles.server.machines = [ "jon" ];
        #       roles.client.machines = [ "sara" ];
        #     };
        #   };
        # };

        # Prerequisite: boot into the installer
        # See: https://docs.clan.lol/getting-started/installer
        # local> mkdir -p ./machines/machine1
        # local> Edit ./machines/machine1/configuration.nix to your liking
        machines = {
          # "jon" will be the hostname of the machine
          bulkyOne = {
            imports = [
              ./modules/shared.nix
              ./modules/disko.nix
              ./machines/bulkyOne/configuration.nix
            ];

            nixpkgs.hostPlatform = system;

            # Set this for clan commands use ssh i.e. `clan machines update`
            # If you change the hostname, you need to update this line to root@<new-hostname>
            # This only works however if you have avahi running on your admin machine else use IP
            clan.core.networking.targetHost = pkgs.lib.mkDefault "root@bulkyOne";

            # ssh root@flash-installer.local lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
            disko.devices.disk.main.device = "/dev/disk/by-id/nvme-INTEL_SSDPEKKW128G7_BTPY63650BWM128A";

            # IMPORTANT! Add your SSH key here
            # e.g. > cat ~/.ssh/id_ed25519.pub
            users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyXLFSU2EJQ3Tzf9RycYrdPijXtHdoCDMmbpOYJE2JC simon@tux" ];

            # Zerotier needs one controller to accept new nodes. Once accepted
            # the controller can be offline and routing still works.
            clan.core.networking.zerotier.controller.enable = true;
          };
        };
      };
    in
    {
      # all machines managed by Clan
      inherit (clan) nixosConfigurations clanInternals;
      # add the Clan cli tool to the dev shell
      devShells.${system}.default = pkgs.mkShell {
        packages = [ clan-core.packages.${system}.clan-cli ];
      };
    };
}
