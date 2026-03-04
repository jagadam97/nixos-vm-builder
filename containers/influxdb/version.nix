{ pkgs, ... }:
{
  image.baseName = "influxdb-v${pkgs.influxdb2-server.version}";
}
