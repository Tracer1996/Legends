-- GENERATED from AshenKeeper\AshenKeeper_Dialogue.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Modular RP dialogue. The Keeper sends only a short reference ("pool:index") over the wire;
-- every client resolves the text from its own QuartermasterDialogue pools, so lines can be
-- edited in AshenKeeper_Config.lua without changing the protocol.

AshenKeeper.Dialogue = AshenKeeper.Dialogue or {}
local AK = AshenKeeper
local D = AK.Dialogue

D.lastSaid = {}

-- Picks a random line index from a pool; returns "pool:index" or nil when disabled/empty.
function D.Ref(pool)
  if AK.db and AK.db.config and not AK.db.config.dialogue then return nil end
  local lines = QuartermasterDialogue[pool]
  if not lines or table.getn(lines) == 0 then return nil end
  return pool .. ":" .. math.random(table.getn(lines))
end

function D.Text(ref)
  if type(ref) ~= "string" then return nil end
  local colon = string.find(ref, ":", 1, true)
  if not colon then return nil end
  local pool = string.sub(ref, 1, colon - 1)
  local idx = tonumber(string.sub(ref, colon + 1))
  local lines = QuartermasterDialogue[pool]
  if not lines or not idx or not lines[idx] then return nil end
  return lines[idx]
end

-- Anti-spam: one line per pool per player every `cooldown` seconds (default 45).
function D.Allow(player, pool, cooldown)
  local key = tostring(player) .. ":" .. tostring(pool)
  local now = AK.Clock()
  local last = D.lastSaid[key]
  if last and (now - last) < (cooldown or 45) then return false end
  D.lastSaid[key] = now
  return true
end

-- Optional: Keeper also says a line in /say (the server may drop addon-initiated chat, so this
-- is off by default and the on-screen window text is the real RP channel).
function D.KeeperSay(text)
  if not text or not AK.db or not AK.db.config.dialogueSay then return end
  if type(SendChatMessage) == "function" then pcall(SendChatMessage, text, "SAY") end
end
