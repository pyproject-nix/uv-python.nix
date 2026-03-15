from pathlib import Path
import os


def fixup_pc(out: str, path: Path):
    lines: [str] = []

    with path.open() as fp:
        for line in fp:
            try:
                key, value = line.split("=", 1)
                if not value.startswith("/install"):
                    raise ValueError()
                lines.append(f"{key}={out + value.removeprefix('/install')}")
            except ValueError:
                lines.append(line)

    with path.open("w") as fp:
        for line in lines:
            fp.write(line)


def main():
    out = os.environ["out"]

    for root, dirs, files in os.walk(out):
        root_path = Path(root)
        for file in files:
            if file.endswith(".pc"):
                fixup_pc(out, root_path.joinpath(file))


if __name__ == "__main__":
    main()
