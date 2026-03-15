{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs (lib.remove "x86_64-freebsd" lib.systems.flakeExposed);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          uv-pythons = (import self) { } {
            inherit (pkgs) stdenv callPackage lib;
          };

        in
           uv-pythons // {
             doc = pkgs.callPackage ./doc {
               inherit self uv-pythons;
             };
          }
      );

      checks = forAllSystems (system: {
        "cpython-3_14_0" = self.packages.${system}."cpython-3.14.0";
        "graalpy-3.10.0" = self.packages.${system}."graalpy-3.10.0";
        "pypy-3.10.12" = self.packages.${system}."pypy-3.10.12";
      });
    };
}
