#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import urllib.request

import yaml

SDK_OPENAPI_URL = "https://raw.githubusercontent.com/Jish2/bluebubbles-sdk/main/openapi.yaml"
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT_PATH = ROOT / "docs" / "openapi.yaml"
METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}


def fetch_openapi(url: str) -> dict:
    with urllib.request.urlopen(url) as response:
        payload = response.read().decode("utf-8")
    data = yaml.safe_load(payload)
    if not isinstance(data, dict):
        raise RuntimeError("OpenAPI payload is not an object")
    return data


def patch_responses(spec: dict) -> int:
    paths = spec.get("paths")
    if not isinstance(paths, dict):
        return 0

    patched = 0
    for path_item in paths.values():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if method not in METHODS or not isinstance(operation, dict):
                continue
            responses = operation.get("responses")
            if not isinstance(responses, dict) or len(responses) == 0:
                operation["responses"] = {
                    "200": {"description": "Successful response"}
                }
                patched += 1
    return patched


def main() -> None:
    spec = fetch_openapi(SDK_OPENAPI_URL)
    patched_count = patch_responses(spec)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8") as f:
        yaml.safe_dump(spec, f, sort_keys=False, allow_unicode=False)
    print(f"synced {OUT_PATH} from {SDK_OPENAPI_URL} (patched operations: {patched_count})")


if __name__ == "__main__":
    main()
