{ config, pkgs, lib, name, platform, ... }:

{

  # InfluxDB directories
  systemd.tmpfiles.rules = [
    "d /var/lib/influxdb2 0755 influxdb influxdb -"
    "d /etc/influxdb2 0755 influxdb influxdb -"
  ];

  # Create influxdb user and group
  users.users.influxdb = {
    isSystemUser = true;
    group = "influxdb";
    home = "/var/lib/influxdb2";
  };
  users.groups.influxdb = { };

  # InfluxDB 2 systemd service
  systemd.services.influxdb2 = {
    description = "InfluxDB ${pkgs.influxdb2-server.version} Server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.influxdb2}/bin/influxd --bolt-path /var/lib/influxdb2/influxd.bolt --engine-path /var/lib/influxdb2/engine --http-bind-address 0.0.0.0:8086";
      User = "influxdb";
      Group = "influxdb";
      Restart = "on-failure";
      WorkingDirectory = "/var/lib/influxdb2";

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/var/lib/influxdb2"
        "/etc/influxdb2"
      ];
    };
  };

  # Packages
  environment.systemPackages = with pkgs; [
    influxdb2
    influxdb2-cli
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    Version: ${pkgs.influxdb2-server.version}
    InfluxDB Version: ${pkgs.influxdb2-server.version}
  '';
}
