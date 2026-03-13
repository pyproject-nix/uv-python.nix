{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          (import self) { } {
            inherit (pkgs) stdenv callPackage lib;
          }
      );

      checks = forAllSystems (system: {
        "cpython-3_14_0" = self.packages.${system}."cpython-3.14.0";
      });
    };
}
