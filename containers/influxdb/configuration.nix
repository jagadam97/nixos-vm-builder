{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../common/lxc-base.nix
  ];

  # Container hostname
  networking.hostName = "influxdb";
  networking.firewall.allowedTCPPorts = [
    8086 # InfluxDB HTTP API
  ];

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

  # Build metadata accessible inside container
  environment.etc."build-info.txt".text = ''
    Container: influxdb-lxc
    NixOS Version: ${config.system.nixos.version}
    InfluxDB Version: ${pkgs.influxdb3.version}

    To see metadata: cat /etc/build-info.txt
  '';
}
