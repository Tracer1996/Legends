# Ashen Banner Achievements

**Version:** 4.1.3 · **Interface:** 11200 (Vanilla WoW / Turtle-WoW-era 1.12, e.g. OctoWoW)
**Guild:** The Ashen Banner

A comprehensive, self-contained achievement, title, and collection tracker.
Track your progress across leveling, exploration, dungeons, raids, PvP, professions, kills, quests, reputation, gold, guild rank, and more, plus full Mounts, Companions, and Toys collection tabs — all stored locally with no external dependencies beyond [ClassicAPI](https://github.com/brues-code/ClassicAPI) (see the [repo root README](../README.md) for why it's required and how to install it).

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Slash Commands](#slash-commands)
- [Minimap Button](#minimap-button)
- [Achievement Categories](#achievement-categories)
- [Collections: Mounts, Companions, Toys](#collections-mounts-companions-toys)
- [Titles System](#titles-system)
- [Guild Chat Integration](#guild-chat-integration)
- [SavedVariables](#savedvariables)
- [File Structure](#file-structure)
- [Contributing / Extending](#contributing--extending)
- [Recent Highlights](#recent-highlights)

---

## Features

- **600+ achievements** across leveling, quests, professions, skills, dungeons, raids, exploration, PvP, gold, elite/casual milestones, guild rank, roleplay, kills, identity, reputation, and legendary meta-achievements — plus a full achievement per collectible mount, companion, and toy.
- **Summary tabs** for both Achievements and Titles — recent unlocks and per-category progress bars at a glance, instead of scrolling the full list.
- **Grouped sidebar navigation** — categories are organized into labeled sections (Character, Content, Collections, Guild & Community, Milestones) rather than one flat list.
- **Mounts / Companions / Toys collection tabs** — dedicated card-grid pages with search and filters, spellbook-scan detection (learned-only, not just sitting in a bag), and real item icons resolved even before you've collected something.
- **Titles system** — earned from achievements (including dedicated milestone tiers for Mounts, Companions, and Toys), guild rank promotions, and legendary feats. Your selected title appears before your name in guild chat.
- **Zone Map & live exploration tracking** — real subzone names and fog-of-war-accurate discovery state pulled from the server's own map data (via ClassicAPI's `C_Map`/`C_MapExplorationInfo`), so already-explored areas are credited immediately.
- **Minimap button** — click to open/close the UI; drag to reposition (angle is saved across sessions).
- **Dungeon & raid progress tracking** — boss-by-boss criteria tracked per dungeon/raid, with full-clear meta-achievements.
- **Kill counter** — generic enemy kills and named mob/critter milestones.
- **Profession & skill mastery** — detects the 300-skill cap in every primary/secondary profession and tracked skill.
- **Reputation tracking** — Revered/Exalted milestones across Alliance, Horde, and neutral factions.
- **Quest chain tracking** — multi-step quest chains tracked step by step via system messages.
- **Guild rank achievements & titles** — rank-up achievements with silent login backfill (no spurious announcements) and auto-equipped titles.
- **Guild officer commands** — `/achgrant` and `/achgrantguild` let officers credit players for pre-addon completions.
- **Debug mode** — toggle verbose logging with `/achtestdebug`.

---

## Installation

See the [repo root README](../README.md) for full install instructions covering both addons in this repository and the required ClassicAPI setup. Short version:

1. Copy this `LeafVillageAchievements/` folder into your WoW `Interface/AddOns/` directory, keeping its name and internal structure exactly as-is:
   ```
   World of Warcraft/
   └── Interface/
       └── AddOns/
           └── LeafVillageAchievements/
               ├── LeafVillageAchievements.toc
               ├── LeafVillageAchievements.lua
               ├── LeafVillageAchievementsCollections.lua
               ├── LeafVillageAchievementsCollectionsPortraits.lua
               └── data/
                   ├── LeafVE_ConsumablesDB.lua
                   ├── LeafVE_Ach_Kills.lua
                   ├── LeafVE_Ach_Skills.lua
                   ├── LeafVE_Ach_Identity.lua
                   ├── LeafVE_Ach_Roleplay.lua
                   ├── LeafVE_Ach_Reputation.lua
                   ├── LeafVE_Ach_Quests.lua
                   ├── LeafVE_Ach_QuestRewards.lua
                   ├── LeafVE_Ach_Companions.lua
                   ├── LeafVE_Ach_Mounts.lua
                   ├── LeafVE_Ach_Toys.lua
                   ├── LeafVE_Ach_Probe.lua
                   └── LeafVE_Ach_ExplorationLive.lua
   ```
2. Install [ClassicAPI](https://github.com/brues-code/ClassicAPI) — **required**, not optional (see the root README for why and how).
3. Log in. A minimap button appears once the addon finishes loading.

> **Compatibility:** This addon targets Interface version `11200` (Vanilla / 1.12.x).
> It uses the Vanilla API (`this`, `arg1`, `event` handler globals) and is not compatible with modern WoW clients.

---

## Slash Commands

| Command | Description |
|---|---|
| `/achtest` | Open the Achievements UI. |
| `/leafach` | Open the Achievements UI (alias for `/achtest`). |
| `/achtestdebug` | Toggle debug/verbose logging on or off. |
| `/achsync` | Broadcast your earned achievements to the guild channel. |
| `/achgrant <Player> <achievementId>` | *(Officer only)* Manually award an achievement to a player, silently. |
| `/achgrantguild <Player> <achievementId>` | *(Officer only)* Same as `/achgrant`, but announces the grant to the guild. |
| `/abcoll [scan\|dump\|open\|help]` | Collections module commands — rescan your spellbook for mounts/companions/toys, dump detected entries, or open the collection window. `/ashencoll` is an alias. |
| `/achprobe` | Diagnostic probe for troubleshooting achievement/data issues. |

**Officer ranks** recognized for `/achgrant`, `/achgrantguild`, and admin panel access: **Anbu, Sannin, Hokage** (legacy ranks) and **Flame, Flame Keeper, Banner Warden, Oath Captain** (current Ashen Banner ranks).

**`/achgrant` examples:**
```
/achgrant Naruto dung_rfc_complete
/achgrant Sakura raid_mc_complete
```
If you omit the `dung_` or `raid_` prefix, the command will try to add it automatically.

A handful of additional slash commands exist purely for development/testing (`/ashenrowtest`, `/ashenuittest`, `/achpopdebug`, `/achtoast`, `/leafzonedebug`) — not intended for normal play.

---

## Minimap Button

A draggable button is placed on the minimap when the addon loads.

- **Left-click** — Toggles the Achievements UI open or closed.
- **Drag** — Repositions the button around the minimap edge. The angle is saved to `LeafVE_AchTest_DB.minimapAngle` and restored on the next login/reload.
- **Hover** — Shows a tooltip with click/drag instructions.

---

## Achievement Categories

The Achievements sidebar groups categories into sections:

**Character** — Leveling, Professions, Skills, Identity (race/class, awarded automatically on login).
**Content** — Quests, Dungeons, Raids, Exploration, PvP.
**Collections** — Mounts, Companions, Toys (see [below](#collections-mounts-companions-toys)).
**Guild & Community** — Guild (rank progression, emote achievements with guild NPCs), Roleplay, Reputation.
**Milestones** — Gold, Elite (high-difficulty repeat-clear tiers), Casual (social/lifestyle goals), Kills, Legendary (rare feats with unique guild-wide announcements and exclusive titles).

A **Summary** view sits above all of these — recent unlocks plus a progress bar per category, with click-through to jump straight to any achievement in the full list.

---

## Collections: Mounts, Companions, Toys

Three dedicated tabs, each with its own card-grid page, search bar, and filter sidebar:

- **Mounts** — every collectible mount, detected via spellbook scan. Individual achievements plus milestone tiers (10/25/50/75/100/all), each with its own title (Rider → Horseman → Cavalier → Steedmaster → Stablemaster → Ridemaster).
- **Companions** — same pattern for companion pets. Milestone titles: Tender → Handler → Tamer → Wrangler → Menagerist → Petmaster.
- **Toys** — categorized into Music/Novelty/Utility/Ambience. Milestone titles: Jester → Trickster → Showman → Toymaster.

All three award their achievement only once the mount/pet/toy is actually learned (not just sitting in a bag or the bank), and pull real item icons — including for things you haven't collected yet — via ClassicAPI, falling back to a slower `GetItemInfo`/tooltip-scan method if it's unavailable.

---

## Titles System

Titles come from three sources: regular achievements, guild rank progression, and collection milestones (Mounts/Companions/Toys, see above).

- Open the UI and navigate to the **Titles** tab (its own Summary view and grouped sidebar mirror the Achievements tab).
- Select a title to make it active — it appears before your name in guild chat, colored by category (orange for most, red for Legendary, brown for Guild).
- Guild rank titles auto-equip on login/rank-up if you don't already have a different title selected — this applies retroactively too, so existing members at a given rank don't need to re-rank to pick it up.

---

## Guild Chat Integration

When a title is active, the addon hooks `SendChatMessage` to prepend your title to **guild** channel messages only:

```
[The Explorer] Naruto: Has anyone done RFC today?
```

The hook installs 3 seconds after `PLAYER_ENTERING_WORLD` to avoid interfering with addon load. It only touches `GUILD` channel messages.

---

## SavedVariables

All data persists in `LeafVE_AchTest_DB` (per-character):

| Key | Description |
|---|---|
| `achievements` | Earned achievements per player character. |
| `collections` | Scanned mount/companion/toy icons and metadata. |
| `collectionSettings` | Collections UI filter/search/page state. |
| `companionTracker` / `toyTracker` | Spellbook-scan seed/state for companions and toys. |
| `mountCollection` / `mountModelOverrides` | Mount collection state and per-mount model tuning. |
| `exploredZones` / `zonesVisited` | Discovered zones/subzones and visited-zone tracking. |
| `selectedTitles` | Currently active title per player character. |
| `dungeonProgress` / `raidProgress` | Per-dungeon/raid boss kill tracking. |
| `progressCounters` / `progressCache` | Generic numeric counters and cached progress values. |
| `completedQuests` | Completed quest chain steps. |
| `peakGold` / `goldEarnedTotal` / `goldLastSeen` | Gold milestone tracking. |
| `reputationSnapshot` / `reputationStats` | Faction reputation tracking. |
| `guildRankState` | Guild rank backfill/seeding state. |
| `minimapAngle` | Saved minimap button angle (0–360°). |
| `versionInfo` | Version-reminder tracking. |

---

## File Structure

```
LeafVillageAchievements/
├── LeafVillageAchievements.toc                    — AddOn manifest (Interface, SavedVariables, file list)
├── LeafVillageAchievements.lua                     — Core addon: UI, events, minimap button, slash commands
├── LeafVillageAchievementsCollections.lua          — Mounts/Companions/Toys collection UI module
├── LeafVillageAchievementsCollectionsPortraits.lua — Collection portrait/icon overrides
└── data/
    ├── LeafVE_ConsumablesDB.lua      — Consumables item database
    ├── LeafVE_Ach_Kills.lua          — Kill-based achievement definitions and handlers
    ├── LeafVE_Ach_Skills.lua         — Skill/profession achievement definitions and handlers
    ├── LeafVE_Ach_Identity.lua       — Race and class achievement definitions and handlers
    ├── LeafVE_Ach_Roleplay.lua       — Roleplay/emote achievement definitions and handlers
    ├── LeafVE_Ach_Reputation.lua     — Faction reputation achievement definitions and handlers
    ├── LeafVE_Ach_Quests.lua         — Quest chain achievement definitions and handlers
    ├── LeafVE_Ach_QuestRewards.lua   — Quest reward item data
    ├── LeafVE_Ach_Companions.lua     — Companion collection catalog, achievements, and titles
    ├── LeafVE_Ach_Mounts.lua         — Mount collection catalog, achievements, and titles
    ├── LeafVE_Ach_Toys.lua           — Toy collection catalog, achievements, and titles
    ├── LeafVE_Ach_Probe.lua          — Diagnostic probe tooling
    └── LeafVE_Ach_ExplorationLive.lua — Live zone/subzone exploration achievements (requires ClassicAPI's C_Map)
```

---

## Contributing / Extending

### Adding a new achievement

1. Call `LeafVE_AchTest:AddAchievement(id, data)`, or add an entry directly to the `ACHIEVEMENTS` table in `LeafVillageAchievements.lua`.
2. Fill in the required fields:
   ```lua
   ACHIEVEMENTS["my_ach"] = {
     id       = "my_ach",
     name     = "My Achievement",
     desc     = "Do the thing.",
     category = "Casual",   -- must match an existing category
     points   = 10,
     icon     = "Interface\\Icons\\INV_Misc_QuestionMark",
   }
   ```
3. Award it in the appropriate event handler:
   ```lua
   LeafVE_AchTest:AwardAchievement("my_ach")
   ```

### Adding a new data file

1. Create `data/LeafVE_Ach_MyCategory.lua`.
2. Register achievements with `LeafVE_AchTest:AddAchievement(...)`.
3. Add the file path to `LeafVillageAchievements.toc`, **before** `LeafVillageAchievements.lua` if it needs to run early, otherwise after it — check load-order comments in the `.toc` for files with cross-dependencies (e.g. `LeafVillageAchievementsCollections.lua` must load last, since it reads master lists other data files publish).

### Debug mode

Enable verbose logging at any time:
```
/achtestdebug
```
All debug messages are prefixed with `[DEBUG]`.

---

## Recent Highlights

This addon has grown substantially past its original v1.x feature set — full version history lives in `git log` rather than a hand-maintained changelog here. Recent additions include: the Toys collection tab; Mount/Companion/Toy milestone titles with per-tier icons; Achievements/Titles Summary tabs; the grouped/redesigned sidebar; item-database-backed icon resolution for mounts, companions, and toys (including uncollected ones); and a round of guild-rank title/backfill and jump-to-achievement scrolling fixes.
