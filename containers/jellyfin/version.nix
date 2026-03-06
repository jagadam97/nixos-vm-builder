{ pkgs, name,... }:
{
  image.baseName = "${name}-v${pkgs.jellyfin.version}_${pkgs.jellyfin-ffmpeg.version}";
}
