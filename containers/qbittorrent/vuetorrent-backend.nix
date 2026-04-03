{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vuetorrent-backend;


  # --- Part 1: The Package (The "Dockerfile" equivalent) ---
  vuetorrent-pkg = pkgs.buildNpmPackage rec {
    pname = "vuetorrent-backend";
    version = "2.7.2";

    src = pkgs.fetchFromGitHub {
      owner = "VueTorrent";
      repo = "vuetorrent-backend";
      rev = "v${version}";
      # Replace this with the actual hash (nix-prefetch-github)
      hash = "sha256-0psf749fbgwrl7hsh50yv46dmxcb314q2r9ygcc5v285sah5fp18";
    };

    # Replace this with the actual dependency hash
    npmDepsHash = "sha256-o1+sQDZkIWPiY4luEdDR/InFfKdNjYIoaMOBE2QyEqE=";

    dontNpmBuild = true;

    nodejs = pkgs.nodejs_22;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/vuetorrent-backend
      cp -r . $out/lib/node_modules/vuetorrent-backend
      
      # Replicates CMD ["node", "src/index.js"]
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/vuetorrent-backend \
        --add-flags "$out/lib/node_modules/vuetorrent-backend/src/index.js" \
        --set NODE_PATH "$out/lib/node_modules/vuetorrent-backend/node_modules"

      runHook postInstall
    '';
  };

in {
  # --- Part 2: The NixOS Module ---
  options.services.vuetorrent-backend = {
    enable = mkEnableOption "VueTorrent Backend";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "The port the backend will listen on.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the port in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    # Replicates 'RUN mkdir -p -m 0777 /vuetorrent'
    # Note: Using /var/lib/vuetorrent is the NixOS standard for state
    systemd.tmpfiles.rules = [
      "d /var/lib/vuetorrent 0700 vuetorrent vuetorrent -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.vuetorrent-backend = {
      description = "VueTorrent Backend Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = toString cfg.port;
        NODE_ENV = "production";
      };

      serviceConfig = {
        ExecStart = "${vuetorrent-pkg}/bin/vuetorrent-backend";
        Restart = "always";

        User = "vuetorrent";
        Group = "vuetorrent";
        StateDirectory = "vuetorrent";
        WorkingDirectory = "/var/lib/vuetorrent";
        
        # Hardening (Optional but recommended)
        ProtectSystem = "full";
        NoNewPrivileges = true;
      };
    };
    users.users.vuetorrent = {
      isSystemUser = true;
      group = "vuetorrent";
      home = "/var/lib/vuetorrent";
    };
    users.groups.vuetorrent = {};
  };
}
