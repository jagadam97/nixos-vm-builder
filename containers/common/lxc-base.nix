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

  # Set PATH in systemd's default environment so lxc-attach / pct enter picks it up
  systemd.settings.Manager.DefaultEnvironment = "PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/run/wrappers/bin:/usr/bin:/bin";

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
