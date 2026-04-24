{ lib, ... }:

{
  networking = {
    useDHCP = lib.mkForce false;
    interfaces.eth0.ipv4.addresses = [{
      address = "192.168.4.218";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.4.1";
    nameservers = [ "152.70.69.235" "8.8.8.8" "1.1.1.1" ];
  };
}
