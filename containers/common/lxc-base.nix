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

  # Symlink NixOS binaries into /usr/local/bin so they're available via pct enter / lxc-attach
  # (lxc-attach hardcodes PATH to /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin)
  system.activationScripts.lxcPath = {
    text = ''
      mkdir -p /usr/local/bin
      for bin in /run/current-system/sw/bin/*; do
        ln -sfn "$bin" /usr/local/bin/
      done
    '';
  };

  # Network configuration
  networking = {
    useDHCP = false;
    useHostResolvConf = lib.mkForce false;
    firewall.enable = true;
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
