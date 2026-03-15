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
    qemu.options = [ "-smp 2" ];
    graphics = false;

    # Port forwarding for testing
    forwardPorts = [
      { from = "host"; host.port = 8080; guest.port = 8080; }
    ];
  };

  # Enable serial console
  boot.kernelParams = [ "console=ttyS0" ];
}
