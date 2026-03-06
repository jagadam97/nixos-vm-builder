{ config, pkgs, lib, name, platform, ... }:

{
  # Firewall - Jellyfin ports
  networking.firewall.allowedTCPPorts = [
    8096  # Jellyfin HTTP web interface
    8920  # Jellyfin HTTPS web interface (optional)
  ];
  networking.firewall.allowedUDPPorts = [
    1900  # DLNA/UPnP discovery
    7359  # Jellyfin service discovery
  ];

  # Jellyfin directories
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0755 jellyfin jellyfin -"
    "d /var/lib/jellyfin/config 0755 jellyfin jellyfin -"
    "d /var/lib/jellyfin/cache 0755 jellyfin jellyfin -"
    "d /var/lib/jellyfin/media 0755 jellyfin jellyfin -"
    "d /mnt/data/jellyfin/data 0755 jellyfin jellyfin -"
    "d /var/log/jellyfin 0755 jellyfin jellyfin -"
    # Data directory on separate disk for vm-nogui
  ];

  # Create jellyfin user and group with video/render for iGPU
  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    home = "/var/lib/jellyfin";
    extraGroups = [ "video" "render" ];
  };
  users.groups.jellyfin = { };
  users.groups.video = { };
  users.groups.render = { };

  # Enable Jellyfin service
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
    dataDir = "/mnt/data/jellyfin";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/lib/jellyfin/cache";
    logDir = "/var/log/jellyfin";
  };

  # Fix Jellyfin crash - ensure SSL certs and restart on failure
  systemd.services.jellyfin = {
    environment = {
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  # Intel iGPU hardware transcoding support (Coffee Lake / UHD 630)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # For Broadwell+ (your UHD 630)
      libvdpau-va-gl      # VDPAU wrapper for VAAPI
    ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    intel-gpu-tools
    libva-utils
  ];

  # Fix Intel iGPU device permissions in LXC container
  # (Proxmox maps host render group to container input group)
  systemd.services.jellyfin-gpu-perms = {
    description = "Fix Intel GPU permissions for Jellyfin";
    wantedBy = [ "multi-user.target" ];
    before = [ "jellyfin.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'chown root:video /dev/dri/card* 2>/dev/null || true; chgrp render /dev/dri/renderD* 2>/dev/null || chown root:input /dev/dri/renderD* 2>/dev/null || true; chmod 660 /dev/dri/* 2>/dev/null || true'";
    };
  };

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    Jellyfin Version: ${pkgs.jellyfin.version}_${pkgs.jellyfin-ffmpeg.version}
  '';
}
