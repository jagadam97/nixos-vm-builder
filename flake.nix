{
  description = "NixOS LXC Container Builder for Proxmox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Get all container directories (excluding "common")
      containerDir = ./containers;
      containerNames = lib.filter
        (name: name != "common" && lib.pathIsDirectory (containerDir + "/${name}"))
        (lib.attrNames (builtins.readDir containerDir));

      # Generate NixOS configurations for a container
      mkContainerConfigs = name: {
        # LXC container configuration
        "${name}-lxc" = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { platform = "lxc"; name = name; };
          modules = [
            # Base template (from repo root)
            ./base.nix
            # Container-specific config (auto-discovered)
          ] ++ lib.optional
            (builtins.pathExists (containerDir + "/${name}/service.nix"))
            ./containers/${name}/service.nix
          ++ lib.optional
            (builtins.pathExists (containerDir + "/${name}/version.nix"))
            ./containers/${name}/version.nix
          ++ lib.optional
            (builtins.pathExists (containerDir + "/${name}/network.nix"))
            ./containers/${name}/network.nix;
        };

        # VM for testing (headless, with port forwarding)
        "${name}-vm-nogui" = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { platform = "vm"; name = name; };
          modules = [
            ./base.nix
          ] ++ lib.optional
            (builtins.pathExists (containerDir + "/${name}/service.nix"))
            ./containers/${name}/service.nix
          ++ lib.optional
            (builtins.pathExists (containerDir + "/${name}/vm-nogui.nix"))
            ./containers/${name}/vm-nogui.nix;
        };
      };

      # Generate packages for a container
      mkContainerPackages = name: {
        "${name}-lxc" = self.nixosConfigurations."${name}-lxc".config.system.build.tarball;
        "${name}-vm-nogui" = self.nixosConfigurations."${name}-vm-nogui".config.system.build.vm;
      };

      # Merge all configurations
      allConfigs = lib.foldl' (acc: name: acc // (mkContainerConfigs name)) { } containerNames;
      allPackages = lib.foldl' (acc: name: acc // (mkContainerPackages name)) { } containerNames;
    in
    {
      nixosConfigurations = allConfigs;
      packages.${system} = allPackages;
    };
}
