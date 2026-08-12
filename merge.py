#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path


class MergeConflict(Exception):
    pass


def read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        raise MergeConflict(str(error)) from error


def write_text(path, content):
    try:
        Path(path).write_text(content, encoding="utf-8")
    except OSError as error:
        raise MergeConflict(str(error)) from error


def merge_gitignore(existing, template):
    existing_patterns = {
        line for line in existing.splitlines() if line and not line.startswith("#")
    }
    missing = [
        line
        for line in template.splitlines()
        if line and not line.startswith("#") and line not in existing_patterns
    ]
    if not missing:
        return existing

    result = existing
    if result and not result.endswith("\n"):
        result += "\n"
    if result and not result.endswith("\n\n"):
        result += "\n"
    return result + "# Added by harness installer\n" + "\n".join(missing) + "\n"


def load_json(content, label):
    try:
        value = json.loads(content)
    except json.JSONDecodeError as error:
        raise MergeConflict(f"{label} JSON が不正です: {error}") from error
    if not isinstance(value, dict):
        raise MergeConflict(f"{label} JSON のルートは object である必要があります")
    return value


def dump_json(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def merge_object(existing, template, location):
    for key, template_value in template.items():
        child_location = f"{location}.{key}"
        if key not in existing:
            existing[key] = template_value
        elif isinstance(existing[key], dict) and isinstance(template_value, dict):
            merge_object(existing[key], template_value, child_location)
        elif existing[key] != template_value:
            raise MergeConflict(f"値が競合しています: {child_location}")


def merge_identified_items(existing, template, identity_key, location):
    if not isinstance(existing, list) or not isinstance(template, list):
        raise MergeConflict(f"配列である必要があります: {location}")

    existing_by_identity = {}
    for item in existing:
        if not isinstance(item, dict) or identity_key not in item:
            raise MergeConflict(f"{identity_key} がない要素です: {location}")
        identity = item[identity_key]
        if identity in existing_by_identity:
            raise MergeConflict(f"{identity_key} が重複しています: {location}")
        existing_by_identity[identity] = item

    for item in template:
        if not isinstance(item, dict) or identity_key not in item:
            raise MergeConflict(f"テンプレートの {identity_key} が不正です: {location}")
        identity = item[identity_key]
        if identity not in existing_by_identity:
            existing.append(item)
        elif existing_by_identity[identity] != item:
            raise MergeConflict(f"定義が競合しています: {location} ({identity})")


def merge_codex_hooks(existing_text, template_text):
    existing = load_json(existing_text, "配置先")
    template = load_json(template_text, "テンプレート")
    if set(template) != {"hooks"}:
        raise MergeConflict("テンプレートの Codex hooks ルートが未対応です")
    if "hooks" not in existing:
        existing["hooks"] = template["hooks"]
        return dump_json(existing)
    if not isinstance(existing["hooks"], dict) or not isinstance(template["hooks"], dict):
        raise MergeConflict("hooks は object である必要があります")

    for event, template_groups in template["hooks"].items():
        if event not in existing["hooks"]:
            existing["hooks"][event] = template_groups
            continue
        existing_groups = existing["hooks"][event]
        if not isinstance(existing_groups, list) or not isinstance(template_groups, list):
            raise MergeConflict(f"hooks.{event} は配列である必要があります")

        by_matcher = {}
        for group in existing_groups:
            if not isinstance(group, dict) or "hooks" not in group:
                raise MergeConflict(f"hooks.{event} のグループが不正です")
            matcher = group.get("matcher")
            if matcher in by_matcher:
                raise MergeConflict(f"hooks.{event} の matcher が重複しています")
            by_matcher[matcher] = group

        for template_group in template_groups:
            if not isinstance(template_group, dict) or "hooks" not in template_group:
                raise MergeConflict(f"テンプレート hooks.{event} が不正です")
            matcher = template_group.get("matcher")
            if matcher not in by_matcher:
                existing_groups.append(template_group)
                continue
            existing_group = by_matcher[matcher]
            if {key: value for key, value in existing_group.items() if key != "hooks"} != {
                key: value for key, value in template_group.items() if key != "hooks"
            }:
                raise MergeConflict(f"hooks.{event} のグループ定義が競合しています")
            merge_identified_items(
                existing_group["hooks"],
                template_group["hooks"],
                "command",
                f"hooks.{event}",
            )
    return dump_json(existing)


def merge_github_hooks(existing_text, template_text):
    existing = load_json(existing_text, "配置先")
    template = load_json(template_text, "テンプレート")
    for key, value in template.items():
        if key == "hooks":
            continue
        if key not in existing:
            existing[key] = value
        elif existing[key] != value:
            raise MergeConflict(f"値が競合しています: {key}")

    if "hooks" not in template or not isinstance(template["hooks"], dict):
        raise MergeConflict("テンプレートの hooks が不正です")
    if "hooks" not in existing:
        existing["hooks"] = template["hooks"]
        return dump_json(existing)
    if not isinstance(existing["hooks"], dict):
        raise MergeConflict("hooks は object である必要があります")

    for event, template_items in template["hooks"].items():
        if event not in existing["hooks"]:
            existing["hooks"][event] = template_items
        else:
            merge_identified_items(
                existing["hooks"][event], template_items, "bash", f"hooks.{event}"
            )
    return dump_json(existing)


def merge_vscode_settings(existing_text, template_text):
    existing = load_json(existing_text, "配置先")
    template = load_json(template_text, "テンプレート")
    merge_object(existing, template, "settings")
    return dump_json(existing)


SECTION_RE = re.compile(r"^\s*\[([^]]+)]\s*(?:#.*)?$")
ASSIGNMENT_RE = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=\s*(.*?)\s*$")


def find_section(lines, name):
    matches = []
    for index, line in enumerate(lines):
        match = SECTION_RE.match(line)
        if match and match.group(1) == name:
            matches.append(index)
    if len(matches) > 1:
        raise MergeConflict(f"TOML セクションが重複しています: [{name}]")
    if not matches:
        return None
    start = matches[0]
    end = len(lines)
    for index in range(start + 1, len(lines)):
        if SECTION_RE.match(lines[index]):
            end = index
            break
    return start, end


def section_assignments(lines, start, end, label):
    assignments = {}
    ordered = []
    for line in lines[start + 1: end]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = ASSIGNMENT_RE.match(line)
        if not match:
            raise MergeConflict(f"未対応の {label} 定義です: {stripped}")
        key, value = match.groups()
        if key in assignments:
            raise MergeConflict(f"{label} キーが重複しています: {key}")
        assignments[key] = value.strip()
        ordered.append((key, line))
    return assignments, ordered


def merge_cargo_toml(existing_text, template_text):
    existing_lines = existing_text.splitlines()
    template_lines = template_text.splitlines()
    template_section = find_section(template_lines, "lints.clippy")
    if template_section is None:
        raise MergeConflict("テンプレートに [lints.clippy] がありません")
    template_values, template_ordered = section_assignments(
        template_lines, *template_section, "テンプレート TOML"
    )
    existing_section = find_section(existing_lines, "lints.clippy")

    if existing_section is None:
        result = existing_text
        if result and not result.endswith("\n"):
            result += "\n"
        if result and not result.endswith("\n\n"):
            result += "\n"
        return result + "\n".join(template_lines[template_section[0]: template_section[1]]) + "\n"

    existing_values, _ = section_assignments(
        existing_lines, *existing_section, "配置先 TOML"
    )
    missing_lines = []
    for key, line in template_ordered:
        if key not in existing_values:
            missing_lines.append(line)
        elif existing_values[key] != template_values[key]:
            raise MergeConflict(f"Cargo.toml の値が競合しています: lints.clippy.{key}")
    if not missing_lines:
        return existing_text

    insertion = existing_section[1]
    existing_lines[insertion:insertion] = missing_lines
    return "\n".join(existing_lines) + ("\n" if existing_text.endswith("\n") else "")


TARGET_RE = re.compile(r"^([A-Za-z0-9_.-]+)\s*:(.*)$")


def make_blocks(text, label):
    lines = text.splitlines()
    starts = []
    for index, line in enumerate(lines):
        match = TARGET_RE.match(line)
        if match:
            starts.append((index, match.group(1)))
    blocks = {}
    order = []
    for position, (start, name) in enumerate(starts):
        if name in blocks:
            raise MergeConflict(f"{label} Makefile ターゲットが重複しています: {name}")
        end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
        block = lines[start:end]
        while block and not block[-1].strip():
            block.pop()
        blocks[name] = "\n".join(block)
        order.append(name)
    return blocks, order


def merge_makefile(existing_text, template_text):
    existing, _ = make_blocks(existing_text, "配置先")
    template, template_order = make_blocks(template_text, "テンプレート")
    if not template:
        raise MergeConflict("テンプレート Makefile にターゲットがありません")
    missing = []
    for name in template_order:
        if name not in existing:
            missing.append(template[name])
        elif existing[name] != template[name]:
            raise MergeConflict(f"Makefile ターゲットが競合しています: {name}")
    if not missing:
        return existing_text

    result = existing_text
    if result and not result.endswith("\n"):
        result += "\n"
    if result and not result.endswith("\n\n"):
        result += "\n"
    return result + "\n\n".join(missing) + "\n"


DOCS_BEGIN_MARKER = "<!-- BEGIN AGENTS.md docs template -->"
DOCS_END_MARKER = "<!-- END AGENTS.md docs template -->"


def merge_docs_readme(existing_text, template_text):
    begin_count = existing_text.count(DOCS_BEGIN_MARKER)
    end_count = existing_text.count(DOCS_END_MARKER)
    if begin_count or end_count:
        if (
            begin_count == 1
            and end_count == 1
            and existing_text.find(DOCS_BEGIN_MARKER)
            < existing_text.find(DOCS_END_MARKER)
        ):
            return existing_text
        raise MergeConflict("文書テンプレートの境界マーカーが不正です")
    if template_text in existing_text:
        return existing_text

    result = existing_text
    if result and not result.endswith("\n"):
        result += "\n"
    if result and not result.endswith("\n\n"):
        result += "\n"
    template_block = template_text
    if template_block and not template_block.endswith("\n"):
        template_block += "\n"
    return (
        result
        + DOCS_BEGIN_MARKER
        + "\n"
        + template_block
        + DOCS_END_MARKER
        + "\n"
    )


def merge(relative_path, existing, template):
    if Path(relative_path).name == ".gitignore":
        return merge_gitignore(existing, template)
    if relative_path == ".codex/hooks.json":
        return merge_codex_hooks(existing, template)
    if relative_path == ".github/hooks/hooks.json":
        return merge_github_hooks(existing, template)
    if relative_path == ".vscode/settings.json":
        return merge_vscode_settings(existing, template)
    if relative_path == "Cargo.toml":
        return merge_cargo_toml(existing, template)
    if relative_path == "Makefile":
        return merge_makefile(existing, template)
    if relative_path == "docs/README.md":
        return merge_docs_readme(existing, template)
    raise MergeConflict("自動マージに対応していません")


def main():
    if len(sys.argv) != 6 or sys.argv[1] != "merge":
        print("usage: merge.py merge RELATIVE_PATH EXISTING TEMPLATE OUTPUT", file=sys.stderr)
        return 2
    _, _, relative_path, existing_path, template_path, output_path = sys.argv
    try:
        result = merge(
            relative_path, read_text(existing_path), read_text(template_path)
        )
        write_text(output_path, result)
    except MergeConflict as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
