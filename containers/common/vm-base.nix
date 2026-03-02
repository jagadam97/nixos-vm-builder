{ pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];
  # Basic system configuration
  # Using 26.05 (nixos-unstable baseline)
  system.stateVersion = "26.05";

  # Network configuration
  networking = {
    useDHCP = true;
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
