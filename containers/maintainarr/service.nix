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
  # Note: /config is also bind-mounted from Proxmox host (/mnt/pve/bx500/maintainarr)
  systemd.tmpfiles.rules = [
    "d /config 0755 root root - -"
    "d /config/bazarr 0755 bazarr bazarr - -"
    "d /config/radarr 0755 radarr radarr - -"
    "d /config/sonarr 0755 sonarr sonarr - -"
  ];

  # Enable tmpfiles setup service
  systemd.services.systemd-tmpfiles-setup.enable = true;

  # Bazarr service
  systemd.services.bazarr = {
    description = "Bazarr ${pkgs.bazarr.version} - Subtitle management";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bazarr}/bin/bazarr --config /config/bazarr --port 6767";
      User = "bazarr";
      Group = "bazarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/bazarr";

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
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.radarr}/bin/Radarr -data=/config/radarr";
      User = "radarr";
      Group = "radarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/radarr";

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
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sonarr}/bin/Sonarr -data=/config/sonarr";
      User = "sonarr";
      Group = "sonarr";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/config/sonarr";

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
    Version: ${pkgs.bazarr.version}-${pkgs.radarr.version}-${pkgs.sonarr.version}
    Bazarr Version: ${pkgs.bazarr.version}
    Radarr Version: ${pkgs.radarr.version}
    Sonarr Version: ${pkgs.sonarr.version}
  '';
}
