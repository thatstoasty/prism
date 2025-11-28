import os
import subprocess
import sys
from pathlib import Path


fn run_files(directory: Path, path: Optional[Path] = None) raises -> None:
    """Runs files in a directory using Mojo."""
    if not directory.exists():
        print("Path does not exist: ", directory)
        return

    var files: List[Path]
    if path:
        files = [path.value()]
    else:
        files = [path for path in directory.listdir() if path.suffix() == ".mojo"]
    for file in files:
        print("\nRunning file:", file)
        print(subprocess.run(String("mojo -D ASSERT=all -I . ", directory / file)))


fn main() raises:
    var args = sys.argv()
    if len(args) < 2:
        print("Usage: mojo scripts/util.mojo [examples|tests|benchmarks] [optional: path_to_file]")
        return

    var mode = args[1]
    var path: Optional[Path] = Optional(Path(args[2])) if len(args) > 2 else None

    if mode == "examples":
        run_files("examples", path)
    elif mode == "tests":
        run_files("test", path)
    elif mode == "benchmarks":
        run_files("benchmarks", path)
    else:
        raise Error("UnknownModeError: ", mode)
