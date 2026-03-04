{ platform, ... }:

let
  isLxc = platform == "lxc";
  isVm = platform == "vm";
in
{
   imports = [
    (if isLxc then ./lxc-base.nix else ./vm-base.nix)
  ];
}

