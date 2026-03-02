from __future__ import annotations

import json
import operator
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Protocol, Sequence

import typer


class CommandRunner(Protocol):
    __call__: Callable[[Sequence[str], str | None], str]


@dataclass(frozen=True)
class PathInfo:
    path: str
    nar_size: int | None
    closure_size: int | None
    references: list[str]


app = typer.Typer(add_completion=False)


def log_event(level: str, message: str, **fields: object):
    """Inputs: level, message, fields. Outputs: None.

    Side effects: Writes a JSON line to stderr.
    Exceptions: Propagates json errors from dumps.
    """
    payload = {"level": level, "message": message, **fields}
    sys.stderr.write(json.dumps(payload) + "\n")


def resolve_store_path(value: str):
    """Inputs: value string. Outputs: resolved store path.

    Side effects: Resolves filesystem paths.
    Exceptions: Raises ValueError when path is invalid.
    """
    path = Path(value)
    try:
        resolved = path.resolve(strict=True)
    except FileNotFoundError as exc:
        raise ValueError("store path does not exist") from exc
    if not str(resolved).startswith("/nix/store/"):
        raise ValueError("path is not in /nix/store")
    return resolved


def run_command(args: Sequence[str], input_text: str | None = None):
    """Inputs: args, input_text. Outputs: stdout text.

    Side effects: Runs a subprocess.
    Exceptions: Raises RuntimeError on non-zero exit.
    """
    result = subprocess.run(
        list(args),
        input=input_text,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        log_event(
            "error",
            "command failed",
            command=list(args),
            return_code=result.returncode,
            stderr=result.stderr.strip(),
        )
        raise RuntimeError("command failed")
    return result.stdout


def coerce_int(value: object):
    """Inputs: value. Outputs: int or None.

    Side effects: None.
    Exceptions: Raises ValueError on unsupported type.
    """
    if value is None:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str) and value.isdigit():
        return int(value)
    raise ValueError("size is not a number")


def parse_path_info_json(raw: object):
    """Inputs: raw json output. Outputs: map of path to PathInfo.

    Side effects: None.
    Exceptions: Raises ValueError on unsupported format.

    Example:
        parse_path_info_json(
            [{"path": "/nix/store/a", "references": []}]
        )
    """
    match raw:
        case list():
            items = raw
        case dict():
            items = []
            for path, info in raw.items():
                if not isinstance(info, dict):
                    raise ValueError("path info entry is not a dict")
                entry = dict(info)
                entry["path"] = path
                items.append(entry)
        case _:
            raise ValueError("unsupported path info json format")

    path_map: dict[str, PathInfo] = {}
    for item in items:
        if not isinstance(item, dict):
            raise ValueError("path info item is not a dict")
        path_value = item.get("path")
        match path_value:
            case str():
                path = path_value
            case dict():
                path = path_value.get("path") or path_value.get("name")
            case _:
                path = None
        if not isinstance(path, str):
            raise ValueError("path value is missing")
        references = item.get("references", [])
        if not isinstance(references, list):
            raise ValueError("references is not a list")
        ref_list = [ref for ref in references if isinstance(ref, str)]
        nar_size = coerce_int(item.get("narSize") or item.get("size"))
        closure_size = coerce_int(item.get("closureSize"))
        path_map[path] = PathInfo(
            path=path,
            nar_size=nar_size,
            closure_size=closure_size,
            references=ref_list,
        )
    return path_map


def parse_derivation_json(raw: object):
    """Inputs: raw derivation json. Outputs: path title map.

    Side effects: None.
    Exceptions: Raises ValueError on unsupported format.

    Example:
        parse_derivation_json(
            {"/nix/store/a.drv": {"env": {"pname": "a"}}}
        )
    """
    if not isinstance(raw, dict):
        raise ValueError("derivation json is not a dict")
    title_map: dict[str, str] = {}
    for drv_info in raw.values():
        if not isinstance(drv_info, dict):
            continue
        env = drv_info.get("env", {})
        outputs = drv_info.get("outputs", {})
        if not isinstance(env, dict) or not isinstance(outputs, dict):
            continue
        pname = env.get("pname")
        version = env.get("version")
        name = env.get("name")
        title = build_title(
            pname if isinstance(pname, str) else None,
            version if isinstance(version, str) else None,
            name if isinstance(name, str) else None,
        )
        for output in outputs.values():
            if not isinstance(output, dict):
                continue
            output_path = output.get("path")
            if isinstance(output_path, str):
                title_map[output_path] = title
    return title_map


def build_title(
    pname: str | None,
    version: str | None,
    name: str | None,
):
    """Inputs: pname, version, name. Outputs: title string.

    Side effects: None.
    Exceptions: None.
    """
    if pname and version:
        return f"{pname} {version}"
    if pname:
        return pname
    if name:
        return name
    return "unknown"


def load_path_info(store_path: Path, run: CommandRunner):
    """Inputs: store_path, runner. Outputs: path info map.

    Side effects: Runs nix path-info.
    Exceptions: Raises RuntimeError on command failure.
    """
    output = run(
        [
            "nix",
            "path-info",
            "--recursive",
            "--json",
            "--size",
            "--closure-size",
            str(store_path),
        ]
    )
    raw = json.loads(output)
    return parse_path_info_json(raw)


def chunk_paths(paths: Sequence[str], size: int):
    """Inputs: paths, size. Outputs: list chunks.

    Side effects: None.
    Exceptions: Raises ValueError for invalid size.
    """
    if size == 0:
        raise ValueError("chunk size must be non-zero")
    chunks: list[list[str]] = []
    for index in range(0, len(paths), size):
        chunks.append(list(paths[index : index + size]))
    return chunks


def load_derivers(paths: list[str], run: CommandRunner):
    """Inputs: paths, runner. Outputs: map of path to drv.

    Side effects: Runs nix-store.
    Exceptions: Raises RuntimeError on command failure.
    """
    if not paths:
        return {}
    path_map: dict[str, str | None] = {}
    for chunk in chunk_paths(paths, 200):
        output = run(["nix-store", "--query", "--deriver", *chunk])
        lines = output.strip().splitlines()
        if len(lines) != len(chunk):
            log_event(
                "error",
                "deriver output mismatch",
                expected=len(chunk),
                actual=len(lines),
            )
            raise RuntimeError("deriver output mismatch")
        for path, drv in zip(chunk, lines, strict=True):
            if drv == "unknown-deriver":
                path_map[path] = None
            else:
                path_map[path] = drv
    return path_map


def load_derivations(drv_paths: list[str], run: CommandRunner):
    """Inputs: drv paths, runner. Outputs: derivation data.

    Side effects: Runs nix derivation show.
    Exceptions: Raises RuntimeError on command failure.
    """
    if not drv_paths:
        return {}
    input_text = "\n".join(drv_paths) + "\n"
    output = run(
        ["nix", "derivation", "show", "--stdin", "--no-pretty"],
        input_text=input_text,
    )
    return json.loads(output)


def title_map_for_paths(paths: list[str], run: CommandRunner):
    """Inputs: paths, runner. Outputs: title map by output path.

    Side effects: Runs nix-store and nix derivation show.
    Exceptions: Raises RuntimeError on command failure.
    """
    derivers = load_derivers(paths, run)
    # Sort for deterministic command input, which is worth O(n log n) here.
    drv_paths = sorted({drv for drv in derivers.values() if isinstance(drv, str)})
    derivation_data = load_derivations(drv_paths, run)
    return parse_derivation_json(derivation_data)


def human_size(value: int | None):
    """Inputs: value in bytes. Outputs: human friendly size.

    Side effects: None.
    Exceptions: None.
    """
    if value is None:
        return "unknown"
    size = float(value)
    units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    for unit in units:
        if unit == units[-1] or operator.lt(size, 1024):
            if unit == "B":
                return f"{int(size)} B"
            return f"{size:.1f} {unit}"
        size = size / 1024
    return f"{int(size)} B"


def quantile_thresholds(values: list[int]):
    """Inputs: values. Outputs: low and high quantiles.

    Side effects: None.
    Exceptions: Raises ValueError on empty values.
    """
    if not values:
        raise ValueError("no values for thresholds")
    # Sort for deterministic quantiles, which is worth O(n log n) here.
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0], ordered[0]
    low_index = int(round((len(ordered) - 1) * (1 / 3)))
    high_index = int(round((len(ordered) - 1) * (2 / 3)))
    return ordered[low_index], ordered[high_index]


def class_for_size(size: int | None, low: int, high: int):
    """Inputs: size, low, high. Outputs: class name.

    Side effects: None.
    Exceptions: None.
    """
    if size is None:
        return "sizeUnknown"
    if operator.le(size, low):
        return "sizeGreen"
    if operator.le(size, high):
        return "sizeYellow"
    return "sizeRed"


def generate_mermaid(store_path: Path, run: CommandRunner = run_command):
    """Inputs: store_path, runner. Outputs: mermaid string.

    Side effects: Runs nix commands.
    Exceptions: Raises RuntimeError on command failure.

    Example:
        generate_mermaid(Path("/nix/store/hash-name"), run_command)
    """
    path_info = load_path_info(store_path, run)
    title_map = title_map_for_paths(list(path_info.keys()), run)
    closure_sizes = [
        info.closure_size
        for info in path_info.values()
        if info.closure_size is not None
    ]
    low, high = quantile_thresholds(closure_sizes)
    # Sort for deterministic output, which is worth O(n log n) here.
    ordered_paths = sorted(path_info.keys())
    node_ids = {path: f"n{index}" for index, path in enumerate(ordered_paths)}
    lines = [
        "graph TD",
        "classDef sizeGreen fill:#8fd694,stroke:#333,stroke-width:1px",
        "classDef sizeYellow fill:#ffe08a,stroke:#333,stroke-width:1px",
        "classDef sizeRed fill:#f4a6a6,stroke:#333,stroke-width:1px",
        "classDef sizeUnknown fill:#dddddd,stroke:#333,stroke-width:1px",
    ]
    for path in ordered_paths:
        info = path_info[path]
        title = title_map.get(path) or path.split("-", 1)[-1]
        label = (
            f"{title}\\n"
            f"size {human_size(info.nar_size)}\\n"
            f"closure {human_size(info.closure_size)}"
        )
        label = label.replace('"', "'")
        node_id = node_ids[path]
        lines.append(f'{node_id}["{label}"]')
        lines.append(f"class {node_id} {class_for_size(info.closure_size, low, high)}")
    for path in ordered_paths:
        node_id = node_ids[path]
        for ref in path_info[path].references:
            if ref in node_ids:
                lines.append(f"{node_id} --- {node_ids[ref]}")
    return "\n".join(lines)


@app.command()
def main(store_path: str):
    """Inputs: store_path argument. Outputs: mermaid on stdout.

    Side effects: Runs nix commands and writes to stdout.
    Exceptions: Raises typer.Exit on invalid input.
    """
    try:
        resolved = resolve_store_path(store_path)
    except ValueError as exc:
        log_event("error", "invalid store path", error=str(exc))
        raise typer.Exit(code=2) from exc
    mermaid = generate_mermaid(resolved, run_command)
    sys.stdout.write(mermaid + "\n")


log_event.__annotations__["return"] = None
parse_path_info_json.__annotations__["return"] = dict[str, PathInfo]
parse_derivation_json.__annotations__["return"] = dict[str, str]
resolve_store_path.__annotations__["return"] = Path
run_command.__annotations__["return"] = str
coerce_int.__annotations__["return"] = int | None
build_title.__annotations__["return"] = str
load_path_info.__annotations__["return"] = dict[str, PathInfo]
chunk_paths.__annotations__["return"] = list[list[str]]
load_derivers.__annotations__["return"] = dict[str, str | None]
load_derivations.__annotations__["return"] = dict[str, object]
title_map_for_paths.__annotations__["return"] = dict[str, str]
human_size.__annotations__["return"] = str
quantile_thresholds.__annotations__["return"] = tuple[int, int]
class_for_size.__annotations__["return"] = str
generate_mermaid.__annotations__["return"] = str
main.__annotations__["return"] = None
