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
  # Using 'e' (adjust) for config dirs that may be Proxmox bind mounts
  # Using 'd' (create) for media mount points
  systemd.tmpfiles.rules = [
    "e /config 0755 root root -"
    "e /config/bazarr 0755 bazarr bazarr -"
    "e /config/radarr 0755 radarr radarr -"
    "e /config/sonarr 0755 sonarr sonarr -"
    "d /mnt 0755 root root -"
    "d /mnt/ssd 0755 root root -"
    "d /mnt/hdd 0755 root root -"
  ];

  # Define mount points for Proxmox bind mounts
  # These will be created but the actual mounting is handled by Proxmox
  fileSystems = {
    "/config" = lib.mkDefault {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=100M" "mode=0755" ];
    };
    "/mnt/ssd" = lib.mkDefault {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=1M" "mode=0755" ];
    };
    "/mnt/hdd" = lib.mkDefault {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=1M" "mode=0755" ];
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

      # Ensure mount points exist before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/bazarr /mnt/ssd /mnt/hdd";

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

      # Ensure mount points exist before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/radarr /mnt/ssd /mnt/hdd";

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

      # Ensure mount points exist before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /config/sonarr /mnt/ssd /mnt/hdd";

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
