# Introduction

Uv is commonly used to install not just Python packages, but also Python interpreters.
This will not "just work" with Nix as in other environments because of things like ELF interpreter paths, RPATHs & more.

`uv-python.nix` provides expressions to use these pre-packaged Python interpreters in a Nix environment.
