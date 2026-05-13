{ pkgs, name, ... }:

{
  image.baseName = "${name}-v${pkgs.postgresql_18.version}";
}
