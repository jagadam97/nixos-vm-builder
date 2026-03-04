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
}
