{ pkgs, name,... }:
{
  image.baseName = "${name}-v${pkgs.influxdb2-server.version}";
}
