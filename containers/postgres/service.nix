{ config, pkgs, lib, name, platform, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "timescaledb"
  ];
  # Data lives on the attached disk — mount it at /var/lib/postgresql in Proxmox:
  #   LXC:  mp0: <disk>,mp=/var/lib/postgresql
  #   VM:   format /dev/sdb as ext4, mount at /var/lib/postgresql
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    # TimescaleDB
    extraPlugins = ps: with ps; [ timescaledb ];
    settings.shared_preload_libraries = "timescaledb";

    # Listen on all interfaces so the backend can connect
    settings.listen_addresses = lib.mkForce "*";

    # Allow connections from local network (192.168.4.0/24)
    authentication = lib.mkForce ''
      local all all              trust
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all 192.168.4.0/24 scram-sha-256
    '';

    # Tuning — conservative defaults for a dedicated DB VM
    settings = {
      max_connections         = 100;
      shared_buffers          = "256MB";
      effective_cache_size    = "768MB";
      maintenance_work_mem    = "64MB";
      checkpoint_completion_target = "0.9";
      wal_buffers             = "16MB";
      default_statistics_target = 100;
      random_page_cost        = 1.1;  # SSD
      effective_io_concurrency = 200; # SSD
      work_mem                = "4MB";
      min_wal_size            = "1GB";
      max_wal_size            = "4GB";
    };

    # Create the riglab database and user on first boot
    initialScript = pkgs.writeText "postgres-init" ''
      CREATE USER riglab WITH PASSWORD 'changeme' CREATEDB;
      CREATE DATABASE riglab OWNER riglab;
      \c riglab
      CREATE EXTENSION IF NOT EXISTS timescaledb;
    '';
  };

  # Open Postgres port
  networking.firewall.allowedTCPPorts = [ 5432 ];

  # Ensure data directory exists before postgres starts
  systemd.tmpfiles.rules = [
    "d /var/lib/postgresql 0700 postgres postgres -"
  ];

  environment.systemPackages = with pkgs; [
    postgresql_17
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    PostgreSQL Version: ${pkgs.postgresql_17.version}
    TimescaleDB: enabled
  '';
}
