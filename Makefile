.PHONY: help list clean

# Auto-detect container directories (excluding 'common')
CONTAINER_DIRS := $(wildcard containers/*)
CONTAINERS := $(notdir $(CONTAINER_DIRS))
CONTAINERS := $(filter-out common,$(CONTAINERS))

# Generate build targets for each container
LXC_TARGETS := $(addsuffix -lxc,$(CONTAINERS))
VM_TARGETS := $(addsuffix -vm-nogui,$(CONTAINERS))
IMAGE_TARGETS := $(addsuffix -image,$(CONTAINERS))

all: help

help:
	@echo "NixOS Container Builder for Proxmox"
	@echo ""
	@echo "Auto-detected containers: $(CONTAINERS)"
	@echo ""
	@echo "Available targets:"
	@echo "  LXC builds:"
	@$(foreach c,$(CONTAINERS),echo "    make $(c)-lxc";)
	@echo ""
	@echo "  VM builds (headless):"
	@$(foreach c,$(CONTAINERS),echo "    make $(c)-vm-nogui";)
	@echo ""
	@echo "  Other:"
	@echo "    make list    - List all available containers"
	@echo "    make clean   - Remove build artifacts"
	@echo ""

list:
	@echo "Available containers: $(CONTAINERS)"

# Pattern rule for LXC builds
%-lxc:
	@echo "Building $* LXC container..."
	nix build .#$*-lxc --print-build-logs
	@echo ""
	@echo "✓ Build complete:" && ls result/tarball/*.tar.xz

# Pattern rule for VM builds
%-vm-nogui:
	@echo "Building $* VM for testing..."
	nix build .#$*-vm-nogui --print-build-logs
	@echo ""
	@echo "Starting VM (no GUI, serial console)..."
	@echo "Login: root / qwerty123"
	@echo ""
	@echo "Press Ctrl+A then X to exit QEMU"
	@echo ""
	result/bin/run-$*-vm -nographic

clean:
	rm -rf result result-*
	@echo "Cleaned build artifacts"
