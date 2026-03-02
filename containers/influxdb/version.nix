{ pkgs, ... }:
{
  image.baseName = "influxdb-v${pkgs.influxdb3.version}";
}
