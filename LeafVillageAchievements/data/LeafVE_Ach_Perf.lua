-- LeafVE_Ach_Perf.lua (v4.2.0)
-- Performance layer for Ashen Banner Achievements. Loaded right after
-- LeafVillageAchievements.lua and before every data\ file.
--
--  * Quiet mode: in combat, inside an instance or in a raid group, background
--    guild sync is ignored and this client's own broadcasts wait; one
--    catch-up runs after leaving. Achievements are still awarded live.
--  * One shared spellbook scan (mounts, companions, toys, collections) instead
--    of four separate scanners firing on every ADDON_LOADED, loading screen and
--    SPELLS_CHANGED. It only re-runs when the spellbook actually changed.
--  * Login sync asks only for data that changed since this character was last
--    online (COLREQ2), instead of making every guild member resend everything.
--  * Other players' achievements are stored as plain timestamps.
-- Lua 5.0 / WoW 1.12: no '#', no '%'.

local A = LeafVE_AchTest
if not A then return end

A.perf = A.perf or {}
local P = A.perf
P.pending = P.pending or {}
if P.quiet == nil then P.quiet = false end
P.quietSince = P.quietSince or 0
P.lastCatchUp = P.lastCatchUp or -100000

local function DB()
  if type(LeafVE_AchTest_DB) ~= "table" then return nil end
  if type(LeafVE_AchTest_DB.perf) ~= "table" then LeafVE_AchTest_DB.perf = {} end
  return LeafVE_AchTest_DB.perf
end

-------------------------------------------------------------------------------
-- Quiet mode
-------------------------------------------------------------------------------
function A:PerfComputeQuiet()
  if UnitAffectingCombat and UnitAffectingCombat("player") then return true end
  if GetNumRaidMembers and GetNumRaidMembers() > 0 then return true end
  if IsInInstance then
    local inInstance = IsInInstance()
    if inInstance then return true end
  end
  return false
end

function A:IsQuiet()
  return P.quiet and true or false
end

-- Messages ignored while quiet. Achievement/collection sync from others is
-- pure display data and is re-requested after leaving quiet mode.
P.quietDropCmd = { ["SYNC"] = true, ["COLSYNC"] = true, ["COLREQ2"] = true }
P.quietDropMsg = { ["COLREQ"] = true, ["VERREQ"] = true }

function A:PerfShouldDropMessage(message)
  if not P.quiet or not message then return false end
  if P.quietDropMsg[message] then return true end
  local colon = string.find(message, ":", 1, true)
  if colon and P.quietDropCmd[string.sub(message, 1, colon - 1)] then return true end
  return false
end

function A:PerfUpdateQuiet()
  local quiet = self:PerfComputeQuiet()
  if quiet == P.quiet then return end
  P.quiet = quiet
  if quiet then
    P.quietSince = time()
    P.quietSinceClock = GetTime()
    return
  end
  local quietFor = GetTime() - (P.quietSinceClock or GetTime())
  if quietFor >= 60 and (GetTime() - P.lastCatchUp) >= 300 then
    P.pending.catchUpSince = P.quietSince
  end
  if P.pending.ach or P.pending.col or P.pending.catchUpSince or P.pending.scan then
    P.catchUpAt = GetTime() + 5 + math.mod(string.len(UnitName("player") or "") * 7, 10)
  end
end

function A:PerfQuietCatchUp()
  if P.quiet then return end
  local pend = P.pending
  if pend.scan then
    pend.scan = nil
    self:QueueSpellScan(0.5)
  end
  if pend.ach then
    pend.ach = nil
    self:BroadcastAchievements()
  end
  if pend.col then
    pend.col = nil
    self:BroadcastMyCollections()
  end
  if pend.catchUpSince then
    local since = pend.catchUpSince
    pend.catchUpSince = nil
    P.lastCatchUp = GetTime()
    self:RequestGuildCollectionsSince(since)
  end
end

-------------------------------------------------------------------------------
-- Login sync: only ask for what changed while we were away
-------------------------------------------------------------------------------
-- When this character was last online (saved), read once at load.
function A:GetLastSeenOnline()
  if P.lastSeenAtLogin == nil then
    local d = DB()
    P.lastSeenAtLogin = d and tonumber(d.lastSeenAt) or 0
  end
  return P.lastSeenAtLogin
end

function A:RequestGuildCollectionsSince(since)
  if not IsInGuild or not IsInGuild() then return end
  since = tonumber(since) or 0
  -- small overlap so clock differences between PCs can't hide a change
  if since > 600 then since = since - 600 else since = 0 end
  SendAddonMessage("LeafVEAch", "COLREQ2:" .. string.format("%.0f", since), "GUILD")
end

-- Newest of: my latest achievement, my latest collection change.
function A:GetMyLastChangeAt()
  local newest = 0
  local me = A.ShortName and A.ShortName(UnitName("player"))
  local mine = me and LeafVE_AchTest_DB and LeafVE_AchTest_DB.achievements and LeafVE_AchTest_DB.achievements[me]
  if type(mine) == "table" then
    for _, data in pairs(mine) do
      local ts = (type(data) == "table" and tonumber(data.timestamp)) or tonumber(data) or 0
      if ts > newest then newest = ts end
    end
  end
  local d = DB()
  local colAt = d and tonumber(d.colChangedAt) or 0
  if colAt > newest then newest = colAt end
  return newest
end

-- Record a change in this character's own collections (count per kind).
function A:NoteOwnCollectionsSignature()
  local cols = LeafVE_AchTest_DB and LeafVE_AchTest_DB.collections
  if type(cols) ~= "table" then return end
  local parts = {}
  local kinds = { "mounts", "companions", "toys" }
  for i = 1, 3 do
    local n = 0
    local t = cols[kinds[i]]
    if type(t) == "table" then
      for _ in pairs(t) do n = n + 1 end
    end
    parts[i] = tostring(n)
  end
  local sig = table.concat(parts, "/")
  local d = DB()
  if d and d.colSig ~= sig then
    d.colSig = sig
    d.colChangedAt = time()
  end
end

-------------------------------------------------------------------------------
-- Shared spellbook scan
-------------------------------------------------------------------------------
P.scanners = P.scanners or {}
local scan = { pending = false, due = 0, force = false, ran = false, sig = nil, entered = false }

function A:RegisterSpellScanner(key, fn)
  local list = P.scanners
  for i = 1, table.getn(list) do
    if list[i].key == key then
      list[i].fn = fn
      return
    end
  end
  table.insert(list, { key = key, fn = fn })
end

local function SpellbookSignature()
  local book = BOOKTYPE_SPELL or "spell"
  local last = 0
  if GetNumSpellTabs and GetSpellTabInfo then
    local nTabs = GetNumSpellTabs() or 0
    for t = 1, nTabs do
      local _, _, offset, num = GetSpellTabInfo(t)
      local e = (tonumber(offset) or 0) + (tonumber(num) or 0)
      if e > last then last = e end
    end
  end
  -- spells this server exposes past the normal tabs
  local guard = 0
  while GetSpellName and GetSpellName(last + 1, book) and guard < 200 do
    last = last + 1
    guard = guard + 1
  end
  local name, rank
  if last > 0 and GetSpellName then name, rank = GetSpellName(last, book) end
  return tostring(last) .. ":" .. tostring(name or "") .. ":" .. tostring(rank or "")
end

-- Runs every registered scanner if the spellbook changed (or force).
-- Scanners get first=true on the session's first run (silent seed).
function A:RunSpellScanNow(force)
  local sig = SpellbookSignature()
  if not force and scan.ran and sig == scan.sig then return false end
  scan.sig = sig
  local first = not scan.ran
  scan.ran = true
  local list = P.scanners
  for i = 1, table.getn(list) do
    local ok, err = pcall(list[i].fn, first)
    if not ok and DEFAULT_CHAT_FRAME and A.DEBUG then
      DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444[Ach] scan " .. tostring(list[i].key) .. ": " .. tostring(err) .. "|r")
    end
  end
  self:NoteOwnCollectionsSignature()
  return true
end

local scanFrame = CreateFrame("Frame")
scanFrame:Hide()
scanFrame:SetScript("OnUpdate", function()
  if GetTime() < scan.due then return end
  if UnitAffectingCombat and UnitAffectingCombat("player") then
    scan.due = GetTime() + 2
    return
  end
  this:Hide()
  scan.pending = false
  local force = scan.force
  scan.force = false
  A:RunSpellScanNow(force)
end)

-- Debounced: bursts of SPELLS_CHANGED collapse into one scan.
function A:QueueSpellScan(delay, force)
  scan.due = GetTime() + (delay or 1.5)
  if force then scan.force = true end
  scan.pending = true
  scanFrame:Show()
end

function A:HasRunSpellScan()
  return scan.ran
end

local scanEvents = CreateFrame("Frame")
scanEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
scanEvents:RegisterEvent("SPELLS_CHANGED")
scanEvents:RegisterEvent("LEARNED_SPELL_IN_TAB")
scanEvents:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    scan.entered = true
    A:QueueSpellScan(2)
    return
  end
  -- SPELLS_CHANGED fires while the spellbook is still settling at login;
  -- wait for the first PLAYER_ENTERING_WORLD (same rule the old scanners used).
  if not scan.entered then return end
  A:QueueSpellScan(1.5)
end)

-------------------------------------------------------------------------------
-- Equipped-gear fingerprint (UNIT_INVENTORY_CHANGED also fires for bag and
-- durability changes; gear achievements only care about equipped items).
-------------------------------------------------------------------------------
P.gearSig = P.gearSig or {}
local gearParts = {}
function A:GearChangedFor(consumer)
  for slot = 1, 19 do
    gearParts[slot] = GetInventoryItemLink("player", slot) or "-"
  end
  local sig = table.concat(gearParts, ",")
  if P.gearSig[consumer] == sig then return false end
  P.gearSig[consumer] = sig
  return true
end

-------------------------------------------------------------------------------
-- Compact storage of other players' achievements: id -> timestamp
-------------------------------------------------------------------------------
function A:CompactOtherPlayersAchievements()
  local all = LeafVE_AchTest_DB and LeafVE_AchTest_DB.achievements
  if type(all) ~= "table" then return 0 end
  local me = A.ShortName and A.ShortName(UnitName("player"))
  local converted = 0
  for name, list in pairs(all) do
    if type(list) ~= "table" then
      all[name] = nil
    elseif name ~= me then
      for achId, data in pairs(list) do
        if type(data) == "table" then
          list[achId] = tonumber(data.timestamp) or 0
          converted = converted + 1
        end
      end
    end
  end
  return converted
end

-------------------------------------------------------------------------------
-- Driver: one light 1-second tick
-------------------------------------------------------------------------------
local tick = CreateFrame("Frame")
local tickElapsed = 0
local seenElapsed = 0
tick:SetScript("OnUpdate", function()
  tickElapsed = tickElapsed + (arg1 or 0)
  if tickElapsed < 1 then return end
  seenElapsed = seenElapsed + tickElapsed
  tickElapsed = 0
  A:PerfUpdateQuiet()
  if P.catchUpAt and GetTime() >= P.catchUpAt and not P.quiet then
    P.catchUpAt = nil
    A:PerfQuietCatchUp()
  end
  -- remember when we were last online (used by the next login's COLREQ2)
  if seenElapsed >= 120 then
    seenElapsed = 0
    A:GetLastSeenOnline()
    local d = DB()
    if d then d.lastSeenAt = time() end
  end
end)

local life = CreateFrame("Frame")
life:RegisterEvent("PLAYER_LOGOUT")
life:RegisterEvent("PLAYER_REGEN_DISABLED")
life:RegisterEvent("PLAYER_ENTERING_WORLD")
life:SetScript("OnEvent", function()
  if event == "PLAYER_LOGOUT" then
    A:GetLastSeenOnline()
    local d = DB()
    if d then d.lastSeenAt = time() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    A:PerfUpdateQuiet()
  elseif event == "PLAYER_ENTERING_WORLD" then
    A:GetLastSeenOnline() -- capture before the first 2-minute stamp overwrites it
    if not P.maintenanceDone then
      P.maintenanceDone = true
      local ok = pcall(function() A:CompactOtherPlayersAchievements() end)
    end
  end
end)
