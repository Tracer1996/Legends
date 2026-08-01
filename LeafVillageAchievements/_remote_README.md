<img src="https://i.ibb.co/z1W5z0T/a.gif"/>

# Relationships Achievements

A **WotLK-style achievement system** for **OctoWoW**.

250+ achievements · 20 categories · gold-banner toast on unlock · WotLK-style panel · fully save-persistent

---

## What it does

Vanilla WoW never shipped with an achievement system — it arrived with
Wrath of the Lich King. Relationships Achievements brings that entire
experience back to the 1.12 client:

- A **WotLK-look panel** with a category list on the left, an overall
  progress bar across the top (`53 / 148 achievements`), and per-row
  progress bars for counted goals (`33 / 100`).
- A **gold-banner toast** that pops on unlock, plays the level-up sound,
  and prints a clickable chat link.
- A **Summary landing page** with your most recent unlocks, dates, and
  point totals.
- A **character scan** that runs every login so retroactive progress
  (levels, guild, tabard, exalted reps, profession skill, visited zones,
  PvP rank, gold in bag) is credited even if you install the addon on
  a character that has already been played for years.

Everything is stored in `SavedVariables`, split between account-wide
credits (e.g. *The Stormwind Rendezvous*, *Shell of a Time*) and
per-character progress (levels, professions, exploration, PvP rank).

---

## Features

### The panel

- Opens with **`Y`** by default (only bound if the key is free), the
  `/rach` slash command, or the `TOGGLERELATIONSHIPSACHIEVEMENT`
  keybinding.
- 20 categories: **General · Character · Quests · Exploration · Player
  vs. Player · Dungeons & Raids · Professions · Reputation · World Events
  · Class · Collections · Fishing · Cooking · Hardcore · Social · Cities ·
  Titles · Legacy · OctoWoW · Feats of Strength**.
- Every category shows `earned / total` next to its name.
- Achievement rows display the icon, name, description, points, unlock
  date, and — for counted goals — a green progress bar with the current
  count rendered on top of the fill.

### The toast

- Fades in at the top-center of the screen on any unlock.
- Shows icon, achievement name, and point value.
- Clickable — opens the achievement detail popup.
- Plays `Sound\Interface\LevelUp.wav`.
                           |

### Slash commands

| Command                | What it does                                       |
| ---------------------- | -------------------------------------------------- |
| `/rach`                | Toggle the achievement panel                       |
| `/rach scan`           | Force a full character rescan right now            |
| `/rach points`         | Print your total point score in chat                |
| `/rach reset`          | **Wipe** all achievement data (account + char)     |
| `/rach test`           | Preview the unlock toast                           |
| `/rach unlock <id>`    | Force-unlock a specific achievement (debug)        |
| `/rach help`           | List the commands above                            |

Aliases: `/rach` = `/relach` = `/relationshipsachievements`.

---

## Categories at a glance

| # | Category            | Examples                                                                              |
| - | ------------------- | ------------------------------------------------------------------------------------- |
| 1 | General             | The Stormwind Rendezvous, Making Friends, Guild Member, Big Spender, Represent, Trainee |
| 2 | Character           | Level 5 → 60 (every 5 levels), First Death, Bloody Rare, The Butcher, Weapon Master, Deep Pockets, Wealthy, Made of Money |
| 3 | Quests              | 1 → 2,000 quests, Loremaster of Elwynn / Durotar, Class Quest Hero, Group Effort      |
| 4 | Exploration         | Every zone in Eastern Kingdoms + Kalimdor + Well Traveled (10) + World Explorer (40) |
| 5 | Player vs. Player   | First Blood, 100 / 1,000 / 10,000 HKs, Warsong / Alterac / Arathi victories + marathons, Duelist / Grand Duelist, Bloodthirsty, Battleground Regular |
| 6 | Dungeons & Raids    | All 22 vanilla 5-man end bosses, MC, Onyxia, BWL, ZG, AQ20, AQ40, Naxxramas, Classic Dungeonmaster (22), Classic Raider (5) + attunements |
| 7 | Professions         | Apprentice → Artisan, Master of every primary profession + First Aid                  |
| 8 | Reputation          | Friendly / Honored / Revered / Exalted, Somebody Likes Me (5), Ambassador (10), Argent Dawn, Thorium Brotherhood, Timbermaw, Cenarion Circle, Brood of Nozdormu, Zandalar, Hydraxian |
| 9 | World Events        | Winter Veil, Midsummer, Hallow's End, Noblegarden, Love is in the Air, Children's Week, Harvest Festival, Lunar Festival, Brewfest, Darkmoon Faire |
| 10| Feats of Strength   | Scarab Lord, Grand Marshal, High Warlord, Atiesh, Thunderfury, Sulfuras                |
| 11| Class               | Reach 60 on each class · Trained · Talented · Fully Specialized · Respec'd            |
| 12| Collections         | Pack Rat, Bag Full of Bags, Little Friends, Menagerie, Stable Master, Leading the Cavalry, Well Equipped, Epic |
| 13| OctoWoW             | Shell of a Time, High Elf Ally, Goblin Trader, Karazhan Crypt, Emerald Sanctum, OctoWoW Hero |
| 14| Fishing             | First Catch, Fisherman (150), Master Angler (300), Deadliest Catch, Old Gnome and the Sea (500) |
| 15| Cooking             | First Dish, Sous Chef, Master Cook, Iron Chef (25 recipes), Gourmet                   |
| 16| Hardcore            | One Life to Live, Survivor, Untouchable, Hardcore Hero, Close Call, No Retreat        |
| 17| Social              | Say Hello (/wave), Dance Off (/dance), Guildmate, Popular, Chatty, Group Therapy, Wedding Bells |
| 18| Cities              | Every capital + Alliance Tourist / Horde Tourist meta                                 |
| 20| Titles              | Private / Sergeant / Knight / Champion / Marshal / Field Marshal, Elder, The Diplomat |
| 21| Legacy              | Classic Combatant, Old World Traveler, Blackrock Veteran, Ony Head Turn-In, AQ Gate Opener, Silithyst Runner, Dire Maul Book Club |

---

## Install

1. Download or clone this repository.
2. Copy the `RelationshipsAchievements` folder into your WoW install:
   ```
   Interface/AddOns/RelationshipsAchievements/
   ```
3. Log out to character select (or restart the client), enable
   **Relationships Achievements** in the AddOns list, then log in.
4. Press **Y** or type **`/rach`** to open the panel.

The first login runs a full character scan after ~2 seconds, so any
progress you already had (levels, guild, tabard, professions, exalted
reps, visited zones, PvP rank, gold) unlocks retroactively.