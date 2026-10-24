# Ashen Consumes 2.1 (WoW Vanilla 1.12, Lua 5.0)

Compact consumable tracker with a one-item-per-press refresh button. No dependencies.

## Tracking consumables (no typing)

Any of these work:

- **Alt + Right-click** an item in your bags to track it (do it again to stop tracking).
- **Drag** an item from your bags onto the HUD or the settings window.
- Open `/ac` and **click an icon** in the *In your bags* section. It lists only consumables
  with a timed buff; switch the filter to *all usable* to see everything with a Use: effect.

The buff name is filled in for you:
- Common raid consumes (flasks, elixirs, Jujus, Zanza, Scorpok, etc.) are already known.
- Food is detected from its tooltip and watches **Well Fed**.
- Anything else is confirmed automatically the first time you use it: the addon sees which
  buff appeared and saves it (shown as "(auto-detect)" until then).
- To change it by hand, click the row in `/ac` and pick from your current buff icons.

## Lineup, stock and sorting

- Every lineup row shows how many you carry, e.g. `2 / 5 in bags`. Click a row to set
  **Keep in bags** (0 = don't check).
- The red **Missing:** line under the lineup is your shopping list, and you also get it in chat
  a few seconds after logging in.
- The **Sort** button cycles between priority, A-Z, missing first and time left. Sorting only
  changes how the list is shown; the use order is always the priority order (`+` / `-`).

## Things that don't stack

Consumes that overwrite each other can't both be in the lineup (adding the second is refused
with a message, and it's shown greyed with a red border in the bag grid). Built in: flasks;
Rumsey Rum / Gordok Green Grog / Merlot; Mongoose / Greater Agility; Giants / Juju Power;
Juju Might / Winterfall Firewater; the Zanza drinks; defense elixirs; arcane elixirs;
firepower elixirs; and any two foods. Anything else is learned automatically: if using one
item knocks another tracked buff off, the pair is remembered. Even if an older lineup has a
clash, the addon never uses an item while a clashing buff is active.

## Using

Macro: `/run AshenConsumes_UseNext()`. Each press uses at most one consumable whose buff is
missing or under the refresh threshold (default 5 min), top of the list first.

HUD (footer button cycles bar / single / hidden). **Single** is one square: the next item to
use (pulsing), red if something's missing, otherwise whatever falls off next with its timer
and a green check, or just a green check when everything has plenty of time. Hover it for the
whole lineup. In **bar** mode the big icon on the left is "use next". The small icons are your tracked buffs with time
left underneath. Click one to use that specific item; right-click or the gear opens settings.
Border colours: pulsing yellow = needs a refresh, red = none in bags, dim = on cooldown.

## Settings window (`/ac`)

- Checkbox enables/disables a row; `+` / `-` changes priority; `x` stops tracking.
- Mouse wheel scrolls the list and the bag grid.
- Footer: refresh threshold (- / +), sound toggle, warrior preset.

## Commands

`/ac` settings · `/ac use` · `/ac buffs` · `/ac list` · `/ac add Item [; Buff]` ·
`/ac remove N` · `/ac preset` · `/ac threshold SECONDS` · `/ac sound` · `/ac hud`

## Limitations

- The addon can't bypass cooldowns, the food channel, combat rules or missing items.
- Different foods share the Well Fed buff, so only track the one food you want to eat.
- Buff names are matched exactly (case-insensitive).
