# LeafVE Discord Bridge

This bridge watches Turtle WoW chat logs and forwards LeafVE guild badge announcement lines to Discord through an incoming webhook.

## What it does

- Only posts guild-style LeafVE badge announcement lines
- Ignores LeafVE achievement announcements
- Strips WoW color and hyperlink markup before sending
- Uses the webhook configured in `LeafVE.DiscordBridge.config.json`

## Files

- `LeafVE-DiscordBridge.ps1`: watcher script
- `LeafVE.DiscordBridge.config.json`: local config
- `Start-LeafVE-DiscordBridge.cmd`: simple launcher for Windows

## How to run

1. Start WoW and log in with LeafVillageLegends enabled.
2. The addon now auto-enables chat logging on login.
3. Run `Start-LeafVE-DiscordBridge.cmd`.
4. Leave that window open while you play.

## Notes

- The webhook URL in the config is a secret. Do not share or commit that file publicly.
- Default log path is `C:\Games\TurtleWoW\Logs\WoWChatLog.txt`.
- If Turtle WoW writes a differently named chat log, the script will fall back to the newest `WoWChatLog*.txt` file in the same folder.
