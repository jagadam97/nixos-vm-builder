{ pkgs, lib, modulesPath, ... }:

{
  # Basic system configuration
  # Using 26.05 (nixos-unstable baseline)
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  system.stateVersion = "26.05";

  # LXC container specific settings
  boot.isContainer = true;
  boot.initrd.enable = false;

  # Symlink NixOS binaries into /bin so they're available via pct enter / lxc-attach
  # (lxc-attach hardcodes PATH to /sbin:/bin:/usr/sbin:/usr/bin)
  # Using a systemd service instead of activation script to ensure proper timing
  systemd.services.lxc-bin-symlinks = {
    description = "Create symlinks for LXC container binaries";
    wantedBy = [ "multi-user.target" ];
    before = [ "getty@tty1.service" "getty@console.service" ];
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
  systemd.services."getty@tty1".enable = true;
  systemd.services."getty@console".enable = true;

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

  # Root user with hashed password (qwerty123)
  # To generate a new hash: mkpasswd -m sha-512
  users.users.root.hashedPassword = "$6$G4Owc0wBptUsb0TD$nNhdRoOaPvFqIS03q3Rv9O/OfH9llDsZSDWg9jGgya4VYvUbzCY3yDpSCfYcDu/C5zzBJmh62gLC4O6YNatac0";

  # Essential packages for all containers
  environment.systemPackages = with pkgs; [
    # Standard tools
    vim
    nano
    curl
    wget
    htop

    # Debugging and system tools
    coreutils # ls, cat, rm, cp, chmod, etc.
    bash
    findutils # find
    diffutils # diff
    netcat-openbsd # nc
    dig # DNS debugging
    strace # System call tracing
    lsof # List open files
    ps_mem # Memory debugging
    man # Documentation
    less # Paging
  ];
}
