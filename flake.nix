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
          ({ modulesPath, lib, config, pkgs, ... }: {
            imports = [
              "${modulesPath}/virtualisation/qemu-vm.nix"
              ./containers/common/vm-base.nix
            ];
            
            # Container configuration (without LXC parts)
            networking.hostName = "influxdb";
            networking.firewall.allowedTCPPorts = [ 8086 ];
            
            # InfluxDB directories
            systemd.tmpfiles.rules = [
              "d /var/lib/influxdb3 0755 influxdb influxdb -"
              "d /etc/influxdb3 0755 influxdb influxdb -"
            ];
            
            # Create influxdb user and group
            users.users.influxdb = {
              isSystemUser = true;
              group = "influxdb";
              home = "/var/lib/influxdb3";
            };
            users.groups.influxdb = { };
            
            # InfluxDB 3 systemd service
            systemd.services.influxdb3 = {
              description = "InfluxDB 3.0 Server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              
              serviceConfig = {
                ExecStart = "${pkgs.influxdb3}/bin/influxdb3 serve --node-id influxdb-node --object-store file --data-dir /var/lib/influxdb3 --http-bind 0.0.0.0:8086";
                User = "influxdb";
                Group = "influxdb";
                Restart = "on-failure";
                WorkingDirectory = "/var/lib/influxdb3";
                
                # Security settings
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [
                  "/var/lib/influxdb3"
                  "/etc/influxdb3"
                ];
              };
              
              environment = {
                INFLUXDB_IOX_DB_DIR = "/var/lib/influxdb3";
              };
            };
            
            # Minimal essential packages for container
            environment.systemPackages = with pkgs; [
              influxdb3
            ];
            
            # Build metadata
            environment.etc."build-info.txt".text = ''
              Container: influxdb-vm (test)
              NixOS Version: ${config.system.nixos.version}
              InfluxDB Version: ${pkgs.influxdb3.version}
              
              To see metadata: cat /etc/build-info.txt
            '';
            
            # VM-specific settings
            virtualisation = {
              memorySize = 2048;
              qemu.options = [ "-smp 2" ];
              graphics = false;
              
              # Port forwarding for testing
              forwardPorts = [
                { from = "host"; host.port = 8086; guest.port = 8086; } # InfluxDB HTTP API
              ];
            };
            
            # Enable serial console
            boot.kernelParams = [ "console=ttyS0" ];
          })
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
