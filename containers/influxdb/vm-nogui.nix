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
      { from = "host"; host.port = 8086; guest.port = 8086; } # InfluxDB HTTP API
    ];
  };

  # Enable serial console
  boot.kernelParams = [ "console=ttyS0" ];

  # Override build metadata
  environment.etc."build-info.txt".text = lib.mkDefault ''
    Type: influxdb-vm-nogui (headless VM for testing)
    NixOS Version: ${config.system.nixos.version}
    InfluxDB Version: ${pkgs.influxdb3.version}

    To see metadata: cat /etc/build-info.txt
  '';
}
