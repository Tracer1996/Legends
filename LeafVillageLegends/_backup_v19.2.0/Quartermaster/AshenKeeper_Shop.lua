-- GENERATED from AshenKeeper\AshenKeeper_Shop.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Shop rules: merged item config, availability, AE balance, weekly requisition slots and
-- purchase validation. Pure logic (no frames, no WoW calls except date/time) so it is testable.
--
-- AE buckets (kept separate on purpose):
--   * lifetime / weekly totals  = the Ashen Banner leaderboard numbers. NEVER modified here.
--   * running balance           = earned (lifetime) + donation credits - purchases. Only this moves.
--   * donation credit           = donated AE not spent yet (u.donCredit). Part of the running balance, but
--                                 the weekly allowance does not limit it and it never expires.

AshenKeeper.Shop = AshenKeeper.Shop or {}
local AK = AshenKeeper
local S = AK.Shop

------------------------------------------------------------------------------
-- Item config (static config + admin overrides stored in AshenKeeperDB.items)
------------------------------------------------------------------------------
function S.Item(key)
  local base = QuartermasterItems[key]
  if not base then return nil end
  local o = AK.db.items[key] or {}
  local item = {
    key = key, code = base.code, itemID = base.itemID, name = base.name,
    requisitionType = base.requisitionType, priority = base.priority, stock = base.stock,
    price = math.floor(base.price * (QuartermasterPriceMultiplier or 1) + 0.5), reserve = base.reserve, enabled = base.enabled,
    lvl = base.lvl or 0, fb = S.DefaultFlamebound(base),
  }
  if o.price ~= nil then item.price = o.price end
  if o.reserve ~= nil then item.reserve = o.reserve end
  if o.enabled ~= nil then item.enabled = o.enabled end
  if o.fb ~= nil then item.fb = o.fb end
  item.grp = o.grp or S.DefaultGroup(key, base)
  return item
end

-- Shop sub-tab of an item (QuartermasterShopGroups): the config's QuartermasterItemGroups, else from its name.
function S.DefaultGroup(key, base)
  local g = QuartermasterItemGroups and QuartermasterItemGroups[key]
  if g then return g end
  local n = string.lower((base and base.name) or "")
  if string.find(n, "^flask ") then return "flask" end
  if string.find(n, "elixir") then return "elixir" end
  if string.find(n, "potion") then return "potion" end
  if string.find(n, "oil$") or string.find(n, "stone$") then return "oil" end
  if string.find(n, " bag$") or string.find(n, "backpack") then return "bag" end
  return "other"
end

function S.IsGroup(g)
  local i
  for i = 1, table.getn(QuartermasterShopGroups or {}) do
    if QuartermasterShopGroups[i].key == g and g ~= "all" then return true end
  end
  return false
end

-- Flamebound only unless the config says otherwise: every flask.
function S.DefaultFlamebound(base)
  if base.fb ~= nil then return base.fb == true end
  return string.find(string.lower(base.name or ""), "^flask ") ~= nil
end

-- Officer-added shop items (Manage > Potions or Shop > Add). The Keeper keeps them in AshenKeeperDB.customItems,
-- players get them in MATS (code:itemID:name:i:level). They are put into QuartermasterItems / QuartermasterOrder
-- (after the config items, by name) so everything that lists or prices the shop treats them like config items;
-- their price and donation values live in AshenKeeperDB.items like any officer override.
function S.CustomItemKey(itemID) return "CITEM_" .. itemID end
function S.CustomItemCode(itemID) return "Y" .. itemID end
S.customKeys = S.customKeys or {}

function S.ApplyCustom()
  local k, i
  for k in pairs(S.customKeys) do
    QuartermasterItems[k] = nil
    for i = table.getn(QuartermasterOrder), 1, -1 do
      if QuartermasterOrder[i] == k then table.remove(QuartermasterOrder, i) end
    end
  end
  S.customKeys = {}
  local list = {}
  local function Collect(tbl)
    if type(tbl) ~= "table" then return end
    local key, c
    for key, c in pairs(tbl) do
      if not S.customKeys[key] and not QuartermasterItems[key] and (tonumber(c.itemID) or 0) > 0 and c.name then
        S.customKeys[key] = true
        table.insert(list, { key = key, c = c })
      end
    end
  end
  Collect(AK.db and AK.db.customItems)
  Collect(AK.cache and AK.cache.customItems)
  table.sort(list, function(a, b) return string.lower(a.c.name) < string.lower(b.c.name) end)
  for i = 1, table.getn(list) do
    local c = list[i].c
    QuartermasterItems[list[i].key] = { code = c.code, itemID = c.itemID, name = c.name, price = c.price or 0, lvl = c.lvl or 0,
                                         fb = c.fb and true or false, requisitionType = "MINOR", stock = 0, reserve = 0,
                                         enabled = true, priority = c.priority or "SECONDARY", custom = true }
    table.insert(QuartermasterOrder, list[i].key)
  end
  if AK.Donations then AK.Donations.allKeys = nil end
end

function S.KeyByCode(code)
  local i
  for i = 1, table.getn(QuartermasterOrder) do
    local k = QuartermasterOrder[i]
    if QuartermasterItems[k].code == code then return k end
  end
  return nil
end

function S.KeyByName(name)
  local lname = AK.Norm(name)
  if not lname then return nil end
  local i
  for i = 1, table.getn(QuartermasterOrder) do
    local k = QuartermasterOrder[i]
    local n = string.lower(QuartermasterItems[k].name)
    if n == lname or k == string.upper(name) or string.lower(QuartermasterItems[k].code) == lname then return k end
  end
  return nil
end

------------------------------------------------------------------------------
-- Stock availability: available = stock - reserve - pending reservations
------------------------------------------------------------------------------
-- Units, not orders: a purchase of 5 holds 5 in reserve.
local function Pending(key)
  if AK.Transactions then return AK.Transactions.PendingCount(key) end
  return 0
end

function S.Available(key)
  local item = S.Item(key)
  if not item then return 0 end
  local stock = AK.Stock.Get(key, item)
  local avail = stock - (item.reserve or 0) - Pending(key)
  if avail < 0 then avail = 0 end
  return avail
end

-- "OK" | "RESERVED" (held for campaign use) | "OOS" (no stock) | "OFF" (disabled)
function S.Status(key)
  local item = S.Item(key)
  if not item then return "OFF" end
  if not item.enabled then return "OFF" end
  local stock = AK.Stock.Get(key, item)
  if stock <= 0 then return "OOS" end
  if S.Available(key) <= 0 then
    if stock - Pending(key) <= 0 then return "OOS" end
    return "RESERVED"
  end
  return "OK"
end

------------------------------------------------------------------------------
-- Earned AE (read-only view of the Ashen Banner leaderboard data) and balance
------------------------------------------------------------------------------
local function SumEntry(v)
  if type(v) == "number" then return v end
  if type(v) == "table" then
    return (tonumber(v.L) or 0) + (tonumber(v.G) or 0) + (tonumber(v.S) or 0)
  end
  return 0
end

-- The Keeper spends only ACCEPTED AE (AK.Integrity, end of this file); a player's own client reads its raw total.
function AK.GetEarnedAE(identity)
  local te = AK.db.testEarned and AK.db.testEarned[identity]
  if te ~= nil then return te end
  if AK.IsKeeper() then
    local acc = AK.Integrity.Accepted(identity)
    if acc then return acc end
  end
  return AK.Integrity.RawEarned(identity)
end

-- Highest total any source shows: the player's own reports and the Ashen Banner leaderboard data.
AK.Integrity = AK.Integrity or {}
function AK.Integrity.RawEarned(identity)
  local best = 0
  -- What the player's own client reported (it knows its own total for sure; the Keeper only knows
  -- members whose points were broadcast while it was online). Never lowered.
  local ru = AK.db.users[identity]
  if ru and (ru.reported or 0) > best then best = ru.reported end
  if type(LeafVE_DB) ~= "table" then return best end
  local sources = { LeafVE_DB.alltime }
  if type(LeafVE_DB.lboard) == "table" then table.insert(sources, LeafVE_DB.lboard.alltime) end
  if type(LeafVE_GlobalDB) == "table" and type(LeafVE_GlobalDB.lboardCache) == "table" then
    table.insert(sources, LeafVE_GlobalDB.lboardCache.alltime)
  end
  local i
  for i = 1, table.getn(sources) do
    local src = sources[i]
    if type(src) == "table" then
      local name, v
      for name, v in pairs(src) do
        if type(name) == "string" and string.lower(name) == identity then
          local total = SumEntry(v)
          if total > best then best = total end
        end
      end
    end
  end
  return best
end

-- AE earned THIS week (Ashen Banner weekly leaderboard, week key = S.WeekKey(); both reset Wednesday 00:00).
function AK.GetWeekEarnedAE(identity, wk)
  local tw = AK.db.testWeekEarned and AK.db.testWeekEarned[identity]
  if tw ~= nil then return tw end
  local best = 0
  local ru = AK.db.users[identity]
  if ru and ru.weekReported and ru.weekReported.key == wk and (ru.weekReported.n or 0) > best then best = ru.weekReported.n end
  local sources = {}
  if type(LeafVE_DB) == "table" and type(LeafVE_DB.lboard) == "table" and type(LeafVE_DB.lboard.weekly) == "table" then
    table.insert(sources, LeafVE_DB.lboard.weekly[wk])
  end
  if type(LeafVE_GlobalDB) == "table" and type(LeafVE_GlobalDB.lboardCache) == "table" and type(LeafVE_GlobalDB.lboardCache.weekly) == "table" then
    table.insert(sources, LeafVE_GlobalDB.lboardCache.weekly[wk])
  end
  local i
  for i = 1, table.getn(sources) do
    local src = sources[i]
    if type(src) == "table" then
      local name, v
      for name, v in pairs(src) do
        if type(name) == "string" and string.lower(name) == identity then
          local total = SumEntry(v)
          if total > best then best = total end
        end
      end
    end
  end
  return best
end

-- The player's own client reports its weekly total (like NoteReported). Only kept for the current week.
function S.NoteWeekReported(identity, displayName, wk, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 or wk ~= S.WeekKey() then return end
  local u = S.User(identity, displayName, true)
  if not u.weekReported or u.weekReported.key ~= wk then u.weekReported = { key = wk, n = 0 } end
  if amount > u.weekReported.n then u.weekReported.n = amount end
end

-- The player's own lifetime total (their client, or their own leaderboard broadcast). On the Keeper it goes
-- through the AE fail-safe before any of it becomes spendable.
function S.NoteReported(identity, displayName, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return end
  local u = S.User(identity, displayName, true)
  if AK.IsKeeper() then AK.Integrity.Report(identity, displayName, amount) end
  if amount > (u.reported or 0) then u.reported = amount end
end

function S.User(identity, displayName, create)
  local u = AK.db.users[identity]
  if not u and create then
    u = { name = displayName or identity, spent = 0, donated = 0 }
    AK.db.users[identity] = u
  end
  if u and displayName and displayName ~= "" then u.name = displayName end
  return u
end

local function PendingOrdersFor(identity)
  if AK.Transactions then return AK.Transactions.PendingFor(identity) end
  return {}
end

-- Donation AE the donor's own Ashen Banner addon has not booked yet. Once their client confirms
-- (CREDIT_ACK) the AE is part of their leaderboard total ("earned"), so it must not be added twice.
function S.Unposted(u)
  if not u then return 0 end
  local n = (u.donated or 0) - (u.posted or 0)
  if n < 0 then n = 0 end
  return n
end

-- Lifetime total as the leaderboard shows it: earned (login/guild/shoutout + booked donations) plus
-- donations still on their way to the leaderboard. Spending never changes it; it only ever goes up.
function S.LifetimeTotal(identity)
  local u = AK.db.users[identity]
  return AK.GetEarnedAE(identity) + S.Unposted(u)
end

-- Running balance. pendingCost is held back so one AE can't buy two things at once.
function S.Balance(identity)
  local earned = AK.GetEarnedAE(identity)
  local u = AK.db.users[identity]
  local donated = S.Unposted(u)
  local spent = u and u.spent or 0
  local pending = 0
  local orders = PendingOrdersFor(identity)
  local i
  for i = 1, table.getn(orders) do pending = pending + (orders[i].price or 0) end
  local bal = earned + donated - spent - pending
  if bal < 0 then bal = 0 end
  return bal, earned, donated, spent, pending
end

------------------------------------------------------------------------------
-- Weekly AE allowance by guild rank (QuartermasterWeeklyAllowance)
------------------------------------------------------------------------------
-- Guild rank names as the Keeper's guild roster shows them: [identity] = rank name. Filled by ReadGuildRoster.
AK.guildRanks = AK.guildRanks or {}
AK.guildRankIndex = AK.guildRankIndex or {}      -- [identity] = rank index (0 = guild master)
AK.rankIndexByName = AK.rankIndexByName or {}    -- [rank key] = rank index
AK.guildLevels = AK.guildLevels or {}            -- [identity] = character level (item level gate)

function S.ReadGuildRoster()
  if type(GetNumGuildMembers) ~= "function" or type(GetGuildRosterInfo) ~= "function" then return end
  local ranks, idx, byName, online, levels = {}, {}, {}, {}, {}
  local i
  for i = 1, (GetNumGuildMembers() or 0) do
    local name, rank, rankIndex, level, _, _, _, _, isOn = GetGuildRosterInfo(i)
    local id = AK.Norm(name)
    if id and rank then
      ranks[id] = rank
      idx[id] = tonumber(rankIndex)
      if tonumber(rankIndex) and S.RankKey(rank) then byName[S.RankKey(rank)] = tonumber(rankIndex) end
    end
    if id and tonumber(level) then levels[id] = tonumber(level) end
    if id and isOn and isOn ~= 0 then online[id] = true end
  end
  AK.guildRanks = ranks
  AK.guildRankIndex = idx
  AK.rankIndexByName = byName
  AK.guildLevels = levels
  AK.Integrity.OnRoster(online)        -- who logged off / back on (offline-jump check)
end

-- Character level as the Keeper's guild roster shows it, or nil when unknown.
function S.LevelOf(identity)
  local tl = AK.db.testLevels and AK.db.testLevels[identity]
  if tl then return tl end
  return AK.guildLevels[identity]
end

-- Flamebound or higher (QuartermasterFlameboundRank): by rank index when the roster knows it, else by name.
function S.IsFlamebound(identity)
  local key = S.RankKey(S.RankOf(identity))
  if not key then return false end
  local minIdx = AK.rankIndexByName[S.RankKey(QuartermasterFlameboundRank or "Flamebound")]
  local myIdx = AK.guildRankIndex[identity] or AK.rankIndexByName[key]
  if minIdx and myIdx then return myIdx <= minIdx end
  local i
  for i = 1, table.getn(QuartermasterFlameboundRanks or {}) do
    if key == QuartermasterFlameboundRanks[i] then return true end
  end
  return false
end

-- Level / rank gate of one item for one buyer: nil when allowed, else "LEVEL" | "LEVEL_UNKNOWN" | "RANK".
function S.Gate(identity, item)
  if (item.lvl or 0) > 1 then
    local lv = S.LevelOf(identity)
    if not lv then return "LEVEL_UNKNOWN" end
    if lv < item.lvl then return "LEVEL" end
  end
  if item.fb and not S.IsFlamebound(identity) then return "RANK" end
  return nil
end

-- Oath Captain or higher (QuartermasterAdminMinRank): by rank index when the roster knows it, else by name.
function S.IsOfficer(identity)
  local rank = S.RankOf(identity)
  local key = S.RankKey(rank)
  if not key then return false end
  local minIdx = AK.rankIndexByName[S.RankKey(QuartermasterAdminMinRank or "Oath Captain")]
  local myIdx = AK.guildRankIndex[identity] or AK.rankIndexByName[key]
  if minIdx and myIdx then return myIdx <= minIdx end
  local i
  for i = 1, table.getn(QuartermasterAdminRanks or {}) do
    if key == QuartermasterAdminRanks[i] then return true end
  end
  return false
end

-- "Member: Born" -> "born", " Ember " -> "ember".
function S.RankKey(rank)
  local r = AK.Norm(rank)
  if not r then return nil end
  local _, _, after = string.find(r, ":%s*(.+)$")
  if after then r = after end
  return r
end

function S.RankOf(identity)
  local tr = AK.db.testRanks and AK.db.testRanks[identity]
  if tr then return tr end
  return AK.guildRanks[identity]
end

-- returns allowance, rank name
function S.Allowance(identity)
  local rank = S.RankOf(identity)
  local key = S.RankKey(rank)
  if not QuartermasterWeeklyAllowance or not key then return 0, rank end
  return QuartermasterWeeklyAllowance[key] or 0, rank
end

-- Donation credit: donated AE not spent yet. Its own pot - it never expires and the weekly allowance does
-- not limit it. Purchases take from it first (see Transactions.Complete), then from the weekly allowance.
function S.DonCredit(u)
  if not u then return 0 end
  return u.donCredit or 0
end

-- Splits a cost into (fromCredit, fromAllowance), credit first. creditUsed = credit already held elsewhere.
function S.SplitCost(u, cost, creditUsed)
  local c = S.DonCredit(u) - (creditUsed or 0)
  if c < 0 then c = 0 end
  if c > cost then c = cost end
  return c, cost - c
end

-- One-time migration (flag in db): donations made before the credit existed become credit, minus what was
-- spent, never more than the whole balance (nobody gains spendable room they never had). Logged in adminLog.
function S.MigrateDonCredit()
  if AK.db.donCreditMigrated then return 0 end
  local n, total = 0, 0
  local id, u
  for id, u in pairs(AK.db.users) do
    if u.donCredit == nil and (u.donated or 0) > 0 then
      local c = (u.donated or 0) - (u.spent or 0)
      local whole = S.Balance(id)
      if c > whole then c = whole end
      if c < 0 then c = 0 end
      u.donCredit = c
      n = n + 1
      total = total + c
    end
  end
  AK.db.donCreditMigrated = AK.Now()
  if AK.Admin and AK.Admin.Log then
    AK.Admin.Log("Keeper", "migrate", "donation credit", "-", n .. " users, " .. total .. " AE")
  end
  return n, total
end

-- What can be spent THIS week: donation credit + what is left of (rank allowance + earned this week - bought
-- from the allowance this week) - pending orders, never more than the whole running balance.
-- Without an allowance table it is the balance. returns spendable, allowance, rank, donCredit
function S.WeeklyBalance(identity)
  local full, _, _, _, pending = S.Balance(identity)
  local u = AK.db.users[identity]
  local credit = S.DonCredit(u)
  if not QuartermasterWeeklyAllowance then return full, nil, nil, credit end
  local allowance, rank = S.Allowance(identity)
  local wk = S.WeekKey()
  local w = u and S.EnsureWeek(u)
  local room = allowance + AK.GetWeekEarnedAE(identity, wk) - (w and w.allowanceSpent or 0)
  if room < 0 then room = 0 end
  local bal = credit + room - pending
  if bal > full then bal = full end
  if bal < 0 then bal = 0 end
  return bal, allowance, rank, credit
end

------------------------------------------------------------------------------
-- Weekly requisition slots
------------------------------------------------------------------------------
function S.WeekKey(now)
  now = now or AK.Now()
  local cfg = AK.db.config
  local t = date("*t", now)
  local weekday = t.wday - 1                      -- 0 = Sunday
  local back = math.mod(weekday - cfg.weekResetDay + 7, 7)
  if back == 0 and t.hour < cfg.weekResetHour then back = 7 end
  return date("%Y%m%d", now - back * 86400)
end

function S.NewWeek(wk)
  -- spent = everything bought this week (shown in My Week); allowanceSpent = the part not paid from donation credit
  return { key = wk, majorUsed = 0, majorConverted = 0, minor = 0, spent = 0, allowanceSpent = 0, recent = {} }
end

function S.EnsureWeek(user)
  local wk = S.WeekKey()
  if type(user.week) ~= "table" or user.week.key ~= wk then
    user.week = S.NewWeek(wk)
  elseif user.week.majorUsed == nil then
    -- week saved by the older single-Major version
    local w = user.week
    w.majorUsed = (w.major == "USED") and 1 or 0
    w.majorConverted = (w.major == "CONVERTED") and 1 or 0
    w.major = nil
  end
  if user.week.allowanceSpent == nil then
    -- week saved before donation credit: this week's donations used to pay first, the rest came from the allowance
    local w = user.week
    w.allowanceSpent = math.max(0, (w.spent or 0) - (w.donated or 0))
    w.donated = nil
  end
  return user.week
end

function S.MajorsTotal() return QuartermasterWeekly.majors or 1 end
function S.MaxPerOrder() return QuartermasterMaxPerOrder or 1 end
function S.MajorsLeft(w) return S.MajorsTotal() - (w.majorUsed or 0) - (w.majorConverted or 0) end
-- Minors per week: QuartermasterWeekly.minors, or minorsWithMajor once a Major was taken this week.
-- (majorConverted is only set in weeks saved by the old "unused Major converts" rule; it counts as taken.)
function S.MinorLimit(w)
  local W = QuartermasterWeekly
  if (w.majorUsed or 0) + (w.majorConverted or 0) > 0 then return W.minorsWithMajor or W.minors or 15 end
  return W.minors or 30
end
-- Most units of one shop item per player per week (nil = no cap).
function S.PerItemCap() return QuartermasterWeekly.perItem end
function S.ItemsThisWeek(w, key) return (w.items and w.items[key]) or 0 end

-- One unit against a week table (mutates). Returns true, or false + reason when the week has no room.
local function ApplyOne(w, reqType, key)
  local cap = S.PerItemCap()
  if key and cap and S.ItemsThisWeek(w, key) >= cap then return false, "ITEM_WEEK" end
  if reqType == "MAJOR" then
    if S.MajorsLeft(w) <= 0 then
      return false, ((w.majorUsed or 0) == 0 and (w.majorConverted or 0) > 0) and "MAJOR_CONVERTED" or "MAJOR_USED"
    end
    -- a Major lowers the minor limit: only while the minors taken so far still fit under it
    local with = QuartermasterWeekly.minorsWithMajor
    if with and (w.minor or 0) > with then return false, "MAJOR_MINORS" end
    w.majorUsed = (w.majorUsed or 0) + 1
  else
    if w.minor >= S.MinorLimit(w) then return false, "MINOR_LIMIT" end
    w.minor = w.minor + 1
  end
  if key then
    w.items = w.items or {}
    w.items[key] = (w.items[key] or 0) + 1
  end
  return true
end

-- Applies a purchase of qty units to a week table (mutates).
function S.ApplyToWeek(w, reqType, key, price, qty)
  local n = qty or 1
  local i
  for i = 1, n do ApplyOne(w, reqType, key) end
  w.spent = w.spent + (price or 0)
end

-- Can this week table buy qty more units of the given type (and item key, for the per-item cap)?
-- returns ok, reasonCode, howManyFit
function S.CanBuyType(w, reqType, qty, key)
  if reqType ~= "MAJOR" and reqType ~= "MINOR" then return false, "BAD_CATEGORY", 0 end
  local copy = AK.CopyTable(w)
  local want = qty or 1
  local fit = 0
  local reason
  local i
  for i = 1, want do
    local ok, why = ApplyOne(copy, reqType, key)
    if not ok then reason = why break end
    fit = fit + 1
  end
  if fit >= want then return true, nil, fit end
  return false, reason, fit
end

-- Units of each shop item taken this week (committed + pending), as "CODE:n;CODE:n" for WEEKITEMS.
function S.WeekItemsWire(w)
  local out = {}
  local i
  for i = 1, table.getn(QuartermasterOrder) do
    local key = QuartermasterOrder[i]
    local n = S.ItemsThisWeek(w, key)
    if n > 0 then table.insert(out, QuartermasterItems[key].code .. ":" .. n) end
  end
  return out
end

-- Committed week + all pending (reserved / fulfilling) orders applied, oldest first.
function S.EffectiveWeek(identity)
  local u = AK.db.users[identity]
  local w
  if u then
    w = AK.CopyTable(S.EnsureWeek(u))
  else
    w = S.NewWeek(S.WeekKey())
  end
  local orders = PendingOrdersFor(identity)
  local i
  for i = 1, table.getn(orders) do
    S.ApplyToWeek(w, orders[i].reqType, orders[i].key, orders[i].price, orders[i].qty)
  end
  return w
end
------------------------------------------------------------------------------
-- Validation (spec order: funds, enabled, stock, reserve, weekly slot, category)
-- returns ok, reasonCode, item
------------------------------------------------------------------------------
function S.Validate(identity, key, qty)
  local item = S.Item(key)
  if not item then return false, "NO_ITEM" end
  qty = math.floor(tonumber(qty) or 1)
  if qty < 1 then return false, "NO_ITEM", item end
  if AK.Integrity.OnHold(identity) then return false, "HOLD", item end
  if qty > S.MaxPerOrder() then return false, "QTY_LIMIT", item end
  local gate = S.Gate(identity, item)
  if gate then return false, gate, item end

  local bal = S.Balance(identity)
  if bal < item.price * qty then return false, "FUNDS", item end
  if QuartermasterWeeklyAllowance and S.WeeklyBalance(identity) < item.price * qty then return false, "WEEKLY_LIMIT", item end
  if not item.enabled then return false, "DISABLED", item end

  local status = S.Status(key)
  if status == "OOS" then return false, "OOS", item end
  if status == "RESERVED" then return false, "RESERVED", item end
  if status ~= "OK" then return false, "DISABLED", item end

  if item.requisitionType ~= "MAJOR" and item.requisitionType ~= "MINOR" then
    return false, "BAD_CATEGORY", item
  end
  if S.Available(key) < qty then return false, "STOCK_LOW", item end
  if AK.db.config.stockMode ~= "manual" and AK.Stock.TradeableQty(item, 6) < qty then return false, "STACKS", item end
  local w = S.EffectiveWeek(identity)
  local ok, reason = S.CanBuyType(w, item.requisitionType, qty, key)
  if not ok then return false, reason, item end
  return true, nil, item
end

-- Maps a failure reason to a dialogue pool name.
function S.ReasonPool(reason)
  if reason == "HOLD" then return "on_hold" end
  if reason == "LEVEL" or reason == "LEVEL_UNKNOWN" then return "too_low" end
  if reason == "RANK" then return "rank_only" end
  if reason == "FUNDS" or reason == "WEEKLY_LIMIT" then return "no_funds" end
  if reason == "OOS" then return "oos" end
  if reason == "RESERVED" then return "reserved" end
  if reason == "MAJOR_USED" or reason == "MAJOR_CONVERTED" or reason == "MAJOR_MINORS" then return "major_used" end
  if reason == "MINOR_LIMIT" or reason == "ITEM_WEEK" then return "minor_limit" end
  if reason == "STOCK_LOW" or reason == "STACKS" then return "oos" end
  if reason == "DISABLED" or reason == "NO_ITEM" or reason == "BAD_CATEGORY" or reason == "QTY_LIMIT" then return "disabled" end
  return "trade_fail"
end

function S.ReasonText(reason)
  if reason == "HOLD" then
    local st = AK.cache and AK.cache.state
    return "Your account is on hold for officer review" .. ((st and st.holdText) and (" (" .. st.holdText .. ")") or "") ..
           ". Nothing can be bought until an officer clears it."
  end
  if reason == "LEVEL" then return "Your level is too low to use that." end
  if reason == "LEVEL_UNKNOWN" then return "The Quartermaster can't see your level in the guild roster yet. Try again in a minute." end
  if reason == "RANK" then return "Only Flamebound and higher ranks can buy that." end
  if reason == "FUNDS" then return "Not enough Ashen Ember." end
  if reason == "WEEKLY_LIMIT" then
    local st = AK.cache and AK.cache.state
    local rank = st and st.rank
    local text = (rank and rank ~= "") and ("You've reached this week's " .. rank .. " allowance") or "You've reached this week's allowance"
    if st and st.donCredit == 0 then text = text .. " and have no donation credit left (donated AE never expires)" end
    return text .. "."
  end
  if reason == "OOS" then return "Out of Stock." end
  if reason == "RESERVED" then return "Reserved for Campaign Use." end
  if reason == "MAJOR_USED" then return "You have used all your Major requisitions this week." end
  if reason == "MAJOR_CONVERTED" then return "Your Major requisitions were converted to supplies this week." end
  if reason == "MINOR_LIMIT" then return "No minor requisitions left this week." end
  if reason == "MAJOR_MINORS" then
    return "You've taken more than " .. (QuartermasterWeekly.minorsWithMajor or 15) .. " minor requisitions this week, so no Major this week."
  end
  if reason == "ITEM_WEEK" then
    return "You can take at most " .. (S.PerItemCap() or 0) .. " of each item per week. That one is used up until the reset."
  end
  if reason == "STOCK_LOW" then return "Not that many in stock." end
  if reason == "STACKS" then return "That is too many to hand over in one trade. Try fewer." end
  if reason == "QTY_LIMIT" then return "That is more than one purchase allows (" .. S.MaxPerOrder() .. " at most)." end
  if reason == "DISABLED" then return "Not being issued right now." end
  if reason == "NO_KEEPER" then return "The Quartermaster is offline." end
  if reason == "BUSY" then return "Too many requests. Try again in a moment." end
  if reason == "TRADE_FAIL" then return "The trade did not complete. Nothing was taken from your Ledger." end
  return "Request refused (" .. tostring(reason) .. ")."
end

------------------------------------------------------------------------------
-- Wire entries for SHOP / STOCK_UPDATE:  code:price:available:status:M|m:flamebound(1/0):required level:sub-tab
-- (clients before 1.3.2 ignore the sub-tab; without it the client uses its own config)
------------------------------------------------------------------------------
function S.WireEntries()
  local out = {}
  local i
  for i = 1, table.getn(QuartermasterOrder) do
    local key = QuartermasterOrder[i]
    local item = S.Item(key)
    local st = S.Status(key)
    local letter = "O"
    if st == "RESERVED" then letter = "R" elseif st == "OOS" then letter = "X" elseif st == "OFF" then letter = "D" end
    local cat = "m"
    if item.requisitionType == "MAJOR" then cat = "M" end
    table.insert(out, item.code .. ":" .. item.price .. ":" .. S.Available(key) .. ":" .. letter .. ":" .. cat ..
                      ":" .. (item.fb and "1" or "0") .. ":" .. (item.lvl or 0) .. ":" .. (item.grp or "other"))
  end
  return out
end

-- Last few completed purchases of a user for the My Week tab / STATE message.
function S.RecentPurchases(user, maxN)
  local out = {}
  if user and user.week and user.week.recent then
    local r = user.week.recent
    local i
    for i = table.getn(r), math.max(1, table.getn(r) - (maxN or 5) + 1), -1 do
      table.insert(out, r[i])
    end
  end
  return out
end

------------------------------------------------------------------------------
-- AE fail-safe (AK.Integrity). The Ashen Banner keeps every player's AE in their own SavedVariables, which can be
-- edited while the game is closed, and the Keeper used to take the highest total anybody reported. Now the Keeper
-- keeps per player (u.ae):
--   acc    accepted lifetime AE: the only part the balance uses. Never lowered.
--   hold   AE reported above what was plausible: not spendable until an officer releases (or discards) it.
--   disc   AE an officer discarded (the player's own total still contains it; it is taken off every report).
--   adj    officer adjustment added to the balance (may be negative).
--   flag   why the player is on hold: SANITY (more than could be earned since the last report), OFFLINE (went up
--          while the Keeper saw them logged off, the Keeper itself online the whole time), TAMPER (their client
--          found its AE data changed outside the game).
--   frz    spending frozen by an officer.
-- Plausible = per server day the boss cap + QuartermasterDailyOtherAEAllowance (x weekend multiplier), counted from
-- the last report, plus donation AE booked since. A player on hold (flag or frz) cannot buy and nothing is handed
-- to them until an Oath Captain+ clears it; donations still work (they only help the guild).
------------------------------------------------------------------------------
local I = AK.Integrity

-- Server-day number of a timestamp (days since 1970, local calendar) and Saturday / Sunday.
function I.Day(ts)
  local l, u = date("*t", ts), date("!*t", ts)
  if type(l) ~= "table" or type(u) ~= "table" then return math.floor(ts / 86400) end
  local off = ((l.hour - u.hour) * 60 + (l.min - u.min)) * 60
  local lk, uk = l.year * 1000 + l.yday, u.year * 1000 + u.yday
  if lk > uk then off = off + 86400 elseif lk < uk then off = off - 86400 end
  return math.floor((ts + off) / 86400)
end

function I.IsWeekend(day)
  local wd = math.mod(day + 4, 7)          -- day 0 (1970-01-01) was a Thursday; 0 = Sunday
  return wd == 0 or wd == 6
end

function I.Mult(day)
  if I.IsWeekend(day) then return tonumber(QuartermasterWeekendAEMultiplier) or 1 end
  return 1
end

function I.DailyMax(day)
  return ((tonumber(QuartermasterDailyBossAECap) or 1250) + (tonumber(QuartermasterDailyOtherAEAllowance) or 0)) * I.Mult(day)
end

-- Most AE one player can earn on server days d0 .. d1 (both included).
function I.Budget(d0, d1)
  if d1 < d0 then return 0 end
  if d1 - d0 > 400 then d0 = d1 - 400 end
  local n = 0
  local d
  for d = d0, d1 do n = n + I.DailyMax(d) end
  return n
end

function I.State(u)
  if type(u.ae) ~= "table" then u.ae = {} end
  return u.ae
end

function I.Baseline(u, raw, now)
  local st = I.State(u)
  st.acc = math.floor(tonumber(raw) or 0)
  st.e0 = I.Day(now)
  st.used = 0
  st.seen = now
  st.last = st.acc
  st.posted = u.posted or 0
  st.hold = st.hold or 0
  st.disc = st.disc or 0
  return st
end

-- Accepted AE + officer adjustment, or nil when the Keeper has no baseline for this player yet.
function I.Accepted(identity)
  local u = AK.db.users[identity]
  local st = u and u.ae
  if type(st) ~= "table" or st.acc == nil then return nil end
  local n = st.acc + (st.adj or 0)
  if n < 0 then n = 0 end
  return n
end

-- The Keeper's own online time (AK.db.keeperUp, newest last: a = logged in, b = last heartbeat, e = "logout").
-- Every login / reload / relog (I.Start) and every heartbeat gap (frozen, asleep, disconnected, clock jump) starts
-- a new interval, so "the Keeper was online the whole time" = the current interval began before it.
I.cur = nil

function I.KeeperLogin(now)
  now = now or AK.Now()
  if type(AK.db.keeperUp) ~= "table" then AK.db.keeperUp = {} end
  local up = AK.db.keeperUp
  table.insert(up, { a = now, b = now })
  while table.getn(up) > 50 do table.remove(up, 1) end
  I.cur = up[table.getn(up)]
  return I.cur
end

-- Heartbeat (timer, roster, reports). After a gap a new interval starts and false is returned.
function I.KeeperAlive(now)
  local cur = I.cur
  if not cur then return false end
  now = now or AK.Now()
  if cur.e or now < cur.b or now - cur.b > (tonumber(QuartermasterKeeperGapSeconds) or 300) then
    I.KeeperLogin(now)
    return false
  end
  cur.b = now
  return true
end

function I.KeeperLogout(now)
  if not I.cur then return end
  I.cur.b = now or AK.Now()
  I.cur.e = "logout"
  I.cur = nil
end

-- Keeper online without a break from t until now.
function I.UpSince(t, now)
  local cur = I.cur
  return cur ~= nil and not cur.e and t ~= nil and cur.a <= t and cur.b >= (now or cur.b)
end

-- Keeper saw the player online again (roster, or a message from them).
function I.Back(st, now)
  st.on = true
  if st.offAt then st.backAt = now end
  st.wit = 0
end

-- Offline jump: only when the Keeper itself was online throughout: it heard a fresh total (the last report, at most
-- QuartermasterOfflineFreshWindow before the logoff), saw the logoff and the login in this same session, and this
-- is the first report since they came back (within QuartermasterOfflineCheckWindow). Anything less = per-day check.
function I.OfflineCase(st, now)
  if st.offAt == nil or st.backAt == nil or st.seen == nil then return false end
  if not I.cur or st.offS ~= I.cur.a then return false end
  if st.offAt < st.seen or st.offAt - st.seen > (tonumber(QuartermasterOfflineFreshWindow) or 2100) then return false end
  if not I.UpSince(st.seen, now) then return false end
  return st.backAt >= st.offAt and now - st.backAt <= (tonumber(QuartermasterOfflineCheckWindow) or 900)
end

-- AE that may be accepted now: budget (earning), posted (donation AE booked since), offline (offline-jump limit).
function I.Allowed(u, st, now)
  local today = I.Day(now)
  local posted = (u.posted or 0) - (st.posted or 0)
  if posted < 0 then posted = 0 end
  local n = I.Budget(st.e0 or today, today) - (st.used or 0)       -- never more than the daily maxima allow
  local since = I.Budget(I.Day(st.seen or now), today)             -- ...in the days since the last report
  if since < n then n = since end
  if n < 0 then n = 0 end
  if I.OfflineCase(st, now) then
    -- the end of the last session (AE heard announced live + a little unheard) and today's login reward
    local lim = (tonumber(QuartermasterOfflineTailAE) or 0) + (st.witTail or 0) + (st.wit or 0)
    if I.Day(st.backAt) ~= I.Day(st.seen or 0) then lim = lim + (tonumber(QuartermasterLoginAE) or 0) * I.Mult(I.Day(st.backAt)) end
    if lim < n then n = lim end
    return n, posted, true
  end
  return n, posted, false
end

function I.Flag(identity, u, why, before, after, held, note)
  local st = I.State(u)
  local f = st.flag
  if not f then
    f = { t = AK.Now(), why = why, before = before }
    st.flag = f
  elseif not string.find(f.why, why, 1, true) then
    f.why = f.why .. "," .. why
  end
  f.after = after
  f.note = note
  if AK.Admin and AK.Admin.Log then
    AK.Admin.Log("Keeper", "ae hold", u.name or identity, AK.FormatAE(before), AK.FormatAE(after) .. " " .. why ..
                 ((held and held > 0) and (", " .. AK.FormatAE(held) .. " AE held") or "") .. (note and (" - " .. note) or ""))
  end
  if I.onFlag then I.onFlag(identity, u, why) end
end

-- A reported total: accept the plausible part, hold the rest. Returns the AE accepted.
function I.Evaluate(identity, u, st, raw, now)
  local gain = raw - (st.disc or 0) - (st.hold or 0) - st.acc
  if gain <= 0 then return 0 end
  local budget, posted, offline = I.Allowed(u, st, now)
  local take = gain
  if take > budget + posted then take = budget + posted end
  local before = st.acc
  st.acc = st.acc + take
  if take - posted > 0 then st.used = (st.used or 0) + take - posted end
  st.posted = u.posted or 0
  local excess = gain - take
  if excess > 0 then
    st.hold = (st.hold or 0) + excess
    local note
    if offline then
      note = "logged off " .. date("%m/%d %H:%M", st.offAt) .. ", back " .. date("%m/%d %H:%M", st.backAt) ..
             ", up to " .. AK.FormatAE(budget + posted) .. " allowed"
    else
      note = "up to " .. AK.FormatAE(budget + posted) .. " allowed since " .. date("%m/%d %H:%M", st.seen or now)
    end
    I.Flag(identity, u, offline and "OFFLINE" or "SANITY", before, raw, excess, note)
  end
  return take
end

-- The player's own lifetime total (STATE_REQ / HELLO / CREDIT_ACK / their own leaderboard broadcast).
function I.Report(identity, displayName, amount, now)
  amount = math.floor(tonumber(amount) or 0)
  if not identity or amount < 0 then return 0 end
  now = now or AK.Now()
  I.KeeperAlive(now)
  local u = S.User(identity, displayName, true)
  local st = I.State(u)
  if st.acc == nil then
    -- first time the Keeper sees them: everything known so far is accepted
    local raw = I.RawEarned(identity)
    if amount > raw then raw = amount end
    I.Baseline(u, raw, now)
    return 0
  end
  if st.on == false then I.Back(st, now) end             -- a report proves they are online
  -- a lower total is remembered (restored file, wipe); accepted AE stays, so lowering and raising again gains nothing
  if st.last and amount < st.last then st.drop = { t = now, from = st.last, to = amount } end
  st.last = amount
  local took = I.Evaluate(identity, u, st, amount, now)
  st.seen = now
  st.wit = 0
  if st.backAt then st.offAt = nil st.backAt = nil st.witTail = nil end
  return took
end

-- online: [identity] = true for every member online now (Shop.ReadGuildRoster, every minute).
function I.OnRoster(online, now)
  if not AK.IsKeeper() then return end
  now = now or AK.Now()
  I.KeeperAlive(now)
  if AK.TableCount(online) == 0 then return end
  -- right after the Keeper logs in the roster may still be loading: learn who is online, record no logoffs
  local settling = not I.cur or now - I.cur.a < (tonumber(QuartermasterKeeperSettleSeconds) or 120)
  local id, u
  for id, u in pairs(AK.db.users) do
    local st = u.ae
    if type(st) == "table" and st.acc ~= nil then
      local on = online[id] == true
      if st.on == nil or settling then
        st.on = on                                -- first roster since the Keeper logged in: nothing known yet
        st.offAt = nil st.backAt = nil st.offS = nil
      elseif st.on and not on then
        st.on = false
        st.offAt = now
        st.offS = I.cur.a                         -- this Keeper session saw the logoff
        st.witTail = st.wit or 0
      elseif on and not st.on then
        I.Back(st, now)
      end
    end
  end
end

-- The Ashen Banner's own addon messages (prefix LeafVE) as the Keeper hears them. PTXN = one award the moment it
-- happens (only the owner sends it); LBOARD rows "L:name:L:G:S" for the sender are their own lifetime total.
function I.OnBannerMessage(sender, msg)
  if not AK.IsKeeper() or type(msg) ~= "string" then return end
  local id = AK.Norm(sender)
  if not id then return end
  if string.sub(msg, 1, 5) == "PTXN:" then
    local p = AK.Split(string.sub(msg, 6), "\31")
    local amount = tonumber(p[2]) or 0
    local u = AK.db.users[id]
    if AK.Norm(p[1]) == id and u and type(u.ae) == "table" and amount > 0 and amount <= 1000 then
      if u.ae.on == false then I.Back(u.ae, AK.Now()) end
      u.ae.wit = (u.ae.wit or 0) + amount
    end
  elseif string.sub(msg, 1, 7) == "LBOARD:" then
    local rows = AK.Split(string.sub(msg, 8), ",")
    local i
    for i = 1, table.getn(rows) do
      local p = AK.Split(rows[i], ":")
      if p[1] == "L" and AK.Norm(p[2]) == id then
        local total = (tonumber(p[3]) or 0) + (tonumber(p[4]) or 0) + (tonumber(p[5]) or 0)
        if total > 0 then S.NoteReported(id, sender, total) end
      end
    end
  end
end

-- The player's client found its signed AE data changed outside the game (tf = when it noticed; tb/ta = its own
-- total before/after). Each detection flags once.
function I.NoteTamper(identity, displayName, tf, tb, ta)
  if not identity or not tf or tf == "" or tf == "0" then return false end
  local u = S.User(identity, displayName, true)
  local st = I.State(u)
  if st.tamperSeen == tostring(tf) then return false end
  st.tamperSeen = tostring(tf)
  I.Flag(identity, u, "TAMPER", tonumber(tb) or 0, tonumber(ta) or 0, 0, "AE data changed while the game was closed")
  return true
end

function I.OnHold(identity)
  local u = AK.db.users[identity]
  local st = u and u.ae
  return type(st) == "table" and (st.flag ~= nil or st.frz == true)
end

-- "SANITY", "OFFLINE,TAMPER", "FROZEN"... or nil.
function I.HoldCode(identity)
  local u = AK.db.users[identity]
  local st = u and u.ae
  if type(st) ~= "table" then return nil end
  local c = st.flag and st.flag.why
  if st.frz then c = c and (c .. ",FROZEN") or "FROZEN" end
  return c
end

I.TEXT = {
  SANITY = "more AE than can be earned in that time", OFFLINE = "AE went up while you were offline",
  TAMPER = "AE data changed outside the game", FROZEN = "spending frozen by an officer",
}

-- STATE carries the reasons as letters ("SANITY,FROZEN" <-> "SF"): it is close to the 250-character limit.
I.LETTER = { SANITY = "S", OFFLINE = "O", TAMPER = "T", FROZEN = "F" }

function I.ToLetters(code)
  if not code or code == "" then return nil end
  local parts = AK.Split(code, ",")
  local out = ""
  local i
  for i = 1, table.getn(parts) do out = out .. (I.LETTER[parts[i]] or "") end
  return out
end

function I.FromLetters(s)
  if not s or s == "" then return nil end
  local out = {}
  local i, k, v
  for i = 1, string.len(s) do
    for k, v in pairs(I.LETTER) do
      if v == string.sub(s, i, i) then table.insert(out, k) end
    end
  end
  if table.getn(out) == 0 then return "HOLD" end
  return table.concat(out, ",")
end

function I.HoldText(code)
  if not code or code == "" then return nil end
  local parts = AK.Split(code, ",")
  local out = {}
  local i
  for i = 1, table.getn(parts) do table.insert(out, I.TEXT[parts[i]] or parts[i]) end
  return table.concat(out, "; ")
end

function I.Describe(u)
  local st = I.State(u)
  return "accepted " .. (st.acc or 0) .. ", held " .. (st.hold or 0) .. ((st.adj and st.adj ~= 0) and (", adjust " .. st.adj) or "") ..
         (st.flag and (", " .. st.flag.why) or "") .. (st.frz and ", frozen" or "")
end

-- Officer decision. act: rel (release the held AE, clear the hold), dis (discard the held AE, clear the hold),
-- adj (adjustment = n), frz / unf (freeze / unfreeze spending). Returns true when act is known.
function I.Officer(u, act, n)
  local st = I.State(u)
  if act == "rel" then
    if st.acc ~= nil then st.acc = st.acc + (st.hold or 0) end
    st.hold = 0
    st.flag = nil
  elseif act == "dis" then
    if st.acc ~= nil then st.disc = (st.disc or 0) + (st.hold or 0) end
    st.hold = 0
    st.flag = nil
  elseif act == "adj" then
    st.adj = math.floor(tonumber(n) or 0)
  elseif act == "frz" then
    st.frz = true
  elseif act == "unf" then
    st.frz = nil
  else
    return false
  end
  return true
end

-- Players on hold, oldest first: { identity, name, why, before, after, held, t, frz, adj }.
function I.HoldList()
  local out = {}
  local id, u
  for id, u in pairs(AK.db.users) do
    local st = u.ae
    if type(st) == "table" and (st.flag or st.frz) then
      local f = st.flag or {}
      table.insert(out, { identity = id, name = u.name or id, why = I.HoldCode(id), before = f.before or st.acc or 0,
                          after = f.after or st.last or 0, held = st.hold or 0, t = f.t or 0, frz = st.frz, adj = st.adj, note = f.note })
    end
  end
  table.sort(out, function(a, b) if a.t ~= b.t then return a.t < b.t end return a.identity < b.identity end)
  return out
end

-- Keeper login / reload / relog (also after a crash): a new online interval, who is online starts unknown and no
-- logoff seen before counts; the first run of this version accepts every known total as it is.
function I.Start(now)
  now = now or AK.Now()
  I.KeeperLogin(now)
  local id, u
  for id, u in pairs(AK.db.users) do
    if type(u.ae) == "table" then u.ae.on = nil u.ae.offAt = nil u.ae.backAt = nil u.ae.witTail = nil u.ae.offS = nil end
  end
  if AK.db.aeBaselined then return 0 end
  local n = 0
  for id, u in pairs(AK.db.users) do
    if type(u.ae) ~= "table" or u.ae.acc == nil then
      I.Baseline(u, I.RawEarned(id), now)
      n = n + 1
    end
  end
  AK.db.aeBaselined = now
  if AK.Admin and AK.Admin.Log then AK.Admin.Log("Keeper", "migrate", "AE fail-safe baseline", "-", n .. " players") end
  return n
end

------------------------------------------------------------------------------
-- Player side: signature over the Ashen Banner's AE rows (LeafVE_DB, saved with that addon). Signed at every
-- logout / reload, checked at login before the Ashen Banner changes anything, so only edits made while the game
-- was closed show up. A keyed hash in plain Lua: it stops casual editing, not a determined programmer (the
-- Keeper's own checks above do not depend on it).
------------------------------------------------------------------------------
I.KEY = "AshenBanner|Grizzwick|ledger|v1"

function I.Hash(s)
  local key = I.KEY
  local klen = string.len(key)
  local a, b = 5381, 52711
  local i
  for i = 1, string.len(s) do
    local c = string.byte(s, i)
    local k = string.byte(key, math.mod(i - 1, klen) + 1)
    a = math.mod(a * 131 + c + k, 2147483629)
    b = math.mod(b * 257 + c * 7 + k * 3, 2147483587)
  end
  return string.format("%08x%08x", a, b)
end

local function Row(v)
  if type(v) == "table" then
    return string.format("%.2f,%.2f,%.2f", tonumber(v.L) or 0, tonumber(v.G) or 0, tonumber(v.S) or 0)
  end
  return string.format("%.2f", tonumber(v) or 0)
end

local function RowFor(tbl, me)
  if type(tbl) ~= "table" then return "-" end
  local name, v
  for name, v in pairs(tbl) do
    if type(name) == "string" and string.lower(name) == me then return Row(v) end
  end
  return "-"
end

-- Canonical text of this character's AE data: every lifetime row it keeps (sorted) + its own leaderboard rows.
function I.BannerText(me)
  if type(LeafVE_DB) ~= "table" or type(LeafVE_DB.alltime) ~= "table" or not me then return nil end
  me = string.lower(me)
  local names = {}
  local name
  for name in pairs(LeafVE_DB.alltime) do
    if type(name) == "string" then table.insert(names, name) end
  end
  table.sort(names)
  local parts = { me }
  local i
  for i = 1, table.getn(names) do table.insert(parts, names[i] .. "=" .. Row(LeafVE_DB.alltime[names[i]])) end
  table.insert(parts, "lb=" .. RowFor(type(LeafVE_DB.lboard) == "table" and LeafVE_DB.lboard.alltime, me))
  table.insert(parts, "gc=" .. RowFor(type(LeafVE_GlobalDB) == "table" and type(LeafVE_GlobalDB.lboardCache) == "table" and
                                       LeafVE_GlobalDB.lboardCache.alltime, me))
  return table.concat(parts, ";")
end

function I.SignBanner()
  local me = AK.Norm(AK.MyName())
  local text = I.BannerText(me)
  if not text then return false end
  LeafVE_DB.aeSig = { h = I.Hash(text), t = AK.Now(), n = math.floor(I.RawEarned(me) or 0) }
  AK.db.aeSigned = AK.db.aeSigned or {}
  AK.db.aeSigned[me] = AK.Now()
  return true
end

-- true = matches, false = changed (remembered in LeafVE_DB.aeTamper), nil = nothing signed yet.
function I.VerifyBanner()
  local me = AK.Norm(AK.MyName())
  local text = I.BannerText(me)
  if not text then return nil end
  local sig = LeafVE_DB.aeSig
  local now = math.floor(I.RawEarned(me) or 0)
  if type(sig) ~= "table" or not sig.h then
    if AK.db.aeSigned and AK.db.aeSigned[me] then
      LeafVE_DB.aeTamper = { t = AK.Now(), before = 0, after = now, why = "signature removed" }
      return false
    end
    return nil
  end
  if sig.h == I.Hash(text) then return true end
  LeafVE_DB.aeTamper = { t = AK.Now(), before = sig.n or 0, after = now, why = "AE data changed" }
  return false
end

-- Adds the tamper flag (tf = when it was noticed, tb/ta = total before/after) to a message for the Keeper.
function I.TamperFields(f)
  local t = type(LeafVE_DB) == "table" and LeafVE_DB.aeTamper
  if type(t) == "table" and t.t then
    f.tf = t.t
    f.tb = math.floor(tonumber(t.before) or 0)
    f.ta = math.floor(tonumber(t.after) or 0)
  end
  return f
end
