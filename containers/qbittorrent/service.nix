{
  config,
  pkgs,
  lib,
  name,
  platform,
  ...
}:

{
  # Firewall
  networking.firewall.allowedTCPPorts = [
    8080 # qBittorrent Web UI
    6881 # qBittorrent BitTorrent
  ];
  networking.firewall.allowedUDPPorts = [
    6881 # qBittorrent BitTorrent
  ];

  # qBittorrent directories
  # /var/lib/qbittorrent is bind-mounted from the Proxmox host
  # (/mnt/pve/bx500/qbittorrent) for persistent config across container rebuilds.
  # /mnt/bx1000 and /mnt/hd4000 are full disk bind-mounts for download storage.
  systemd.tmpfiles.rules = [
    "d /var/lib/qbittorrent 0755 qbittorrent qbittorrent -"
    "d /mnt/bx1000 0755 qbittorrent qbittorrent -"
    "d /mnt/hd4000 0755 qbittorrent qbittorrent -"
  ];

  # Create qbittorrent user and group
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "qbittorrent";
    home = "/var/lib/qbittorrent";
  };
  users.groups.qbittorrent = { };

  # qBittorrent-nox systemd service
  systemd.services.qbittorrent = {
    description = "qBittorrent ${pkgs.qbittorrent-nox.version} Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      # --profile sets the base directory for config and data
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --profile=/var/lib/qbittorrent --webui-port=8080";
      User = "qbittorrent";
      Group = "qbittorrent";
      Restart = "on-failure";
      WorkingDirectory = "/var/lib/qbittorrent";

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/var/lib/qbittorrent"
        "/mnt/bx1000"
        "/mnt/hd4000"
      ];
    };
  };

  # Packages
  environment.systemPackages = with pkgs; [
    qbittorrent-nox
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    qBittorrent Version: ${pkgs.qbittorrent-nox.version}
  '';
}
