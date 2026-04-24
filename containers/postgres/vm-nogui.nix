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

    diskSize = 1024; # MB — system disk
    emptyDiskImages = [ 20480 ]; # 20 GB virtual data disk for testing

    # Port forwarding for local testing
    forwardPorts = [
      { from = "host"; host.port = 5432; guest.port = 5432; }
    ];
  };

  boot.kernelParams = [ "console=ttyS0" ];
}
