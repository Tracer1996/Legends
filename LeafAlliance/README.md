# LeafAlliance

A World of Warcraft **1.12 / Lua 5.0** addon that helps players work with the custom `Alliance` chat channel.

---

## Features

- Automatically attempts to join the `Alliance` channel on login
- Automatically joins `Alliance` with the password `Turtleboys`
- Attempts to enforce the `Alliance` channel password after joining so the channel stays protected when this client owns the channel
- Suppresses local `Alliance` join/leave channel notices, including your own join and leave system messages
- When this client is the first member creating the channel on login/join, it also toggles custom-channel announcements off so other players do not see join/leave spam either
- **Locally restyled Alliance channel lines** - every chat message received on the `Alliance` channel is displayed with:
  - A yellow **[Alliance]** channel tag
  - Yellow linked text after the prefix, including the sender and message
- Uses custom clickable link formatting for styled chat text:
  - Yellow channel display
  - Yellow linked chat text
  - Tooltip text: **Alliance Chat**
- If `Prat-V` is installed, the numeric custom-channel tag (such as `[6]`) is renamed visually to `[Alliance]` for the active Alliance channel slot

---

## Compatibility

| Requirement | Version |
|---|---|
| WoW client | 1.12 (vanilla) |
| Lua | 5.0 |

---

## Installation

1. Download or clone this repository.
2. Copy the `LeafAlliance` folder into your WoW addons directory:
   ```
   World of Warcraft/Interface/AddOns/LeafAlliance/
   ```
3. The folder must contain at minimum:
   - `LeafAlliance.toc`
   - `LeafAlliance.lua`
4. Launch the WoW 1.12 client.
5. On the character-selection screen, click **AddOns** and make sure **LeafAlliance** is enabled.
6. Log in - the addon will attempt to join the `Alliance` channel automatically.

---

## Notes

- The addon attempts to join the `Alliance` channel each time you log in.
- The addon joins `Alliance` with the password `Turtleboys`.
- After joining, the addon also attempts to call `SetChannelPassword("Alliance", "Turtleboys")`. This keeps the channel protected when the player running the addon is the current channel owner.
- All local `Alliance` join/leave notices are suppressed so your chat frame stays clean.
- Channel-wide join/leave announcement suppression for **everyone** can only be changed by the channel owner or a moderator. This addon safely toggles those announcements off only when it can tell the channel was just created by this login/join pass (for example, when this player is the first and only member in the channel).
- **Local styling only** - the yellow `[Alliance]` label and yellow linked chat text are applied only in your own chat frame. Other players see the messages in their default channel color. Message sending and `/N` routing are not affected.

---

## File Overview

| File | Purpose |
|---|---|
| `LeafAlliance.toc` | Addon metadata (interface version, title, file list) |
| `LeafAlliance.lua` | All addon logic |

---

## Behavior on Login

1. Waits for default channel slots to be ready, then calls `JoinChannelByName("Alliance", "Turtleboys")` so `Alliance` does not take over `/1` (`General`) and uses the configured password automatically.
2. Detects and caches the assigned `Alliance` channel ID dynamically by scanning the current channel list (does not assume channel `1`) and applies the channel color as yellow.
   - If `Prat-V` ChannelNames is present, the addon remaps that live channel slot from `[N]` to `[Alliance]`.
3. Re-hooks `ChatFrame_MessageEventHandler` after login and on channel UI refresh so later-loading chat addons do not take back the channel renderer, then:
   - Re-add `Alliance` to the visible chat frames manually, allowing the addon to suppress `JOIN`, `LEAVE`, `YOU_JOINED`, and `YOU_LEFT` `Alliance` notices locally without losing channel visibility.
   - Intercept `CHAT_MSG_CHANNEL` events for the `Alliance` channel, suppress the default rendered line, and re-print a locally styled replacement: **[Alliance]** in yellow with yellow linked sender/message text.
4. Attempts to enforce the `Alliance` password after joining and, when this player is creating a fresh one-member custom channel, toggles channel announcements off for everyone in that channel.
5. Overrides `SetItemRef` so that clicking the custom Alliance chat links shows a tooltip with the text **Alliance Chat**.
6. Prints a confirmation message in the default chat frame.
