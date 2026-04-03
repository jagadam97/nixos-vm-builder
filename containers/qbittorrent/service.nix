{
  config,
  pkgs,
  lib,
  name,
  platform,
  ...
}:

{
  imports = [
    ./vuetorrent-backend.nix
  ];
  # qBittorrent directories
  # /var/lib/qbittorrent is bind-mounted from the Proxmox host
  # (/mnt/pve/bx500/qbittorrent) for persistent config across container rebuilds.
  # /mnt/bx1000/downloads and /mnt/hd4000/downloads are bind-mounted from the host
  # for persistent download storage.
  systemd.tmpfiles.rules = [
    "d /var/lib/qbittorrent 0755 qbittorrent qbittorrent -"
    "d /var/lib/qbittorrent/qBittorrent 0755 qbittorrent qbittorrent -"
    "d /var/lib/qbittorrent/qBittorrent/cache 0755 qbittorrent qbittorrent -"
    "d /mnt/bx1000/downloads 0755 qbittorrent qbittorrent -"
    "d /mnt/hd4000/downloads 0755 qbittorrent qbittorrent -"
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

    # Create qBittorrent config to allow connections from backend
    preStart = ''
      mkdir -p /var/lib/qbittorrent/qBittorrent/config
      # Configure WebUI to accept requests from VueTorrent backend
      # Disable host header validation to allow proxying from backend
      cat > /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf << 'EOF'
[Preferences]
WebUI\HostHeaderValidation=false
WebUI\LocalHostAuth=false
WebUI\Port=8080
EOF
      chown -R qbittorrent:qbittorrent /var/lib/qbittorrent
    '';

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
        "/mnt/bx1000/downloads"
        "/mnt/hd4000/downloads"
      ];
    };
  };

  services.vuetorrent-backend = {
    enable = true;
    port = 8081;
    qbittorrentUrl = "http://localhost:8080";
    openFirewall = true;
  };

  # Packages
  environment.systemPackages = with pkgs; [
    qbittorrent-nox
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    qBittorrent Version: ${builtins.toString pkgs.qbittorrent-nox.version}
  '';
}
