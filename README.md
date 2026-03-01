# NixOS LXC Container Builder for Proxmox

Build declarative, minimal NixOS LXC containers with persistent storage for Proxmox.

## Quick Start

### Build InfluxDB Container

```bash
make influxdb-lxc
```

## CI/CD with GitHub Actions

This repository includes automated builds with GitHub Actions:

- **Automatic builds** on every push/PR
- **Matrix-based builds** for multiple containers
- **Artifact uploads** (90-day retention)
- **GitHub Releases** when you push a tag

Images are uploaded as artifacts/releases for Terraform to download and deploy.

See [.github/README.md](.github/README.md) for details on downloading and using with Terraform.

**Output naming:** `nixos-image-lxc-{container-name}-{app-version}.tar.xz`

## Proxmox Setup

### 1. Build the Container

```bash
make influxdb-lxc
```

This creates a minimal NixOS LXC container tarball.

### 2. Create Persistent Storage on Proxmox Host

On your Proxmox host, create directories for persistent data:

```bash
# Create persistent storage directories
mkdir -p /var/lib/lxc-storage/influxdb/data
mkdir -p /var/lib/lxc-storage/influxdb/config

# Set permissions (InfluxDB UID may vary, adjust after first run)
chown -R 100000:100000 /var/lib/lxc-storage/influxdb/
```

### 3. Create Container in Proxmox

```bash
# Copy the tarball to Proxmox
scp result/tarball/nixos-system-*.tar.xz proxmox:/var/lib/vz/template/cache/

# On Proxmox, create the container
pct create <CTID> \
  /var/lib/vz/template/cache/nixos-system-*.tar.xz \
  --hostname influxdb \
  --memory 2048 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --rootfs local-lvm:8 \
  --unprivileged 1 \
  --features nesting=1

# Add bind mounts for persistent storage
pct set <CTID> -mp0 /var/lib/lxc-storage/influxdb/data,mp=/var/lib/influxdb2
pct set <CTID> -mp1 /var/lib/lxc-storage/influxdb/config,mp=/etc/influxdb2

# Start the container
pct start <CTID>
```

### 4. Initial Setup

Access the container and configure InfluxDB:

```bash
# Enter the container (password: qwerty123)
pct enter <CTID>

# Setup InfluxDB
influx setup
```

Access InfluxDB at `http://<container-ip>:8086`

## In-Place Upgrades

The power of NixOS LXC containers for upgrades:

1. **Update your config** - Edit `containers/influxdb/configuration.nix`
2. **Rebuild the container** - Run `make influxdb-lxc`
3. **Replace the container** - Create new container with updated tarball
4. **Reuse persistent storage** - Point bind mounts to same directories!

```bash
# Stop old container
pct stop <OLD_CTID>

# Create new container with new tarball
pct create <NEW_CTID> /var/lib/vz/template/cache/nixos-system-NEW.tar.xz \
  --hostname influxdb \
  --memory 2048 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --rootfs local-lvm:8 \
  --unprivileged 1 \
  --features nesting=1

# Reuse same persistent storage!
pct set <NEW_CTID> -mp0 /var/lib/lxc-storage/influxdb/data,mp=/var/lib/influxdb2
pct set <NEW_CTID> -mp1 /var/lib/lxc-storage/influxdb/config,mp=/etc/influxdb2

# Start new container
pct start <NEW_CTID>

# Verify, then delete old container
pct destroy <OLD_CTID>
```

Your InfluxDB data and config persist across upgrades! 🎉

## Architecture

- **Container Root**: Ephemeral, contains OS and InfluxDB 3 binaries
- **Bind Mount** `/var/lib/influxdb3`: Persistent data from host
- **Bind Mount** `/etc/influxdb3`: Persistent config from host
- **Root Access**: User `root`, password `qwerty123` (use `pct enter`)

## Customization

Edit `containers/influxdb/configuration.nix` to:
- Add additional packages
- Configure firewall rules
- Adjust InfluxDB settings
- Change root password

## Benefits of LXC vs VM

- **Lightweight**: No hypervisor overhead, near-native performance
- **Fast startup**: Containers boot in seconds
- **Easy backups**: Just backup the host directories
- **Flexible**: Bind mount any host directory into container

## Requirements

- Nix with flakes enabled
- Proxmox VE host
- Jujutsu (`jj`) for version control

## Available Commands

```bash
make help           # Show all available commands
make influxdb-lxc   # Build InfluxDB LXC container
make list           # List all available containers
make clean          # Remove build artifacts
```

## Troubleshooting

**Container won't start:**
- Check `pct status <CTID>`
- View logs: `journalctl -u pve-container@<CTID>`

**InfluxDB not accessible:**
- Verify container IP: `pct exec <CTID> ip addr`
- Check firewall: Container allows port 8086

**Permission issues:**
- LXC uses UID mapping (unprivileged containers)
- Host UID 100000 = Container UID 0 (root)
- Adjust ownership on host: `chown -R 100000:100000 /var/lib/lxc-storage/influxdb/`
