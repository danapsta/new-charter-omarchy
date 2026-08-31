#!/usr/bin/env python3

"""Merge New Charter overrides into Omarchy's JSONC menu configuration."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def strip_jsonc(source: str) -> str:
    output: list[str] = []
    in_string = False
    escaped = False
    line_comment = False
    block_comment = False
    index = 0

    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
                output.append(char)
            index += 1
            continue

        if block_comment:
            if char == "*" and next_char == "/":
                block_comment = False
                index += 2
            else:
                if char == "\n":
                    output.append(char)
                index += 1
            continue

        if in_string:
            output.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            output.append(char)
            index += 1
        elif char == "/" and next_char == "/":
            line_comment = True
            index += 2
        elif char == "/" and next_char == "*":
            block_comment = True
            index += 2
        else:
            output.append(char)
            index += 1

    return re.sub(r",(?=\s*[}\]])", "", "".join(output))


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: merge-menu.py <menu.jsonc> <overrides.json>", file=sys.stderr)
        return 2

    menu_path = Path(sys.argv[1])
    override_path = Path(sys.argv[2])

    if menu_path.exists():
        try:
            menu = json.loads(strip_jsonc(menu_path.read_text(encoding="utf-8")))
        except (json.JSONDecodeError, OSError) as error:
            print(f"Unable to parse existing menu {menu_path}: {error}", file=sys.stderr)
            return 1
    else:
        menu = {}

    overrides = json.loads(override_path.read_text(encoding="utf-8"))
    if not isinstance(menu, dict) or not isinstance(overrides, dict):
        print("Menu and overrides must both be JSON objects", file=sys.stderr)
        return 1

    for key, value in overrides.items():
        if isinstance(menu.get(key), dict) and isinstance(value, dict):
            menu[key].update(value)
        else:
            menu[key] = value

    menu_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = menu_path.with_name(f".{menu_path.name}.new-charter.tmp")
    temporary.write_text(json.dumps(menu, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temporary.replace(menu_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
