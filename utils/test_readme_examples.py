#!/usr/bin/env python3
"""Compile-test the Mojo code blocks embedded in README.md.

The script scans a Markdown file for fenced ```mojo code blocks, writes each one
to a temporary `.mojo` file, and attempts to compile it with `mojo build`. A
successful build means the example is syntactically valid and type-checks against
the current `prism` package (it does *not* run the example, so no network calls
are made).

Usage:
    pixi run python utils/test_readme_examples.py
    python utils/test_readme_examples.py --readme README.md --mojo "pixi run mojo"

Exit code is the number of examples that failed to compile (0 = all passed), so
it can be wired into CI directly.
"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass
class CodeBlock:
    """A single fenced code block extracted from a Markdown file."""

    index: int  # 1-based ordinal among the mojo blocks
    start_line: int  # 1-based line number of the opening fence in the source
    code: str  # the block's contents, without the fences


def find_repo_root(start: Path) -> Path:
    """Return the repository root by walking up until a README.md is found.

    Falls back to the script's parent-of-parent (utils/ lives at the repo root)
    when no README.md is found on the way up.
    """
    for candidate in (start, *start.parents):
        if (candidate / "README.md").is_file():
            return candidate
    return start.parent


def extract_mojo_blocks(markdown: str, language: str = "mojo") -> list[CodeBlock]:
    """Parse fenced code blocks tagged with the given language from Markdown text.

    Handles fences of three or more backticks and ignores nested fences that use a
    different number of backticks. Only the info-string's first token is matched,
    so ```mojo and ```mojo title=foo both count.
    """
    blocks: list[CodeBlock] = []
    lines = markdown.splitlines()
    i = 0
    n = len(lines)
    while i < n:
        stripped = lines[i].lstrip()
        if stripped.startswith("```"):
            fence = stripped[: len(stripped) - len(stripped.lstrip("`"))]
            info = stripped[len(fence) :].strip()
            lang = info.split()[0].lower() if info else ""
            start_line = i + 1  # 1-based line of the opening fence
            i += 1
            body: list[str] = []
            # Consume until a closing fence of the same length (or EOF).
            while i < n:
                candidate = lines[i].lstrip()
                if (
                    candidate.startswith(fence)
                    and candidate[len(fence) :].strip() == ""
                ):
                    break
                body.append(lines[i])
                i += 1
            if lang == language:
                blocks.append(
                    CodeBlock(
                        index=len(blocks) + 1,
                        start_line=start_line,
                        code="\n".join(body) + "\n",
                    )
                )
        i += 1
    return blocks


def compile_block(
    block: CodeBlock,
    *,
    mojo_cmd: list[str],
    include_path: Path,
    work_dir: Path,
) -> tuple[bool, str, float]:
    """Write a block to a temp file and try to compile it.

    Returns (succeeded, combined_output, elapsed_seconds).
    """
    src = work_dir / f"readme_block_{block.index:02d}.mojo"
    src.write_text(block.code)
    out = work_dir / f"readme_block_{block.index:02d}.bin"

    command = [*mojo_cmd, "build", "-I", str(include_path), str(src), "-o", str(out)]
    start = time.monotonic()
    proc = subprocess.run(command, capture_output=True, text=True)
    elapsed = time.monotonic() - start
    output = (proc.stdout + proc.stderr).strip()
    return proc.returncode == 0, output, elapsed


def _indent(text: str, prefix: str = "    ") -> str:
    return "\n".join(prefix + line for line in text.splitlines())


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    default_root = find_repo_root(script_dir)

    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--readme",
        type=Path,
        default=default_root / "README.md",
        help="Path to the Markdown file to scan (default: repo README.md).",
    )
    parser.add_argument(
        "--include",
        type=Path,
        default=default_root,
        help="Directory passed to `mojo build -I` so `import prism` resolves (default: repo root).",
    )
    parser.add_argument(
        "--mojo",
        default="pixi run mojo",
        help='Launcher for the mojo compiler (default: "pixi run mojo").',
    )
    parser.add_argument(
        "--language",
        default="mojo",
        help="Fenced code-block language tag to test (default: mojo).",
    )
    parser.add_argument(
        "--keep",
        action="store_true",
        help="Keep the generated temporary .mojo files instead of deleting them.",
    )
    args = parser.parse_args()

    readme_path: Path = args.readme
    if not readme_path.is_file():
        print(f"error: README not found: {readme_path}", file=sys.stderr)
        return 2

    blocks = extract_mojo_blocks(readme_path.read_text(), args.language)
    if not blocks:
        print(f"No `{args.language}` code blocks found in {readme_path}.")
        return 0

    mojo_cmd = shlex.split(args.mojo)
    print(f"Testing {len(blocks)} `{args.language}` block(s) from {readme_path}\n")

    tmp_ctx = tempfile.mkdtemp(prefix="prism_readme_") if args.keep else None
    if args.keep:
        work_dir = Path(tmp_ctx)
        results = _run_all(blocks, mojo_cmd, args.include, work_dir)
        print(f"\nGenerated files kept in: {work_dir}")
    else:
        with tempfile.TemporaryDirectory(prefix="prism_readme_") as tmp:
            results = _run_all(blocks, mojo_cmd, args.include, Path(tmp))

    failures = [r for r in results if not r[1]]
    print("\n" + "=" * 60)
    passed = len(results) - len(failures)
    print(f"Results: {passed}/{len(results)} passed, {len(failures)} failed")
    for block, ok, output, elapsed in results:
        if not ok:
            print(
                f"\n--- FAILED: block #{block.index} (README.md:{block.start_line}) ---"
            )
            print(_indent(output or "(no compiler output)"))

    return len(failures)


def _run_all(blocks, mojo_cmd, include_path, work_dir):
    """Compile each block, printing a live PASS/FAIL line, and collect results."""
    results = []
    for block in blocks:
        ok, output, elapsed = compile_block(
            block, mojo_cmd=mojo_cmd, include_path=include_path, work_dir=work_dir
        )
        status = "PASS" if ok else "FAIL"
        print(
            f"[{status}] block #{block.index:>2}  (README.md:{block.start_line:<4})  {elapsed:6.2f}s"
        )
        results.append((block, ok, output, elapsed))
    return results


if __name__ == "__main__":
    sys.exit(main())
