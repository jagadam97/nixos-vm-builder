#!/usr/bin/env bash
set -euo pipefail

# Upload LXC template to Proxmox via API
# Required environment variables:
#   PROXMOX_HOST - Proxmox server hostname/IP
#   PROXMOX_USER - Proxmox user (e.g., root@pam)
#   PROXMOX_PASSWORD - Password or API token
#   PROXMOX_NODE - Node name (e.g., pve)
#   PROXMOX_STORAGE - Storage for templates (e.g., local)
#   TARBALL_PATH - Path to the tarball to upload

TARBALL_PATH="${1:-}"

if [ -z "$TARBALL_PATH" ]; then
    echo "Error: Tarball path not provided"
    echo "Usage: $0 <tarball-path>"
    exit 1
fi

if [ ! -f "$TARBALL_PATH" ]; then
    echo "Error: Tarball not found: $TARBALL_PATH"
    exit 1
fi

# Extract filename from path
FILENAME=$(basename "$TARBALL_PATH")

echo "===================================="
echo "Uploading to Proxmox"
echo "===================================="
echo "Host: $PROXMOX_HOST"
echo "Node: $PROXMOX_NODE"
echo "Storage: $PROXMOX_STORAGE"
echo "File: $FILENAME"
echo "===================================="

# Get authentication ticket
echo "Authenticating..."
AUTH_RESPONSE=$(curl -k -s -S -X POST \
  "https://${PROXMOX_HOST}:8006/api2/json/access/ticket" \
  -d "username=${PROXMOX_USER}" \
  -d "password=${PROXMOX_PASSWORD}")

TICKET=$(echo "$AUTH_RESPONSE" | jq -r '.data.ticket')
CSRF_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.CSRFPreventionToken')

if [ -z "$TICKET" ] || [ "$TICKET" = "null" ]; then
    echo "Error: Failed to authenticate with Proxmox"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo "Authentication successful!"

# Upload the template
echo "Uploading template..."
UPLOAD_RESPONSE=$(curl -k -s -S -X POST \
  "https://${PROXMOX_HOST}:8006/api2/json/nodes/${PROXMOX_NODE}/storage/${PROXMOX_STORAGE}/upload" \
  -H "CSRFPreventionToken: ${CSRF_TOKEN}" \
  -H "Cookie: PVEAuthCookie=${TICKET}" \
  -F "content=vztmpl" \
  -F "filename=@${TARBALL_PATH}")

echo "Upload response: $UPLOAD_RESPONSE"

# Check if upload was successful
if echo "$UPLOAD_RESPONSE" | jq -e '.data' > /dev/null 2>&1; then
    echo "✅ Template uploaded successfully!"
    echo "Template available at: ${PROXMOX_STORAGE}:vztmpl/${FILENAME}"
else
    echo "❌ Upload failed!"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi
