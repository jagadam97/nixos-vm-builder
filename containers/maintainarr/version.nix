{ pkgs, name, ... }:
{
  image.baseName = "${name}-v${pkgs.bazarr.version}_${pkgs.radarr.version}_${pkgs.sonarr.version}";
}
