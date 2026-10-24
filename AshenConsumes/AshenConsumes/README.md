# Ashen Consumes (WoW Vanilla 1.12, Lua 5.0)

A movable consumable tracker, expiry reminders, and a one-item-at-a-time button for your warrior and other characters. No ClassicAPI/SuperMacro dependency.

## Install

Extract the folder `AshenConsumes` into `World of Warcraft/Interface/AddOns/` (so that `Interface/AddOns/AshenConsumes/AshenConsumes.toc` exists). Restart client or `/reload` after adding the folder. Enable Ashen Consumes in the character AddOns menu.

## First setup

1. Type `/ac` to open settings.
2. Click **Warrior Preset** to add suggested items, or **Add** to specify an item and its *actual player buff name*. Turn off or delete any default items you do not want to use.
3. Create a normal WoW macro with precisely:

   `/run AshenConsumes_UseNext()`

   Put the macro on your bar and press/spam it. Every successful press attempts **a maximum of one** ready consumable (selected in list order). You can also click the movable in-game **USE NEXT CONSUME** button.
4. When the buff is **missing** or has **300 seconds or less**, and the item exists and is not on cooldown, pressing the macro uses it. Buffs with more than 5 minutes remaining are never intentionally overwritten.
5. Drag the HUD or the large options window to move it. Press the `O` button on the HUD to edit your list.

**Warning:** This addon uses actual buffs not assumptions about items. The item's on-use aura can have a *different* name. Run `/ac buffs` while buffed to show the exact aura name and correct the row using `E`. Most buff rows are presets, *not verified for every custom OctoWoW spell*. Keep the 1st use under observation.

**Food:** Configure a food item with its real aura name, often `Well Fed`. Enable `Food (wait up to 12 sec)` in the row editor, to avoid pressing more consumables during eating. Different foods with identical `Well Fed` aura names cannot be distinguished from the buff's name alone. The user must select only the food they want.

**Shared buffs / cooldowns:** Don't configure incompatible consumes to refresh simultaneously. The addon can't bypass spell/item cooldowns, the food cast, combat restrictions, missing items, or server-side rules. Some custom items can also require a target; the addon attempts to target yourself when the normal item opens a targeting cursor.

## Commands

- `/ac` — Toggle settings.
- `/ac use` — Attempt one consumable (alternative to the keybind).
- `/ac buffs` — List actual helpful buff names and durations, to aid matching.
- `/ac list` — Show priority and currently configured mappings.
- `/ac add Elixir of the Mongoose ; Elixir of the Mongoose` — Add item and buff names separated by a semicolon.
- `/ac remove 3` — Remove item #3.
- `/ac preset` — Add missing warrior preset items (doesn't duplicate matching names).
- `/ac threshold 300` — Adjust refresh threshold in **seconds**.
- `/ac sound` — Toggle warning audio.
- `/ac hud` — Toggle mini HUD.

Notes: Order matters (top to bottom); `^` moves a row up, `X` deletes it, `E` edits it, and the checkbox enables/disables it. Use `Previous` and `Next` to page through items. Config is saved per character. Audio and on-screen alerts are throttled, and the list is scanned on a low-frequency timer rather than continuously.

## Known limitations

- Tested by syntax/static inspection only, not live inside OctoWoW. If a buff has a different effect tooltip name, edit that name; `/ac buffs` is the reliable inspector.
- Buff names are matched exactly (case insensitive), not by texture, so similarly named buffs don't silently stand in for each other.
- Food and target-sensitive custom consumes may require realm-specific tweaks.
- `/run` macro is recommended rather than relying on the legacy `/click` macro implementation.
