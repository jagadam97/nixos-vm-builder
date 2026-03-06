{
  config,
  pkgs,
  lib,
  ...
}:

{
  # VM-specific settings (no GUI)
  virtualisation = {
    memorySize = 2048;
    diskSize = 10240;  # 10GB - Jellyfin requires 2GB minimum
    qemu.options = [ "-smp 2" ];
    graphics = false;

    # Port forwarding for testing
    forwardPorts = [
      { from = "host"; host.port = 8096; guest.port = 8096; }
    ];
  };

  # Enable serial console
  boot.kernelParams = [ "console=ttyS0" ];

  # Add 10GB data disk for Jellyfin (requires 2GB minimum)
  virtualisation.emptyDiskImages = [ 10240 ];

  # Mount it to /mnt/data for Jellyfin
  fileSystems."/mnt/data" = {
    device = "/dev/vdb";
    fsType = "ext4";
    autoFormat = true;
    options = [ "defaults" "noatime" ];
  };
}
