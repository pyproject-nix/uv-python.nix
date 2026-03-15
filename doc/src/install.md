# Installation

## Classic Nix

Documentation examples in `uv-python.nix` are using Flakes for convenience.

You can just as easily import `uv-python.nix` without using Flakes:
``` nix
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  uv-pythons = pkgs.callPackage (import (builtins.fetchGit {
    url = "https://github.com/pyproject-nix/uv-python.nix.git";
  }) { }) { };

  python = uv-python.packages.${system}."cpython-3.10";
in
  ...
```

## Flakes
``` nix
let
  python = uv-python.packages.${system}."cpython-3.10";
in
  ...
```
