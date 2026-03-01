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
      
      # VM version for testing (without LXC-specific modules)
      influxdb-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./containers/influxdb/configuration.nix
          {
            # Override LXC imports for VM testing
            disabledModules = [ "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix" ];
            
            # Enable VM-specific settings
            virtualisation.vmVariant = {
              virtualisation = {
                memorySize = 2048;
                cores = 2;
                graphics = false;
              };
            };
            
            # Enable essential tools for testing
            environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
              vim
              curl
              htop
            ];
            
            # Enable serial console
            boot.kernelParams = [ "console=ttyS0" ];
          }
        ];
      };
    };

    # LXC container tarball builder
    packages.x86_64-linux = {
      influxdb-lxc = self.nixosConfigurations.influxdb-lxc.config.system.build.tarball;
      influxdb-vm = self.nixosConfigurations.influxdb-vm.config.system.build.vm;
    };
  };
}
