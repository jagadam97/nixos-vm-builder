{ pkgs, name,... }:
{
  image.baseName = "${name}-v${pkgs.qbittorrent.version}";
}
