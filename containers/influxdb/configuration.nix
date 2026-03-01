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
      allowedTCPPorts = [ 8086 ]; # InfluxDB HTTP API
    };
  };

  # LXC container specific settings
  boot.isContainer = true;
  
  # InfluxDB will use bind-mounted directories from host
  # In Proxmox LXC config, add:
  # mp0: /path/on/host/influxdb-data,mp=/var/lib/influxdb2
  # mp1: /path/on/host/influxdb-config,mp=/etc/influxdb2
  
  # Ensure directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/influxdb2 0755 influxdb2 influxdb2 -"
    "d /etc/influxdb2 0755 influxdb2 influxdb2 -"
  ];

  # InfluxDB service configuration
  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "0.0.0.0:8086";
      reporting-disabled = true;
    };
  };

  # Minimal essential packages for container
  environment.systemPackages = with pkgs; [
    vim
    curl
    htop
    influxdb2-cli
  ];

  # Root user with hashed password (qwerty123)
  # To generate a new hash: mkpasswd -m sha-512
  users.users.root.hashedPassword = "$6$G4Owc0wBptUsb0TD$nNhdRoOaPvFqIS03q3Rv9O/OfH9llDsZSDWg9jGgya4VYvUbzCY3yDpSCfYcDu/C5zzBJmh62gLC4O6YNatac0";

  # Build metadata accessible inside container
  environment.etc."build-info.txt".text = ''
    Container: influxdb-lxc
    NixOS Version: ${config.system.nixos.version}
    InfluxDB Version: ${pkgs.influxdb2-server.version}
    
    To see metadata: cat /etc/build-info.txt
  '';
}


