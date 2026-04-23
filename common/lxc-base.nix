{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # LXC container specific settings
  boot.isContainer = true;
  boot.initrd.enable = false;

  # Symlink NixOS binaries into /bin so they're available via pct enter / lxc-attach
  # (lxc-attach hardcodes PATH to /sbin:/bin:/usr/sbin:/usr/bin)
  systemd.services.lxc-bin-symlinks = {
    description = "Create symlinks for LXC container binaries";
    wantedBy = [ "multi-user.target" ];
    after = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /bin
      for bin in /run/current-system/sw/bin/*; do
        ln -sfn "$bin" /bin/
      done
    '';
  };

  # Enable getty on console for Proxmox web console
  systemd.enableEmergencyMode = false;

  # Getty on console device
  systemd.services.lxc-web-console = {
    description = "Getty on Console for Proxmox";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-logind.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.util-linux}/bin/agetty --noclear --keep-baud console 115200,38400,9600 $TERM";
      Restart = "always";
      RestartSec = "1sec";
    };
  };

  # Getty on tty1 (some Proxmox setups use this)
  systemd.services.lxc-web-console-tty1 = {
    description = "Getty on tty1 for Proxmox";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-logind.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.util-linux}/bin/agetty --noclear --keep-baud tty1 115200,38400,9600 $TERM";
      Restart = "always";
      RestartSec = "1sec";
    };
  };

  # Network configuration - DHCP by default
  # Override by creating containers/<name>/network.nix
  networking = {
    useDHCP = lib.mkDefault true;
    useHostResolvConf = lib.mkForce false;
    firewall.enable = false;
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Network tuning for high-speed transfers (applies to all LXC containers)
  boot.kernel.sysctl = {
    # TCP buffer sizes for gigabit+ throughput
    "net.core.rmem_max" = 134217728;      # 128 MB
    "net.core.wmem_max" = 134217728;      # 128 MB
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";   # min default max
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";   # min default max

    # Additional network optimizations
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.netdev_max_backlog" = 65536;
    "net.ipv4.tcp_notsent_lowat" = 16384;
    "net.ipv4.tcp_window_scaling" = 1;
  };
}
