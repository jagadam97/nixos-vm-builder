.PHONY: help influxdb-lxc clean list

help:
	@echo "NixOS LXC Container Builder for Proxmox"
	@echo ""
	@echo "Available targets:"
	@echo "  make influxdb-lxc   - Build InfluxDB LXC container"
	@echo "  make list           - List all available containers"
	@echo "  make clean          - Remove build artifacts"
	@echo ""

influxdb-lxc:
	@echo "Building InfluxDB LXC container..."
	nix build .#influxdb-lxc --print-build-logs
	@echo ""
	@echo "Creating final tarball with version..."
	@ORIGINAL_TARBALL=$$(ls result/tarball/*.tar.xz); \
	INFLUXDB_VERSION=$$(nix eval nixpkgs#influxdb3.version --raw); \
	NEW_NAME="nixos-influxdb-v$${INFLUXDB_VERSION}.tar.xz"; \
	cp "$$ORIGINAL_TARBALL" "$$NEW_NAME"; \
	echo "✓ Created: $$NEW_NAME"; \
	ls -lh "$$NEW_NAME"

list:
	@echo "Available containers:"
	@echo "  - influxdb-lxc"
	@echo "  - maintainer-lxc"

clean:
	rm -rf result result-* nixos-influxdb-*.tar.xz
	@echo "Cleaned build artifacts"
