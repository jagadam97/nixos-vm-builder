{ pkgs, name,... }:
{
  image.baseName = "${name}-v${pkgs.influxdb3.version}";
}
