let
  pkgs = import <nixpkgs> { };
in
pkgs.mkShell {
  packages = [
    pkgs.mdbook
    pkgs.mdbook-cmdrun
  ];
}
