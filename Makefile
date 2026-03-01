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
	@echo "Creating final tarball..."
	@ORIGINAL_TARBALL=$$(ls result/tarball/*.tar.xz); \
	NEW_NAME="nixos-image-lxc-influxdb-lxc.tar.xz"; \
	cp "$$ORIGINAL_TARBALL" "$$NEW_NAME"; \
	echo "✓ Created: $$NEW_NAME"; \
	ls -lh "$$NEW_NAME"

list:
	@echo "Available containers:"
	@echo "  - influxdb-lxc"

clean:
	rm -rf result result-* nixos-image-lxc-*.tar.xz
	@echo "Cleaned build artifacts"
