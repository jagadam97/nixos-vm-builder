{ config, pkgs, lib, name, platform, ... }:

{

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
    description = "InfluxDB ${pkgs.influxdb3.version} Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.influxdb3}/bin/influxdb3 serve --node-id node1 --object-store file --data-dir /var/lib/influxdb3 --http-bind 0.0.0.0:8086";
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
  };

  # Packages
  environment.systemPackages = with pkgs; [
    influxdb3
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    Version: ${pkgs.influxdb3.version}
    InfluxDB Version: ${pkgs.influxdb3.version}
  '';
}
