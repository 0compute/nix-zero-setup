import json
from pathlib import Path

import pytest
import typer

from nix_seed_tools import nix_path_mermaid as module


PATH_INFO_LIST = [
    {
        "path": "/nix/store/aaaaa-foo-1.0",
        "narSize": 100,
        "closureSize": 400,
        "references": ["/nix/store/bbbbb-bar-2.0"],
    },
    {
        "path": "/nix/store/bbbbb-bar-2.0",
        "narSize": 200,
        "closureSize": 200,
        "references": [],
    },
]

PATH_INFO_DICT = {
    "/nix/store/ccccc-baz-3.0": {
        "narSize": 50,
        "closureSize": 50,
        "references": [],
    }
}

PATH_INFO_V2 = [
    {
        "path": {"path": "/nix/store/ddddd-qux-4.0"},
        "narSize": 10,
        "closureSize": 10,
        "references": [],
    }
]

DERIVATION_JSON = {
    "/nix/store/ddd-foo-1.0.drv": {
        "env": {"pname": "foo", "version": "1.0"},
        "outputs": {"out": {"path": "/nix/store/aaaaa-foo-1.0"}},
    },
    "/nix/store/eee-bar-2.0.drv": {
        "env": {"name": "bar-2.0"},
        "outputs": {"out": {"path": "/nix/store/bbbbb-bar-2.0"}},
    },
}

DERIVATION_JSON_WITH_SKIP = {
    "/nix/store/fff-skip.drv": {
        "env": "not-a-dict",
        "outputs": {"out": {"path": "/nix/store/skip"}},
    }
}


class DummyResult:
    def __init__(self, returncode, stdout, stderr):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


def test_log_event_writes_json(capsys):
    module.log_event("info", "message", value="x")
    captured = capsys.readouterr()
    payload = json.loads(captured.err.strip())

    assert payload["level"] == "info"
    assert payload["message"] == "message"
    assert payload["value"] == "x"


def test_resolve_store_path_valid(monkeypatch):
    def fake_resolve(self, strict=True):
        return Path("/nix/store/valid-path")

    monkeypatch.setattr(module.Path, "resolve", fake_resolve)

    resolved = module.resolve_store_path("input")

    assert str(resolved) == "/nix/store/valid-path"


def test_resolve_store_path_missing(monkeypatch):
    def fake_resolve(self, strict=True):
        raise FileNotFoundError

    monkeypatch.setattr(module.Path, "resolve", fake_resolve)

    with pytest.raises(ValueError):
        module.resolve_store_path("missing")


def test_resolve_store_path_not_store(monkeypatch):
    def fake_resolve(self, strict=True):
        return Path("/tmp/not-store")

    monkeypatch.setattr(module.Path, "resolve", fake_resolve)

    with pytest.raises(ValueError):
        module.resolve_store_path("bad")


def test_run_command_success(monkeypatch):
    def fake_run(*args, **kwargs):
        return DummyResult(0, "ok", "")

    monkeypatch.setattr(module.subprocess, "run", fake_run)

    assert module.run_command(["echo", "ok"]) == "ok"


def test_run_command_failure(monkeypatch, capsys):
    def fake_run(*args, **kwargs):
        return DummyResult(1, "", "boom")

    monkeypatch.setattr(module.subprocess, "run", fake_run)

    with pytest.raises(RuntimeError):
        module.run_command(["false"])
    captured = capsys.readouterr()
    payload = json.loads(captured.err.strip())

    assert payload["message"] == "command failed"


def test_coerce_int_variants():
    assert module.coerce_int(1) == 1
    assert module.coerce_int(1.1) == 1
    assert module.coerce_int("10") == 10
    assert module.coerce_int(None) is None
    with pytest.raises(ValueError):
        module.coerce_int("nope")


def test_parse_path_info_list_and_dict():
    list_map = module.parse_path_info_json(PATH_INFO_LIST)
    dict_map = module.parse_path_info_json(PATH_INFO_DICT)

    assert list_map["/nix/store/aaaaa-foo-1.0"].nar_size == 100
    assert dict_map["/nix/store/ccccc-baz-3.0"].closure_size == 50


def test_parse_path_info_v2_path_dict():
    path_map = module.parse_path_info_json(PATH_INFO_V2)

    assert "/nix/store/ddddd-qux-4.0" in path_map


def test_parse_path_info_errors():
    with pytest.raises(ValueError):
        module.parse_path_info_json("bad")
    with pytest.raises(ValueError):
        module.parse_path_info_json([{"references": []}])
    with pytest.raises(ValueError):
        module.parse_path_info_json([{"path": "/nix/store/x", "references": 1}])
    with pytest.raises(ValueError):
        module.parse_path_info_json(["bad-item"])


def test_parse_derivation_json_builds_title_map():
    title_map = module.parse_derivation_json(DERIVATION_JSON)

    assert title_map["/nix/store/aaaaa-foo-1.0"] == "foo 1.0"
    assert title_map["/nix/store/bbbbb-bar-2.0"] == "bar-2.0"


def test_parse_derivation_json_errors():
    with pytest.raises(ValueError):
        module.parse_derivation_json("bad")
    title_map = module.parse_derivation_json(DERIVATION_JSON_WITH_SKIP)

    assert title_map == {}


def test_parse_derivation_json_output_skip():
    data = {
        "/nix/store/out.drv": {
            "env": {"name": "out"},
            "outputs": {"out": "bad"},
        }
    }
    title_map = module.parse_derivation_json(data)

    assert title_map == {}


def test_build_title_variants():
    assert module.build_title("p", "1.0", None) == "p 1.0"
    assert module.build_title("p", None, None) == "p"
    assert module.build_title(None, None, "name") == "name"
    assert module.build_title(None, None, None) == "unknown"


def test_load_path_info(monkeypatch):
    def fake_run(args, input_text=None):
        return json.dumps(PATH_INFO_LIST)

    monkeypatch.setattr(module, "run_command", fake_run)

    path_map = module.load_path_info(Path("/nix/store/x"), fake_run)

    assert "/nix/store/aaaaa-foo-1.0" in path_map


def test_chunk_paths():
    with pytest.raises(ValueError):
        module.chunk_paths(["a"], 0)
    assert module.chunk_paths(["a", "b", "c"], 2) == [["a", "b"], ["c"]]


def test_load_derivers(monkeypatch):
    def fake_run(args, input_text=None):
        paths = args[3:]
        mapping = {
            "a": "/nix/store/a.drv",
            "b": "unknown-deriver",
        }
        return "\n".join(mapping[path] for path in paths) + "\n"

    result = module.load_derivers(["a", "b"], fake_run)

    assert result["a"] == "/nix/store/a.drv"
    assert result["b"] is None


def test_load_derivers_empty():
    assert module.load_derivers([], lambda *_: "") == {}


def test_load_derivers_mismatch():
    def fake_run(args, input_text=None):
        return "/nix/store/a.drv\n"

    with pytest.raises(RuntimeError):
        module.load_derivers(["a", "b"], fake_run)


def test_load_derivations(monkeypatch):
    def fake_run(args, input_text=None):
        return json.dumps(DERIVATION_JSON)

    assert module.load_derivations([], fake_run) == {}
    result = module.load_derivations(["/nix/store/a.drv"], fake_run)

    assert "outputs" in result["/nix/store/ddd-foo-1.0.drv"]


def test_title_map_for_paths(monkeypatch):
    def fake_run(args, input_text=None):
        if args[:3] == ["nix-store", "--query", "--deriver"]:
            paths = args[3:]
            mapping = {
                "/nix/store/aaaaa-foo-1.0": "/nix/store/ddd-foo-1.0.drv",
            }
            return "\n".join(mapping[path] for path in paths) + "\n"
        if args[:3] == ["nix", "derivation", "show"]:
            return json.dumps(DERIVATION_JSON)
        raise AssertionError("unexpected command")

    title_map = module.title_map_for_paths(
        ["/nix/store/aaaaa-foo-1.0"],
        fake_run,
    )

    assert title_map["/nix/store/aaaaa-foo-1.0"] == "foo 1.0"


def test_human_size_variants():
    assert module.human_size(None) == "unknown"
    assert module.human_size(10) == "10 B"
    assert module.human_size(2048) == "2.0 KiB"


def test_quantile_thresholds_variants():
    with pytest.raises(ValueError):
        module.quantile_thresholds([])
    low, high = module.quantile_thresholds([10])
    assert low == 10
    assert high == 10
    low, high = module.quantile_thresholds([1, 2, 3])
    assert low in [1, 2, 3]
    assert high in [1, 2, 3]


def test_class_for_size_variants():
    assert module.class_for_size(None, 1, 2) == "sizeUnknown"
    assert module.class_for_size(1, 1, 2) == "sizeGreen"
    assert module.class_for_size(2, 1, 2) == "sizeYellow"
    assert module.class_for_size(3, 1, 2) == "sizeRed"


def test_generate_mermaid_uses_titles_and_edges():
    def fake_run(args, input_text=None):
        if args[:2] == ["nix", "path-info"]:
            return json.dumps(PATH_INFO_LIST)
        if args[:3] == ["nix-store", "--query", "--deriver"]:
            paths = args[3:]
            mapping = {
                "/nix/store/aaaaa-foo-1.0": "/nix/store/ddd-foo-1.0.drv",
                "/nix/store/bbbbb-bar-2.0": "/nix/store/eee-bar-2.0.drv",
            }
            return "\n".join(mapping[path] for path in paths) + "\n"
        if args[:3] == ["nix", "derivation", "show"]:
            assert input_text is not None
            return json.dumps(DERIVATION_JSON)
        raise AssertionError("unexpected command")

    output = module.generate_mermaid(
        Path("/nix/store/aaaaa-foo-1.0"),
        run=fake_run,
    )

    assert "graph TD" in output
    assert "foo 1.0" in output
    assert "bar-2.0" in output
    assert "---" in output


def test_generate_mermaid_fallback_title():
    def fake_run(args, input_text=None):
        if args[:2] == ["nix", "path-info"]:
            return json.dumps(PATH_INFO_LIST)
        if args[:3] == ["nix-store", "--query", "--deriver"]:
            return "unknown-deriver\nunknown-deriver\n"
        if args[:3] == ["nix", "derivation", "show"]:
            return "{}"
        raise AssertionError("unexpected command")

    output = module.generate_mermaid(
        Path("/nix/store/aaaaa-foo-1.0"),
        run=fake_run,
    )

    assert "foo-1.0" in output


def test_generate_mermaid_without_closure_sizes():
    def fake_run(args, input_text=None):
        if args[:2] == ["nix", "path-info"]:
            return json.dumps([{"path": "/nix/store/x", "references": []}])
        if args[:3] == ["nix-store", "--query", "--deriver"]:
            return "unknown-deriver\n"
        if args[:3] == ["nix", "derivation", "show"]:
            return "{}"
        raise AssertionError("unexpected command")

    with pytest.raises(ValueError):
        module.generate_mermaid(Path("/nix/store/x"), run=fake_run)


def test_main_success(monkeypatch, capsys):
    def fake_resolve(value):
        return Path("/nix/store/ok")

    def fake_generate(store_path, run):
        return "graph TD"

    monkeypatch.setattr(module, "resolve_store_path", fake_resolve)
    monkeypatch.setattr(module, "generate_mermaid", fake_generate)

    module.main("ok")
    captured = capsys.readouterr()

    assert "graph TD" in captured.out


def test_main_failure(monkeypatch, capsys):
    def fake_resolve(value):
        raise ValueError("bad")

    monkeypatch.setattr(module, "resolve_store_path", fake_resolve)

    with pytest.raises(typer.Exit) as exc:
        module.main("bad")
    captured = capsys.readouterr()

    assert exc.value.exit_code == 2
    assert "invalid store path" in captured.err
