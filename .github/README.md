# GitHub Actions Secrets Configuration

To enable automatic deployment to Proxmox, configure the following secrets in your GitHub repository:

## Required Secrets

Go to: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### 1. PROXMOX_HOST
The hostname or IP address of your Proxmox server.
```
Example: 192.168.1.100 or proxmox.example.com
```

### 2. PROXMOX_USER
The SSH user to connect to Proxmox (typically `root`).
```
Example: root
```

### 3. PROXMOX_SSH_KEY
Your SSH private key for connecting to Proxmox.

```bash
# Generate a new SSH key (if needed)
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions_proxmox

# Copy the public key to Proxmox
ssh-copy-id -i ~/.ssh/github_actions_proxmox.pub root@<PROXMOX_HOST>

# Copy the PRIVATE key content and paste into the GitHub secret
cat ~/.ssh/github_actions_proxmox
```

**Important:** Paste the entire private key including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

## Workflow Behavior

- **On Pull Request**: Builds containers but does NOT deploy to Proxmox
- **On Push to main/master**: Builds AND deploys to Proxmox
- **Manual Trigger**: Available via "Actions" → "Build and Deploy LXC Containers" → "Run workflow"

## Output Naming

Containers are deployed with the format:
```
nixos-image-lxc-{container-name}-{app-version}.tar.xz
```

Example:
```
nixos-image-lxc-influxdb-lxc-2.7.4.tar.xz
```

## Adding New Containers

To add a new container to the build matrix, edit `.github/workflows/build-deploy.yml`:

```yaml
matrix:
  container:
    - name: influxdb-lxc
      app: influxdb2
    - name: your-new-container
      app: your-app-name
```
