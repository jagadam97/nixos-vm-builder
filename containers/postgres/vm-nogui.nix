{
  config,
  pkgs,
  lib,
  ...
}:

{
  virtualisation = {
    memorySize = 2048;
    qemu.options = [ "-smp 2" ];
    graphics = false;

    # Attach a second virtual disk for postgres data
    # In production replace with the real attached disk in Proxmox
    diskSize = 1024; # MB — system disk
    additionalDiskImages = [
      {
        name = "pgdata";
        size = 20480; # 20 GB data disk
      }
    ];

    # Port forwarding for local testing
    forwardPorts = [
      { from = "host"; host.port = 5432; guest.port = 5432; }
    ];
  };

  boot.kernelParams = [ "console=ttyS0" ];
}
