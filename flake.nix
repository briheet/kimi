{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ...}:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        buildInputs = [
          pkgs.istioctl
          pkgs.kind
          pkgs.docker
          pkgs.kubectl
        ];
      };
    });
}
