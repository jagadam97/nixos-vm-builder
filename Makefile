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
	@echo "✓ Container built successfully!"
	@echo "Result: $$(readlink -f result)"
	@echo "Tarball: $$(readlink -f result)/tarball/*.tar.xz"

list:
	@echo "Available containers:"
	@echo "  - influxdb-lxc"

clean:
	rm -rf result result-*
	@echo "Cleaned build artifacts"
