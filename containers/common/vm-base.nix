{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  # Network configuration
  networking = {
    useDHCP = true;
    firewall.enable = true;
  };
}
