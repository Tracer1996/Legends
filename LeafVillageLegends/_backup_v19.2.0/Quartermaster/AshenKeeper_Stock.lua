-- GENERATED from AshenKeeper\AshenKeeper_Stock.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Keeper-side stock: scans the Keeper's real bags (event driven, debounced) or uses manual
-- admin numbers ("manual" stock mode, for debugging). Players never scan anything.

AshenKeeper.Stock = AshenKeeper.Stock or {}
local AK = AshenKeeper
local S = AK.Stock

S.byID = {}
S.byName = {}
S.slots = {}        -- [lowername] = array of { bag, slot, count }
S.scanned = false

local function ParseLink(link)
  if type(link) ~= "string" then return nil, nil end
  local _, _, id = string.find(link, "item:(%d+)")
  local _, _, name = string.find(link, "%[(.-)%]")
  return tonumber(id), name
end
S.ParseLink = ParseLink

-- Units in one bag or trade slot from the count the game gives. 1.12 reports an item with charges (oils,
-- wands...) as MINUS its charges ("-5"); such items never stack, so the slot holds exactly one.
function S.Units(count)
  count = tonumber(count)
  if not count then return 1 end
  if count < 0 then return 1 end
  return count
end

-- Normal bags only: herb/enchanting/soul bags and quivers cannot hold what the shop trades.
function S.IsNormalBag(bag)
  if bag == 0 then return true end
  if type(GetInventoryItemLink) ~= "function" or type(ContainerIDToInventoryID) ~= "function" or not GetItemInfo then return true end
  local id = ParseLink(GetInventoryItemLink("player", ContainerIDToInventoryID(bag)))
  if not id then return true end
  local _, _, _, _, itype, isub = GetItemInfo(id)
  if not itype then return true end
  return itype == "Container" and (isub == nil or isub == "Bag")
end

function S.ScanBags()
  S.byID = {}
  S.byName = {}
  S.slots = {}
  S.free = 0
  if type(GetContainerNumSlots) ~= "function" then return end
  local bag, slot
  for bag = 0, 4 do
    local n = GetContainerNumSlots(bag) or 0
    local normal = S.IsNormalBag(bag)
    for slot = 1, n do
      local link = GetContainerItemLink(bag, slot)
      if not link and normal then S.free = S.free + 1 end
      if link then
        local id, name = ParseLink(link)
        local _, count = GetContainerItemInfo(bag, slot)
        count = S.Units(count)
        if id then S.byID[id] = (S.byID[id] or 0) + count end
        if name then
          local lname = string.lower(name)
          S.byName[lname] = (S.byName[lname] or 0) + count
          if not S.slots[lname] then S.slots[lname] = {} end
          table.insert(S.slots[lname], { bag = bag, slot = slot, count = count, id = id })
        end
      end
    end
  end
  S.scanned = true
  S.lastScan = AK.Clock()
  if S.onScan then S.onScan() end
end

-- Called on BAG_UPDATE; collapses bursts into one scan.
function S.MarkDirty()
  if AK.db and AK.db.config.stockMode == "manual" then return end
  AK.After("abk-scan", 1.5, S.ScanBags)
end

-- Count of an entry (shop item or material) by itemID, falling back to name.
function S.CountEntry(entry)
  if not entry then return 0 end
  local n
  if entry.itemID and entry.itemID > 0 then n = S.byID[entry.itemID] end
  if (n == nil or n == 0) and entry.name then n = S.byName[string.lower(entry.name)] end
  return n or 0
end

-- Stock for a shop item key. Manual mode reads the admin number.
function S.Get(key, entry)
  if AK.db.config.stockMode == "manual" then
    local o = AK.db.items[key]
    if o and o.manualStock ~= nil then return o.manualStock end
    return entry.stock or 0
  end
  return S.CountEntry(entry)
end

function S.SetManual(key, n)
  if not AK.db.items[key] then AK.db.items[key] = {} end
  AK.db.items[key].manualStock = math.max(0, math.floor(tonumber(n) or 0))
end

-- Removes n items in manual mode (used when a test/manual order completes).
function S.AdjustManual(key, entry, delta)
  local cur = S.Get(key, entry)
  S.SetManual(key, cur + delta)
end

-- All stacks of an entry, biggest first: { { bag, slot, count }, ... }.
function S.FindSlots(entry)
  local out = {}
  if not entry or not entry.name then return out end
  local list = S.slots[string.lower(entry.name)]
  if not list then return out end
  local i
  for i = 1, table.getn(list) do table.insert(out, { bag = list[i].bag, slot = list[i].slot, count = list[i].count }) end
  table.sort(out, function(a, b) return a.count > b.count end)
  return out
end

-- Biggest stack the item can form (GetItemInfo's stack count), else the biggest stack in the bags.
function S.MaxStack(entry)
  if entry and entry.itemID and entry.itemID > 0 and GetItemInfo then
    local _, _, _, _, _, _, n = GetItemInfo(entry.itemID)
    n = tonumber(n)
    if n and n > 0 then return n end
  end
  local m = 1
  local list = S.FindSlots(entry)
  local i
  for i = 1, table.getn(list) do if list[i].count > m then m = list[i].count end end
  return m
end

-- How many units fit in ONE trade: the window has 6 slots and the Keeper stacks the order up before trading
-- (Trade.PlaceOrderItem), so up to 6 full stacks.
function S.TradeableQty(entry, maxSlots)
  local stacks = S.FindSlots(entry)
  local total = 0
  local i
  for i = 1, table.getn(stacks) do total = total + stacks[i].count end
  local cap = (maxSlots or 6) * S.MaxStack(entry)
  if total > cap then total = cap end
  return total
end

-- Donations need room in the Keeper's normal bags (QuartermasterDonationFreeSlots, default 1 empty slot).
-- Manual stock mode / before the first scan: always true.
function S.HasDonationSpace()
  if not S.scanned or (AK.db and AK.db.config.stockMode == "manual") then return true end
  return (S.free or 0) >= (QuartermasterDonationFreeSlots or 1)
end

-- Finds a stack in the bags that has at least one of the entry. Returns bag, slot, count.
function S.FindSlot(entry)
  if not entry then return nil end
  local lname = entry.name and string.lower(entry.name)
  local list = lname and S.slots[lname]
  if list and list[1] then return list[1].bag, list[1].slot, list[1].count end
  return nil
end

------------------------------------------------------------------------------
-- Auction House price scan (/ak ahscan): any character standing at an open Auction House looks up every shop
-- item and board material by name, page by page, and keeps what is listed with a buyout in AshenKeeperDB.ahPrices
-- (copper per unit). It waits while a trade window is open and while the AshenBot addon runs its own query, and
-- stops (keeping what it has) when the Auction House closes. SavedVariables reach the disk on /reload or logout.
------------------------------------------------------------------------------
AK.AH = AK.AH or {}
local AH = AK.AH
AH.MAX_PAGES = 10          -- 50 listings a page
AH.QUERY_TIMEOUT = 10      -- seconds without a fresh result before the page is asked again
AH.SETTLE = 0.6            -- the list must be quiet this long after AUCTION_ITEM_LIST_UPDATE before it is read
AH.MIN_WAIT = 0.5          -- never read a page sooner than this after asking for it
AH.MAX_RETRIES = 2
AH.STEP_SECONDS = 0.2

function AH.Money(c)
  c = math.floor(tonumber(c) or 0)
  local g = math.floor(c / 10000)
  local s = math.floor(math.mod(c, 10000) / 100)
  local out = (g > 0) and (g .. "g " .. s .. "s") or (s .. "s " .. math.mod(c, 100) .. "c")
  return out
end

-- Shop items, then board materials, then officer-added materials; each name once.
function AH.ScanList()
  local out = {}
  local seen = {}
  local function Add(e)
    if not e or type(e.name) ~= "string" or e.name == "" then return end
    local ln = string.lower(e.name)
    if seen[ln] then return end
    seen[ln] = true
    table.insert(out, { name = e.name, id = e.itemID or 0, code = e.code })
  end
  local i
  for i = 1, table.getn(QuartermasterOrder) do Add(QuartermasterItems[QuartermasterOrder[i]]) end
  for i = 1, table.getn(QuartermasterMaterialOrder) do Add(QuartermasterMaterials[QuartermasterMaterialOrder[i]]) end
  if AK.Donations and AK.Donations.CustomTable then
    local k, c
    for k, c in pairs(AK.Donations.CustomTable()) do Add(c) end
  end
  return out
end

-- listings: { { count, buyout }, ... } (buyout > 0). min / units-weighted median / median of the 5 cheapest
-- listings, all copper per unit.
function AH.Summarize(listings)
  local rows = {}
  local units = 0
  local i
  for i = 1, table.getn(listings) do
    local l = listings[i]
    local n = math.max(1, tonumber(l[1]) or 1)
    table.insert(rows, { n = n, unit = l[2] / n })
    units = units + n
  end
  local r = { n = table.getn(rows), u = units }
  if r.n == 0 then return r end
  table.sort(rows, function(a, b) return a.unit < b.unit end)
  r.min = math.floor(rows[1].unit + 0.5)
  local acc = 0
  for i = 1, r.n do
    acc = acc + rows[i].n
    if acc * 2 >= units then r.med = math.floor(rows[i].unit + 0.5) break end
  end
  local low = math.min(5, r.n)
  local mid = math.floor((low + 1) / 2)
  if math.mod(low, 2) == 1 then r.low = rows[mid].unit else r.low = (rows[mid].unit + rows[mid + 1].unit) / 2 end
  r.low = math.floor(r.low + 0.5)
  return r
end

function AH.IsOpen()
  if AH.open ~= nil then return AH.open end
  return AuctionFrame ~= nil and AuctionFrame.IsVisible ~= nil and AuctionFrame:IsVisible() and true or false
end

-- Why the scan has to wait right now (nil = it may query).
function AH.Blocked()
  if (TradeFrame and TradeFrame.IsVisible and TradeFrame:IsVisible()) or (AK.Trade and AK.Trade.cur) then return "a trade is open" end
  if AshenBotAuction and AshenBotAuction.active then return "AshenBot is running its own query" end
  return nil
end

local function EnsureAHFrame()
  if AH.frame or type(CreateFrame) ~= "function" then return end
  AH.frame = CreateFrame("Frame")
  AH.frame:RegisterEvent("AUCTION_HOUSE_SHOW")
  AH.frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
  AH.frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
  AH.frame:SetScript("OnEvent", function() AH.OnEvent(event) end)
end

function AH.Start()
  if AH.run then AK.Print("AH scan already running (" .. AH.run.i .. "/" .. table.getn(AH.run.list) .. "). /ak ahscan stop to end it.") return false end
  EnsureAHFrame()
  if not AH.IsOpen() then AK.Print("Open the Auction House first (right-click the auctioneer), then /ak ahscan.") return false end
  if type(QueryAuctionItems) ~= "function" or type(GetAuctionItemInfo) ~= "function" then AK.Print("This client has no auction query API.") return false end
  local list = AH.ScanList()
  local prev = AK.db.ahPrices
  if prev and prev.items then AK.db.ahPricesPrev = prev end
  AK.db.ahPrices = { started = AK.Now(), complete = false, who = AK.MyName(),
                     realm = (type(GetRealmName) == "function") and GetRealmName() or nil,
                     faction = (type(UnitFactionGroup) == "function") and UnitFactionGroup("player") or nil, items = {} }
  AH.run = { list = list, i = 1, page = 0, listings = {}, nobuy = 0, retries = 0, waiting = false, blocked = nil }
  AK.Print("AH scan: " .. table.getn(list) .. " items. Stay at the Auction House; it pauses during trades.")
  AK.Every("abk-ahscan", AH.STEP_SECONDS, AH.Step)
  AH.Step()
  return true
end

function AH.Finish(why)
  local run = AH.run
  if not run then return end
  AH.run = nil
  AK.Cancel("abk-ahscan")
  local p = AK.db.ahPrices
  p.t = AK.Now()
  p.complete = (why == nil)
  local n = 0
  local k
  for k in pairs(p.items) do n = n + 1 end
  if why then
    AK.Print("AH scan stopped (" .. why .. ") after " .. n .. " of " .. table.getn(run.list) .. " items. What it found is kept.")
  else
    AK.Print("AH scan done: " .. n .. " items. /reload (or log out) to write it to SavedVariables. /ak ahprices to list it.")
  end
  -- the scanner character hands its prices to the Keeper (who only takes them from QuartermasterAHScanner)
  if n > 0 and AH.IsScanner(AK.MyName()) and not AK.IsKeeper() and AK.KeeperName() then
    if AH.Send(AK.db.ahPrices, AK.KeeperName()) then AK.Print("Prices sent to " .. AK.KeeperName() .. ".") end
  end
end

function AH.IsScanner(name)
  return QuartermasterAHScanner ~= nil and AK.Norm(name) ~= nil and AK.Norm(name) == AK.Norm(QuartermasterAHScanner)
end

-- AHP messages: s = scan start, t = finish, c = complete (1/0), i / n = chunk,
-- d = code:min:med:low:listings:units:itemID;... Scanner -> Keeper after a scan, Keeper -> officer for Manage > Log.
-- The receiver matches an entry by item ID first: an officer-added item can have a different code on each side
-- (X<id> as a board material on the scanner, Y<id> once the Keeper made it a shop item).
function AH.Wire(p)
  local out = {}
  local list = AH.ScanList()
  local i
  for i = 1, table.getn(list) do
    local r = p.items[list[i].name]
    if r and list[i].code then
      table.insert(out, list[i].code .. ":" .. (r.min or "") .. ":" .. (r.med or "") .. ":" .. (r.low or "") .. ":" .. (r.n or 0) .. ":" .. (r.u or 0) ..
                        ":" .. (tonumber(list[i].id) or 0))
    end
  end
  return out
end

function AH.Send(p, target)
  if not p or not p.items or not target then return false end
  local chunks = AK.Protocol.ChunkList(AH.Wire(p), 170)
  local n = table.getn(chunks)
  if n == 0 then return false end
  local i
  for i = 1, n do
    AK.Protocol.Send("AHP", { s = p.started or 0, t = p.t or 0, c = p.complete and "1" or "0", w = p.who, i = i, n = n, d = chunks[i] },
                     { "s", "t", "c", "w", "i", "n", "d" }, target)
  end
  return true
end

-- One AHP chunk from sender. Returns the finished price table once every chunk of that scan is in, else nil.
AH.incoming = AH.incoming or {}
function AH.Receive(sender, f)
  local key = AK.Norm(sender) or "?"
  local s = tonumber(f.s) or 0
  local n = tonumber(f.n) or 1
  local i = tonumber(f.i) or 1
  local inc = AH.incoming[key]
  if not inc or inc.s ~= s or inc.n ~= n then
    inc = { s = s, n = n, got = 0, parts = {} }
    AH.incoming[key] = inc
  end
  if not inc.parts[i] then inc.got = inc.got + 1 end
  inc.parts[i] = f.d or ""
  if inc.got < n then return nil end
  AH.incoming[key] = nil
  local byCode = {}
  local byId = {}
  local list = AH.ScanList()
  local j
  for j = 1, table.getn(list) do
    if list[j].code then byCode[list[j].code] = list[j] end
    if (tonumber(list[j].id) or 0) > 0 then byId[tonumber(list[j].id)] = list[j] end
  end
  local p = { started = s, t = tonumber(f.t) or 0, complete = (f.c == "1"), who = f.w or sender, from = sender, got = AK.Now(), items = {} }
  for j = 1, n do
    local entries = AK.Protocol.SplitList(inc.parts[j])
    local k
    for k = 1, table.getn(entries) do
      local e = AK.Split(entries[k], ":")
      local it = byId[tonumber(e[7] or "") or 0] or byCode[e[1] or ""]
      if it then
        p.items[it.name] = { id = it.id, min = tonumber(e[2]), med = tonumber(e[3]), low = tonumber(e[4]),
                             n = tonumber(e[5]) or 0, u = tonumber(e[6]) or 0, t = p.t }
      end
    end
  end
  return p
end

-- The Keeper asks the scanner for a fresh scan (it answers AHSCAN_ACK: ok, or why not).
function AH.Request()
  if not QuartermasterAHScanner or QuartermasterAHScanner == "" then AK.Print("No scanner set (QuartermasterAHScanner).") return false end
  AK.Protocol.Send("AHSCAN_REQ", { r = AK.Now() }, { "r" }, QuartermasterAHScanner)
  AK.Print("Asked " .. QuartermasterAHScanner .. " for a fresh Auction House scan.")
  return true
end

-- Keeper, every half hour: the last prices are older than QuartermasterAHScanMaxAge -> ask for new ones.
function AH.CheckAge()
  local p = AK.db.ahPrices
  if p and p.t and AK.Now() - p.t < (QuartermasterAHScanMaxAge or 86400) then return false end
  if AK.Clock() - (AH.lastAsk or -100000) < 3 * 3600 then return false end      -- not every half hour while it is away
  AH.lastAsk = AK.Clock()
  AK.Protocol.Send("AHSCAN_REQ", { r = AK.Now() }, { "r" }, QuartermasterAHScanner)
  return true
end

local function NextItem(run)
  local e = run.list[run.i]
  local r = AH.Summarize(run.listings)
  r.id = e.id
  r.nb = run.nobuy
  r.t = AK.Now()
  if run.failed then r.err = "no result" end
  AK.db.ahPrices.items[e.name] = r
  AK.Print("[" .. run.i .. "/" .. table.getn(run.list) .. "] " .. e.name .. ": " ..
           (r.n > 0 and (r.n .. " listings, " .. r.u .. " units, min " .. AH.Money(r.min) .. ", median " .. AH.Money(r.med))
                    or (run.failed and "no answer from the server" or "none listed")))
  run.i = run.i + 1
  run.page = 0
  run.listings = {}
  run.nobuy = 0
  run.retries = 0
  run.failed = nil
  run.waiting = false
  if run.i > table.getn(run.list) then AH.Finish(nil) end
end

function AH.Step()
  local run = AH.run
  if not run then AK.Cancel("abk-ahscan") return end
  if not AH.IsOpen() then AH.Finish("the Auction House closed") return end
  local why = AH.Blocked()
  if why then
    if run.blocked ~= why then AK.Print("AH scan paused: " .. why .. ".") end
    run.blocked = why
    run.waiting = false            -- the page is asked again once it is clear
    return
  end
  if run.blocked then AK.Print("AH scan resumed.") run.blocked = nil end
  if run.waiting and run.updAt and AK.Clock() - run.updAt >= AH.SETTLE and AK.Clock() - run.sentAt >= AH.MIN_WAIT then
    AH.ReadPage()
    if not run.waiting or AH.run ~= run then return end
  end
  if run.waiting then
    if AK.Clock() - run.sentAt < AH.QUERY_TIMEOUT then return end
    run.retries = run.retries + 1
    run.waiting = false
    if run.retries > AH.MAX_RETRIES then run.failed = true NextItem(run) return end
  end
  if type(CanSendAuctionQuery) == "function" and not CanSendAuctionQuery() then return end
  local e = run.list[run.i]
  local ok = pcall(QueryAuctionItems, e.name, "", "", nil, nil, nil, run.page, nil, nil)
  if ok then
    run.waiting = true
    run.sentAt = AK.Clock()
    run.updAt = nil
  end
end

-- GetAuctionItemInfo: name, texture, count, quality, canUse, level, then minBid, minIncrement, buyout on 1.12
-- (some Turtle-derived clients put level-column text at #7 and the buyout one later; see AshenBot Auction.lua).
local function Buyout(r7, r8, r9, r10)
  if type(r7) == "number" then return tonumber(r9) or 0 end
  return tonumber(r10) or 0
end

-- The list changes as the answer streams in (and the event also fires for the query being sent), so the page is
-- read once it has been quiet for AH.SETTLE (Step). A page identical to the last one read is the old answer
-- still on screen: keep waiting (the timeout asks again).
function AH.OnListUpdate()
  local run = AH.run
  if not run or not run.waiting then return end
  if AH.Blocked() then run.waiting = false return end
  run.updAt = AK.Clock()
end

function AH.ReadPage()
  local run = AH.run
  local okCount, batch, total = pcall(GetNumAuctionItems, "list")
  if not okCount then return end
  batch = tonumber(batch) or 0
  total = tonumber(total) or 0
  local want = string.lower(run.list[run.i].name)
  local rows = {}
  local sig = batch .. "/" .. total
  local i
  for i = 1, batch do
    local ok, name, _, count, _, _, _, r7, r8, r9, r10 = pcall(GetAuctionItemInfo, "list", i)
    if ok and type(name) == "string" then
      local b = Buyout(r7, r8, r9, r10)
      if i <= 8 then sig = sig .. "|" .. name .. "x" .. tostring(count) .. "@" .. b end
      if string.lower(name) == want then table.insert(rows, { S.Units(count), b }) end
    end
  end
  if batch > 0 and sig == AH.lastSig then run.updAt = nil return end      -- stale: still the previous answer
  AH.lastSig = sig
  for i = 1, table.getn(rows) do
    if rows[i][2] > 0 then table.insert(run.listings, rows[i]) else run.nobuy = run.nobuy + 1 end
  end
  run.waiting = false
  run.updAt = nil
  if batch == 0 or (run.page + 1) * 50 >= total or run.page + 1 >= AH.MAX_PAGES then
    NextItem(run)
  else
    run.page = run.page + 1
    run.retries = 0
  end
end

function AH.OnEvent(ev)
  if ev == "AUCTION_HOUSE_SHOW" then AH.open = true
  elseif ev == "AUCTION_HOUSE_CLOSED" then
    AH.open = false
    if AH.run then AH.Finish("the Auction House closed") end
  elseif ev == "AUCTION_ITEM_LIST_UPDATE" then AH.OnListUpdate() end
end

-- Lines for /ak ahprices [part of a name].
function AH.Lines(filter, p)
  p = p or (AK.db and AK.db.ahPrices) or (AK.cache and AK.cache.ahPrices)
  if not p or not p.items then return { "No AH scan saved yet. Stand at the Auction House and type /ak ahscan." } end
  local out = { "AH scan " .. (p.t and date("%m/%d %H:%M", p.t) or "in progress") .. (p.complete and "" or " (partial)") ..
                " by " .. tostring(p.who) .. ", " .. tostring(p.realm) .. " " .. tostring(p.faction) }
  local list = AH.ScanList()
  local i
  for i = 1, table.getn(list) do
    local r = p.items[list[i].name]
    if r and (not filter or string.find(string.lower(list[i].name), string.lower(filter), 1, true)) then
      table.insert(out, list[i].name .. ": " .. (r.n > 0 and ("min " .. AH.Money(r.min) .. ", median " .. AH.Money(r.med) ..
                   ", low5 " .. AH.Money(r.low) .. ", " .. r.n .. " listings / " .. r.u .. " units") or "none listed"))
    end
  end
  return out
end
