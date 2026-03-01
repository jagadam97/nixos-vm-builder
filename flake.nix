{
  description = "NixOS LXC Container Builder for Proxmox - Starting with InfluxDB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      influxdb-lxc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./containers/influxdb/configuration.nix
        ];
      };
    };

    # LXC container tarball builder
    packages.x86_64-linux = {
      influxdb-lxc = self.nixosConfigurations.influxdb-lxc.config.system.build.tarball;
    };
  };
}
