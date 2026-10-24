-- GENERATED from AshenKeeper\AshenKeeper_Client.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Player side of the Quartermaster protocol: the local cache the window reads, every Keeper -> player message, and
-- the player -> Keeper requests. Shared by AshenKeeper and The Ashen Banner (LeafVillageLegends\Quartermaster gets
-- an identical copy), so nothing here may depend on the Keeper-only files (Trade, Transactions, Stock bag scans).

local AK = AshenKeeper
local P = AK.Protocol

AK.Player = AK.Player or {}
local PL = AK.Player

AK.KEEPER_PING_SECONDS = 25
AK.KEEPER_OFFLINE_AFTER = 75

------------------------------------------------------------------------------
-- PLAYER SIDE: cache + handlers
------------------------------------------------------------------------------
function PL.IsKeeperOnline()
  if AK.IsKeeper() then return true end
  return AK.keeperSeen ~= nil and (AK.Clock() - AK.keeperSeen) < AK.KEEPER_OFFLINE_AFTER
end

function PL.Shop()
  AK.cache.shop = AK.cache.shop or {}
  return AK.cache.shop
end

function PL.Board()
  AK.cache.board = AK.cache.board or {}
  return AK.cache.board
end

local function UIRefresh()
  if AK.UI and AK.UI.RefreshPlayer then AK.UI.RefreshPlayer() end
end

local function UIMessage(text, good)
  if AK.UI and AK.UI.Message then AK.UI.Message(text, good) end
end

P.On("KEEPER_PING", function(sender, f)
  if AK.IsKeeper() then return end
  local known = AK.Norm(AK.db.config.keeperName)
  if known and known ~= AK.Norm(sender) then return end            -- ignore impostors
  if not known and AK.cache.keeperName and AK.cache.keeperName ~= "" and AK.Norm(AK.cache.keeperName) ~= AK.Norm(sender) then
    return                                                          -- first-seen Keeper stays locked in
  end
  AK.cache.keeperName = sender
  AK.keeperSeen = AK.Clock()
  AK.cache.keeperVersion = f.v
  AK.cache.keeperMinClient = f.mv
  PL.CheckVersion(f.v, f.mv)
  UIRefresh()
end)

-- The Keeper needs a newer client than this one (mv = the oldest it works with, from a 1.3.2+ Keeper; an older
-- Keeper only sends its own version kv): remember it (the window shows it) and say so once a session.
function PL.CheckVersion(kv, mv)
  local need = mv or kv
  if not need or not AK.VersionLess(AK.VERSION, need) then return false end
  AK.outdated = need
  if not AK.outdatedTold then
    AK.outdatedTold = true
    local text
    if AK.host == "Banner" then
      text = "The Quartermaster window in your Ashen Banner addon (v" .. tostring(AK.HostVersion and AK.HostVersion()) ..
             ") is older than the Quartermaster's. Please update The Ashen Banner - some things may not work until you do."
    else
      text = "Your AshenKeeper addon (v" .. AK.VERSION .. ") is older than the Quartermaster's (v" .. need ..
             "). Please install the new version - some things may not work until you do."
    end
    AK.Print(text)
    UIMessage(text, false)
  end
  return true
end

-- Auction House prices the Keeper sent this officer (Manage > Log, /qm ahprices).
function PL.OnAHP(sender, f)
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  local p = AK.AH and AK.AH.Receive(sender, f)
  if p then AK.cache.ahPrices = p UIRefresh() end
end

-- Units of each shop item taken this week (Keeper 1.3.2+). Chunk 1 starts afresh; cap 0 = no per-item cap.
P.On("WEEKITEMS", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  if tonumber(f.i) == 1 or not AK.cache.weekItems then AK.cache.weekItems = { cap = tonumber(f.c) or 0, n = {} } end
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local p = AK.Split(entries[i], ":")
    if p[1] and p[1] ~= "" then AK.cache.weekItems.n[p[1]] = tonumber(p[2]) or 0 end
  end
  AK.cache.weekItems.t = AK.Now()
  UIRefresh()
end)

-- Fields that say which client this is: v = Quartermaster client version, hb = Ashen Banner version when the
-- client runs inside the Banner (the Keeper's out-of-date whisper then names the Banner).
function PL.VersionFields(f)
  f.v = AK.VERSION
  if AK.host == "Banner" and AK.HostVersion then f.hb = AK.HostVersion() end
  return f
end

local function MergeShop(f)
  local shop = PL.Shop()
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local parts = AK.Split(entries[i], ":")
    if parts[1] then
      -- fb / lvl are nil from a Keeper before 1.2.0, grp (shop sub-tab) before 1.3.2 (the UI then uses the config)
      local grp = parts[8]
      if grp == "" then grp = nil end
      shop[parts[1]] = { price = tonumber(parts[2]) or 0, avail = tonumber(parts[3]) or 0, status = parts[4] or "O", cat = parts[5] or "m",
                         fb = (parts[6] == "1") or ((parts[6] ~= "0") and nil), lvl = tonumber(parts[7]), grp = grp }
    end
  end
  AK.cache.shopTime = AK.Now()
  UIRefresh()
end
P.On("SHOP", function(sender, f) if not AK.IsKeeper() then MergeShop(f) end end)
P.On("STOCK_UPDATE", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  MergeShop(f)
end)

P.On("BOARD", function(sender, f)
  if AK.IsKeeper() then return end
  local board = PL.Board()
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local parts = AK.Split(entries[i], ":")
    if parts[1] then
      board[parts[1]] = { ae = tonumber(parts[2]) or 0, cur = tonumber(parts[3]) or 0, target = tonumber(parts[4]) or 0, flag = parts[5] or "O",
                          priority = (parts[6] == "C" and "CRITICAL") or (parts[6] == "S" and "SECONDARY") or nil,
                          baseAE = tonumber(parts[7]), on = (parts[8] ~= "0") }
    end
  end
  AK.cache.boardTime = AK.Now()
  UIRefresh()
end)

-- Officer-added board entries: code:itemID:name, and officer-added shop items: code:itemID:name:i:level.
-- Chunk 1 starts fresh lists.
P.On("MATS", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  if tonumber(f.i) == 1 or not AK.cache.customMats then AK.cache.customMats = {} end
  if tonumber(f.i) == 1 or not AK.cache.customItems then AK.cache.customItems = {} end
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local parts = AK.Split(entries[i], ":")
    local id = tonumber(parts[2]) or 0
    if parts[1] and id > 0 and parts[3] and parts[4] == "i" then
      AK.cache.customItems[AK.Shop.CustomItemKey(id)] = { code = parts[1], itemID = id, name = parts[3], lvl = tonumber(parts[5]) or 0 }
    elseif parts[1] and id > 0 and parts[3] then
      AK.cache.customMats[AK.Donations.CustomKey(id)] = { code = parts[1], itemID = id, name = parts[3], ae = 0, target = 0,
                                                          overstockAE = 0, enabled = true, priority = "SECONDARY" }
    end
  end
  AK.Shop.ApplyCustom()
  UIRefresh()
end)

P.On("ADMIN_OK", function(sender, f)
  if AK.IsKeeper() then return end
  UIMessage("Change saved (" .. tostring(f.op) .. " " .. tostring(f.k) .. "). Everyone's lists update in a moment.", true)
  AK.After("abk-admin-refresh", 2.5, function()
    P.ToKeeper("BOARD_REQ", { r = AK.Now() }, { "r" })
    if f.op == "cfg" then PL.RefreshAll() end           -- settings ride in STATE
  end)
end)

P.On("ADMIN_FAIL", function(sender, f)
  if AK.IsKeeper() then return end
  UIMessage(AK.Admin.ReasonText(f.e), false)
  -- the officer's boxes go back to the Keeper's values
  if AK.UI and AK.UI.AdminFailed then AK.UI.AdminFailed() end
end)

P.On("STATE", function(sender, f)
  if AK.IsKeeper() then return end
  if f.d and not f.b or f.b == "" then
    local text = AK.Dialogue.Text(f.d)
    if text and AK.UI and AK.UI.Say then AK.UI.Say(text) end
    return
  end
  AK.cache.state = {
    bal = tonumber(f.b) or 0, earned = tonumber(f.e) or 0, donated = tonumber(f.dn) or 0,
    spent = tonumber(f.sp) or 0, pending = tonumber(f.pe) or 0,
    majorUsed = tonumber(f.mu) or 0, majorConverted = tonumber(f.mc) or 0, majorTotal = tonumber(f.mt) or 1,
    minor = tonumber(f.mn) or 0, minorLimit = tonumber(f.ml) or 5, maxQty = tonumber(f.mx) or 1,
    weekSpent = tonumber(f.ws) or 0, weekKey = f.wk, recent = f.rc or "", t = AK.Now(),
    donatedTotal = tonumber(f.dt),
    allowance = tonumber(f.al), rank = f.rk, lifetimeBal = tonumber(f.lb), isAdmin = (f.ad == "1"),
    donCredit = tonumber(f.dc),       -- nil from an older Keeper
    kv = f.kv,
    hold = AK.Integrity.FromLetters(f.hd), holdText = AK.Integrity.HoldText(AK.Integrity.FromLetters(f.hd)), held = tonumber(f.hh),
    flamebound = (f.fe == "1") or ((f.fe ~= "0") and nil),     -- nil from an older Keeper
    minorsWithMajor = tonumber(f.mw),   -- nil from an older Keeper
  }
  PL.CheckVersion(f.kv, f.mv or (f.kv == AK.cache.keeperVersion and AK.cache.keeperMinClient) or nil)
  UIRefresh()
end)

-- Officers: players on hold for AE review (Manage > Log). Chunk 1 starts afresh.
P.On("HOLDS", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  if tonumber(f.i) == 1 or not AK.cache.holds then AK.cache.holds = {} end
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local p = AK.Split(entries[i], ":")
    if p[1] and p[1] ~= "" then
      table.insert(AK.cache.holds, { name = p[1], why = p[2], before = tonumber(p[3]) or 0, after = tonumber(p[4]) or 0,
                                     held = tonumber(p[5]) or 0, t = tonumber(p[6]) or 0, frz = (p[7] == "1"), adj = tonumber(p[8]) or 0 })
    end
  end
  AK.cache.holdsTime = AK.Now()
  UIRefresh()
end)

-- Officers: the Keeper's trade log (newest first) and weekly report, for Manage > Log. Chunk 1 starts afresh.
P.On("TLOG", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  if tonumber(f.i) == 1 or not AK.cache.tradeLog then AK.cache.tradeLog = {} end
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local p = AK.Split(entries[i], ":")
    if p[2] then
      table.insert(AK.cache.tradeLog, { t = tonumber(p[1]) or 0, who = p[2], kind = p[3], what = p[4], ae = tonumber(p[5]) or 0,
                                        res = p[6], why = p[7] })
    end
  end
  AK.cache.tradeLogTime = AK.Now()
  UIRefresh()
end)

-- My Week > Donations: one page of this player's donation history (t:ae:CODE.qty,CODE.qty). Chunk 1 starts afresh.
P.On("DHIST", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  local h = AK.cache.dhist
  if tonumber(f.i) == 1 or not h or h.pg ~= tonumber(f.pg) then
    h = { pg = tonumber(f.pg) or 1, pn = tonumber(f.pn) or 1, total = tonumber(f.tt) or 0, list = {} }
    AK.cache.dhist = h
  end
  h.t = AK.Now()
  local entries = P.SplitList(f.d)
  local i
  for i = 1, table.getn(entries) do
    local p = AK.Split(entries[i], ":")
    if p[3] then
      local items = {}
      local parts = AK.Split(p[3], ",")
      local j
      for j = 1, table.getn(parts) do
        local cq = AK.Split(parts[j], ".")
        table.insert(items, { code = cq[1], qty = tonumber(cq[2]) })
      end
      table.insert(h.list, { t = tonumber(p[1]) or 0, ae = tonumber(p[2]) or 0, items = items })
    end
  end
  UIRefresh()
end)

function PL.RequestHistory(page)
  return PL.Request("DHIST_REQ", { r = AK.Now(), p = page or 1 }, { "r", "p" })
end

P.On("WEEKLY", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  local i = tonumber(f.i) or 1
  if i == 1 or not AK.cache.weekly or AK.cache.weekly.wk ~= f.wk then AK.cache.weekly = { wk = f.wk, lines = {} } end
  AK.cache.weekly.lines[i] = f.d
  UIRefresh()
end)

P.On("CREDIT", function(sender, f)
  if AK.IsKeeper() then return end
  if AK.Norm(sender) ~= AK.Norm(AK.KeeperName()) then return end
  local ae = math.floor(tonumber(f.ae) or 0)
  if not f.x or ae <= 0 then return end
  AK.db.credited = AK.db.credited or {}
  if not AK.db.credited[f.x] then
    -- Banner addon missing or too old: leave the credit open on the Keeper (it still counts there).
    if not (LeafVE and LeafVE.AddDonationPoints) then return end
    local reason = "Quartermaster donation"
    if f.sm and f.sm ~= "" then reason = reason .. ": " .. f.sm end
    local ok, got = pcall(LeafVE.AddDonationPoints, LeafVE, ae, reason, f.lt == "1")
    if not ok or not got or got <= 0 then return end
    AK.db.credited[f.x] = AK.Now()
  end
  local mine = math.floor(AK.GetEarnedAE(AK.Norm(AK.MyName()) or "") or 0)
  P.ToKeeper("CREDIT_ACK", { x = f.x, e = mine }, { "x", "e" })
end)

local function Resolve(f, fallback)
  local text = f.d and AK.Dialogue.Text(f.d)
  return text or fallback
end

P.On("PURCHASE_OK", function(sender, f)
  if AK.IsKeeper() then return end
  if f.s == "C" then
    local key = AK.Shop.KeyByCode(f.i)
    local name = key and QuartermasterItems[key].name or "item"
    local q = tonumber(f.q) or 1
    UIMessage("PURCHASE COMPLETE\n" .. (q > 1 and (q .. "x ") or "") .. name .. "\n-" .. AK.FormatAE(f.p) .. " Ashen Ember\n" .. (Resolve(f, "")), true)
  else
    local q = tonumber(f.q) or 1
    UIMessage("Order accepted" .. (q > 1 and (" (" .. q .. " items)") or "") .. ". The Quartermaster will open a trade with you. Stay close and accept it.", true)
  end
  UIRefresh()
end)

P.On("PURCHASE_FAIL", function(sender, f)
  if AK.IsKeeper() then return end
  UIMessage(AK.Shop.ReasonText(f.e) .. "\n" .. Resolve(f, ""), false)
  UIRefresh()
end)

P.On("DONATE_OK", function(sender, f)
  if AK.IsKeeper() then return end
  if f.s == "C" then
    UIMessage("CONTRIBUTION ACCEPTED\n" .. tostring(f.sm or "") .. "\n+" .. AK.FormatAE(f.ae) .. " Ashen Ember\n" .. Resolve(f, ""), true)
    AK.cache.dhist = nil                -- My Week > Donations asks for the new history next time
    if AK.UI and AK.UI.ClearBasket then AK.UI.ClearBasket() end
  elseif f.s == "W" then
    UIMessage("DONATION TRADE\n" .. tostring(f.sm or ""), f.ok == "1")
  else
    UIMessage("DONATION REGISTERED" .. ((f.nt and f.nt ~= "") and ("  (" .. f.nt .. ")") or "") ..
              "\nGrizzwick will open a trade. Put exactly: " .. tostring(f.sm or "") ..
              "\nReward: " .. AK.FormatAE(f.ae) .. " AE once the trade completes.", true)
  end
  UIRefresh()
end)

P.On("DONATE_FAIL", function(sender, f)
  if AK.IsKeeper() then return end
  local why = "The contribution could not be completed. Nothing changed."
  if f.e == "NO_TRADE" then why = "I could not open a trade with you. Stay close to me and press Donate Selected again." end
  if f.e == "CANCELLED" then why = "Trade closed. Nothing was taken or paid. Press Donate Selected again when you are ready." end
  if f.e == "FULL" then why = "That requisition is fulfilled. No more is needed." end
  if f.e == "NO_SPACE" then why = "The Quartermaster's bags are full. Donations are paused." end
  UIMessage(why .. "\n" .. Resolve(f, ""), false)
  UIRefresh()
end)

-- Player -> Keeper requests -------------------------------------------------
function PL.Request(msgType, fields, order)
  if not PL.IsKeeperOnline() then
    UIMessage(AK.Shop.ReasonText("NO_KEEPER"), false)
    return false
  end
  return P.ToKeeper(msgType, fields, order)
end

function PL.RefreshAll()
  -- Our own lifetime total, so the Keeper can show the real balance even for members whose points it has
  -- not seen broadcast yet.
  local me = AK.Norm(AK.MyName()) or ""
  local mine = AK.GetEarnedAE(me)
  local wk = AK.Shop.WeekKey()
  local week = AK.GetWeekEarnedAE(me, wk)
  P.ToKeeper("STATE_REQ", AK.Integrity.TamperFields(PL.VersionFields({ r = AK.Now(), e = math.floor(mine or 0), w = math.floor(week or 0), wk = wk })),
             { "r", "e", "w", "wk", "v", "hb", "tf", "tb", "ta" })
  P.ToKeeper("SHOP_REQ", { r = AK.Now() }, { "r" })
  P.ToKeeper("BOARD_REQ", { r = AK.Now() }, { "r" })
end

function PL.Purchase(key, qty)
  local item = QuartermasterItems[key]
  if not item then return end
  qty = math.floor(tonumber(qty) or 1)
  if qty < 1 then qty = 1 end
  PL.Request("PURCHASE_REQ", { r = AK.Now(), i = item.code, q = qty }, { "r", "i", "q" })
end

-- Officer change (Manage tab). fields: op = set|add|remove|shop|ae, k = code (ae: player name), plus ae/tg/pr/en,
-- id/n (add), p/rs/fb/gr (shop; fb = Flamebound only 1/0, gr = shop sub-tab), a (ae: rel|dis|adj|frz|unf).
function PL.Admin(fields)
  fields.r = AK.Now()
  return PL.Request("ADMIN_REQ", fields, { "r", "op", "k", "a", "id", "n", "ae", "tg", "pr", "en", "p", "rs", "fb", "gr" })
end

-- Lifetime + weekly total and the tamper flag, for HELLO (sent at login, so the Keeper's offline-jump check sees
-- the first total after logging in).
function PL.HelloFields()
  local me = AK.Norm(AK.MyName()) or ""
  local wk = AK.Shop.WeekKey()
  return AK.Integrity.TamperFields(PL.VersionFields({ e = math.floor(AK.GetEarnedAE(me) or 0),
                                     w = math.floor(AK.GetWeekEarnedAE(me, wk) or 0), wk = wk }))
end
PL.HELLO_ORDER = { "v", "hb", "e", "w", "wk", "tf", "tb", "ta" }

-- Sent once, a few seconds after login (Main / the Banner's QM_Main.lua).
function PL.SendHello()
  return AK.Protocol.Send("HELLO", PL.HelloFields(), PL.HELLO_ORDER)
end

-- basket: { [materialKey] = quantity }
function PL.DonateBasket(basket)
  local entries = {}
  local key, qty
  for key, qty in pairs(basket) do
    local m = AK.Donations.Base(key)
    qty = math.floor(tonumber(qty) or 0)
    if m and qty >= 1 then table.insert(entries, m.code .. ":" .. qty) end
  end
  if table.getn(entries) == 0 then UIMessage("Select at least one material to donate.", false) return false end
  if table.getn(entries) > 20 then UIMessage("That is too many different materials for one trade (20 max).", false) return false end
  return PL.Request("DONATE_REQ", { r = AK.Now(), l = table.concat(entries, ";") }, { "r", "l" })
end
