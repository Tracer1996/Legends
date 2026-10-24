-- GENERATED from AshenKeeper\AshenKeeper_Core.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- AshenKeeper: core utilities, database, scheduler, identity, mode detection.
-- WoW 1.12 / Lua 5.0 only: no '#' operator, no '%' operator, no string.gmatch, no varargs tricks.

AshenKeeper = AshenKeeper or {}
local AK = AshenKeeper

AK.VERSION = "1.3.2"          -- this client / Keeper version (sent as v / kv)
AK.MIN_CLIENT = "1.3.1"       -- the Keeper warns clients older than this (Main: NoteClientVersion); clients compare
                              -- themselves against the Keeper's mc (or kv from a Keeper before 1.3.2)
AK.PROTOCOL_VERSION = 1
AK.PREFIX = "ABK1"
-- Where the player-side client runs: "AshenKeeper" (this addon) or "Banner" (the copy inside The Ashen Banner,
-- LeafVillageLegends\Quartermaster, which sets AshenKeeper.host before this file runs).
AK.host = AK.host or "AshenKeeper"

-- SavedVariables this copy reads and writes. The Banner copy points these at its own variables (QM_Host.lua).
AK.SV = AK.SV or {
  get = function() return AshenKeeperDB, AshenKeeperCache end,
  set = function(db, cache) AshenKeeperDB = db AshenKeeperCache = cache end,
}

-- Optional default Keeper character. The real value lives in AshenKeeperDB.config.keeperName
-- and can be changed with "/ak setkeeper <Name>" (the character name is not final yet).
ASHEN_KEEPER_NAME = ASHEN_KEEPER_NAME or "Grizzwick"   -- the Quartermaster character; override with /ak setkeeper <name>

------------------------------------------------------------------------------
-- Small helpers
------------------------------------------------------------------------------
function AK.Now()
  if type(time) == "function" then return time() end
  return 0
end

function AK.Clock()
  if type(GetTime) == "function" then return GetTime() end
  return 0
end

function AK.Trim(s)
  if type(s) ~= "string" then return "" end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

function AK.Norm(name)
  if type(name) ~= "string" then return nil end
  name = AK.Trim(name)
  if name == "" then return nil end
  return string.lower(name)
end

function AK.Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37[AshenKeeper]|r " .. tostring(msg))
  end
end

function AK.Debug(msg)
  if AK.db and AK.db.config and AK.db.config.debug then
    AK.Print("|cff888888" .. tostring(msg) .. "|r")
  end
end

-- Last thing that went wrong (task / handler errors, trade failures); shown by /ak health.
function AK.NoteError(msg)
  AK.lastError = { t = AK.Now(), msg = tostring(msg) }
  AK.Debug(msg)
end

-- "1.0.0" < "1.1.0" < "1.10.0". Missing / unparsable parts count as 0.
function AK.VersionLess(a, b)
  local pa = AK.Split(tostring(a or "0"), ".")
  local pb = AK.Split(tostring(b or "0"), ".")
  local i
  for i = 1, 3 do
    local x, y = tonumber(pa[i]) or 0, tonumber(pb[i]) or 0
    if x ~= y then return x < y end
  end
  return false
end

function AK.Split(s, sep)
  local out = {}
  local pos = 1
  local seplen = string.len(sep)
  while true do
    local a = string.find(s, sep, pos, true)
    if not a then
      table.insert(out, string.sub(s, pos))
      break
    end
    table.insert(out, string.sub(s, pos, a - 1))
    pos = a + seplen
  end
  return out
end

function AK.Esc(v)
  v = tostring(v)
  v = string.gsub(v, "%%", "%%25")
  v = string.gsub(v, "%^", "%%5E")
  v = string.gsub(v, "=", "%%3D")
  -- ":" and ";" are NOT escaped: the list values (shop/stock/board) are made of them, and escaping each
  -- one tripled its size, pushing every list message past the 250-character limit so it was dropped.
  -- Free text never nests inside a list, so nothing needs protecting. (Unesc still understands the old form.)
  return v
end

function AK.Unesc(v)
  v = string.gsub(v, "%%3A", ":")
  v = string.gsub(v, "%%3B", ";")
  v = string.gsub(v, "%%3D", "=")
  v = string.gsub(v, "%%5E", "^")
  v = string.gsub(v, "%%25", "%%")
  return v
end

function AK.FormatAE(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  local neg = n < 0
  if neg then n = -n end
  local s = tostring(n)
  local out = ""
  while string.len(s) > 3 do
    out = "," .. string.sub(s, -3) .. out
    s = string.sub(s, 1, string.len(s) - 3)
  end
  out = s .. out
  if neg then out = "-" .. out end
  return out
end

function AK.CopyTable(t)
  if type(t) ~= "table" then return t end
  local c = {}
  local k, v
  for k, v in pairs(t) do c[k] = AK.CopyTable(v) end
  return c
end

function AK.TableCount(t)
  local n = 0
  local k
  for k in pairs(t) do n = n + 1 end
  return n
end

------------------------------------------------------------------------------
-- Identity abstraction. Phase 1: normalized character name.
-- Later this becomes a shared member ID without touching the economy code.
------------------------------------------------------------------------------
function AshenKeeper_GetIdentity(characterName)
  return AshenKeeper.Norm(characterName)
end

------------------------------------------------------------------------------
-- Scheduler: one hidden frame, tasks only cost anything while at least one exists.
------------------------------------------------------------------------------
AK.tasks = {}
AK.taskCount = 0

local function SchedulerOnUpdate()
  local now = AK.Clock()
  local i = 1
  local list = AK.tasks
  while i <= table.getn(list) do
    local t = list[i]
    if now >= t.at then
      if t.interval then
        t.at = now + t.interval
      else
        table.remove(list, i)
        i = i - 1
      end
      local ok, err = pcall(t.fn)
      if not ok then AK.NoteError("task " .. tostring(t.key) .. " error: " .. tostring(err)) end
    end
    i = i + 1
  end
  if table.getn(list) == 0 and AK.schedFrame then AK.schedFrame:Hide() end
end

local function EnsureSchedFrame()
  if not AK.schedFrame and CreateFrame then
    AK.schedFrame = CreateFrame("Frame", "AshenKeeperSchedulerFrame")
    AK.schedFrame:SetScript("OnUpdate", SchedulerOnUpdate)
  end
  if AK.schedFrame then AK.schedFrame:Show() end
end

local function RemoveTask(key)
  local list = AK.tasks
  local i
  for i = table.getn(list), 1, -1 do
    if list[i].key == key then table.remove(list, i) end
  end
end

function AK.After(key, delay, fn)
  RemoveTask(key)
  table.insert(AK.tasks, { key = key, at = AK.Clock() + delay, fn = fn })
  EnsureSchedFrame()
end

function AK.Every(key, interval, fn)
  RemoveTask(key)
  table.insert(AK.tasks, { key = key, at = AK.Clock() + interval, interval = interval, fn = fn })
  EnsureSchedFrame()
end

function AK.Cancel(key)
  RemoveTask(key)
end

------------------------------------------------------------------------------
-- Database
------------------------------------------------------------------------------
local function DefaultConfig()
  return {
    keeperName = ASHEN_KEEPER_NAME or "",
    stockMode = "bag",          -- "bag" (scan Keeper bags) or "manual" (admin override / debugging)
    transport = "GUILD",        -- addon-message channel: "GUILD" or "WHISPER"
    autoFulfill = true,         -- Keeper tries to open trades itself
    orderTimeout = 900,         -- seconds before an unfulfilled order is cancelled and released
    weekResetDay = 3,           -- 0=Sun .. 6=Sat (3 = Wednesday, matches the Ashen Banner week)
    weekResetHour = 0,
    dialogue = true,            -- RP dialogue lines on/off
    dialogueSay = false,        -- also /say lines from the Keeper (server may drop addon chat)
    debug = false,
    unlockLocked = false,       -- allow editing LOCKED values (e.g. Elemental Fire AE)
    allowManualTrades = false,  -- false: the Keeper declines every trade that is not for an order or a donation
    tidyBags = true,            -- merge part stacks of the same item while idle (Trade.Tidy)
  }
end

function AK.NewDB()
  return {
    version = 1,
    config = DefaultConfig(),
    items = {},          -- per-item overrides: { [key] = { price, reserve, enabled, manualStock } }
    mats = {},           -- per-material overrides: { [key] = { ae, target, overstockAE, enabled, priority, current } }
    orders = {},         -- active orders (REQUESTED..FULFILLING); finished ones move to transactions
    nextOrderId = 1,
    transactions = {},   -- bounded ring (see Transactions.Record)
    users = {},          -- [identity] = { name, spent, donated, week = {...} }
    donationIntents = {},
    stats = { day = "", purchases = 0, donations = 0, aeSpent = 0, aeAwarded = 0 },
    testEarned = {},     -- test mode: pretend earned AE per identity
    customMats = {},     -- board entries officers added: [key] = { code, itemID, name, ae, target, overstockAE, enabled, priority }
    customItems = {},    -- shop items officers added: [key] = { code, itemID, name, lvl } (Shop.ApplyCustom)
    adminLog = {},       -- officer changes (bounded, see Admin.Log)
    tradeLog = {},       -- every trade attempt and its outcome (bounded, see Trade.Log)
    -- tradeInFlight = { ... }  the trade being handed over right now (Trade.Recover settles it after a reload)
    -- weeklyReport = { wk, t, lines }  the last weekly officer summary; lastWeeklyKey = week it was sent for
  }
end

local function MergeDefaults(db)
  local d = AK.NewDB()
  local k, v
  for k, v in pairs(d) do
    if db[k] == nil then db[k] = v end
  end
  for k, v in pairs(d.config) do
    if db.config[k] == nil then db.config[k] = v end
  end
  -- An earlier version saved keeperName as "" before the default existed; "" means "unset".
  if (db.config.keeperName == nil or db.config.keeperName == "") and d.config.keeperName ~= "" then
    db.config.keeperName = d.config.keeperName
  end
  return db
end

function AK.InitDB()
  local db, cache = AK.SV.get()
  if type(db) ~= "table" then db = AK.NewDB() end
  db = MergeDefaults(db)
  if type(cache) ~= "table" then cache = {} end
  AK.SV.set(db, cache)
  AK.db = db
  AK.cache = cache
  if AK.Shop and AK.Shop.ApplyCustom then AK.Shop.ApplyCustom() end   -- officer-added shop items join the config list
end

-- Per-character window settings (last Shop sub-tab ...): AK.Pref(key) reads, AK.Pref(key, value) stores.
function AK.Pref(k, v)
  if not AK.db then return nil end
  local me = AK.Norm(AK.MyName()) or "?"
  AK.db.ui = AK.db.ui or {}
  AK.db.ui[me] = AK.db.ui[me] or {}
  if v ~= nil then AK.db.ui[me][k] = v end
  return AK.db.ui[me][k]
end

-- Test mode swaps in a throwaway DB so tests never touch real data.
function AK.UseTestDB()
  AK.realDB = AK.realDB or AK.db
  AK.db = AK.NewDB()
  AK.db.config.stockMode = "manual"
  AK.testMode = true
  if AK.Shop and AK.Shop.ApplyCustom then AK.Shop.ApplyCustom() end
  return AK.db
end

function AK.EndTestDB()
  if AK.realDB then AK.db = AK.realDB end
  AK.realDB = nil
  AK.testMode = false
  if AK.Shop and AK.Shop.ApplyCustom then AK.Shop.ApplyCustom() end
end

------------------------------------------------------------------------------
-- Mode detection
------------------------------------------------------------------------------
function AK.MyName()
  if type(UnitName) == "function" then return UnitName("player") end
  return nil
end

function AK.IsKeeper()
  if AK.forceKeeper then return true end
  if not AK.db then return false end
  local kn = AK.Norm(AK.db.config.keeperName)
  if not kn then return false end
  return kn == AK.Norm(AK.MyName())
end

-- Name of the Keeper as far as this client knows (own name if we are the Keeper).
function AK.KeeperName()
  if AK.IsKeeper() then return AK.MyName() end
  if AK.cache and AK.cache.keeperName and AK.cache.keeperName ~= "" then return AK.cache.keeperName end
  if AK.db and AK.db.config.keeperName ~= "" then return AK.db.config.keeperName end
  return nil
end
