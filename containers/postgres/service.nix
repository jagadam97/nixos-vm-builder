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
    package = pkgs.postgresql_18;

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

  # Disable systemd's StateDirectory management — it tries to chown the
  # bind-mounted data dir which is blocked in unprivileged LXC containers.
  # We manage the directory ourselves via tmpfiles instead.
  # ProtectSystem=strict normally gets its ReadWritePaths from StateDirectory,
  # so we must add the path back explicitly — otherwise initdb sees ROFS.
  systemd.services.postgresql.serviceConfig = {
    StateDirectory = lib.mkForce "";
    ReadWritePaths = [ "/var/lib/postgresql" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/postgresql 0700 postgres postgres -"
  ];

  # Keep the TimescaleDB extension catalog in sync with the deployed binary.
  # When an image rebuild bumps the TimescaleDB version, the catalog on the
  # persisted data disk lags behind and Postgres can't load the old versioned
  # .so (`could not access file "timescaledb-<old>"`). Run the update on every
  # boot once Postgres is accepting connections. `ALTER EXTENSION ... UPDATE`
  # must be the first statement in the session — the loader permits it even
  # when the prior .so is absent — and it's a harmless no-op when already
  # current.
  systemd.services.timescaledb-update = {
    description = "Sync TimescaleDB extension catalog with the deployed binary";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script = ''
      psql=${config.services.postgresql.package}/bin/psql
      # Enumerate connectable DBs from `postgres`, which has no extension, so
      # the listing query never trips the loader on a stale catalog.
      dbs=$("$psql" -d postgres -tAc \
        "SELECT datname FROM pg_database WHERE datallowconn AND datname NOT IN ('template0','template1')")
      for db in $dbs; do
        # First statement in a fresh session; tolerate DBs without the extension.
        "$psql" -d "$db" -c 'ALTER EXTENSION timescaledb UPDATE;' || true
      done
    '';
  };

  environment.systemPackages = with pkgs; [
    postgresql_18
  ];

  # Build metadata
  environment.etc."build-info.txt".text = lib.mkForce ''
    Type: ${name}-${platform}
    NixOS Version: ${config.system.nixos.version}
    PostgreSQL Version: ${pkgs.postgresql_18.version}
    Version: ${pkgs.postgresql_18.version}
    TimescaleDB: enabled
  '';
}
