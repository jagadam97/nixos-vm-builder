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
      hash = "sha256-KFxXoNIFiV0Yez5lgUkYi/XaDNkeFKjhoZm/5RI5Tl8=";
    };

    # npm dependencies hash
    npmDepsHash = "sha256-wYcI1D2a8wsjA7ZIbeNOq3mLnA6y8p6wWetPuhwHwaQ=";

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

    qbittorrentUrl = mkOption {
      type = types.str;
      default = "http://localhost:8080";
      description = "The base URL of the qBittorrent Web UI.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the port in the firewall.";
    };
  };

  config = mkIf cfg.enable {
    # Replicates 'RUN mkdir -p -m 0777 /vuetorrent'
    # The backend downloads VueTorrent updates to this directory
    systemd.tmpfiles.rules = [
      "d /var/lib/vuetorrent 0700 vuetorrent vuetorrent -"
      "d /vuetorrent 0755 vuetorrent vuetorrent -"
    ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.vuetorrent-backend = {
      description = "VueTorrent Backend Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = toString cfg.port;
        NODE_ENV = "production";
        QBIT_BASE = cfg.qbittorrentUrl;
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
