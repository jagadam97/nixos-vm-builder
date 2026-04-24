{ pkgs, name, ... }:

{
  image.baseName = "${name}-v${pkgs.postgresql_17.version}";
}
