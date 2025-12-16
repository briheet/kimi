{
  description = "Service and devShell for storage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.process-compose-flake.flakeModule
      ];

      perSystem =
        {
          # self',
          pkgs,
          # config,
          # lib,
          ...
        }:
        {

          process-compose."myservices" =
            { config, ... }:
            let
              dbName = "Kimi_db";
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

              imports = [
                inputs.services-flake.processComposeModules.default
              ];

              # Postgres
              services.postgres."pg1" = {
                enable = true;
              };
              # Postgres ends

              # Pgweb and test
              settings.processes.pgweb =
                let
                  pgcfg = config.services.postgres.pg1;
                in
                {
                  environment.PGWEB_DATABASE_URL = pgcfg.connectionURI { inherit dbName; };
                  command = pkgs.pgweb;
                  depends_on."pg1".condition = "process_healthy";
                };

              settings.processes.test = {
                command = pkgs.writeShellApplication {
                  name = "pg1-test";
                  runtimeInputs = [ config.services.postgres.pg1.package ];
                  text = ''
                    echo 'SELECT version();' | psql -h 127.0.0.1 ${dbName}
                  '';
                };
                depends_on."pg1".condition = "process_healthy";
              };
              # Pgweb ends

              # Redis
              services.redis."r1" = {
                enable = true;
              };
              # Redis ends

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
              # Nats end

            };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.go_1_25
              pkgs.gopls
              pkgs.goperf
              pkgs.golangci-lint
              pkgs.golangci-lint-langserver
              pkgs.delve

              pkgs.rust-analyzer
              pkgs.rustfmt
              pkgs.cargo
            ];

            shellHook = ''
              export TERM=xterm-256color
              export COLORTERM=truecolor
            '';

          };

        };
    };
}
