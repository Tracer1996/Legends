#!/usr/bin/env python3
"""
Convert an EpochAchievementExporter SavedVariables dump into normalized
artifacts for porting native 3.3.5 achievements into the 1.12 addon.

Requirements:
  pip install slpp

Example:
  python tools/epoch_dump_bridge.py ^
    --input "C:\\Ascension\\Launcher\\resources\\epoch-live\\WTF\\Account\\WALKERSALES96\\SavedVariables\\EpochAchievementExporter.lua" ^
    --output-dir "tools\\generated\\epoch_native"
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

try:
    from slpp import slpp as lua
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency 'slpp'. Install it with: pip install slpp"
    ) from exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Path to EpochAchievementExporter.lua")
    parser.add_argument("--output-dir", required=True, help="Directory for generated artifacts")
    return parser.parse_args()


def load_saved_variables(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"-- \[\d+\]", "", text)
    text = re.sub(r"EpochAchievementExportDB\s*=\s*", "", text, count=1)
    return lua.decode(text)


def index_categories(categories: list[dict[str, Any]]) -> dict[int, dict[str, Any]]:
    return {category["id"]: category for category in categories if "id" in category}


def visible_ids_from_categories(categories: list[dict[str, Any]]) -> set[int]:
    visible: set[int] = set()
    for category in categories:
        for achievement_id in category.get("achievementIDs") or []:
            if isinstance(achievement_id, int):
                visible.add(achievement_id)
    return visible


def normalize_criteria(criteria: dict[str, Any]) -> dict[str, Any]:
    return {
        "index": criteria.get("index"),
        "criteriaID": criteria.get("criteriaID"),
        "criteriaType": criteria.get("criteriaType"),
        "description": criteria.get("description"),
        "completed": criteria.get("completed"),
        "quantity": criteria.get("quantity"),
        "requiredQuantity": criteria.get("requiredQuantity"),
        "quantityString": criteria.get("quantityString"),
        "assetID": criteria.get("assetID"),
        "flags": criteria.get("flags"),
        "characterName": criteria.get("characterName"),
    }


def normalize_achievement(
    achievement: dict[str, Any],
    categories_by_id: dict[int, dict[str, Any]],
    visible_ids: set[int],
) -> dict[str, Any]:
    category = categories_by_id.get(achievement.get("categoryID"))
    criteria = [normalize_criteria(item) for item in (achievement.get("criteria") or [])]
    return {
        "id": achievement.get("id"),
        "name": achievement.get("name"),
        "description": achievement.get("description"),
        "points": achievement.get("points"),
        "icon": achievement.get("icon"),
        "flags": achievement.get("flags"),
        "completed": achievement.get("completed"),
        "rewardText": achievement.get("rewardText"),
        "link": achievement.get("link"),
        "numCriteria": achievement.get("numCriteria", 0),
        "numRewards": achievement.get("numRewards", 0),
        "categoryID": achievement.get("categoryID"),
        "categoryName": category.get("name") if category else None,
        "parentCategoryID": category.get("parentID") if category else None,
        "visible": achievement.get("id") in visible_ids,
        "criteria": criteria,
    }


def compute_dependency_closure(
    achievement_by_id: dict[int, dict[str, Any]],
    visible_ids: set[int],
) -> set[int]:
    needed = set(visible_ids)
    changed = True
    while changed:
        changed = False
        for achievement_id in list(needed):
            achievement = achievement_by_id.get(achievement_id)
            if not achievement:
                continue
            for criteria in achievement.get("criteria") or []:
                asset_id = criteria.get("assetID")
                if isinstance(asset_id, int) and asset_id in achievement_by_id and asset_id not in needed:
                    needed.add(asset_id)
                    changed = True
    return needed


def summarize_criteria_types(
    achievements: list[dict[str, Any]],
    achievement_ids: set[int],
    visible_ids: set[int],
) -> list[dict[str, Any]]:
    totals = Counter()
    achievement_counts = Counter()
    hidden_ref_counts = Counter()
    examples: dict[int, dict[str, Any]] = {}

    for achievement in achievements:
        seen_for_achievement: set[int] = set()
        for criteria in achievement.get("criteria") or []:
            criteria_type = criteria.get("criteriaType")
            if criteria_type is None:
                continue
            totals[criteria_type] += 1
            seen_for_achievement.add(criteria_type)

            asset_id = criteria.get("assetID")
            if isinstance(asset_id, int) and asset_id in achievement_ids and asset_id not in visible_ids:
                hidden_ref_counts[criteria_type] += 1

            if criteria_type not in examples:
                examples[criteria_type] = {
                    "achievementID": achievement.get("id"),
                    "achievementName": achievement.get("name"),
                    "criteriaID": criteria.get("criteriaID"),
                    "description": criteria.get("description"),
                    "quantityString": criteria.get("quantityString"),
                    "assetID": criteria.get("assetID"),
                }

        for criteria_type in seen_for_achievement:
            achievement_counts[criteria_type] += 1

    summary = []
    for criteria_type, rows in totals.most_common():
        summary.append(
            {
                "criteriaType": criteria_type,
                "criteriaRows": rows,
                "achievementCount": achievement_counts[criteria_type],
                "hiddenAchievementRefRows": hidden_ref_counts[criteria_type],
                "example": examples.get(criteria_type),
            }
        )
    return summary


def build_summary(
    dump: dict[str, Any],
    categories: list[dict[str, Any]],
    visible_ids: set[int],
    dependency_ids: set[int],
    criteria_type_summary: list[dict[str, Any]],
) -> dict[str, Any]:
    achievements = dump["achievements"]
    achievement_by_id = {achievement["id"]: achievement for achievement in achievements}

    categories_sorted = []
    for category in categories:
        categories_sorted.append(
            {
                "id": category.get("id"),
                "name": category.get("name"),
                "parentID": category.get("parentID"),
                "numAchievements": category.get("numAchievements", 0),
                "numCompleted": category.get("numCompleted", 0),
                "numIncomplete": category.get("numIncomplete", 0),
            }
        )

    return {
        "build": dump.get("build"),
        "generatedAt": dump.get("generatedAt"),
        "player": dump.get("player"),
        "realm": dump.get("realm"),
        "totalPoints": dump.get("totalPoints"),
        "summary": dump.get("summary"),
        "visibleAchievementCount": len(visible_ids),
        "hiddenAchievementCount": len(achievements) - len(visible_ids),
        "dependencyClosureCount": len(dependency_ids),
        "hiddenDependencyCount": len(dependency_ids - visible_ids),
        "customVisibleAchievementCount": sum(1 for aid in visible_ids if aid >= 4900),
        "customDependencyCount": sum(1 for aid in dependency_ids if aid >= 4900),
        "categories": categories_sorted,
        "topCriteriaTypes": criteria_type_summary[:20],
        "notableCustomVisibleAchievements": [
            {
                "id": achievement_by_id[aid]["id"],
                "name": achievement_by_id[aid]["name"],
                "categoryID": achievement_by_id[aid].get("categoryID"),
            }
            for aid in sorted(visible_ids)
            if aid >= 4900 and aid in achievement_by_id
        ],
    }


def render_summary_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# Epoch Native Achievement Summary",
        "",
        f"- Generated: `{summary.get('generatedAt')}`",
        f"- Player: `{summary.get('player')}` on `{summary.get('realm')}`",
        f"- Build: `{summary.get('build', {}).get('version')}` (`{summary.get('build', {}).get('build')}`)",
        f"- Dumped achievements: `{summary.get('summary', {}).get('achievementCount')}`",
        f"- Visible achievements: `{summary.get('visibleAchievementCount')}`",
        f"- Hidden achievements: `{summary.get('hiddenAchievementCount')}`",
        f"- Dependency closure for visible achievements: `{summary.get('dependencyClosureCount')}`",
        f"- Hidden dependencies actually referenced by visible achievements: `{summary.get('hiddenDependencyCount')}`",
        f"- Visible custom achievements (`>= 4900`): `{summary.get('customVisibleAchievementCount')}`",
        "",
        "## Categories",
        "",
    ]

    for category in summary.get("categories", []):
        lines.append(
            f"- `{category['id']}` {category['name']}: "
            f"{category.get('numAchievements', 0)} visible achievements"
        )

    lines.extend(["", "## Top Criteria Types", ""])
    for item in summary.get("topCriteriaTypes", []):
        example = item.get("example") or {}
        lines.append(
            f"- Type `{item['criteriaType']}`: "
            f"{item['criteriaRows']} criteria rows across {item['achievementCount']} achievements; "
            f"example `{example.get('achievementName')}` -> `{example.get('description')}`"
        )

    lines.extend(["", "## Notable Custom Visible Achievements", ""])
    for achievement in summary.get("notableCustomVisibleAchievements", []):
        lines.append(f"- `{achievement['id']}` {achievement['name']}")

    return "\n".join(lines) + "\n"


def main() -> None:
    args = parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    saved_variables = load_saved_variables(input_path)
    dump = saved_variables["lastDump"]
    categories = dump["categories"]
    achievements = dump["achievements"]
    categories_by_id = index_categories(categories)
    visible_ids = visible_ids_from_categories(categories)
    achievement_by_id = {achievement["id"]: achievement for achievement in achievements}
    achievement_ids = set(achievement_by_id)
    dependency_ids = compute_dependency_closure(achievement_by_id, visible_ids)

    visible_achievements = [
        normalize_achievement(achievement_by_id[achievement_id], categories_by_id, visible_ids)
        for achievement_id in sorted(visible_ids)
        if achievement_id in achievement_by_id
    ]
    support_achievements = [
        normalize_achievement(achievement_by_id[achievement_id], categories_by_id, visible_ids)
        for achievement_id in sorted(dependency_ids - visible_ids)
        if achievement_id in achievement_by_id
    ]

    criteria_type_summary = summarize_criteria_types(achievements, achievement_ids, visible_ids)
    summary = build_summary(dump, categories, visible_ids, dependency_ids, criteria_type_summary)

    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    (output_dir / "summary.md").write_text(render_summary_markdown(summary), encoding="utf-8")
    (output_dir / "categories.json").write_text(
        json.dumps(categories, indent=2), encoding="utf-8"
    )
    (output_dir / "visible_achievements.json").write_text(
        json.dumps(visible_achievements, indent=2), encoding="utf-8"
    )
    (output_dir / "support_achievements.json").write_text(
        json.dumps(support_achievements, indent=2), encoding="utf-8"
    )
    (output_dir / "criteria_types.json").write_text(
        json.dumps(criteria_type_summary, indent=2), encoding="utf-8"
    )

    print(f"Wrote artifacts to {output_dir}")
    print(f"Visible achievements: {len(visible_achievements)}")
    print(f"Support achievements: {len(support_achievements)}")


if __name__ == "__main__":
    main()
