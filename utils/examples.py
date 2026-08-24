#!/usr/bin/env python3

import os
import shutil
import sys
import subprocess
import tempfile
import logging
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PACKAGE_NAME = "prism"
EXAMPLES_DIR = Path("examples")

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger()

# Test cases: binary name -> list of arg lists to invoke it with.
# Binary name matches the .mojo file stem in the examples directory.
TEST_CASES: dict[str, list[list[str]]] = {
    "aliases": [
        ["my", "thing"],
    ],
    "hello_world": [
        ["say", "hello"],
    ],
    "parent": [
        ["--required", "--host=www.example.com", "--port", "8080"],
        ["--required", "--host", "www.example.com"],
        ["--required", "--host", "www.example.com", "--uri", "abcdef", "--port", "8080"],
        [],
    ],
    "child": [
        ["tool", "--required", "-a", "--host=www.example.com", "--port", "8080"],
        ["tool", "--required", "-a", "--host", "www.example.com"],
        ["tool", "--required", "--also", "--host", "www.example.com", "--uri", "abcdef", "--port", "8080"],
    ],
    "arg_validators": [
        ["Hello", "from", "Mojo!"],
        ["no_args", "Hello", "from", "Mojo!"],
        ["valid_values", "Pineapple"],
        ["minimum_n_args", "Hello", "from", "Mojo!"],
        ["maximum_n_args", "Hello", "from", "Mojo!"],
        ["exact_args", "Hello", "from", "Mojo!"],
        ["range_args", "Hello", "from", "Mojo!"],
    ],
    "alt_flag_values": [
        ["-n", "Mojo"],
        [],
    ],
    "flag_action": [
        [],
        ["-n", "Mojo"],
    ],
    "list_flags": [
        [],
        ["-n", "My", "-n", "Mojo"],
        ["sum", "-n", "1", "-n", "2", "-n", "3", "-n", "4", "-n", "5"],
        ["sum_float", "-n", "1.2", "-n", "2.3", "-n", "3.4", "-n", "4.5", "-n", "5.6"],
    ],
    "version": [
        ["-v"],
        ["--version"],
    ],
    "exit": [
        [],
    ],
    "multiple_bool_flag": [
        ["-r0vvas"],
        ["-r0vas"],
        ["-r0a", "--verbose", "Hello Mojo!"],
    ],
    "suggest": [
        ["--gelp"],
    ],
    "full_api": [
        [],
        ["connect", "-r0a", "--verbose", "--host", "192.168.1.1"],
        ["--gelp"],
        ["allow", "-r0"],
        ["allow", "-hl", "localhost", "-hl", "192.168.1.1", "-r0"],
        ["allow", "-hl", "localhost", "-hl", "192.168.1.2", "-r0"],
    ],
    "named_args": [
        ["deploy", "--help"],
        ["deploy", "staging", "3"],
        ["deploy", "production", "5", "0.25", "--dry-run"],
        ["logs", "api"],
        ["hello", "world"],
    ],
    "custom_types": [
        ["localhost:8080"],
        ["0.0.0.0:443", "--timeout", "5m"],
        ["api.example.com:9000", "-t", "2h"],
        ["--help"],
    ],
    "configure_help_version": [
        ["--custom-help"],
        ["--custom-version"],
    ]
}


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    print(f"\n\x1b[1m{' '.join(cmd)}\x1b[0m")
    return subprocess.run(cmd, **kwargs)


def main() -> int:
    temp_dir = Path(tempfile.mkdtemp(prefix="prism_examples_"))
    logger.info(f"Using temp directory: {temp_dir}")

    try:
        # 1. Build the mojo package.
        logger.info(f"Building {PACKAGE_NAME} package.")
        result = run(
            ["mojo", "package", PACKAGE_NAME, "-o", str(temp_dir / f"{PACKAGE_NAME}.mojopkg")]
        )
        if result.returncode != 0:
            logger.error("Failed to build package.")
            return 1

        # 2. Build all example .mojo files into the temp directory.
        mojo_files = sorted(EXAMPLES_DIR.glob("*.mojo"))
        if not mojo_files:
            logger.info("[ERROR] No .mojo files found in examples directory.")
            return 1

        # Builds dominate the runtime of this script -- the examples themselves finish in
        # milliseconds -- so they run concurrently. Threads are enough because the work happens in
        # subprocesses. Output is captured per build and printed after the pool joins, since
        # letting a dozen compilers write to the terminal at once interleaves their diagnostics
        # into something unreadable. Diagnostics go to stderr so they stay next to the warning
        # that introduces them: the logger writes to stderr unbuffered, and printing to block
        # buffered stdout lands them somewhere else entirely once output is redirected.
        workers = min(len(mojo_files), os.cpu_count() or 4)
        logger.info(f"Building {len(mojo_files)} example binaries across {workers} workers.")

        def build(mojo_file: Path) -> tuple[Path, subprocess.CompletedProcess]:
            command = [
                "mojo", "build", "-D", "ASSERT=all", "-I", ".",
                str(mojo_file), "-o", str(temp_dir / mojo_file.stem),
            ]
            return mojo_file, subprocess.run(command, capture_output=True, text=True)

        built: set[str] = set()
        with ThreadPoolExecutor(max_workers=workers) as pool:
            results = list(pool.map(build, mojo_files))

        for mojo_file, result in results:
            if result.returncode != 0:
                logger.warning(f"Failed to build {mojo_file}")
                if result.stderr:
                    print(result.stderr, end="", file=sys.stderr)
            else:
                built.add(mojo_file.stem)

        # 3. Run each binary with its test-case args.
        logger.info("Running examples...")
        for binary_name, cases in TEST_CASES.items():
            binary_path = temp_dir / binary_name
            if binary_name not in built:
                logger.warning(f"Binary not found: {binary_name}, skipping.")
                continue

            for args in cases:
                result = run([str(binary_path), *args])
                if result.returncode != 0:
                    logger.info(f"  Exit Code: {result.returncode}")

    finally:
        # 4. Clean up.
        logger.info("Cleaning up temp directory.")
        shutil.rmtree(temp_dir)

    return 0


if __name__ == "__main__":
    main()
