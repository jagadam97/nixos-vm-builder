{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../common/lxc-base.nix
  ];

  # Container hostname
  networking.hostName = "maintainer";

  # Minimal essential packages for container
  environment.systemPackages = with pkgs; [
    # Add maintainer-specific tools here if needed
  ];

  # Build metadata accessible inside container
  environment.etc."build-info.txt".text = ''
    Container: maintainer-lxc
    NixOS Version: ${config.system.nixos.version}

    To see metadata: cat /etc/build-info.txt
  '';
}
