{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # Basic system configuration
  # Using 26.05 (nixos-unstable baseline)
  system.stateVersion = "26.05";

  # Network configuration
  networking = {
    hostName = "influxdb";
    useDHCP = false;
    useHostResolvConf = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8086 8181 ]; # InfluxDB HTTP API and RPC
    };
  };

  # LXC container specific settings
  boot.isContainer = true;
  
  # InfluxDB will use bind-mounted directories from host
  # In Proxmox LXC config, add:
  # mp0: /path/on/host/influxdb-data,mp=/var/lib/influxdb3
  # mp1: /path/on/host/influxdb-config,mp=/etc/influxdb3
  
  # Ensure directories exist
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
  users.groups.influxdb = {};

  # InfluxDB 3 systemd service
  systemd.services.influxdb3 = {
    description = "InfluxDB 3.0 Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.influxdb3}/bin/influxdb3 serve";
      User = "influxdb";
      Group = "influxdb";
      Restart = "on-failure";
      WorkingDirectory = "/var/lib/influxdb3";
      
      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/influxdb3" "/etc/influxdb3" ];
    };

    environment = {
      INFLUXDB_IOX_DB_DIR = "/var/lib/influxdb3";
    };
  };

  # Minimal essential packages for container
  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    influxdb3
  ];

  # Root user with hashed password (qwerty123)
  # To generate a new hash: mkpasswd -m sha-512
  users.users.root.hashedPassword = "$6$G4Owc0wBptUsb0TD$nNhdRoOaPvFqIS03q3Rv9O/OfH9llDsZSDWg9jGgya4VYvUbzCY3yDpSCfYcDu/C5zzBJmh62gLC4O6YNatac0";

  # Build metadata accessible inside container
  environment.etc."build-info.txt".text = ''
    Container: influxdb-lxc
    NixOS Version: ${config.system.nixos.version}
    InfluxDB Version: ${pkgs.influxdb3.version}
    
    To see metadata: cat /etc/build-info.txt
  '';
}


