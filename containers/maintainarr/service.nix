{ config, pkgs, lib, name, platform, ... }:

{

  # Create users and groups for each service
  users.users.bazarr = {
    isSystemUser = true;
    group = "bazarr";
    home = "/config/bazarr";
  };
  users.groups.bazarr = { };

  users.users.radarr = {
    isSystemUser = true;
    group = "radarr";
    home = "/config/radarr";
  };
  users.groups.radarr = { };

  users.users.sonarr = {
    isSystemUser = true;
    group = "sonarr";
    home = "/config/sonarr";
  };
  users.groups.sonarr = { };

  # Ensure config directories exist and have correct permissions
  # Note: /mnt/ssd and /mnt/hdd are bind-mounted from Proxmox host
  systemd.tmpfiles.rules = [
    "e /config 0755 root root -"
    "e /config/bazarr 0755 bazarr bazarr -"
    "e /config/radarr 0755 radarr radarr -"
    "e /config/sonarr 0755 sonarr sonarr -"
  ];

  # Define mount points for Proxmox bind mounts
  # /mnt/ssd and /mnt/hdd are bind-mounted from the Proxmox host
  fileSystems = {
    "/config" = lib.mkDefault {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=100M" "mode=0755" ];
    };
  };

  # Bazarr service
  systemd.services.bazarr = {
    description = "Bazarr ${pkgs.bazarr.version} - Subtitle management";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    requires = [ "local-fs.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.bazarr}/bin/bazarr --config /config/bazarr --port 6767";
      User = "bazarr";
      Group = "bazarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/bazarr";

      # Ensure config directory exists before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/bazarr";

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/config/bazarr"
        "/mnt/ssd"
        "/mnt/hdd"
      ];
    };
  };

  # Radarr service
  systemd.services.radarr = {
    description = "Radarr ${pkgs.radarr.version} - Movie management";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    requires = [ "local-fs.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.radarr}/bin/Radarr -data=/config/radarr";
      User = "radarr";
      Group = "radarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/radarr";

      # Ensure config directory exists before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/radarr";

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/config/radarr"
        "/mnt/ssd"
        "/mnt/hdd"
      ];
    };
  };

  # Sonarr service
  systemd.services.sonarr = {
    description = "Sonarr ${pkgs.sonarr.version} - TV show management";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    requires = [ "local-fs.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.sonarr}/bin/Sonarr -data=/config/sonarr";
      User = "sonarr";
      Group = "sonarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/sonarr";

      # Ensure config directory exists before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/sonarr";

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/config/sonarr"
        "/mnt/ssd"
        "/mnt/hdd"
      ];
    };
  };

  # Packages
  environment.systemPackages = with pkgs; [
    bazarr
    radarr
    sonarr
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    Bazarr Version: ${pkgs.bazarr.version}
    Radarr Version: ${pkgs.radarr.version}
    Sonarr Version: ${pkgs.sonarr.version}
  '';
}
