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
      { from = "host"; host.port = 6767; guest.port = 6767; }  # Bazarr
      { from = "host"; host.port = 7878; guest.port = 7878; }  # Radarr
      { from = "host"; host.port = 8989; guest.port = 8989; }  # Sonarr
    ];
  };

  # Enable serial console
  boot.kernelParams = [ "console=ttyS0" ];
}
