# Base template for all containers
# This file provides the common structure that all containers inherit

{ name, config, pkgs, lib, modulesPath, platform, ... }:

{
  imports = [
    ./common/common.nix
  ];

  # Container hostname - derived from folder name
  networking.hostName = name;

  # Build metadata accessible inside container
  environment.etc."build-info.txt".text = lib.mkDefault ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
  '';
}
