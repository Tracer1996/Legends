_G = _G or (getfenv and getfenv(0)) or {}

LATEST_VERSION = "18.9.3"
LEAFVE_STYLE = _G.LeafVE_Styles or {}
LEAFVE_UI_MODERN = _G.LeafVE_UIModernization or {}

SEP = "\31"
SECONDS_PER_DAY = 86400
SECONDS_PER_HOUR = 3600
OUTDATED_VERSION_POPUP_COOLDOWN = 24 * SECONDS_PER_HOUR
GROUP_MIN_TIME = 300
GROUP_COOLDOWN = 900
GROUP_POINT_INTERVAL = 3600
GUILD_ROSTER_CACHE_DURATION = 30
-- A guildmate is only treated as "confirmed departed" (and their Ashen
-- Ember/banner data purged) after being absent from this many consecutive
-- COMPLETE roster scans (see UpdateGuildRosterCache's SetGuildRosterShowOffline
-- toggle) AND at least this much real time has passed since they were first
-- noticed missing -- both conditions, not either, so a single dropped scan or
-- a normal multi-day absence can never trigger a purge on its own.
ROSTER_DEPARTURE_MIN_MISS_STREAK = 5
ROSTER_DEPARTURE_MIN_ELAPSED = 3 * SECONDS_PER_DAY
SHOUTOUT_MAX_PER_DAY = 2
WORK_ORDER_LOGIN_ALERT_COOLDOWN = 24 * SECONDS_PER_HOUR
LBOARD_RESYNC_COOLDOWN = 30
LBOARD_RESPOND_COOLDOWN = 30
MYSTATS_RESPOND_COOLDOWN = 5
MAX_FUTURE_EPOCH_OFFSET = 7 * SECONDS_PER_DAY
SHOUT_SYNC_RESPOND_COOLDOWN = 30
DEFAULT_ACHIEVEMENT_POINTS = 10
FULL_WIPE_GUILD_MARKER = "LVLFW"
FULL_WIPE_GUILD_MARKER_PATTERN = "%[" .. FULL_WIPE_GUILD_MARKER .. ":(%d+)%]"
FULL_WIPE_GUILD_MARKER_STRIP_PATTERN = "%s*%[" .. FULL_WIPE_GUILD_MARKER .. ":%d+%]%s*"

GEAR_BROADCAST_THROTTLE = 10
GEAR_CAPTURE_CACHE_WINDOW = 5
GEAR_REQUEST_THROTTLE = 8
GEAR_EVENT_DEBOUNCE = 0.2
GUILD_BANK_REFRESH_DEBOUNCE = 0.2
