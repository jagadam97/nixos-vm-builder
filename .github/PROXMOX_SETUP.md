# Proxmox Upload Setup

This guide shows how to configure GitHub Actions to automatically upload LXC templates to your Proxmox server.

## Prerequisites

- Proxmox VE server accessible from the internet (or via VPN)
- GitHub repository with Actions enabled

## Step 1: Create Proxmox API User (Recommended)

For better security, create a dedicated user for GitHub Actions instead of using root:

1. Log into Proxmox web UI
2. Navigate to **Datacenter → Permissions → Users**
3. Click **Add** and create a new user:
   - User name: `github-actions`
   - Realm: `Proxmox VE authentication server` (pve)
   - Password: Generate a strong password

4. Navigate to **Datacenter → Permissions → Add → User Permission**
   - Path: `/`
   - User: `github-actions@pve`
   - Role: `Administrator` (or create a custom role with just storage upload permissions)

## Step 2: (Optional) Create API Token

API tokens are more secure than passwords:

1. Navigate to **Datacenter → Permissions → API Tokens**
2. Click **Add**
   - User: `github-actions@pve`
   - Token ID: `github-upload`
   - Uncheck **Privilege Separation** (or assign appropriate permissions)
3. Copy the token ID and secret (format: `USER@REALM!TOKENID=SECRET`)

## Step 3: Configure GitHub Secrets

Go to your GitHub repository → **Settings → Secrets and variables → Actions**

Add the following secrets:

### Required Secrets

| Secret Name | Example Value | Description |
|-------------|---------------|-------------|
| `PROXMOX_HOST` | `192.168.1.100` or `pve.example.com` | Proxmox server IP or hostname |
| `PROXMOX_USER` | `root@pam` or `github-actions@pve` | Proxmox user with upload permissions |
| `PROXMOX_PASSWORD` | `your-password` or `TOKEN-SECRET` | Password or API token secret |
| `PROXMOX_NODE` | `pve` or `node1` | Name of the Proxmox node |
| `PROXMOX_STORAGE` | `local` | Storage pool for templates |

### Finding Your Node Name

```bash
# SSH into Proxmox and run:
pvesh get /nodes
```

### Finding Your Storage Names

```bash
# SSH into Proxmox and run:
pvesh get /storage
```

Look for storages with `content` that includes `vztmpl` (container templates).

## Step 4: Verify Upload Location

After a successful upload, templates will be available at:
- **Web UI**: `pve` → `local` → `CT Templates`
- **File System**: `/var/lib/vz/template/cache/nixos-image-lxc-*.tar.xz`
- **Terraform**: `storage:vztmpl/nixos-image-lxc-influxdb-lxc.tar.xz`

## Step 5: Network Access

Ensure GitHub Actions can reach your Proxmox server:

### Option A: Public IP with Firewall
```bash
# Allow HTTPS from GitHub Actions IP ranges
# See: https://api.github.com/meta
iptables -A INPUT -p tcp --dport 8006 -s <github-ip-range> -j ACCEPT
```

### Option B: Tailscale/Cloudflare Tunnel
Use a secure tunnel service to expose Proxmox without opening ports.

### Option C: Self-Hosted Runner
Run GitHub Actions on your local network with a self-hosted runner.

## How It Works

1. **Build**: GitHub Actions builds the LXC tarball using Nix
2. **Upload**: On push to `main` branch, automatically uploads to Proxmox
3. **Deploy**: Use Terraform to create containers from the uploaded template

## Security Best Practices

✅ **DO**:
- Use API tokens instead of passwords
- Create a dedicated user with minimal permissions
- Use HTTPS (default Proxmox setup)
- Restrict IP access to GitHub Actions ranges
- Rotate credentials regularly

❌ **DON'T**:
- Commit credentials to the repository
- Use root@pam if possible (create dedicated user)
- Expose Proxmox to the entire internet without firewall rules

## Troubleshooting

### Authentication Failed
- Verify username format: `root@pam` or `user@pve`
- Check password/token is correct
- Ensure user has proper permissions

### Connection Refused
- Check `PROXMOX_HOST` is reachable from internet
- Verify port 8006 is accessible
- Check firewall rules

### Upload Failed
- Verify storage name supports `vztmpl` content type
- Check storage has enough free space
- Ensure user has write permissions to storage

### SSL Certificate Error
The script uses `-k` flag to skip SSL verification. For production:
1. Add a valid SSL certificate to Proxmox
2. Remove the `-k` flag from `upload-to-proxmox.sh`

## Example Terraform Usage

After templates are uploaded, use them in Terraform:

```hcl
resource "proxmox_lxc" "influxdb" {
  target_node  = "pve"
  hostname     = "influxdb"
  ostemplate   = "local:vztmpl/nixos-image-lxc-influxdb-lxc.tar.xz"
  password     = "qwerty123"
  unprivileged = true
  
  cores  = 2
  memory = 2048
  swap   = 512
  
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }
  
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
  
  # Persistent storage bind mounts
  mountpoint {
    key     = "0"
    slot    = 0
    storage = "/mnt/influxdb-data"
    mp      = "/var/lib/influxdb3"
    size    = "20G"
  }
  
  mountpoint {
    key     = "1"
    slot    = 1
    storage = "/mnt/influxdb-config"
    mp      = "/etc/influxdb3"
    size    = "1G"
  }
}
```

## Manual Upload (Alternative)

If you prefer manual uploads:

```bash
# Build locally
make influxdb-lxc

# Upload via SCP
scp nixos-image-lxc-influxdb-lxc.tar.xz root@pve:/var/lib/vz/template/cache/
```
