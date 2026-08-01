ASHEN BANNER ACHIEVEMENTS v4.0.2
================================

This is one standalone addon.

Install only:
  Interface\AddOns\LeafVillageAchievements\

Delete or disable the old AshenBannerCollections folder. Its 2D mount and
companion collection system is now loaded as internal LeafVillageAchievements
modules, so there is no second addon or dependency.

Included in the single addon:
- Achievements and titles
- Mount and companion collection cards
- Independent search and source filters for each collection tab
- Spellbook collection detection
- Individual mount and companion achievements
- 25 / 50 / 75 / 100 point difficulty tiers
- Collection milestone achievements
- Summon/call buttons for learned collection spells

v4.0.1 UI corrections:
- Companion scrolling can no longer reveal recycled achievement rows.
- The existing Mounts tab is reused instead of creating a duplicate label.
- Collection tabs clear stale achievement-list state before drawing cards.

Saved data:
- Existing LeafVE_AchTest_DB achievement progress is preserved.
- Collection UI settings save under LeafVE_AchTest_DB.collectionSettings.

Legacy /abcoll utility commands still operate inside this addon.


v4.0.2 mount audit and sidebar corrections:
- Removed 11 confirmed OctoWoW equipment/export anomalies from the mount journal.
- Purges those invalid rows from existing saved collection data on login/rescan.
- Unknown spellbook mounts now require a real summon/rideable tooltip; generic
  mount-speed equipment effects can no longer generate mount entries.
- Both collection sidebars are hidden before the active sidebar is shown,
  preventing category lists from overlapping after tab changes.
