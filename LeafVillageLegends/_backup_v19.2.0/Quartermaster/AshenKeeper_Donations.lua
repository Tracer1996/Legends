-- GENERATED from AshenKeeper\AshenKeeper_Donations.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Donation / requisition board (Keeper side logic).
-- AE is only awarded for items that really arrived in a completed trade. Pressing "Donate"
-- merely registers an intent so the Keeper knows to expect that player.

AshenKeeper.Donations = AshenKeeper.Donations or {}
local AK = AshenKeeper
local D = AK.Donations

D.INTENT_TTL = 600

------------------------------------------------------------------------------
-- Material config (static + admin overrides in AshenKeeperDB.mats)
------------------------------------------------------------------------------
-- Every donatable thing: the requisition materials first, then the shop items (potions, flasks...) which are
-- accepted at a fraction of their shop price with no target. A shop item that is the same thing as a material
-- (same name) is only listed once, as the material.
-- Board entries officers added (Admin.lua). The Keeper keeps them in its DB; players get them by MATS message.
function D.CustomTable()
  if AK.db and AK.db.customMats and AK.IsKeeper() then return AK.db.customMats end
  if AK.cache and AK.cache.customMats then return AK.cache.customMats end
  return (AK.db and AK.db.customMats) or {}
end

function D.Custom(key)
  return D.CustomTable()[key]
end

-- A config material an officer removed from the board (Keeper side; players simply never get it in BOARD).
function D.Removed(key)
  local o = AK.db and AK.db.mats and AK.db.mats[key]
  return o ~= nil and o.removed == true
end

function D.AllKeys()
  if D.allKeys then return D.allKeys end
  local out = {}
  local names = {}
  local i
  for i = 1, table.getn(QuartermasterMaterialOrder) do
    local k = QuartermasterMaterialOrder[i]
    if not D.Removed(k) then table.insert(out, k) end
    names[string.lower(QuartermasterMaterials[k].name)] = true
  end
  local ck, c
  for ck, c in pairs(D.CustomTable()) do
    table.insert(out, ck)
    names[string.lower(c.name)] = true
  end
  if (QuartermasterItemDonationRate or 0) > 0 then
    for i = 1, table.getn(QuartermasterOrder) do
      local k = QuartermasterOrder[i]
      if not names[string.lower(QuartermasterItems[k].name)] then table.insert(out, k) end
    end
  end
  D.allKeys = out
  return out
end

function D.IsItem(key)
  return QuartermasterMaterials[key] == nil and QuartermasterItems[key] ~= nil
end

-- Donation priority of a shop item: officer override, else its shop priority.
local function ItemPriority(key)
  local o = AK.db and AK.db.items and AK.db.items[key]
  return (o and o.donatePriority) or QuartermasterItems[key].priority or "SECONDARY"
end

-- Static facts about a donatable key (name, code, itemID) for both the Keeper and players.
function D.Base(key)
  local m = QuartermasterMaterials[key] or D.Custom(key)
  if m then return m end
  local it = QuartermasterItems[key]
  if it then
    return { code = it.code, itemID = it.itemID, name = it.name, priority = ItemPriority(key), ae = 0, target = 0, isItem = true }
  end
  return nil
end

function D.Mat(key)
  if D.IsItem(key) then
    local item = AK.Shop and AK.Shop.Item(key) or QuartermasterItems[key]
    -- Per-item reward (admin override, then config), else the flat rate; capped at half the live price.
    local o = AK.db and AK.db.items and AK.db.items[key]
    local ae = (o and o.donateAE) or QuartermasterItems[key].donateAE
    if ae == nil then ae = (item.price or 0) * (QuartermasterItemDonationRate or 0) end
    ae = math.floor(math.min(ae, (item.price or 0) * 0.5))
    -- needed until the Keeper holds this many (officer override, per-item config, then the general target)
    local target = (o and o.donateTarget) or QuartermasterItems[key].donateTarget or QuartermasterItemDonationTarget or 0
    return {
      key = key, code = item.code, itemID = item.itemID, name = item.name, locked = false,
      ae = ae, target = target, overstockAE = 0,
      enabled = (item.enabled ~= false) and ae > 0 and not (o and o.donateEnabled == false),
      priority = ItemPriority(key), isItem = true,
    }
  end
  local base = QuartermasterMaterials[key] or D.Custom(key)
  if not base then return nil end
  local o = AK.db.mats[key] or {}
  local m = {
    key = key, code = base.code, itemID = base.itemID, name = base.name, locked = base.locked,
    ae = base.ae, target = base.target, overstockAE = base.overstockAE,
    enabled = base.enabled, priority = base.priority,
  }
  if o.ae ~= nil then m.ae = o.ae end
  if o.target ~= nil then m.target = o.target end
  if o.overstockAE ~= nil then m.overstockAE = o.overstockAE end
  if o.enabled ~= nil then m.enabled = o.enabled end
  if o.priority ~= nil then m.priority = o.priority end
  return m
end

function D.KeyByCode(code)
  local i
  local all = D.AllKeys()
  for i = 1, table.getn(all) do
    local k = all[i]
    if D.Base(k).code == code then return k end
  end
  return nil
end

function D.KeyByName(name)
  local lname = AK.Norm(name)
  if not lname then return nil end
  local i
  local all = D.AllKeys()
  for i = 1, table.getn(all) do
    local k = all[i]
    local b = D.Base(k)
    if string.lower(b.name) == lname or string.lower(b.code) == lname then return k end
  end
  return nil
end

-- Current stocked quantity of a material (bag scan, or tracked number in manual mode).
function D.Current(key)
  local m = D.Mat(key)
  if not m then return 0 end
  if AK.db.config.stockMode == "manual" then
    local o = AK.db.mats[key]
    return (o and o.current) or 0
  end
  return AK.Stock.CountEntry(m)
end

function D.SetCurrent(key, n)
  if not AK.db.mats[key] then AK.db.mats[key] = {} end
  AK.db.mats[key].current = math.max(0, math.floor(tonumber(n) or 0))
end

-- Remaining quantity the guild still wants (never negative).
function D.Remaining(key)
  local m = D.Mat(key)
  if not m then return 0 end
  local r = m.target - D.Current(key)
  if r < 0 then r = 0 end
  return r
end

-- AE per item right now (0 once the target is met and there is no overstock reward).
function D.RewardEach(key)
  local m = D.Mat(key)
  if not m or not m.enabled then return 0 end
  if D.Remaining(key) > 0 then return m.ae end
  return m.overstockAE or 0
end

-- "O" open, "F" fulfilled (target met: nothing more is accepted), "D" disabled (also while the Keeper's bags are full)
function D.Flag(key)
  local m = D.Mat(key)
  if not m or not m.enabled then return "D" end
  if not AK.Stock.HasDonationSpace() then return "D" end
  if D.Remaining(key) <= 0 then return "F" end
  return "O"
end

-- How many units can still be accepted: never more than the board still needs (an overstock reward no
-- longer opens it up; that stops the shop being flooded for AE).
function D.MaxAccept(key)
  local m = D.Mat(key)
  if not m or not m.enabled then return 0 end
  return D.Remaining(key)
end

-- AE for quantity qty of key: units up to the target pay ae, extra units pay overstockAE.
function D.Reward(key, qty)
  local m = D.Mat(key)
  if not m or not m.enabled then return 0 end
  local rem = D.Remaining(key)
  local normal = qty
  if normal > rem then normal = rem end
  local extra = qty - normal
  return normal * m.ae + extra * (m.overstockAE or 0)
end

function D.WireEntries()
  local out = {}
  local i
  local all = D.AllKeys()
  for i = 1, table.getn(all) do
    local key = all[i]
    local m = D.Mat(key)
    local pri = (m.priority == "CRITICAL") and "C" or "S"
    -- code:payNow:current:target:flag:priority(C/S):configuredAE:enabled(1/0)
    table.insert(out, m.code .. ":" .. D.RewardEach(key) .. ":" .. D.Current(key) .. ":" .. m.target .. ":" .. D.Flag(key) .. ":" .. pri ..
                      ":" .. m.ae .. ":" .. (m.enabled and "1" or "0"))
  end
  return out
end

-- MATS message entries for officer-added board entries: code:itemID:name (':' and ';' in names become ' ').
function D.CustomWire()
  local out = {}
  local key, c
  for key, c in pairs(D.CustomTable()) do
    local name = string.gsub(string.gsub(c.name, ":", " "), ";", " ")
    table.insert(out, c.code .. ":" .. (c.itemID or 0) .. ":" .. name)
  end
  -- officer-added shop items ride along: code:itemID:name:i:level (Shop.ApplyCustom on the player)
  if AK.IsKeeper() and AK.db and AK.db.customItems then
    for key, c in pairs(AK.db.customItems) do
      local name = string.gsub(string.gsub(c.name, ":", " "), ";", " ")
      table.insert(out, c.code .. ":" .. (c.itemID or 0) .. ":" .. name .. ":i:" .. (c.lvl or 0))
    end
  end
  return out
end

-- Key for an officer-added entry; the code carries the itemID so players can rebuild it.
function D.CustomKey(itemID) return "CUSTOM_" .. itemID end
function D.CustomCode(itemID) return "X" .. itemID end

------------------------------------------------------------------------------
-- Intents (player pressed Donate -> Keeper expects a trade)
------------------------------------------------------------------------------
-- itemsOrKey: an array of { key, qty } (the donation basket) or, for the old single-item form, a key + qty.
function D.SetIntent(identity, displayName, itemsOrKey, qty)
  local items
  if type(itemsOrKey) == "table" then items = itemsOrKey else items = { { key = itemsOrKey, qty = qty } } end
  AK.db.donationIntents[identity] = {
    name = displayName, items = items, t = AK.Now(),
    key = items[1] and items[1].key, qty = items[1] and items[1].qty,      -- legacy fields
  }
end

-- "10x Elemental Fire, 5x Firebloom"
function D.IntentSummary(intent)
  local out = {}
  local i
  for i = 1, table.getn(intent.items or {}) do
    local it = intent.items[i]
    local m = D.Mat(it.key)
    table.insert(out, it.qty .. "x " .. (m and m.name or it.key))
  end
  return table.concat(out, ", ")
end

function D.IntentAE(intent)
  local total = 0
  local i
  for i = 1, table.getn(intent.items or {}) do total = total + D.Reward(intent.items[i].key, intent.items[i].qty) end
  return total
end

-- Exact match between what the donor declared and what is in the trade window.
-- agg = { [materialKey] = quantityInWindow }.  Returns true, or false + a short human reason.
function D.CompareOffer(intent, agg)
  local want = {}
  local order = {}
  local i
  for i = 1, table.getn(intent.items or {}) do
    local it = intent.items[i]
    if not want[it.key] then want[it.key] = 0; table.insert(order, it.key) end
    want[it.key] = want[it.key] + it.qty
  end
  local problems = {}
  for i = 1, table.getn(order) do
    local key = order[i]
    local have = agg[key] or 0
    local m = D.Mat(key)
    if have < want[key] then
      table.insert(problems, "need " .. (want[key] - have) .. " more " .. m.name)
    elseif have > want[key] then
      table.insert(problems, "remove " .. (have - want[key]) .. " " .. m.name)
    end
  end
  local key, qty
  for key, qty in pairs(agg) do
    if not want[key] then
      local m = D.Mat(key)
      table.insert(problems, "remove " .. (m and m.name or key) .. " (not in your donation)")
    end
  end
  if table.getn(problems) == 0 then return true end
  return false, table.concat(problems, "; ")
end

-- Longer than the other trades: the donor has to find and place every item.
D.TRADE_TIMEOUT = 240

function D.GetIntent(identity)
  local it = AK.db.donationIntents[identity]
  if it and (AK.Now() - it.t) > D.INTENT_TTL then
    AK.db.donationIntents[identity] = nil
    return nil
  end
  return it
end

function D.ClearIntent(identity)
  AK.db.donationIntents[identity] = nil
end

------------------------------------------------------------------------------
-- Completion: items = array of { key, qty } actually received in the finished trade.
-- Returns total AE awarded.
------------------------------------------------------------------------------
function D.Complete(identity, displayName, items)
  local total = 0
  local u = AK.Shop.User(identity, displayName, true)
  local i
  local summary = ""
  local hist = D.History(identity)
  local rec = { t = AK.Now(), ae = 0, l = {} }
  for i = 1, table.getn(items) do
    local it = items[i]
    -- ae is normally precomputed at trade-accept time (before the bag rescan changes
    -- "current"); computing it here is only for callers that have no earlier snapshot.
    local ae = it.ae
    if ae == nil then ae = D.Reward(it.key, it.qty) end
    total = total + ae
    local m = D.Mat(it.key)
    if AK.db.config.stockMode == "manual" then
      D.SetCurrent(it.key, D.Current(it.key) + it.qty)
    end
    AK.Transactions.Record({ type = "DONATION", player = u.name, what = m.name, qty = it.qty, ae = ae, status = "COMPLETED" })
    table.insert(rec.l, { c = m.code, n = m.name, q = it.qty })
    if summary ~= "" then summary = summary .. ", " end
    summary = summary .. m.name .. " x" .. it.qty
  end
  rec.ae = total
  D.AddHistory(hist, rec)
  D.EnsureCredits(u)
  u.donated = (u.donated or 0) + total
  u.donCredit = AK.Shop.DonCredit(u) + total    -- spendable until used, never expires (Shop.WeeklyBalance)
  D.AddCredit(u, total, summary, false)
  local st = AK.Transactions.Stats()
  st.donations = st.donations + 1
  st.aeAwarded = st.aeAwarded + total
  D.ClearIntent(identity)
  return total, summary
end

------------------------------------------------------------------------------
-- Donation history (My Week > Donations): per player, newest last, D.HISTORY_MAX kept.
-- u.dh = array of { t, ae, l = { { c = code, n = name, q = qty }, ... } }
------------------------------------------------------------------------------
D.HISTORY_MAX = 50
D.HISTORY_PAGE = 8

-- The player's history; the first time it is built from the Keeper's transaction log (bounded, so only the
-- donations still in it).
function D.History(identity)
  local u = AK.db.users[identity]
  if not u then return {} end
  if type(u.dh) == "table" then return u.dh end
  local out = {}
  local list = AK.db.transactions or {}
  local i
  for i = 1, table.getn(list) do
    local r = list[i]
    if r.type == "DONATION" and r.status == "COMPLETED" and AK.Norm(r.player) == identity then
      local last = out[table.getn(out)]
      if not last or last.t ~= r.t then
        last = { t = r.t or 0, ae = 0, l = {} }
        table.insert(out, last)
      end
      local key = D.KeyByName(r.what or "")
      local b = key and D.Base(key)
      table.insert(last.l, { c = b and b.code, n = r.what, q = r.qty or 1 })
      last.ae = last.ae + (r.ae or 0)
    end
  end
  while table.getn(out) > D.HISTORY_MAX do table.remove(out, 1) end
  u.dh = out
  return out
end

function D.AddHistory(hist, rec)
  table.insert(hist, rec)
  while table.getn(hist) > D.HISTORY_MAX do table.remove(hist, 1) end
end

-- DHIST entries for one page, newest first: time:ae:CODE.qty,CODE.qty (an unknown code is sent as its name).
-- Returns entries, pages, total.
function D.HistoryWire(identity, page)
  local hist = D.History(identity)
  local total = table.getn(hist)
  local per = D.HISTORY_PAGE
  local pages = math.max(1, math.ceil(total / per))
  page = math.max(1, math.min(pages, math.floor(tonumber(page) or 1)))
  local out = {}
  local i
  for i = total - (page - 1) * per, math.max(1, total - page * per + 1), -1 do
    local h = hist[i]
    local parts = {}
    local j
    for j = 1, table.getn(h.l or {}) do
      local e = h.l[j]
      local c = e.c or string.gsub(string.gsub(tostring(e.n or "?"), "[:;,%.]", " "), "^%s+", "")
      table.insert(parts, c .. "." .. (e.q or 1))
    end
    local items = table.concat(parts, ",")
    if string.len(items) > 150 then
      -- a very big basket: as many as fit, then how many more
      local cut, shown = "", 0
      for j = 1, table.getn(parts) do
        if string.len(cut) + string.len(parts[j]) + 6 > 150 then break end
        cut = (cut == "" and parts[j]) or (cut .. "," .. parts[j])
        shown = j
      end
      items = cut .. ",+" .. (table.getn(parts) - shown)
    end
    table.insert(out, (h.t or 0) .. ":" .. math.floor(h.ae or 0) .. ":" .. items)
  end
  return out, pages, total, page
end

------------------------------------------------------------------------------
-- Leaderboard credits. The Ashen Banner addon only books points on the player's own client, so every
-- completed donation is queued here and sent to the donor (CREDIT) until their client confirms it was
-- added to their lifetime + weekly totals (CREDIT_ACK). Until then it still counts via Shop.Unposted.
------------------------------------------------------------------------------
function D.AddCredit(u, ae, note, lifetimeOnly)
  ae = math.floor(tonumber(ae) or 0)
  if ae <= 0 then return end
  AK.db.nextCreditId = (AK.db.nextCreditId or 1)
  local id = tostring(AK.Now()) .. "-" .. AK.db.nextCreditId
  AK.db.nextCreditId = AK.db.nextCreditId + 1
  u.credits = u.credits or {}
  table.insert(u.credits, { x = id, ae = ae, sm = note, lt = lifetimeOnly and "1" or nil })
end

-- Donations made before credits existed: one lifetime-only credit for the whole amount.
function D.EnsureCredits(u)
  if not u or u.posted ~= nil then return end
  u.posted = 0
  if (u.donated or 0) > 0 then D.AddCredit(u, u.donated, "Earlier Quartermaster donations", true) end
end

-- Donor confirmed: the AE is on their leaderboard now. Returns true if the credit was still open.
function D.AckCredit(u, id)
  if not u or not u.credits then return false end
  local i
  for i = 1, table.getn(u.credits) do
    if u.credits[i].x == id then
      u.posted = (u.posted or 0) + u.credits[i].ae
      table.remove(u.credits, i)
      return true
    end
  end
  return false
end

------------------------------------------------------------------------------
-- Officer management (was planned as AshenKeeper_Admin.lua; kept in this file so a /reload picks it up -
-- WoW 1.12 only reads new .toc entries on a full client restart).
------------------------------------------------------------------------------
-- Officer management (Oath Captain and above) of the requisition board and the shop, through the Keeper.
-- Officers send ADMIN_REQ from their own client (Manage tab); the Keeper re-checks their guild rank on every
-- request. Every change goes into the same AshenKeeperDB override tables the Keeper's own /ak commands and
-- admin window write (db.mats / db.items), plus db.customMats for entries that are not in the config.
-- Pure logic (no frames) so it is testable. Lua 5.0.

AshenKeeper.Admin = AshenKeeper.Admin or {}
local AK = AshenKeeper
local A = AK.Admin

A.MAX_LOG = 200
A.LIMITS = { ae = 10000, target = 1000, price = 100000, reserve = 1000 }

local function Clamp(v, lo, hi)
  v = tonumber(v)
  if not v then return nil end
  v = math.floor(v)
  if v < lo then v = lo end
  if v > hi then v = hi end
  return v
end

function A.Log(who, op, what, before, after)
  local log = AK.db.adminLog
  table.insert(log, { t = AK.Now(), who = who, op = op, what = what, before = before, after = after })
  while table.getn(log) > A.MAX_LOG do table.remove(log, 1) end
end

local function DescribeBoard(key)
  local m = AK.Donations.Mat(key)
  if not m then return "-" end
  if not AK.Donations.IsItem(key) and AK.Donations.Removed(key) then return "removed" end
  return "ae=" .. m.ae .. " target=" .. m.target .. " " .. tostring(m.priority) .. " " .. (m.enabled and "on" or "off")
end

local function DescribeShop(key)
  local it = AK.Shop.Item(key)
  if not it then return "-" end
  return "price=" .. it.price .. " reserve=" .. (it.reserve or 0) .. " " .. (it.enabled and "on" or "off") ..
         (it.fb and " flamebound" or "") .. " " .. tostring(it.grp)
end

local function SetMat(key, field, value)
  if not AK.db.mats[key] then AK.db.mats[key] = {} end
  AK.db.mats[key][field] = value
end

local function SetItem(key, field, value)
  if not AK.db.items[key] then AK.db.items[key] = {} end
  AK.db.items[key][field] = value
end

-- Board key for a code the officer sent: any donatable entry, including a config material that was removed.
local function BoardKey(code)
  if not code or code == "" then return nil end
  local k = AK.Donations.KeyByCode(code)
  if k then return k end
  local key, m
  for key, m in pairs(QuartermasterMaterials) do
    if m.code == code then return key end
  end
  return nil
end

-- Reads ae / tg / pr / en from the request. Returns a table of values, or nil + reason. Nothing is changed.
local function ParseBoard(f, key)
  local v = {}
  local base = QuartermasterMaterials[key]
  if f.ae and f.ae ~= "" then
    v.ae = Clamp(f.ae, 0, A.LIMITS.ae)
    if not v.ae then return nil, "BAD_VALUE" end
    if base and base.locked and not AK.db.config.unlockLocked then return nil, "LOCKED" end
  end
  if f.tg and f.tg ~= "" then
    v.target = Clamp(f.tg, 0, A.LIMITS.target)
    if not v.target then return nil, "BAD_VALUE" end
  end
  if f.pr and f.pr ~= "" then
    if f.pr == "C" then v.priority = "CRITICAL" elseif f.pr == "S" then v.priority = "SECONDARY" else return nil, "BAD_VALUE" end
  end
  if f.en and f.en ~= "" then v.enabled = (f.en == "1") end
  return v
end

local function ApplyBoard(key, v)
  if AK.Donations.IsItem(key) then
    if v.ae ~= nil then SetItem(key, "donateAE", v.ae) end
    if v.target ~= nil then SetItem(key, "donateTarget", v.target) end
    if v.priority ~= nil then SetItem(key, "donatePriority", v.priority) end
    if v.enabled ~= nil then SetItem(key, "donateEnabled", v.enabled) end
  else
    if v.ae ~= nil then SetMat(key, "ae", v.ae) end
    if v.target ~= nil then SetMat(key, "target", v.target) end
    if v.priority ~= nil then SetMat(key, "priority", v.priority) end
    if v.enabled ~= nil then SetMat(key, "enabled", v.enabled) end
  end
end

-- Finds an existing entry for an item (config material incl. removed ones, shop item, officer-added entry).
local function FindExisting(itemID, name)
  local lname = AK.Norm(name)
  local key, m
  for key, m in pairs(QuartermasterMaterials) do
    if (itemID > 0 and m.itemID == itemID) or (lname and string.lower(m.name) == lname) then return key end
  end
  for key, m in pairs(QuartermasterItems) do
    if (itemID > 0 and m.itemID == itemID) or (lname and string.lower(m.name) == lname) then return key end
  end
  for key, m in pairs(AK.db.customMats) do
    if (itemID > 0 and m.itemID == itemID) or (lname and string.lower(m.name) == lname) then return key end
  end
  return nil
end

local function OpSet(f)
  local key = BoardKey(f.k)
  if not key then return false, "BAD_ITEM" end
  local v, why = ParseBoard(f, key)
  if not v then return false, why end
  local before = DescribeBoard(key)
  ApplyBoard(key, v)
  return true, key, before, DescribeBoard(key)
end

local function OpAdd(f)
  local itemID = math.floor(tonumber(f.id) or 0)
  local name = f.n
  if itemID > 0 and GetItemInfo then
    local known = GetItemInfo(itemID)
    if known then name = known end
  end
  if type(name) ~= "string" or AK.Trim(name) == "" or string.len(name) > 60 then return false, "BAD_ITEM" end
  name = AK.Trim(name)
  local key = FindExisting(itemID, name)
  local before = "absent"
  if key then
    before = DescribeBoard(key)
    if QuartermasterMaterials[key] then SetMat(key, "removed", nil) end
  else
    if itemID <= 0 then return false, "BAD_ITEM" end           -- new entries need an item link
    key = AK.Donations.CustomKey(itemID)
    AK.db.customMats[key] = {
      code = AK.Donations.CustomCode(itemID), itemID = itemID, name = name,
      ae = 0, target = 0, overstockAE = 0, enabled = true, priority = "SECONDARY",
    }
  end
  AK.Donations.allKeys = nil
  local v, why = ParseBoard(f, key)
  if not v then return false, why end
  if v.enabled == nil then v.enabled = true end
  ApplyBoard(key, v)
  return true, key, before, DescribeBoard(key)
end

-- Adds a shop item (Manage > Potions or Shop): buyable, and donatable like the potions. An item that is already
-- in the shop only gets the values sent; an officer-added material becomes a shop item (its AE, target and
-- priority become the donation values). p = price (default: twice the donation AE, as donations pay half),
-- ae / tg / pr = donation AE, target, priority, fb = Flamebound only. Config materials stay materials.
local function OpAddItem(f)
  local itemID = math.floor(tonumber(f.id) or 0)
  local name = f.n
  local lvl = 0
  if itemID > 0 and GetItemInfo then
    local known, _, _, minLevel = GetItemInfo(itemID)
    if known then name = known lvl = tonumber(minLevel) or 0 end
  end
  if type(name) ~= "string" or AK.Trim(name) == "" or string.len(name) > 60 then return false, "BAD_ITEM" end
  name = AK.Trim(name)
  local v, why = ParseBoard(f, nil)
  if not v then return false, why end
  local price
  if f.p and f.p ~= "" then
    price = Clamp(f.p, 1, A.LIMITS.price)
    if not price then return false, "BAD_VALUE" end
  end
  local key = FindExisting(itemID, name)
  if key and QuartermasterMaterials[key] then return false, "IS_MATERIAL" end
  local before = "absent"
  if key and QuartermasterItems[key] then
    before = DescribeShop(key)
  else
    local carry
    if key then                                   -- an officer-added material: it moves to the shop
      local m = AK.db.customMats[key]
      local o = AK.db.mats[key] or {}
      before = "material " .. DescribeBoard(key)
      itemID = m.itemID
      name = m.name
      carry = { ae = o.ae or m.ae, target = o.target or m.target, priority = o.priority or m.priority }
      AK.db.customMats[key] = nil
      AK.db.mats[key] = nil
    end
    if itemID <= 0 then return false, "BAD_ITEM" end           -- new entries need an item link
    key = AK.Shop.CustomItemKey(itemID)
    AK.db.customItems[key] = { code = AK.Shop.CustomItemCode(itemID), itemID = itemID, name = name, lvl = lvl }
    AK.Shop.ApplyCustom()
    if carry then
      if (carry.ae or 0) > 0 then SetItem(key, "donateAE", carry.ae) end
      if (carry.target or 0) > 0 then SetItem(key, "donateTarget", carry.target) end
      if carry.priority then SetItem(key, "donatePriority", carry.priority) end
    end
  end
  AK.Donations.allKeys = nil
  if v.enabled == nil then v.enabled = true end
  ApplyBoard(key, v)
  local o = AK.db.items[key] or {}
  if not price and o.price == nil and QuartermasterItems[key].custom then price = math.max(1, 2 * (o.donateAE or 0)) end
  if price then SetItem(key, "price", price) end
  if f.fb and f.fb ~= "" then SetItem(key, "fb", f.fb == "1") end
  return true, key, before, DescribeShop(key) .. ", donation " .. DescribeBoard(key)
end

-- Sagefish Delight and Scroll of Strength IV went onto the board as materials (before shop items could be
-- added); once on the Keeper they become shop items. Returns how many moved.
A.CONSUMABLE_FIX = { 21217, 10310 }
function A.MigrateConsumables()
  if AK.db.consumablesMoved then return 0 end
  AK.db.consumablesMoved = AK.Now()
  local n = 0
  local i
  for i = 1, table.getn(A.CONSUMABLE_FIX) do
    local m = AK.db.customMats[AK.Donations.CustomKey(A.CONSUMABLE_FIX[i])]
    if m and A.Local({ op = "additem", id = m.itemID, n = m.name }) then n = n + 1 end
  end
  return n
end

-- Scanned gold price of a name (median of the 5 cheapest listings), or nil when it had no listings.
local function ScanGold(p, name)
  local r = p and p.items and p.items[name]
  if not r or (r.n or 0) == 0 or not r.low then return nil end
  return r.low / 10000
end

-- Shop AE per gold: the configured rate, else the one that keeps the anchor item at its anchor price.
function A.ShopRate(p)
  if QuartermasterShopAEPerGold then return QuartermasterShopAEPerGold end
  local a = QuartermasterShopAnchor
  local base = a and QuartermasterItems[a.key]
  local g = base and ScanGold(p, base.name)
  if not g or g <= 0 then return nil end
  return a.ae / g
end

function A.RoundPrice(x)
  local step = (x >= 200) and 25 or 5
  local v = math.floor(x / step + 0.5) * step
  return math.max(QuartermasterShopMinPrice or 10, v)
end

-- Shop prices and donation AE from the last Auction House scan (AshenKeeperDB.ahPrices), see Config.lua
-- (/ak donaterate). Returns rows { key, name, gold, now, new, shopNow, shopNew, note } for every donatable entry
-- (shop items that are also a board material are listed once, as the material), the scan and the shop rate.
-- share: donation share of the shop price (0.3 or 30; default QuartermasterDonateShare).
-- new / shopNew = nil: left alone (note says why).
function A.RatePlan(share)
  share = tonumber(share) or QuartermasterDonateShare or 0.3
  if share > 1 then share = share / 100 end
  local p = AK.db.ahPrices
  local shopRate = A.ShopRate(p)
  local rows = {}
  local all = AK.Donations.AllKeys()
  local i
  for i = 1, table.getn(all) do
    local key = all[i]
    local m = AK.Donations.Mat(key)
    local isItem = AK.Donations.IsItem(key)
    local row = { key = key, name = m.name, now = m.ae, gold = ScanGold(p, m.name) }
    local notes = {}
    local shop
    if isItem then
      row.shopNow = AK.Shop.Item(key).price
      shop = row.shopNow
      if row.gold and shopRate then row.shopNew = A.RoundPrice(row.gold * shopRate) shop = row.shopNew end
    elseif row.gold and shopRate and AK.Shop.KeyByName(m.name) then
      shop = A.RoundPrice(row.gold * shopRate)            -- a material that is also sold: paid like the shop item
    end
    local want
    if shop then want = shop * share
    elseif row.gold then want = row.gold * (shopRate and share * shopRate or QuartermasterDonateAEPerGold or 250) end
    if not want then
      table.insert(notes, "not in the scan")
    elseif QuartermasterDonateAEFixed and QuartermasterDonateAEFixed[key] then
      table.insert(notes, "donation fixed")
    elseif m.locked and not AK.db.config.unlockLocked then
      table.insert(notes, "locked")
    else
      if not row.gold then table.insert(notes, "not in the scan, shop price kept") end
      row.new = math.max(1, math.floor(want + 0.5))
      if isItem and row.new > math.floor(shop * 0.5) then
        table.insert(notes, "capped at half the shop price (" .. row.new .. " wanted)")
        row.new = math.floor(shop * 0.5)
      end
    end
    if table.getn(notes) > 0 then row.note = table.concat(notes, ", ") end
    table.insert(rows, row)
  end
  return rows, p, shopRate
end

function A.ApplyRate(rows)
  local n = 0
  local i
  for i = 1, table.getn(rows) do
    local r = rows[i]
    if r.shopNew and r.shopNew ~= r.shopNow then SetItem(r.key, "price", r.shopNew) n = n + 1 end
    if r.new and r.new ~= r.now then
      if AK.Donations.IsItem(r.key) then SetItem(r.key, "donateAE", r.new) else SetMat(r.key, "ae", r.new) end
      n = n + 1
    end
  end
  A.Log((AK.MyName() or "Keeper") .. " (console)", "donaterate", n .. " entries", "-", "from AH scan")
  return n
end

local function OpRemove(f)
  local key = BoardKey(f.k)
  if not key then return false, "BAD_ITEM" end
  local before = DescribeBoard(key)
  if AK.Donations.IsItem(key) then
    SetItem(key, "donateEnabled", false)
  elseif QuartermasterMaterials[key] then
    SetMat(key, "removed", true)
  else
    AK.db.customMats[key] = nil
    AK.db.mats[key] = nil
  end
  return true, key, before, "removed"
end

local function OpShop(f)
  local key = AK.Shop.KeyByCode(f.k)
  if not key then return false, "BAD_ITEM" end
  local price, reserve
  if f.p and f.p ~= "" then
    price = Clamp(f.p, 1, A.LIMITS.price)
    if not price then return false, "BAD_VALUE" end
  end
  if f.rs and f.rs ~= "" then
    reserve = Clamp(f.rs, 0, A.LIMITS.reserve)
    if not reserve then return false, "BAD_VALUE" end
  end
  if f.gr and f.gr ~= "" and not AK.Shop.IsGroup(f.gr) then return false, "BAD_VALUE" end
  local before = DescribeShop(key)
  if price then SetItem(key, "price", price) end
  if reserve then SetItem(key, "reserve", reserve) end
  if f.gr and f.gr ~= "" then SetItem(key, "grp", f.gr) end           -- shop sub-tab (Shop.DefaultGroup)
  if f.en and f.en ~= "" then SetItem(key, "enabled", f.en == "1") end
  if f.fb and f.fb ~= "" then SetItem(key, "fb", f.fb == "1") end       -- Flamebound only (Shop.Gate)
  return true, key, before, DescribeShop(key)
end

-- AE fail-safe review (AK.Integrity): k = player name, a = rel (release held AE) | dis (discard held AE) |
-- adj (adjustment, ae = amount, may be negative) | frz | unf (freeze / unfreeze spending).
local function OpAE(f)
  local id = AK.Norm(f.k)
  local u = id and AK.db.users[id]
  if not u then return false, "BAD_PLAYER" end
  local n
  if f.a == "adj" then
    n = Clamp(f.ae, -1000000, 1000000)
    if not n then return false, "BAD_VALUE" end
  end
  local before = AK.Integrity.Describe(u)
  if not AK.Integrity.Officer(u, f.a, n) then return false, "BAD_VALUE" end
  return true, u.name or id, before, AK.Integrity.Describe(u)
end

A.ops = { set = OpSet, add = OpAdd, additem = OpAddItem, remove = OpRemove, shop = OpShop, ae = OpAE }

-- An officer decision taken on the Keeper itself (/ak release <name> ...): same op, no rank check.
function A.Local(f)
  local op = A.ops[f.op or ""]
  if not op then return false, "BAD_OP" end
  local ok, key, before, after = op(f)
  if not ok then return false, key end
  A.Log((AK.MyName() or "Keeper") .. " (console)", f.op .. (f.a and (" " .. f.a) or ""), key, before, after)
  return true, key
end

-- Entry point for ADMIN_REQ. Returns true, code-of-the-changed-entry; or false, reason.
function A.Request(sender, f)
  local identity = AshenKeeper_GetIdentity(sender)
  if not identity or not AK.Shop.IsOfficer(identity) then return false, "NOT_OFFICER" end
  local op = A.ops[f.op or ""]
  if not op then return false, "BAD_OP" end
  local ok, key, before, after = op(f)
  if not ok then return false, key end
  AK.Donations.allKeys = nil
  A.Log(sender, f.op .. ((f.op == "ae" and f.a) and (" " .. f.a) or ""), key, before, after)
  if f.op == "ae" then return true, key end
  local b = AK.Donations.Base(key) or QuartermasterItems[key]
  return true, (b and b.code) or key
end

function A.ReasonText(reason)
  if reason == "NOT_OFFICER" then return "Only Oath Captains and above can change the Quartermaster's lists." end
  if reason == "BAD_ITEM" then return "Grizzwick doesn't know that item. Shift-click it from your bags into the box." end
  if reason == "BAD_VALUE" then return "That value isn't valid." end
  if reason == "LOCKED" then return "That value is locked on the Quartermaster." end
  if reason == "BAD_PLAYER" then return "Grizzwick has no AE record for that player." end
  if reason == "BUSY" then return "Too many changes at once. Try again in a moment." end
  if reason == "IS_MATERIAL" then return "That is a requisition material. Add it on the Materials tab." end
  return "Change refused (" .. tostring(reason) .. ")."
end
