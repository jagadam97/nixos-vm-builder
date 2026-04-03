{ pkgs, name, ... }:
{
  image.baseName = "${name}-v${pkgs.bazarr.version}-${pkgs.radarr.version}-${pkgs.sonarr.version}";
}
