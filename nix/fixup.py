#!/usr/bin/env python3
from pathlib import Path
import subprocess
import shutil
import os


ELF_MAGIC = b"\x7fELF"


def is_elf(path: Path) -> bool:
    if path.is_symlink():
        return False

    with open(path, "rb") as f:
        magic_bytes = f.read(len(ELF_MAGIC))
        return magic_bytes == ELF_MAGIC


def wrap_elf(interpreter: str, path: Path):
    parent = path.parent
    name = "." + path.name + "-wrapped"
    target = Path(parent).joinpath(name)
    _ = shutil.move(path, target)

    cc = os.environ.get("CC", "cc")
    _ = subprocess.run(
        [
            cc,
            "-Wall",
            "-Werror",
            "-Wpedantic",
            "-Wno-overlength-strings",
            "-Os",
            "-x",
            "c",
            "-o",
            str(path),
            "-",
        ],
        check=True,
        input=(
            """
      #include <unistd.h>

      int main(int argc, char *argv[]) {
          char *wrapped_argv[argc + 4];

          wrapped_argv[0] = "%s";
          wrapped_argv[1] = "--argv0";
          wrapped_argv[2] = argv[0];
          wrapped_argv[3] = "%s";

          for (int i = 1; i < argc; i++)
              wrapped_argv[3 + i] = argv[i];
          wrapped_argv[3 + argc] = NULL;

          execv("%s", wrapped_argv);

          return 127;
      }
    """
            % (path, target, interpreter)
            + "\n"
        ).encode(),
    )


def get_interpreter() -> str:
    with open(
        Path(os.environ["NIX_CC"]).joinpath("nix-support").joinpath("dynamic-linker")
    ) as fp:
        return fp.read().strip()


def main():
    interpreter = get_interpreter()

    bins = Path(os.environ["out"]).joinpath("bin")
    for bin in bins.iterdir():
        if is_elf(bin):
            wrap_elf(interpreter, bin)


if __name__ == "__main__":
    main()
