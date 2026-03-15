# Introduction

Uv is commonly used to install not just Python packages, but also Python interpreters.
This will not "just work" with Nix as in other environments because of things like ELF interpreter paths, RPATHs & more.

These packages allows you to use Python interpreter versions unsupported by nixpkgs for impure development or with tooling like uv2nix.

`uv-python.nix` provides expressions to use these pre-packaged Python interpreters in a Nix environment.
