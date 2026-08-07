# The Ashen Banner — WoW 1.12 Addons

Two companion addons built for **The Ashen Banner** guild, targeting the Vanilla/Turtle-era `Interface: 11200` client (covers OctoWoW and other Turtle-WoW-based servers). Not compatible with modern retail clients.

| Addon | Folder | Title in-game | What it does |
|---|---|---|---|
| **LeafVillageLegends** | `LeafVillageLegends/` | *The Ashen Banner* | Guild utility suite — roster/dossier UI, gear tracking, group tracking, raid sign-ups, work orders, badges/leaderboard, crafting & spell databases, Discord bridge. |
| **LeafVillageAchievements** | `LeafVillageAchievements/` | *Ashen Banner Achievements* | Standalone achievement, title, and collection tracker — 340+ achievements, a title system, and dedicated Mounts/Companions/Toys collection tabs. See [`LeafVillageAchievements/README.md`](LeafVillageAchievements/README.md) for the full feature list and slash commands. |

Both are independent — you can install either one on its own — but they're built to sit alongside each other for the same guild, and share the `Interface: 11200` target and `LeafVE_*` naming conventions.

---

## Installation

Each addon lives in its own top-level folder here, already named to match its `.toc` file. Copy whichever one(s) you want straight into your WoW client's `Interface/AddOns/` directory — no build step, no renaming needed.

```
World of Warcraft/
└── Interface/
    └── AddOns/
        ├── LeafVillageLegends/          (copy of this repo's LeafVillageLegends/ folder)
        └── LeafVillageAchievements/     (copy of this repo's LeafVillageAchievements/ folder)
```

1. Download or clone this repository.
2. Copy `LeafVillageLegends/` and/or `LeafVillageAchievements/` into `Interface/AddOns/`, keeping each folder's name and internal structure exactly as-is (the folder name must match the `.toc` inside it).
3. Complete the ClassicAPI installation steps below — LeafVillageAchievements requires it (see [Required: ClassicAPI](#required-classicapi)).
4. Launch the game (or `/reload` if it's already running) and confirm the addon(s) are checked at the AddOns list on the character-select screen.
5. Log in. LeafVillageAchievements adds a minimap button (click to open/close); LeafVillageLegends' UI is reached through its own in-game commands — see that addon's own docs/comments for specifics.

---

## Required: ClassicAPI

[ClassicAPI](https://github.com/brues-code/ClassicAPI) is a **client-side DLL patch** (not a normal `Interface/AddOns` addon) that LeafVillageAchievements requires for full functionality. It backports modern API namespaces onto this 1.12 client that don't exist there natively, and this addon leans on two of them:

- **Item icons** — `GetItemIcon(itemID)` resolves icons for mounts/companions/toys you haven't collected yet directly from item data, instead of needing a slower `GetItemInfo` server round-trip or a tooltip-scan fallback.
- **Maps** — `C_Map` (`GetAreas`, `GetMapOverlays`, `GetAreaInfo`) and `C_MapExplorationInfo` (`GetExploredMapTextures`) power the addon's live per-zone exploration achievements and the in-game Zone Map view: real subzone names and real fog-of-war explored state pulled straight from the server's own map data, so already-explored areas are credited immediately instead of only picking up new areas from the next zone change onward.

Without ClassicAPI, these systems have nothing to read from, so install it before using LeafVillageAchievements.

### Installing it (from the [ClassicAPI README](https://github.com/brues-code/ClassicAPI#installation))

1. Install [VanillaFixes](https://github.com/brues-code/VanillaFixes) if you don't already have it — ClassicAPI loads through it.
2. Download the prebuilt `ClassicAPI.dll` from the [latest release](https://github.com/brues-code/ClassicAPI/releases/latest).
3. Copy `ClassicAPI.dll` into your WoW game directory (next to `Wow.exe`).
4. Add `ClassicAPI.dll` to `dlls.txt` (same directory) so VanillaFixes loads it.
5. Launch the game via `VanillaFixes.exe` instead of `Wow.exe` directly.

Nothing needs installing or enabling on the addon side — ClassicAPI's Lua library is embedded in the DLL and registers itself automatically once the game loads. (For local development against it, you can drop a copy in `Interface/AddOns/!!!ClassicAPI/`, which takes priority over the embedded version — not needed for normal use.)

---

## Troubleshooting

- **Addon doesn't appear in the AddOns list:** check the folder name in `Interface/AddOns/` matches the `.toc` name exactly (`LeafVillageLegends` or `LeafVillageAchievements`) and directly contains the `.toc` file, not nested a level deeper.
- **No minimap button after logging in (LeafVillageAchievements):** check for a Lua error on load (`/console scriptErrors 1` then `/reload`) — a load-time error will silently stop the addon from finishing setup.
- **Uncollected mount/companion/toy icons show a "?" placeholder:** install ClassicAPI per above (see [Required: ClassicAPI](#required-classicapi)) — without it, icon lookups fall back to a slower method that doesn't cover custom server-only items.
- **Zone Map / live exploration achievements show no data:** these read directly from ClassicAPI's `C_Map`/`C_MapExplorationInfo` APIs, which don't exist on this client otherwise — install ClassicAPI per above.
