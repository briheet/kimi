{
  description = "A very basic flake with devShell + process-compose";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];

      imports = [
        inputs.process-compose-flake.flakeModule
      ];

      perSystem =
        {
          pkgs,
          ...
        }:
        let
          lib = pkgs.lib;

          commonClusterSettings = {
            accounts = {
              "$SYS".users = [
                {
                  user = "admin";
                  pass = "admin";
                }
              ];

              js = {
                jetstream = "enabled";
                users = [
                  {
                    user = "js";
                    pass = "js";
                  }
                ];
              };
            };

            jetstream.max_file = "128M";

            cluster = {
              name = "default-cluster";
              routes = [
                "nats://localhost:14248"
                "nats://localhost:24248"
                "nats://localhost:34248"
              ];
            };
          };
        in
        {
          # Dev shell
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.istioctl
              pkgs.kind
              pkgs.docker
              pkgs.kubectl
            ];
          };

          # process-compose
          process-compose."myservices" = {
            imports = [
              inputs.services-flake.processComposeModules.default
            ];

            # Redis
            services.redis."r1".enable = true;

            # NATS cluster
            services.nats-server."nats-1" = {
              enable = true;
              settings = lib.recursiveUpdate commonClusterSettings {
                port = 14222;
                monitor_port = 18222;
                cluster.port = 14248;
              };
            };

            services.nats-server."nats-2" = {
              enable = true;
              settings = lib.recursiveUpdate commonClusterSettings {
                port = 24222;
                monitor_port = 28222;
                cluster.port = 24248;
              };
            };

            services.nats-server."nats-3" = {
              enable = true;
              settings = lib.recursiveUpdate commonClusterSettings {
                port = 34222;
                monitor_port = 38222;
                cluster.port = 34248;
              };
            };

            # Postgres
            services.postgres."pg1".enable = true;
          };
        };
    };
}
