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
  users.groups.video = {
    gid = 26;
  };
  users.groups.render = {
    gid = 303;
   };

  # Enable Jellyfin service
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
    dataDir = "/var/lib/jellyfin/data";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/lib/jellyfin/cache";
    logDir = "/var/log/jellyfin";
  };

  # Fix Jellyfin crash - ensure SSL certs and restart on failure
  systemd.services.jellyfin = {
    # This ensures Jellyfin can find the ICU libraries and GPU drivers
    path = with pkgs; [ 
      icu 
      intel-media-driver 
      intel-gpu-tools 
    ];
    environment = {
      LIBVA_DRIVER_NAME = "iHD";
      ONEVPL_SEARCH_PATH = "${pkgs.vpl-gpu-rt}/lib/vpl";
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
          intel-media-driver
          intel-compute-runtime # for HDR tone mapping
        ]);
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "0";
      CLR_ICU_PATH = "${pkgs.icu}/lib";
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
      intel-media-driver   # The modern VA-API driver
      vpl-gpu-rt           # The modern QSV runtime
      intel-compute-runtime # For HDR tone mapping
    ];
  };

  # Packages
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    intel-gpu-tools
    libva-utils
    icu
  ];

  # Fix Intel iGPU device permissions in LXC container
  # (Proxmox maps host render group to container input group)
  systemd.services.jellyfin-gpu-perms = {
    description = "Ensure jellyfin can access the GPU";
    wantedBy = [ "multi-user.target" ];
    before = [ "jellyfin.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'chgrp render /dev/dri/renderD128 && chgrp video /dev/dri/card1 && chmod 660 /dev/dri/*'";
    };
  };

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    Jellyfin Version: ${pkgs.jellyfin.version}_${pkgs.jellyfin-ffmpeg.version}
  '';
}
