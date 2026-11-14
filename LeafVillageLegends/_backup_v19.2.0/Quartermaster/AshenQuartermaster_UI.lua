-- GENERATED from AshenKeeper\AshenQuartermaster_UI.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- Player-facing Quartermaster window. Flat dark theme with ember/gold accents.
-- Tabs: Shop | Donate | Needs | My Week.  All data comes from the local cache filled by Keeper messages;
-- the window only talks to the Keeper through AK.Player.  Lua 5.0 / WoW 1.12: no '#', no '%', no varargs.

local AK = AshenKeeper
AK.UI = AK.UI or {}
local UI = AK.UI

------------------------------------------------------------------------------
-- Look
------------------------------------------------------------------------------
local FONT = "Fonts\\FRIZQT__.TTF"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local C = {
  bg      = { 0.050, 0.046, 0.052 },
  panel   = { 0.085, 0.078, 0.086 },
  panel2  = { 0.070, 0.064, 0.072 },
  hover   = { 0.130, 0.105, 0.105 },
  line    = { 0.230, 0.190, 0.170 },
  gold    = { 0.96, 0.78, 0.30 },
  ember   = { 0.80, 0.29, 0.12 },
  emberHi = { 0.96, 0.42, 0.18 },
  text    = { 0.93, 0.91, 0.87 },
  muted   = { 0.62, 0.58, 0.56 },
  green   = { 0.42, 0.86, 0.46 },
  amber   = { 0.96, 0.72, 0.26 },
  red     = { 0.92, 0.36, 0.30 },
  grey    = { 0.18, 0.17, 0.18 },
}

local ROWS = 8
local ROW_H = 48
local ROW_W = 688

UI.tab = "shop"
UI.page = { shop = 1, donate = 1, req = 1, manage = 1, week = 1 }
UI.donateSub = UI.donateSub or "items"     -- Donate tab: "items" (potions) | "mats" (materials)
UI.weekSub = UI.weekSub or "week"          -- My Week tab: "week" (this week) | "dhist" (my donation history)
UI.manageSub = UI.manageSub or "mats"      -- Manage tab: "items" | "mats" | "shop" | "log" (trade log + weekly report)
UI.addCritical = false
UI.rows = {}
UI.lastRefreshReq = 0
UI.filter = ""
UI.qtyShop = UI.qtyShop or {}
UI.basket = UI.basket or {}
UI.pending = UI.pending or {}   -- Manage tab: values sent to the Keeper and not on the board yet ("tg:CODE" -> { v, at })

-- Layout. LIST_Y is where the rows start (below the search / add row and the column headings).
local TOP_Y = -124        -- search box / add row / sub-tabs
local CTRL_H = 24
local GAP = 6
local HEAD_Y = -156       -- column headings
local LIST_Y = -168
-- Manage tab columns inside a row: { x, width }, 10px apart, Remove right after On.
UI.MCOL = { pri = { 318, 76 }, target = { 404, 56 }, ae = { 470, 64 }, on = { 544, 56 }, del = { 610, 66 } }

------------------------------------------------------------------------------
-- Small building blocks
------------------------------------------------------------------------------
local function Solid(parent, layer, color, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(color[1], color[2], color[3], a or 1)
  return t
end

local function Label(parent, size, color, justify, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(FONT, size or 12, flags)
  fs:SetTextColor(color[1], color[2], color[3])
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

local function Border(frame, color, a)
  local top = Solid(frame, "BORDER", color, a)
  top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  top:SetHeight(1)
  local bottom = Solid(frame, "BORDER", color, a)
  bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  bottom:SetHeight(1)
  local left = Solid(frame, "BORDER", color, a)
  left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  left:SetWidth(1)
  local right = Solid(frame, "BORDER", color, a)
  right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  right:SetWidth(1)
end

local function IconFor(entry)
  if entry.icon then return entry.icon end
  if entry.itemID and entry.itemID > 0 and GetItemInfo then
    local _, _, _, _, _, _, _, _, tex = GetItemInfo(entry.itemID)
    if tex then return tex end
  end
  return FALLBACK_ICON
end

local function ShowItemTooltip(owner, entry)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  -- Only hyperlink items the client already knows (unknown item links can disconnect on 1.12).
  if entry.itemID and entry.itemID > 0 and GetItemInfo and GetItemInfo(entry.itemID) then
    GameTooltip:SetHyperlink("item:" .. entry.itemID .. ":0:0:0")
  else
    GameTooltip:SetText(entry.name, 1, 1, 1)
  end
  GameTooltip:Show()
end

-- Flat button. style: "ember" (primary), "ghost" (quiet).
local function PaintButton(b)
  if b.off then
    b.bg:SetTexture(C.grey[1], C.grey[2], C.grey[3], 1)
    b.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
  elseif b.style == "ghost" then
    if b.hover then b.bg:SetTexture(C.hover[1], C.hover[2], C.hover[3], 1) else b.bg:SetTexture(C.panel[1], C.panel[2], C.panel[3], 1) end
    b.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
  else
    if b.hover then b.bg:SetTexture(C.emberHi[1], C.emberHi[2], C.emberHi[3], 1) else b.bg:SetTexture(C.ember[1], C.ember[2], C.ember[3], 1) end
    b.text:SetTextColor(1, 0.97, 0.92)
  end
end

local function MakeButton(parent, w, h, label, style)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(w)
  b:SetHeight(h)
  b.bg = Solid(b, "BACKGROUND", C.ember)
  b.bg:SetAllPoints(b)
  b.text = Label(b, 11, C.text, "CENTER", "OUTLINE")
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.text:SetText(label or "")
  b.style = style or "ember"
  b:SetScript("OnEnter", function() b.hover = true PaintButton(b) end)
  b:SetScript("OnLeave", function() b.hover = false PaintButton(b) end)
  PaintButton(b)
  return b
end

local function SetBtn(b, text, enabled)
  if text then b.text:SetText(text) end
  b.off = not enabled
  if enabled then b:Enable() else b:Disable() end
  PaintButton(b)
end

-- Small numeric box with a flat look.
local function MakeEdit(parent, w, h, size)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetWidth(w)
  box:SetHeight(h)
  box:SetFont(FONT, size or 12)
  box:SetTextColor(C.text[1], C.text[2], C.text[3])
  box:SetAutoFocus(false)
  box:SetJustifyH("CENTER")
  box.bg = Solid(box, "BACKGROUND", C.bg)
  box.bg:SetAllPoints(box)
  Border(box, C.line)
  -- Escape puts back the value the box showed; any other way of leaving the box (Enter, clicking elsewhere,
  -- Tab) hands the text to box.onCommit when one is set.
  box:SetScript("OnEscapePressed", function() box.escaped = true box:ClearFocus() end)
  box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
  box:SetScript("OnEditFocusGained", function() box.hasFocus = true box.bg:SetTexture(0.12, 0.10, 0.10, 1) end)
  box:SetScript("OnEditFocusLost", function()
    box.hasFocus = false
    box.bg:SetTexture(C.bg[1], C.bg[2], C.bg[3], 1)
    local esc = box.escaped
    box.escaped = nil
    if esc then
      if box.shown ~= nil then box:SetText(tostring(box.shown)) end
    elseif box.onCommit then
      box.onCommit()
    end
  end)
  return box
end

-- Thin progress bar. bar:Set(fraction 0..1, color)
local function MakeBar(parent, w, h)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetWidth(w)
  bar:SetHeight(h)
  bar.back = Solid(bar, "BACKGROUND", C.bg)
  bar.back:SetAllPoints(bar)
  bar.fill = Solid(bar, "ARTWORK", C.ember)
  bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
  bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
  bar.w = w
  function bar.Set(self, frac, color)
    if frac < 0 then frac = 0 end
    if frac > 1 then frac = 1 end
    local px = math.floor(self.w * frac + 0.5)
    if px < 1 then self.fill:Hide() else self.fill:Show() self.fill:SetWidth(px) end
    local col = color or C.ember
    self.fill:SetTexture(col[1], col[2], col[3], 1)
  end
  return bar
end

------------------------------------------------------------------------------
-- Data providers (static config merged with what the Keeper sent)
------------------------------------------------------------------------------
local function Matches(name)
  if UI.filter == "" then return true end
  return string.find(string.lower(name), UI.filter, 1, true) ~= nil
end

local function State() return AK.cache and AK.cache.state end

local function MyLevel()
  if type(UnitLevel) == "function" then return tonumber(UnitLevel("player")) end
  return nil
end

-- Why this player can't buy an item at all (level / rank), from what the Keeper sent (else the config).
-- The Keeper re-checks both on every purchase.
function UI.ShopBlock(lvl, fb)
  local me = MyLevel()
  if (lvl or 0) > 1 and me and me > 0 and me < lvl then return "Requires level " .. lvl .. " (you are " .. me .. ")" end
  local s = State()
  if fb and s and s.flamebound == false then return "Flamebound and higher ranks only" end
  return nil
end

-- Shop sub-tab (QuartermasterShopGroups key) the player last picked; remembered per character (AK.Pref).
function UI.ShopSub()
  if not UI.shopSub then UI.shopSub = AK.Pref("shopSub") or "all" end
  if UI.shopSub ~= "all" and not AK.Shop.IsGroup(UI.shopSub) then UI.shopSub = "all" end
  return UI.shopSub
end

function UI.SetShopSub(g)
  UI.shopSub = g
  AK.Pref("shopSub", g)
  UI.page.shop = 1
end

function UI.GroupLabel(g)
  local i
  for i = 1, table.getn(QuartermasterShopGroups or {}) do
    if QuartermasterShopGroups[i].key == g then return QuartermasterShopGroups[i].label end
  end
  return "Other"
end

function UI.GroupIndex(g)
  local i
  for i = 1, table.getn(QuartermasterShopGroups or {}) do
    if QuartermasterShopGroups[i].key == g then return i end
  end
  return nil
end

-- The sub-tab after g (wrapping, skipping All) for Manage > Shop.
function UI.NextGroupIndex(g)
  local n = table.getn(QuartermasterShopGroups or {})
  local i = UI.GroupIndex(g) or 1
  local k
  for k = 1, n do
    i = i + 1
    if i > n then i = 1 end
    if QuartermasterShopGroups[i].key ~= "all" then return i end
  end
  return nil
end

-- 1 = in stock and this player may buy it, 2 = in stock but level / rank gated, 3 = out of stock (or unknown).
local function StockGroup(d)
  if d.status ~= "O" or d.avail < 1 then return 3 end
  if d.block then return 2 end
  return 1
end

-- allGroups: every item (Manage > Shop); otherwise only the chosen Shop sub-tab.
local function ShopRows(allGroups)
  local out = {}
  local shop = AK.Player.Shop()
  local want = (not allGroups) and UI.ShopSub() or "all"
  local i
  for i = 1, table.getn(QuartermasterOrder) do
    local key = QuartermasterOrder[i]
    local base = QuartermasterItems[key]
    local c = shop[base.code]
    local grp = (c and c.grp) or AK.Shop.Item(key).grp
    if Matches(base.name) and (want == "all" or grp == want) then
      local price = (c and c.price) or AK.Shop.Item(key).price
      local status = (c and c.status) or "?"
      local avail = (c and c.avail) or 0
      local cat = (c and c.cat) or (base.requisitionType == "MAJOR" and "M" or "m")
      local lvl = (c and c.lvl) or base.lvl or 0
      local fb = c and c.fb
      if fb == nil then fb = AK.Shop.DefaultFlamebound(base) end
      table.insert(out, { key = key, entry = base, price = price, status = status, avail = avail, major = (cat == "M"),
                          lvl = lvl, fb = fb, block = UI.ShopBlock(lvl, fb), grp = grp })
    end
  end
  -- In stock and usable, then in stock but not for this player, then out of stock; each highest AE price first.
  table.sort(out, function(a, b)
    local ga, gb = StockGroup(a), StockGroup(b)
    if ga ~= gb then return ga < gb end
    if a.price ~= b.price then return a.price > b.price end
    return a.entry.name < b.entry.name
  end)
  return out
end
UI.ShopRows = ShopRows

-- Open CRITICAL needs first, then other open needs, then closed / fulfilled / unknown entries.
local function BoardGroup(d)
  if d.flag ~= "O" then return 3 end
  if d.priority == "CRITICAL" then return 1 end
  return 2
end

-- kind: "items" = shop items (potions, flasks...) that can be donated, "mats" = requisition materials.
-- Sorted by group (above), then highest AE, then name. Entries the Keeper took off the board are left out.
local function BoardRows(kind)
  local out = {}
  local board = AK.Player.Board()
  local haveBoard = AK.cache and AK.cache.boardTime
  local keys = AK.Donations.AllKeys()
  local i
  for i = 1, table.getn(keys) do
    local key = keys[i]
    local base = AK.Donations.Base(key)
    if base and ((kind == "items") == (base.isItem == true)) and Matches(base.name) then
      local c = board[base.code]
      if c or not haveBoard then
        table.insert(out, {
          key = key, entry = base, isItem = base.isItem,
          ae = (c and c.ae) or base.ae, cur = (c and c.cur) or 0, target = (c and c.target) or base.target,
          flag = (c and c.flag) or "?", priority = (c and c.priority) or base.priority,
          baseAE = (c and c.baseAE) or base.ae, on = (not c) or c.on ~= false,
        })
      end
    end
  end
  table.sort(out, function(a, b)
    local ga, gb = BoardGroup(a), BoardGroup(b)
    if ga ~= gb then return ga < gb end
    if a.ae ~= b.ae then return a.ae > b.ae end
    return a.entry.name < b.entry.name
  end)
  return out
end
UI.BoardRows = BoardRows

-- How many of each item the player carries (by lowercase name).
local function BagCounts()
  local counts = {}
  if type(GetContainerNumSlots) ~= "function" then return counts end
  local bag, slot
  for bag = 0, 4 do
    local n = GetContainerNumSlots(bag) or 0
    for slot = 1, n do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local _, name = AK.Stock.ParseLink(link)
        local _, count = GetContainerItemInfo(bag, slot)
        if name then
          local k = string.lower(name)
          counts[k] = (counts[k] or 0) + AK.Stock.Units(count)
        end
      end
    end
  end
  return counts
end

-- Units of a shop item the player could still buy right now, from what the client knows. The Keeper
-- re-checks everything; this only drives the number in the box and the greyed-out reasons.
local function ShopLimit(row)
  local s = State()
  local cap = (s and s.maxQty) or QuartermasterMaxPerOrder or 1
  local reason
  local why = "at most " .. cap .. " per purchase"   -- what limits it (shown when the box asks for more)
  local m = row.avail
  if m < cap then
    why = "only " .. m .. " in stock"
    if m < 1 then reason = "Out of stock" end
  else m = cap end
  if s then
    -- s.bal is what can be spent this week; s.lifetimeBal is the whole balance. When the whole balance
    -- would cover it but this week's does not, it is the rank allowance that stops the purchase.
    local byFunds = math.floor(s.bal / row.price)
    if byFunds < m then
      m = byFunds
      if s.allowance and s.lifetimeBal and s.lifetimeBal >= row.price * (m + 1) then
        why = "weekly allowance: " .. AK.FormatAE(s.bal) .. " AE left this week"
      else
        why = "your balance is " .. AK.FormatAE(s.bal) .. " AE"
      end
      if m < 1 then
        if s.allowance and s.lifetimeBal and s.lifetimeBal >= row.price then
          reason = "Weekly allowance reached (" .. AK.FormatAE(s.bal) .. " AE left this week" ..
                   (s.donCredit == 0 and ", no donation credit" or "") .. ")"
        else
          reason = "Need " .. AK.FormatAE(row.price - s.bal) .. " more AE"
        end
      end
    end
    local majorsLeft = s.majorTotal - s.majorUsed - s.majorConverted
    local byWeek
    if row.major then
      byWeek = majorsLeft
      local mw = s.minorsWithMajor or QuartermasterWeekly.minorsWithMajor
      if byWeek < 1 then reason = "No Major requisitions left this week"
      elseif mw and s.minor > mw then
        byWeek = 0
        reason = "No Major this week: more than " .. mw .. " minors taken"
      end
    else
      byWeek = s.minorLimit - s.minor
      if byWeek < 1 then reason = "No Minor requisitions left this week" end
    end
    if byWeek < m then
      m = byWeek
      why = row.major and "Major requisitions left this week" or "Minor requisitions left this week"
    end
  end
  -- at most N of one item per week (WEEKITEMS from a 1.3.2+ Keeper)
  local wi = AK.cache and AK.cache.weekItems
  if wi and (wi.cap or 0) > 0 then
    local left = wi.cap - (wi.n[row.entry.code] or 0)
    if left < 1 then
      left = 0
      reason = "Weekly limit reached: " .. wi.cap .. " of each item"
    end
    if left < m then
      m = left
      why = "at most " .. wi.cap .. " of each item per week"
    end
  end
  if m < 0 then m = 0 end
  return m, reason, why
end

------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------
local function BuildRow(parent, i)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(ROW_W)
  row:SetHeight(ROW_H - 2)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
  row:EnableMouse(true)

  row.bg = Solid(row, "BACKGROUND", (math.mod(i, 2) == 1) and C.panel or C.panel2)
  row.bg:SetAllPoints(row)
  row.shade = (math.mod(i, 2) == 1) and C.panel or C.panel2

  row.accent = Solid(row, "ARTWORK", C.line)
  row.accent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  row.accent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
  row.accent:SetWidth(3)

  local frame = Solid(row, "ARTWORK", C.line)
  frame:SetWidth(36)
  frame:SetHeight(36)
  frame:SetPoint("LEFT", row, "LEFT", 14, 0)
  row.icon = row:CreateTexture(nil, "OVERLAY")
  row.icon:SetWidth(34)
  row.icon:SetHeight(34)
  row.icon:SetPoint("CENTER", frame, "CENTER", 0, 0)

  row.name = Label(row, 13, C.text, "LEFT")
  row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 60, -7)
  row.name:SetWidth(250)
  row.sub = Label(row, 10, C.muted, "LEFT")
  row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", 60, -24)
  row.sub:SetWidth(250)

  row.c2 = Label(row, 11, C.text, "LEFT")
  row.c2:SetPoint("LEFT", row, "LEFT", 318, 0)
  row.c2:SetWidth(120)
  row.c1 = Label(row, 14, C.gold, "RIGHT")
  row.c1:SetPoint("LEFT", row, "LEFT", 440, 0)
  row.c1:SetWidth(86)

  row.qty = MakeEdit(row, 38, 22, 12)
  row.qty:SetPoint("LEFT", row, "LEFT", 536, 0)
  row.qty:SetNumeric(true)
  row.qty:SetMaxLetters(3)
  row.max = MakeButton(row, 30, 22, "MAX", "ghost")
  row.max:SetPoint("LEFT", row.qty, "RIGHT", 4, 0)
  row.btn = MakeButton(row, 66, 24, "Buy")
  row.btn:SetPoint("RIGHT", row, "RIGHT", -6, 0)

  row.bar = MakeBar(row, 250, 4)
  row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 60, -38)
  row.bar:Hide()

  -- Manage tab (officers): priority toggle, target, AE (or price), on/off, remove. Evenly spaced columns
  -- (UI.MCOL, also used for their headings), all 24 high.
  local M = UI.MCOL
  row.mPri = MakeButton(row, M.pri[2], 24, "Critical", "ghost")
  row.mPri:SetPoint("LEFT", row, "LEFT", M.pri[1], 0)
  row.mTarget = MakeEdit(row, M.target[2], 24, 11)
  row.mTarget:SetPoint("LEFT", row, "LEFT", M.target[1], 0)
  row.mTarget:SetNumeric(true)
  row.mTarget:SetMaxLetters(4)
  row.mAE = MakeEdit(row, M.ae[2], 24, 11)
  row.mAE:SetPoint("LEFT", row, "LEFT", M.ae[1], 0)
  row.mAE:SetNumeric(true)
  row.mAE:SetMaxLetters(6)
  row.mOn = MakeButton(row, M.on[2], 24, "On", "ghost")
  row.mOn:SetPoint("LEFT", row, "LEFT", M.on[1], 0)
  row.mDel = MakeButton(row, M.del[2], 24, "Remove", "ghost")
  row.mDel:SetPoint("LEFT", row, "LEFT", M.del[1], 0)
  row.mPri:Hide() row.mTarget:Hide() row.mAE:Hide() row.mOn:Hide() row.mDel:Hide()

  row:SetScript("OnEnter", function()
    row.bg:SetTexture(C.hover[1], C.hover[2], C.hover[3], 1)
    if row.data then ShowItemTooltip(row, row.data.entry) end
  end)
  row:SetScript("OnLeave", function()
    row.bg:SetTexture(row.shade[1], row.shade[2], row.shade[3], 1)
    GameTooltip:Hide()
  end)
  return row
end

local function Build()
  if UI.frame then return end
  local f = CreateFrame("Frame", "AshenQuartermasterFrame", UIParent)
  f:SetWidth(720)
  f:SetHeight(690)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:EnableMouseWheel(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:SetScript("OnMouseWheel", function()
    if arg1 and arg1 > 0 then UI.ChangePage(-1) else UI.ChangePage(1) end
  end)
  f.bg = Solid(f, "BACKGROUND", C.bg)   -- opaque: at 0.98 whatever sat behind the window showed through faintly
  f.bg:SetAllPoints(f)
  Border(f, C.line)
  f:Hide()
  UI.frame = f
  if UISpecialFrames then table.insert(UISpecialFrames, "AshenQuartermasterFrame") end

  -- Header
  local head = CreateFrame("Frame", nil, f)
  head:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  head:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
  head:SetHeight(76)
  head.bg = Solid(head, "BACKGROUND", C.panel)
  head.bg:SetAllPoints(head)
  local bar = Solid(head, "ARTWORK", C.ember)
  bar:SetPoint("TOPLEFT", head, "TOPLEFT", 0, 0)
  bar:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 0)
  bar:SetWidth(5)
  local rule = Solid(head, "ARTWORK", C.gold, 0.55)
  rule:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 0)
  rule:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 0)
  rule:SetHeight(1)

  local kicker = Label(head, 10, C.gold, "LEFT")
  kicker:SetPoint("TOPLEFT", head, "TOPLEFT", 22, -12)
  kicker:SetText("THE  ASHEN  BANNER")
  local title = Label(head, 24, C.text, "LEFT", "OUTLINE")
  title:SetPoint("TOPLEFT", head, "TOPLEFT", 21, -26)
  title:SetText("Quartermaster")

  UI.dot = Solid(head, "OVERLAY", C.red)
  UI.dot:SetWidth(8)
  UI.dot:SetHeight(8)
  UI.dot:SetPoint("TOPLEFT", head, "TOPLEFT", 24, -58)
  UI.online = Label(head, 10, C.muted, "LEFT")
  UI.online:SetPoint("LEFT", UI.dot, "RIGHT", 6, 0)

  -- Rank + weekly allowance + donation credit, in the free space between the title and the balance cards
  -- (four short lines; the balance card starts about 290px to the right of x = 206)
  UI.rankLine = Label(head, 9, C.gold, "LEFT")
  UI.rankLine:SetPoint("TOPLEFT", head, "TOPLEFT", 206, -20)
  UI.rankLine:SetWidth(270)
  UI.allowLine = Label(head, 9, C.muted, "LEFT")
  UI.allowLine:SetPoint("TOPLEFT", head, "TOPLEFT", 206, -32)
  UI.allowLine:SetWidth(270)
  UI.creditLine = Label(head, 9, C.muted, "LEFT")
  UI.creditLine:SetPoint("TOPLEFT", head, "TOPLEFT", 206, -44)
  UI.creditLine:SetWidth(270)
  UI.resetLine = Label(head, 9, C.muted, "LEFT")
  UI.resetLine:SetPoint("TOPLEFT", head, "TOPLEFT", 206, -56)
  UI.resetLine:SetWidth(270)

  -- Balance chips (right side)
  local card = CreateFrame("Frame", nil, head)
  card:SetWidth(176)
  card:SetHeight(52)
  card:SetPoint("TOPRIGHT", head, "TOPRIGHT", -44, -12)
  card.bg = Solid(card, "BACKGROUND", C.bg)
  card.bg:SetAllPoints(card)
  Border(card, C.gold, 0.5)
  local cl = Label(card, 9, C.muted, "LEFT")
  cl:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -7)
  cl:SetText("BALANCE")
  UI.balanceLabel = cl
  UI.balance = Label(card, 22, C.gold, "LEFT", "OUTLINE")
  UI.balance:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -20)
  UI.balance:SetWidth(158)

  local card2 = CreateFrame("Frame", nil, head)
  card2:SetWidth(120)
  card2:SetHeight(52)
  card2:SetPoint("RIGHT", card, "LEFT", -8, 0)
  card2.bg = Solid(card2, "BACKGROUND", C.bg)
  card2.bg:SetAllPoints(card2)
  Border(card2, C.line)
  local c2l = Label(card2, 9, C.muted, "LEFT")
  c2l:SetPoint("TOPLEFT", card2, "TOPLEFT", 10, -7)
  c2l:SetText("LIFETIME TOTAL")
  UI.lifetime = Label(card2, 15, C.text, "LEFT")
  UI.lifetime:SetPoint("TOPLEFT", card2, "TOPLEFT", 10, -24)
  UI.lifetime:SetWidth(104)

  local close = CreateFrame("Button", nil, head)
  close:SetWidth(24)
  close:SetHeight(24)
  close:SetPoint("TOPRIGHT", head, "TOPRIGHT", -8, -8)
  local cx = Label(close, 18, C.muted, "CENTER")
  cx:SetPoint("CENTER", close, "CENTER", 0, 1)
  cx:SetText("x")
  close:SetScript("OnEnter", function() cx:SetTextColor(C.red[1], C.red[2], C.red[3]) end)
  close:SetScript("OnLeave", function() cx:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end)
  close:SetScript("OnClick", function() f:Hide() end)

  -- Tabs
  local tabs = { { "shop", "Shop" }, { "donate", "Donate" }, { "req", "Needs" }, { "week", "My Week" }, { "manage", "Manage" } }
  UI.tabButtons = {}
  local i
  for i = 1, table.getn(tabs) do
    local t = tabs[i]
    local b = CreateFrame("Button", nil, f)
    b:SetWidth(112)
    b:SetHeight(30)
    b:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + (i - 1) * 116, -84)
    b.label = Label(b, 13, C.muted, "CENTER", "OUTLINE")
    b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.label:SetText(t[2])
    b.under = Solid(b, "ARTWORK", C.gold)
    b.under:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 8, 0)
    b.under:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -8, 0)
    b.under:SetHeight(2)
    b.under:Hide()
    b:SetScript("OnEnter", function() if UI.tab ~= t[1] then b.label:SetTextColor(C.text[1], C.text[2], C.text[3]) end end)
    b:SetScript("OnLeave", function() if UI.tab ~= t[1] then b.label:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end end)
    b:SetScript("OnClick", function() UI.SetTab(t[1]) end)
    UI.tabButtons[t[1]] = b
  end
  local tabRule = Solid(f, "ARTWORK", C.line)
  tabRule:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -114)
  tabRule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -114)
  tabRule:SetHeight(1)

  -- Search row
  UI.search = MakeEdit(f, 220, CTRL_H, 12)
  UI.search:SetPoint("TOPLEFT", f, "TOPLEFT", 16, TOP_Y)
  UI.search:SetJustifyH("LEFT")
  UI.search:SetTextInsets(8, 8, 0, 0)
  UI.search:SetMaxLetters(30)
  UI.searchHint = Label(f, 11, C.muted, "LEFT")
  UI.searchHint:SetPoint("LEFT", UI.search, "LEFT", 9, 0)
  UI.searchHint:SetText("Search by name...")
  UI.search:SetScript("OnTextChanged", function()
    local text = string.lower(UI.search:GetText() or "")
    if text == "" then UI.searchHint:Show() else UI.searchHint:Hide() end
    if text ~= UI.filter then
      UI.filter = text
      UI.page.shop, UI.page.donate, UI.page.req = 1, 1, 1
      UI.RefreshPlayer()
    end
  end)
  UI.sortNote = Label(f, 10, C.muted, "RIGHT")
  UI.sortNote:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, TOP_Y - 6)
  UI.sortNote:SetWidth(270)

  -- Sub-tabs (Donate: Potions | Materials; Manage: Potions | Materials | Shop) on the right of the search row;
  -- RefreshPlayer places them (they take the sort note's spot on those tabs).
  local function SubTab(label, kind)
    local b = MakeButton(f, 80, CTRL_H, label, "ghost")
    b:SetScript("OnClick", function()
      if UI.tab == "manage" then UI.manageSub = kind UI.page.manage = 1
      elseif UI.tab == "week" then UI.weekSub = kind UI.page.week = 1
      elseif UI.tab == "shop" then UI.SetShopSub(kind)
      else UI.donateSub = kind UI.page.donate = 1 end
      UI.RefreshPlayer()
    end)
    b.kind = kind
    b:Hide()
    return b
  end
  UI.subTabs = { SubTab("Potions", "items"), SubTab("Materials", "mats"), SubTab("Shop", "shop"), SubTab("Log", "log"),
                 SubTab("This Week", "week"), SubTab("Donations", "dhist") }
  -- Shop: one sub-tab per QuartermasterShopGroups entry (All, Flasks, Elixirs ...), from index 7 on
  UI.shopTabs = {}
  for i = 1, table.getn(QuartermasterShopGroups or {}) do
    local g = QuartermasterShopGroups[i]
    table.insert(UI.subTabs, SubTab(g.tab or g.label, g.key))
    table.insert(UI.shopTabs, table.getn(UI.subTabs))
  end

  -- grey hint text inside an empty edit box
  local function Hint(box, text)
    local h = Label(box, 10, C.muted, "LEFT")
    h:SetPoint("LEFT", box, "LEFT", 6, 0)
    h:SetText(text)
    box:SetScript("OnTextChanged", function() if (box:GetText() or "") == "" then h:Show() else h:Hide() end end)
    return h
  end

  -- Manage tab: add an item to the board (replaces the search box there)
  UI.addBox = MakeEdit(f, 160, CTRL_H, 11)
  UI.addBox:SetPoint("TOPLEFT", f, "TOPLEFT", 16, TOP_Y)
  UI.addBox:SetJustifyH("LEFT")
  UI.addBox:SetTextInsets(6, 6, 0, 0)
  UI.addBox:SetMaxLetters(120)
  UI.addBox:SetScript("OnEnterPressed", function() UI.addBox:ClearFocus() UI.AddFromBox() end)
  local boxHint = Hint(UI.addBox, "Shift-click an item here")
  UI.addTarget = MakeEdit(f, 46, CTRL_H, 11)
  UI.addTarget:SetPoint("LEFT", UI.addBox, "RIGHT", GAP, 0)
  UI.addTarget:SetNumeric(true)
  UI.addTarget:SetMaxLetters(4)
  local targetHint = Hint(UI.addTarget, "need")
  UI.addAE = MakeEdit(f, 46, CTRL_H, 11)
  UI.addAE:SetPoint("LEFT", UI.addTarget, "RIGHT", GAP, 0)
  UI.addAE:SetNumeric(true)
  UI.addAE:SetMaxLetters(5)
  local aeHint = Hint(UI.addAE, "AE")
  UI.addAEHint = aeHint                        -- "price" on Manage > Shop (RenderManage)
  UI.addPri = MakeButton(f, 72, CTRL_H, "Secondary", "ghost")
  UI.addPri:SetPoint("LEFT", UI.addAE, "RIGHT", GAP, 0)
  UI.addPri:SetScript("OnClick", function()
    UI.addCritical = not UI.addCritical
    SetBtn(UI.addPri, UI.addCritical and "Critical" or "Secondary", true)
  end)
  UI.addGo = MakeButton(f, 48, CTRL_H, "Add")
  UI.addGo:SetPoint("LEFT", UI.addPri, "RIGHT", GAP, 0)
  UI.addGo:SetScript("OnClick", function() UI.AddFromBox() end)
  UI.addControls = { UI.addBox, UI.addTarget, UI.addAE, UI.addPri, UI.addGo }
  local c
  for c = 1, table.getn(UI.addControls) do UI.addControls[c]:Hide() end

  -- List
  local list = CreateFrame("Frame", nil, f)
  list:SetWidth(ROW_W)
  list:SetHeight(ROWS * ROW_H)
  list:SetPoint("TOPLEFT", f, "TOPLEFT", 16, LIST_Y)
  UI.list = list
  for i = 1, ROWS do UI.rows[i] = BuildRow(list, i) end

  -- Column headings (above the list, tiny), each over its column (the list starts at x=16)
  UI.h1 = Label(f, 9, C.muted, "LEFT")
  UI.h1:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + 60, HEAD_Y)
  UI.h2 = Label(f, 9, C.muted, "LEFT")
  UI.h2:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + 318, HEAD_Y)
  UI.h3 = Label(f, 9, C.muted, "RIGHT")
  UI.h3:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + 440, HEAD_Y)
  UI.h3:SetWidth(86)
  UI.h4 = Label(f, 9, C.muted, "LEFT")
  UI.h4:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + 536, HEAD_Y)
  -- Manage tab: one centred heading per control column
  UI.mHead = {}
  local cols = { "pri", "target", "ae", "on" }
  for i = 1, 4 do
    local col = UI.MCOL[cols[i]]
    local h = Label(f, 9, C.muted, "CENTER")
    h:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + col[1], HEAD_Y)
    h:SetWidth(col[2])
    h:Hide()
    UI.mHead[cols[i]] = h
  end

  -- Week panel (cards)
  local wp = CreateFrame("Frame", nil, f)
  wp:SetWidth(ROW_W)
  wp:SetHeight(ROWS * ROW_H)
  wp:SetPoint("TOPLEFT", f, "TOPLEFT", 16, LIST_Y)
  wp:Hide()
  UI.weekPanel = wp
  local function Card(x, w, titleText)
    local c = CreateFrame("Frame", nil, wp)
    c:SetWidth(w)
    c:SetHeight(108)
    c:SetPoint("TOPLEFT", wp, "TOPLEFT", x, 0)
    c.bg = Solid(c, "BACKGROUND", C.panel)
    c.bg:SetAllPoints(c)
    Border(c, C.line)
    c.title = Label(c, 10, C.gold, "LEFT")
    c.title:SetPoint("TOPLEFT", c, "TOPLEFT", 14, -12)
    c.title:SetText(titleText)
    c.big = Label(c, 26, C.text, "LEFT", "OUTLINE")
    c.big:SetPoint("TOPLEFT", c, "TOPLEFT", 14, -28)
    c.note = Label(c, 10, C.muted, "LEFT")
    c.note:SetPoint("TOPLEFT", c, "TOPLEFT", 14, -62)
    c.note:SetWidth(w - 28)
    c.bar = MakeBar(c, w - 28, 6)
    c.bar:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 14, 12)
    return c
  end
  UI.cardMajor = Card(0, 340, "MAJOR REQUISITIONS  -  FLASKS")
  UI.cardMinor = Card(348, 340, "MINOR REQUISITIONS  -  POTIONS, ELIXIRS, OILS")
  UI.weekLine = Label(wp, 12, C.text, "LEFT")
  UI.weekLine:SetPoint("TOPLEFT", wp, "TOPLEFT", 2, -126)
  UI.weekLine:SetWidth(680)
  UI.weekLine2 = Label(wp, 11, C.muted, "LEFT")
  UI.weekLine2:SetPoint("TOPLEFT", wp, "TOPLEFT", 2, -148)
  UI.weekLine2:SetWidth(680)
  UI.itemLine = Label(wp, 10, C.muted, "LEFT")       -- per-item weekly cap (WEEKITEMS)
  UI.itemLine:SetPoint("TOPLEFT", wp, "TOPLEFT", 2, -164)
  UI.itemLine:SetWidth(680)
  local rh = Label(wp, 10, C.gold, "LEFT")
  rh:SetPoint("TOPLEFT", wp, "TOPLEFT", 2, -180)
  rh:SetText("RECENT PURCHASES")
  UI.recent = {}
  for i = 1, 6 do
    UI.recent[i] = Label(wp, 12, C.text, "LEFT")
    UI.recent[i]:SetPoint("TOPLEFT", wp, "TOPLEFT", 10, -198 - (i - 1) * 20)
    UI.recent[i]:SetWidth(660)
  end

  -- Footer: paging + donation basket
  local prev = MakeButton(f, 64, 22, "< Prev", "ghost")
  prev:SetPoint("BOTTOM", f, "BOTTOM", -60, 100)
  prev:SetScript("OnClick", function() UI.ChangePage(-1) end)
  local nxt = MakeButton(f, 64, 22, "Next >", "ghost")
  nxt:SetPoint("BOTTOM", f, "BOTTOM", 60, 100)
  nxt:SetScript("OnClick", function() UI.ChangePage(1) end)
  UI.prev, UI.nxt = prev, nxt
  UI.pageText = Label(f, 11, C.muted, "CENTER")
  UI.pageText:SetPoint("BOTTOM", f, "BOTTOM", 0, 104)
  UI.pageText:SetWidth(100)

  UI.basketText = Label(f, 11, C.text, "LEFT")
  UI.basketText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 104)
  UI.basketText:SetWidth(240)
  UI.basketText:Hide()
  UI.donateGo = MakeButton(f, 150, 26, "Donate Selected")
  UI.donateGo:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 99)
  UI.donateGo:SetScript("OnClick", function() UI.DonateSelected() end)
  UI.donateGo:Hide()

  -- Message / RP box
  local box = CreateFrame("Frame", nil, f)
  box:SetWidth(688)
  box:SetHeight(76)
  box:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 14)
  box.bg = Solid(box, "BACKGROUND", C.panel)
  box.bg:SetAllPoints(box)
  Border(box, C.line)
  local boxBar = Solid(box, "ARTWORK", C.ember)
  boxBar:SetPoint("TOPLEFT", box, "TOPLEFT", 0, 0)
  boxBar:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 0, 0)
  boxBar:SetWidth(4)
  -- Speaker badge: the Keeper's initial and name above what he says
  local badge = CreateFrame("Frame", nil, box)
  badge:SetWidth(32)
  badge:SetHeight(32)
  badge:SetPoint("TOPLEFT", box, "TOPLEFT", 16, -12)
  badge.bg = Solid(badge, "BACKGROUND", C.bg)
  badge.bg:SetAllPoints(badge)
  Border(badge, C.gold, 0.6)
  UI.badgeText = Label(badge, 15, C.gold, "CENTER", "OUTLINE")
  UI.badgeText:SetPoint("CENTER", badge, "CENTER", 0, 1)
  UI.badgeText:SetText("G")
  UI.msgName = Label(box, 10, C.gold, "LEFT")
  UI.msgName:SetPoint("TOPLEFT", box, "TOPLEFT", 60, -10)
  UI.msgName:SetText("GRIZZWICK")
  UI.msg = Label(box, 12, C.text, "LEFT")
  UI.msg:SetPoint("TOPLEFT", box, "TOPLEFT", 60, -24)
  UI.msg:SetWidth(616)
  UI.msg:SetHeight(46)
  UI.msg:SetJustifyV("TOP")
  UI.msg:SetText("The Banner's stores are open.")

  f:SetScript("OnShow", function() UI.OnOpen() end)
  f:SetScript("OnHide", function() UI.lastClosed = AK.Clock() end)
end

------------------------------------------------------------------------------
-- Rendering
------------------------------------------------------------------------------
local function AccentFor(status)
  if status == "O" then return C.green end
  if status == "R" then return C.amber end
  if status == "X" or status == "D" then return C.red end
  return C.line
end

local function ResetRow(i, d)
  local r = UI.rows[i]
  -- A reused row that now shows a different item (new page, tab or list) must not keep the old item's
  -- typing focus, or keystrokes would land on the new item.
  local view = UI.tab .. ":" .. ((UI.tab == "manage") and UI.manageSub or ((UI.tab == "week") and UI.weekSub or ""))
  local same = d and r.data and r.data.key == d.key and r.view == view
  if r.qty.hasFocus and not same then r.qty:ClearFocus() end
  r.view = view
  if not d then r:Hide() r.data = nil return nil end
  r:Show()
  -- Hiding an edit box takes its keyboard focus away, so a box the player is typing in stays shown when the
  -- row still holds the same item (every ping / STATE re-renders the list).
  local typingTarget = same and r.mTarget.hasFocus
  local typingAE = same and r.mAE.hasFocus
  r.data = d
  r.icon:SetTexture(IconFor(d.entry))
  r.name:SetWidth(250)          -- (the Log sub-tab widens them)
  r.sub:SetWidth(250)
  r.name:SetText(d.entry.name)
  r.name:SetTextColor(C.text[1], C.text[2], C.text[3])
  r.sub:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
  r.sub:Show()
  r.bar:Hide()
  r.max:Show()
  r.qty:Show()
  r.btn:Show()
  r.qty:SetScript("OnTextChanged", nil)
  r.max:SetScript("OnClick", nil)
  r.btn:SetScript("OnClick", nil)
  r.mPri:Hide() r.mOn:Hide() r.mDel:Hide()
  if not typingTarget then r.mTarget:Hide() end
  if not typingAE then r.mAE:Hide() end
  if not same then r.mTarget.onCommit = nil r.mAE.onCommit = nil end
  r.mPri:SetScript("OnClick", nil)
  r.mOn:SetScript("OnClick", nil)
  r.mDel:SetScript("OnClick", nil)
  return r
end

local function SetQtyText(box, n)
  box:SetScript("OnTextChanged", nil)
  box:SetText(tostring(n))
end

local function RenderShop()
  UI.h1:SetText("ITEM")
  UI.h2:SetText("AVAILABILITY")
  UI.h3:SetText("PRICE")
  UI.h4:SetText("QUANTITY")
  UI.sortNote:SetText("Highest AE price first")
  local all = ShopRows()
  local pages = math.max(1, math.ceil(table.getn(all) / ROWS))
  if UI.page.shop > pages then UI.page.shop = pages end
  local base = (UI.page.shop - 1) * ROWS
  local i
  for i = 1, ROWS do
    local d = all[base + i]
    local r = ResetRow(i, d)
    if r then
      local key = d.key
      local limit, why, capWhy = ShopLimit(d)
      -- Keep what the player typed, even when it is more than they can buy right now: the line below says
      -- why and Buy stays grey. (Silently snapping the box back to the limit looked like it ignored input.)
      local q = UI.qtyShop[key] or 1
      local cap = (State() and State().maxQty) or QuartermasterMaxPerOrder or 1
      if q > cap then q = cap end
      if q < 1 then q = 1 end
      UI.qtyShop[key] = q
      -- Don't rewrite the box under the player's cursor while they are typing in it (an emptied box
      -- counts as 1 until they type the new number).
      local typed = r.qty:GetText() or ""
      if not (r.qty.hasFocus and (typed == "" or math.floor(tonumber(typed) or 0) == q)) then SetQtyText(r.qty, q) end

      local col = AccentFor(d.status)
      r.accent:SetTexture(col[1], col[2], col[3], 1)
      r.c1:SetText(AK.FormatAE(d.price))
      r.c1:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
      local stock, scol
      if d.status == "O" then stock, scol = d.avail .. " available", C.green
      elseif d.status == "R" then stock, scol = "Reserved for the campaign", C.amber
      elseif d.status == "X" then stock, scol = "Out of stock", C.red
      elseif d.status == "D" then stock, scol = "Not available", C.red
      else stock, scol = "Loading...", C.muted end
      r.c2:SetText(stock)
      r.c2:SetTextColor(scol[1], scol[2], scol[3])

      local sub = d.major and "MAJOR  -  one of your weekly flasks" or "MINOR requisition"
      if d.fb then sub = sub .. "  -  Flamebound+" end
      if q > 1 then sub = AK.FormatAE(d.price * q) .. " AE for " .. q end
      local hold = State() and State().hold           -- AE fail-safe: on hold for officer review, nothing can be bought
      local canBuy = (not hold) and (not d.block) and AK.Player.IsKeeperOnline() and d.status == "O" and limit >= 1 and q <= limit
      if not AK.Player.IsKeeperOnline() then sub = "Quartermaster is offline"
      elseif hold then sub = "On hold for officer review: " .. tostring(State().holdText or hold)
      elseif d.block then sub = d.block
      elseif d.status == "?" then sub = "Waiting for the Quartermaster's list..."
      elseif d.status == "O" and limit < 1 and why then sub = why
      elseif d.status == "O" and q > limit then sub = "You can buy up to " .. limit .. " right now (" .. capWhy .. ")" end
      r.sub:SetText(sub)
      if hold then r.sub:SetTextColor(C.red[1], C.red[2], C.red[3])
      elseif d.block then
        -- greyed out: this player can't use / isn't allowed this item
        r.sub:SetTextColor(C.red[1], C.red[2], C.red[3])
        r.name:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        r.accent:SetTexture(C.line[1], C.line[2], C.line[3], 1)
      elseif not canBuy and d.status == "O" and limit >= 1 then r.sub:SetTextColor(C.amber[1], C.amber[2], C.amber[3]) end

      r.qty:SetScript("OnTextChanged", function()
        local n = math.floor(tonumber(r.qty:GetText()) or 0)
        if n < 1 then n = 1 end
        if n ~= UI.qtyShop[key] then UI.qtyShop[key] = n UI.RefreshPlayer() end
      end)
      r.max:SetScript("OnClick", function()
        local lim = ShopLimit(d)
        if lim < 1 then lim = 1 end
        UI.qtyShop[key] = lim
        UI.RefreshPlayer()
      end)
      local label = q > 1 and ("Buy x" .. q) or "Buy"
      if hold then label = "On hold"
      elseif d.block then label = (string.find(d.block, "^Requires") and ("Level " .. d.lvl)) or "Flamebound"
      elseif d.status == "X" then label = "Sold out" elseif d.status == "D" or d.status == "R" then label = "Unavailable" end
      SetBtn(r.btn, label, canBuy)
      SetBtn(r.max, "MAX", d.status == "O" and limit > 1 and not d.block)
      r.btn:SetScript("OnClick", function() AK.Player.Purchase(key, UI.qtyShop[key] or 1) end)
    end
  end
  UI.pageText:SetText("Page " .. UI.page.shop .. " / " .. pages)
end

function UI.UpdateBasket()
  if not UI.basketText then return end
  local n, ae = 0, 0
  local key, qty
  for key, qty in pairs(UI.basket) do
    n = n + 1
    local m = AK.Donations.Base(key)
    local b = m and AK.Player.Board()[m.code]
    ae = ae + qty * ((b and b.ae) or (m and m.ae) or 0)
  end
  if n == 0 then
    UI.basketText:SetText("Add items below, then Donate Selected.")
    SetBtn(UI.donateGo, "Donate Selected", false)
  else
    UI.basketText:SetText(n .. " selected  -  about " .. AK.FormatAE(ae) .. " AE")
    SetBtn(UI.donateGo, "Donate Selected", AK.Player.IsKeeperOnline())
  end
end

function UI.ClearBasket()
  UI.basket = {}
  if UI.frame and UI.frame:IsShown() then UI.RefreshPlayer() end
end

function UI.DonateSelected()
  AK.Player.DonateBasket(UI.basket)
end

local function RenderDonate()
  UI.h1:SetText("MATERIAL OR ITEM")
  UI.h2:SetText("YOU HAVE")
  UI.h3:SetText("PAYS EACH")
  UI.h4:SetText("AMOUNT")
  UI.sortNote:SetText("Critical needs first, then highest AE")
  local all = BoardRows(UI.donateSub == "mats" and "mats" or "items")
  local have = BagCounts()
  local pages = math.max(1, math.ceil(table.getn(all) / ROWS))
  if UI.page.donate > pages then UI.page.donate = pages end
  local base = (UI.page.donate - 1) * ROWS
  local i
  for i = 1, ROWS do
    local d = all[base + i]
    local r = ResetRow(i, d)
    if r then
      local key = d.key
      local owned = have[string.lower(d.entry.name)] or 0
      local need = math.max(0, d.target - d.cur)
      r.c1:SetText(AK.FormatAE(d.ae))
      r.c1:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
      r.c2:SetText(owned > 0 and (owned .. " in bags") or "none in bags")
      if owned > 0 then r.c2:SetTextColor(C.green[1], C.green[2], C.green[3]) else r.c2:SetTextColor(C.muted[1], C.muted[2], C.muted[3]) end
      local col = (d.flag == "O") and C.green or ((d.flag == "F") and C.amber or C.line)
      r.accent:SetTexture(col[1], col[2], col[3], 1)

      local sub
      if d.isItem then
        if d.flag == "D" then sub = "Not accepted"
        elseif d.flag == "F" then sub = "Stores are full of these - not needed right now"
        elseif d.target > 0 then sub = "Shop item  -  needed " .. need .. " (" .. d.cur .. "/" .. d.target .. ")"
        else sub = "Shop item - stocked for everyone to buy" end
      elseif d.flag == "F" then sub = "Requisition fulfilled - thank you"
      elseif d.flag == "D" then sub = "Not requested right now"
      else
        sub = (d.priority == "CRITICAL" and "Critical need" or "Secondary need") .. "  -  needed " .. need .. " (" .. d.cur .. "/" .. d.target .. ")"
        r.bar:Show()
        r.bar:Set(d.target > 0 and (d.cur / d.target) or 0, (d.priority == "CRITICAL") and C.ember or C.amber)
      end
      r.sub:SetText(sub)
      if not AK.Player.IsKeeperOnline() then r.sub:SetText("Quartermaster is offline")
      elseif d.flag == "?" then r.sub:SetText("Waiting for the Quartermaster's list...") end

      local q = UI.basket[key] or UI.qtyShop["d:" .. key] or 1
      if q < 1 then q = 1 end
      SetQtyText(r.qty, q)
      r.qty:SetScript("OnTextChanged", function()
        local n = math.floor(tonumber(r.qty:GetText()) or 0)
        UI.qtyShop["d:" .. key] = (n >= 1) and n or 1
        if UI.basket[key] then
          if n < 1 then UI.basket[key] = nil else UI.basket[key] = n end
          UI.UpdateBasket()
        end
      end)
      r.max:SetScript("OnClick", function()
        local lim = owned
        if d.target > 0 and need > 0 and need < lim then lim = need end      -- never more than is still needed
        if lim < 1 then lim = 1 end
        UI.qtyShop["d:" .. key] = lim
        if UI.basket[key] then UI.basket[key] = lim end
        UI.RefreshPlayer()
      end)
      local open = AK.Player.IsKeeperOnline() and d.flag == "O" and owned > 0
      SetBtn(r.max, "MAX", open)
      SetBtn(r.btn, UI.basket[key] and "Added" or "Add", open or (UI.basket[key] ~= nil))
      r.btn:SetScript("OnClick", function()
        if UI.basket[key] then
          UI.basket[key] = nil
        else
          local n = math.floor(tonumber(r.qty:GetText()) or 1)
          if n < 1 then n = 1 end
          UI.basket[key] = n
        end
        UI.RefreshPlayer()
      end)
    end
  end
  UI.pageText:SetText("Page " .. UI.page.donate .. " / " .. pages)
  UI.UpdateBasket()
end

local function RenderReq()
  UI.h1:SetText("MATERIAL")
  UI.h2:SetText("STILL NEEDED")
  UI.h3:SetText("PAYS EACH")
  UI.h4:SetText("")
  UI.sortNote:SetText("Critical needs first, then highest AE")
  local all = BoardRows("mats")
  local pages = math.max(1, math.ceil(table.getn(all) / ROWS))
  if UI.page.req > pages then UI.page.req = pages end
  local base = (UI.page.req - 1) * ROWS
  local i
  for i = 1, ROWS do
    local d = all[base + i]
    local r = ResetRow(i, d)
    if r then
      r.qty:Hide()
      r.max:Hide()
      r.btn:Hide()
      local need = math.max(0, d.target - d.cur)
      local fulfilled = (d.flag == "F")
      local col = fulfilled and C.green or ((d.priority == "CRITICAL") and C.ember or C.amber)
      r.accent:SetTexture(col[1], col[2], col[3], 1)
      r.c2:SetText(fulfilled and "Fulfilled" or (need .. " needed"))
      if fulfilled then r.c2:SetTextColor(C.green[1], C.green[2], C.green[3]) else r.c2:SetTextColor(C.text[1], C.text[2], C.text[3]) end
      r.c1:SetText(AK.FormatAE(d.ae))
      r.c1:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
      r.sub:SetText(d.cur .. " / " .. d.target .. "   " .. ((d.priority == "CRITICAL") and "CRITICAL" or "secondary"))
      r.bar:Show()
      r.bar:Set(d.target > 0 and (d.cur / d.target) or 0, col)
    end
  end
  UI.pageText:SetText("Page " .. UI.page.req .. " / " .. pages)
end

-- Officers (Oath Captain and above): change the board / shop through the Keeper. Grizzwick re-checks the rank.
local function SendSet(code, fields)
  fields.op = "set"
  fields.k = code
  return AK.Player.Admin(fields)
end

-- A value an officer sent stays in its box (with "Saving...") until the Keeper's BOARD / SHOP update carries
-- it, ADMIN_FAIL arrives (UI.AdminFailed), or PENDING_FOR seconds pass with neither.
local PENDING_FOR = 15
local function Pending(id, current)
  local p = UI.pending[id]
  if not p then return nil end
  if tonumber(current) == p.v or AK.Clock() - p.at > PENDING_FOR then UI.pending[id] = nil return nil end
  return p.v
end

local function Rerender()
  if not UI.rendering then UI.RefreshPlayer() end
end

-- Shows value in an officer's edit box (unless they are typing in it) and sends what they type when they
-- leave the box (Enter, clicking elsewhere); Escape puts the value back. send(n) returns false when nothing
-- was sent (Keeper offline).
local function EditField(box, id, value, send)
  box:Show()
  box.shown = value
  if not box.hasFocus then SetQtyText(box, value) end
  box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
  box.onCommit = function()
    local n = tonumber(box:GetText() or "")
    if not n then box:SetText(tostring(value)) return end
    n = math.floor(n)
    if n == tonumber(value) then return end
    if send(n) ~= false then
      UI.pending[id] = { v = n, at = AK.Clock() }
      UI.Message("Saving...", true)
    end
    Rerender()
  end
end

function UI.AdminFailed()
  UI.pending = {}
  Rerender()
end

-- Manage > Log: Grizzwick's last weekly report, then his newest trades. Asks him for fresh data while open.
local LOG_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local WEEK_ICON = "Interface\\Icons\\INV_Scroll_03"

local HOLD_ICON = "Interface\\Icons\\INV_Misc_Key_03"
local AH_ICON = "Interface\\Icons\\INV_Misc_Coin_02"

-- Players on hold for AE review come first (with Release / Discard / Freeze), then the weekly report and trades.
function UI.LogRows()
  local out = {}
  local wk = AK.cache and AK.cache.weekly
  local i
  local holds = (AK.cache and AK.cache.holds) or {}
  for i = 1, table.getn(holds) do
    local h = holds[i]
    local text = AK.FormatAE(h.before) .. " -> " .. AK.FormatAE(h.after) .. " AE, " .. AK.FormatAE(h.held) .. " held" ..
                 (h.frz and ", frozen" or "") .. ((h.adj or 0) ~= 0 and (", adjust " .. h.adj) or "")
    table.insert(out, { key = "h" .. string.lower(h.name), hold = h,
                        entry = { name = "ON HOLD  " .. h.name .. "  -  " .. tostring(AK.Integrity.HoldText(h.why) or h.why), icon = HOLD_ICON },
                        text = text, col = C.red })
  end
  if wk and wk.lines then
    for i = 1, table.getn(wk.lines) do
      local line = wk.lines[i] or ""
      local a = string.find(line, ": ", 1, true)
      local head, rest = line, ""
      if a then head, rest = string.sub(line, 1, a - 1), string.sub(line, a + 2) end
      table.insert(out, { key = "w" .. i, entry = { name = (i == 1) and ("Weekly report - " .. head) or head, icon = WEEK_ICON },
                          text = rest, col = C.gold })
    end
  end
  -- the last Auction House scan (stored and shown only; prices are never changed from it)
  local ah = AK.cache and AK.cache.ahPrices
  if AK.IsKeeper() then ah = AK.db.ahPrices end
  if ah and ah.items then
    table.insert(out, { key = "ahhead", entry = { name = "Auction House prices - " .. (ah.t and date("%m/%d %H:%M", ah.t) or "?") ..
                        " by " .. tostring(ah.who) .. (ah.complete and "" or " (partial)"), icon = AH_ICON },
                        text = "Per unit: cheapest / average of the 5 cheapest / listings. Not applied to the shop.", col = C.gold })
    local list = AK.AH.ScanList()
    for i = 1, table.getn(list) do
      local r = ah.items[list[i].name]
      if r then
        local text = (r.n or 0) > 0 and (AK.AH.Money(r.min) .. "  /  " .. AK.AH.Money(r.low) .. "  /  " .. r.n .. " listings, " .. r.u .. " units")
                     or "none listed"
        table.insert(out, { key = "ah" .. i, entry = { name = list[i].name, itemID = list[i].id }, text = text,
                            col = ((r.n or 0) > 0) and C.amber or C.line })
      end
    end
  end
  local log = (AK.cache and AK.cache.tradeLog) or {}
  for i = 1, table.getn(log) do
    local e = log[i]
    local col = C.amber
    if e.res == "OK" or e.res == "RECOVERED" then col = C.green elseif e.res == "FAILED" then col = C.red end
    local text = tostring(e.what or "-")
    if (e.ae or 0) ~= 0 then text = text .. "   -   " .. AK.FormatAE(e.ae) .. " AE" end
    text = text .. "   -   " .. tostring(e.res) .. ((e.why and e.why ~= "") and (" (" .. e.why .. ")") or "")
    table.insert(out, { key = "t" .. i, entry = { name = date("%m/%d %H:%M", e.t) .. "   " .. tostring(e.who) .. "   " ..
                        (e.kind == "DONATE" and "donation" or "purchase"), icon = LOG_ICON }, text = text, col = col })
  end
  return out
end

local function RenderLog()
  UI.sortNote:SetText("")
  if AK.Clock() - (UI.lastLogReq or -1000) > 15 then
    UI.lastLogReq = AK.Clock()
    AK.Player.Request("LOG_REQ", { r = AK.Now() }, { "r" })
  end
  local all = UI.LogRows()
  if table.getn(all) == 0 then
    all = { { key = "none", entry = { name = AK.cache.tradeLogTime and "No trades logged yet" or "Asking the Quartermaster...", icon = LOG_ICON },
              text = "", col = C.line } }
  end
  local pages = math.max(1, math.ceil(table.getn(all) / ROWS))
  if UI.page.manage > pages then UI.page.manage = pages end
  local base = (UI.page.manage - 1) * ROWS
  local i
  for i = 1, ROWS do
    local d = all[base + i]
    local r = ResetRow(i, d)
    if r then
      r.qty:Hide()
      r.max:Hide()
      r.btn:Hide()
      r.c1:SetText("")
      r.c2:SetText("")
      r.name:SetWidth(610)
      r.sub:SetWidth(610)
      r.sub:SetText(d.text)
      r.accent:SetTexture(d.col[1], d.col[2], d.col[3], 1)
      if d.hold then
        -- AE review: Release (held AE becomes spendable) / Discard (held AE dropped) both clear the hold
        local h = d.hold
        r.name:SetWidth(250)
        r.sub:SetWidth(250)
        r.name:SetTextColor(C.red[1], C.red[2], C.red[3])
        local function Act(a) AK.Player.Admin({ op = "ae", k = h.name, a = a }) end
        SetBtn(r.mPri, "Release", true)
        r.mPri:SetScript("OnClick", function() Act("rel") end)
        SetBtn(r.mOn, h.frz and "Unfreeze" or "Freeze", true)
        r.mOn:SetScript("OnClick", function() Act(h.frz and "unf" or "frz") end)
        SetBtn(r.mDel, "Discard", true)
        r.mDel:SetScript("OnClick", function() Act("dis") end)
        r.mPri:Show() r.mOn:Show() r.mDel:Show()
      end
    end
  end
  UI.pageText:SetText("Page " .. UI.page.manage .. " / " .. pages)
end

local function RenderManage()
  UI.h1:SetText("ITEM")
  UI.h2:SetText("")
  UI.h3:SetText("")
  UI.h4:SetText("")
  local sub = UI.manageSub
  if sub == "log" then UI.h1:SetText("") return RenderLog() end
  local mh = UI.mHead
  if UI.addAEHint then UI.addAEHint:SetText(sub == "shop" and "price" or "AE") end
  if sub == "shop" then
    mh.pri:SetText("WHO") mh.target:SetText("") mh.ae:SetText("PRICE") mh.on:SetText("SELLING")
    UI.sortNote:SetText("Edit a price and press Enter")
  else
    mh.pri:SetText("PRIORITY") mh.target:SetText("TARGET") mh.ae:SetText("AE EACH") mh.on:SetText("ON")
    UI.sortNote:SetText("Shift-click an item into the box to add it")
  end
  local all
  if sub == "shop" then all = ShopRows(true) else all = BoardRows(sub == "mats" and "mats" or "items") end
  local pages = math.max(1, math.ceil(table.getn(all) / ROWS))
  if UI.page.manage > pages then UI.page.manage = pages end
  local base = (UI.page.manage - 1) * ROWS
  local i
  for i = 1, ROWS do
    local d = all[base + i]
    local r = ResetRow(i, d)
    if r then
      r.qty:Hide()
      r.max:Hide()
      r.btn:Hide()
      r.c1:SetText("")
      r.c2:SetText("")
      local code = d.entry.code
      if sub == "shop" then
        local on = (d.status ~= "D")
        local price = Pending("p:" .. code, d.price)
        r.sub:SetText((d.major and "MAJOR" or "MINOR") .. (((d.lvl or 0) > 1) and ("  -  level " .. d.lvl .. "+") or "") ..
                      (price and "   -   Saving..." or ""))
        r.accent:SetTexture(AccentFor(d.status)[1], AccentFor(d.status)[2], AccentFor(d.status)[3], 1)
        -- who may buy it: Flamebound and higher only, or everyone (the Keeper checks the rank)
        r.mPri:Show()
        SetBtn(r.mPri, d.fb and "Flamebound" or "Everyone", true)
        r.mPri:SetScript("OnClick", function() AK.Player.Admin({ op = "shop", k = code, fb = d.fb and "0" or "1" }) end)
        EditField(r.mAE, "p:" .. code, price or d.price, function(n) return AK.Player.Admin({ op = "shop", k = code, p = n }) end)
        r.mOn:Show()
        SetBtn(r.mOn, on and "On" or "Off", true)
        r.mOn:SetScript("OnClick", function() AK.Player.Admin({ op = "shop", k = code, en = on and "0" or "1" }) end)
        -- Shop sub-tab: each click moves it to the next one (All excluded)
        r.mDel:Show()
        local tg = QuartermasterShopGroups[UI.NextGroupIndex(d.grp)]
        SetBtn(r.mDel, (QuartermasterShopGroups[UI.GroupIndex(d.grp)] or {}).tab or UI.GroupLabel(d.grp), true)
        r.mDel:SetScript("OnClick", function() if tg then AK.Player.Admin({ op = "shop", k = code, gr = tg.key }) end end)
      else
        local crit = (d.priority == "CRITICAL")
        local col = (not d.on) and C.line or (crit and C.ember or C.amber)
        r.accent:SetTexture(col[1], col[2], col[3], 1)
        local target = Pending("tg:" .. code, d.target)
        local ae = Pending("ae:" .. code, d.baseAE or d.ae)
        local saving = (target or ae) and "   -   Saving..." or ""
        r.sub:SetText((d.isItem and "Potion  -  " or "") .. "Have " .. d.cur .. " / " .. (target or d.target) .. saving)
        r.mPri:Show()
        SetBtn(r.mPri, crit and "Critical" or "Secondary", true)
        r.mPri:SetScript("OnClick", function() SendSet(code, { pr = crit and "S" or "C" }) end)
        -- potions have a target too: donations stop once the Keeper holds that many
        EditField(r.mTarget, "tg:" .. code, target or d.target, function(n) return SendSet(code, { tg = n }) end)
        EditField(r.mAE, "ae:" .. code, ae or d.baseAE or d.ae, function(n) return SendSet(code, { ae = n }) end)
        r.mOn:Show()
        SetBtn(r.mOn, d.on and "On" or "Off", true)
        r.mOn:SetScript("OnClick", function() SendSet(code, { en = d.on and "0" or "1" }) end)
        r.mDel:Show()
        SetBtn(r.mDel, "Remove", true)
        -- two clicks within 4 seconds: nothing disappears by accident
        r.mDel:SetScript("OnClick", function()
          if r.delArmed == code and AK.Clock() - (r.delAt or 0) < 4 then
            r.delArmed = nil
            AK.Player.Admin({ op = "remove", k = code })
          else
            r.delArmed = code
            r.delAt = AK.Clock()
            SetBtn(r.mDel, "Sure?", true)
          end
        end)
      end
    end
  end
  UI.pageText:SetText("Page " .. UI.page.manage .. " / " .. pages)
end

-- Add box (Manage tab): an item link (shift-click) or the name of something already known.
function UI.AddFromBox()
  local text = UI.addBox:GetText() or ""
  local id, name = AK.Stock.ParseLink(text)
  if not name then name = AK.Trim(text) id = 0 end
  if name == "" then UI.Message("Shift-click an item from your bags into the box first.", false) return end
  -- Materials tab adds a requisition material; Potions adds a shop item (the AE box = donation AE, price twice
  -- that) and Shop adds a shop item (the AE box = its price, donations pay half).
  local f = { op = "add", id = id or 0, n = name, tg = UI.addTarget:GetText(), ae = UI.addAE:GetText(), pr = UI.addCritical and "C" or "S" }
  if UI.manageSub == "items" then
    f.op = "additem"
  elseif UI.manageSub == "shop" then
    f.op = "additem"
    f.p = f.ae
    local p = tonumber(f.p)
    f.ae = p and tostring(math.floor(p / 2)) or ""
  end
  AK.Player.Admin(f)
  UI.addBox:SetText("")
end

-- My Week > Donations: the player's own donation history from the Keeper, newest first, one page at a time.
local DON_ICON = "Interface\\Icons\\INV_Misc_Bag_10"

function UI.HistoryRows(h)
  local out = {}
  if not h then return out end
  local i, j
  for i = 1, table.getn(h.list or {}) do
    local e = h.list[i]
    local names, qty, icon = {}, 0, nil
    for j = 1, table.getn(e.items) do
      local it = e.items[j]
      local k = it.code and AK.Donations.KeyByCode(it.code)
      local b = k and AK.Donations.Base(k)
      if it.qty then
        table.insert(names, it.qty .. "x " .. ((b and b.name) or tostring(it.code)))
        qty = qty + it.qty
      else
        table.insert(names, "and " .. string.sub(tostring(it.code), 2) .. " more")      -- "+3" from a huge basket
      end
      if not icon and b and b.itemID and b.itemID > 0 then icon = IconFor({ itemID = b.itemID }) end
    end
    table.insert(out, { key = "d" .. i .. ":" .. (e.t or 0), qty = qty, ae = e.ae, text = table.concat(names, ", "),
                        entry = { name = date("%m/%d/%Y  %H:%M", e.t), icon = icon or DON_ICON } })
  end
  return out
end

local function RenderHistory()
  UI.h1:SetText("DATE  /  ITEMS")
  UI.h2:SetText("QUANTITY")
  UI.h3:SetText("AE")
  UI.h4:SetText("")
  local h = AK.cache and AK.cache.dhist
  if h and UI.page.week > (h.pn or 1) then UI.page.week = h.pn or 1 end
  local want = UI.page.week
  if (not h or h.pg ~= want or AK.Now() - (h.t or 0) > 60) and AK.Player.IsKeeperOnline() and
     AK.Clock() - (UI.lastDhReq or -1000) > 3 then
    UI.lastDhReq = AK.Clock()
    AK.Player.RequestHistory(want)
  end
  local all
  if h and h.pg == want then all = UI.HistoryRows(h) else all = {} end
  if table.getn(all) == 0 then
    local text = "Asking the Quartermaster..."
    if not AK.Player.IsKeeperOnline() then text = "The Quartermaster is offline"
    elseif h and h.pg == want then text = "No donations recorded yet" end
    all = { { key = "none", entry = { name = text, icon = DON_ICON }, text = "Donations you make show up here.", none = true } }
  end
  local i
  for i = 1, ROWS do
    local d = all[i]
    local r = ResetRow(i, d)
    if r then
      r.qty:Hide()
      r.max:Hide()
      r.btn:Hide()
      r.name:SetWidth(250)
      r.sub:SetText(d.text)
      r.accent:SetTexture(C.gold[1], C.gold[2], C.gold[3], 1)
      if d.none then
        r.c1:SetText("")
        r.c2:SetText("")
        r.accent:SetTexture(C.line[1], C.line[2], C.line[3], 1)
      else
        r.c2:SetText(d.qty .. (d.qty == 1 and " item" or " items"))
        r.c2:SetTextColor(C.text[1], C.text[2], C.text[3])
        r.c1:SetText("+" .. AK.FormatAE(d.ae))
        r.c1:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
      end
    end
  end
  local pages = (h and h.pn) or 1
  UI.pageText:SetText("Page " .. want .. " / " .. pages)
  UI.sortNote:SetText((h and h.total) and (h.total .. " donations, newest first") or "Newest first")
end

-- My Week: the per-item cap and what was taken of each item this week (most first, as many as fit one line).
function UI.WeekItemsText()
  local wi = AK.cache and AK.cache.weekItems
  if not wi or (wi.cap or 0) <= 0 then return "" end
  local list = {}
  local code, n
  for code, n in pairs(wi.n) do
    if n > 0 then
      local k = AK.Shop.KeyByCode(code)
      table.insert(list, { name = k and QuartermasterItems[k].name or code, n = n })
    end
  end
  table.sort(list, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.name < b.name end)
  local text = "Up to " .. wi.cap .. " of each item per week."
  if table.getn(list) == 0 then return text end
  text = text .. "  Taken:"
  local i
  for i = 1, table.getn(list) do
    local part = " " .. list[i].name .. " " .. list[i].n .. "/" .. wi.cap .. (i < table.getn(list) and "," or "")
    if string.len(text) + string.len(part) > 120 then text = text .. " ..." break end
    text = text .. part
  end
  return text
end

local function RenderWeek()
  UI.h1:SetText("")
  UI.h2:SetText("")
  UI.h3:SetText("")
  UI.h4:SetText("")
  UI.sortNote:SetText("Resets every week")
  UI.pageText:SetText("")
  local s = State()
  local m, n = UI.cardMajor, UI.cardMinor
  if not s then
    m.big:SetText("...")
    n.big:SetText("...")
    m.note:SetText("No data yet. Open this window near the Quartermaster.")
    n.note:SetText("")
    m.bar:Set(0)
    n.bar:Set(0)
    UI.weekLine:SetText("")
    UI.weekLine2:SetText("")
    UI.itemLine:SetText("")
    local i
    for i = 1, 6 do UI.recent[i]:SetText("") end
    return
  end
  local majorsLeft = s.majorTotal - s.majorUsed - s.majorConverted
  local mw = s.minorsWithMajor or QuartermasterWeekly.minorsWithMajor
  m.big:SetText(majorsLeft .. " / " .. s.majorTotal .. " left")
  if majorsLeft > 0 and mw and s.minor > mw then
    m.note:SetText("Not this week: you took more than " .. mw .. " minors.  A Major is only possible while you have " .. mw .. " or fewer.")
  else
    m.note:SetText("Used " .. s.majorUsed .. ".  Taking a Major lowers this week's minors to " .. (mw or "?") ..
                   " (only while you have taken " .. (mw or "?") .. " or fewer).")
  end
  m.bar:Set(s.majorTotal > 0 and (majorsLeft / s.majorTotal) or 0, C.gold)
  local minorLeft = s.minorLimit - s.minor
  if minorLeft < 0 then minorLeft = 0 end
  n.big:SetText(minorLeft .. " / " .. s.minorLimit .. " left")
  n.note:SetText("Used " .. s.minor .. " this week.  One purchase can hold up to " .. s.maxQty .. " items.")
  n.bar:Set(s.minorLimit > 0 and (minorLeft / s.minorLimit) or 0, C.ember)
  UI.itemLine:SetText(UI.WeekItemsText())
  local weekText = "Spent this week: |cfff5c84c" .. AK.FormatAE(s.weekSpent) .. " AE|r     Left to spend this week: |cfff5c84c" ..
                   AK.FormatAE(s.bal) .. " AE|r"
  if s.lifetimeBal then weekText = weekText .. "     Total balance: |cfff5c84c" .. AK.FormatAE(s.lifetimeBal) .. " AE|r" end
  UI.weekLine:SetText(weekText)
  local lifeText = "Lifetime total " .. AK.FormatAE(s.earned + s.donated) .. " AE"
  if s.donatedTotal and s.donatedTotal > 0 then lifeText = lifeText .. " (includes " .. AK.FormatAE(s.donatedTotal) .. " AE donated)" end
  if s.allowance then
    lifeText = lifeText .. "     " .. ((s.rank and s.rank ~= "") and (s.rank .. " allowance: ") or "Weekly allowance: ") ..
               AK.FormatAE(s.allowance) .. " AE, resets Wednesday"
    if s.donCredit then lifeText = lifeText .. "     Donation credit " .. AK.FormatAE(s.donCredit) .. " AE (never expires)" end
  end
  UI.weekLine2:SetText(lifeText .. "      Spending never lowers your lifetime total.")
  local list = AK.Protocol.SplitList(s.recent)
  local i
  for i = 1, 6 do UI.recent[i]:SetText("") end
  if table.getn(list) == 0 then UI.recent[1]:SetText("|cff9e9490Nothing bought yet this week.|r") end
  for i = 1, table.getn(list) do
    if i <= 6 then
      local parts = AK.Split(list[i], ":")
      local k = AK.Shop.KeyByCode(parts[1])
      local q = tonumber(parts[3]) or 1
      UI.recent[i]:SetText((q > 1 and (q .. "x ") or "") .. (k and QuartermasterItems[k].name or parts[1]) ..
                           "   -   |cfff5c84c" .. AK.FormatAE(parts[2]) .. " AE|r")
    end
  end
end

function UI.RefreshPlayer()
  local f = UI.frame
  if not f or not f:IsShown() then return end
  local kn = AK.KeeperName()
  if AK.Player.IsKeeperOnline() and AK.outdated then
    -- the Keeper runs a newer addon (Main: PL.CheckVersion); short enough to end before the rank lines (x = 206)
    UI.online:SetText((kn or "Quartermaster") .. "  -  addon outdated")
    UI.online:SetTextColor(C.amber[1], C.amber[2], C.amber[3])
    UI.dot:SetTexture(C.green[1], C.green[2], C.green[3], 1)
  elseif AK.Player.IsKeeperOnline() then
    UI.online:SetText((kn or "Quartermaster") .. "  -  online")
    UI.online:SetTextColor(C.green[1], C.green[2], C.green[3])
    UI.dot:SetTexture(C.green[1], C.green[2], C.green[3], 1)
  else
    UI.online:SetText((kn or "Quartermaster") .. "  -  offline")
    UI.online:SetTextColor(C.red[1], C.red[2], C.red[3])
    UI.dot:SetTexture(C.red[1], C.red[2], C.red[3], 1)
  end
  if kn then
    UI.msgName:SetText(string.upper(kn))
    UI.badgeText:SetText(string.upper(string.sub(kn, 1, 1)))
  end
  local s = State()
  if s then
    UI.balance:SetText(AK.FormatAE(s.bal) .. " AE")
    UI.lifetime:SetText(AK.FormatAE(s.earned + s.donated))
    if s.allowance then
      UI.balanceLabel:SetText("LEFT TO SPEND THIS WEEK")
      UI.rankLine:SetText(string.upper((s.rank and s.rank ~= "") and s.rank or "Weekly") .. "  -  " .. AK.FormatAE(s.allowance) .. " AE / WEEK")
      UI.allowLine:SetText(s.lifetimeBal and ("Total balance " .. AK.FormatAE(s.lifetimeBal) .. " AE") or "")
      UI.creditLine:SetText(s.donCredit and ("Donation credit " .. AK.FormatAE(s.donCredit) .. " AE (never expires)") or "")
      UI.resetLine:SetText("Resets Wednesday")
    else
      UI.balanceLabel:SetText("BALANCE")
      UI.rankLine:SetText("")
      UI.allowLine:SetText("")
      UI.creditLine:SetText("")
      UI.resetLine:SetText("")
    end
  else
    UI.balance:SetText("...")
    UI.lifetime:SetText("")
    UI.rankLine:SetText("")
    UI.creditLine:SetText("")
    UI.allowLine:SetText("")
    UI.resetLine:SetText("")
  end

  -- Manage tab only for officers (the Keeper flags them in STATE; it re-checks every change anyway)
  local admin = s and s.isAdmin
  if admin then UI.tabButtons.manage:Show() else UI.tabButtons.manage:Hide() end
  if UI.tab == "manage" and not admin then UI.tab = "shop" end

  local tab = UI.tab
  local k, b
  for k, b in pairs(UI.tabButtons) do
    if k == tab then
      b.label:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
      b.under:Show()
    else
      b.label:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
      b.under:Hide()
    end
  end

  local week = (tab == "week")
  local manage = (tab == "manage")
  local cards = week and UI.weekSub ~= "dhist"       -- My Week > This Week: the cards; > Donations: the list
  if cards then UI.list:Hide() UI.weekPanel:Show() else UI.list:Show() UI.weekPanel:Hide() end
  if week or manage then UI.search:Hide() UI.searchHint:Hide() else UI.search:Show() if UI.filter == "" then UI.searchHint:Show() end end
  local editing = manage and UI.manageSub ~= "log"
  local i
  for i = 1, table.getn(UI.addControls) do if editing then UI.addControls[i]:Show() else UI.addControls[i]:Hide() end end
  local hk, h
  for hk, h in pairs(UI.mHead) do if editing then h:Show() else h:Hide() end end

  -- sub-tabs: Donate = Potions | Materials, Manage = Potions | Materials | Shop | Log, My Week = This Week |
  -- Donations (right-aligned, same row, height and spacing as the add row; on Manage they are narrower so all four
  -- clear the add row)
  -- Shop = All | Flasks | Elixirs ... (narrow, beside a shorter search box)
  local show = {}
  local shopTab = (tab == "shop")
  if tab == "donate" then show = { 1, 2 } elseif manage then show = { 1, 2, 3, 4 } elseif week then show = { 5, 6 }
  elseif shopTab then show = UI.shopTabs end
  local subs = table.getn(show)
  local current = (manage and UI.manageSub) or (week and UI.weekSub) or (shopTab and UI.ShopSub()) or UI.donateSub
  local sw = (manage and 66) or (week and 90) or (shopTab and 64) or 80
  local gap = shopTab and 4 or GAP
  UI.search:SetWidth((shopTab and subs > 0) and 140 or 220)
  for i = 1, table.getn(UI.subTabs) do UI.subTabs[i]:Hide() end
  for i = 1, subs do
    local sb = UI.subTabs[show[i]]
    sb:ClearAllPoints()
    sb:SetWidth(sw)
    sb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16 - (subs - i) * (sw + gap), TOP_Y)
    sb.style = (sb.kind == current) and "ember" or "ghost"
    SetBtn(sb, nil, true)
    sb:Show()
  end
  if subs > 0 then UI.sortNote:Hide() else UI.sortNote:Show() end
  if tab == "donate" then
    UI.basketText:Show()
    UI.donateGo:Show()
  else
    UI.basketText:Hide()
    UI.donateGo:Hide()
  end
  if cards then UI.prev:Hide() UI.nxt:Hide() else UI.prev:Show() UI.nxt:Show() end

  -- (an edit box losing focus while the rows are rebuilt commits; it must not start a second render)
  UI.rendering = true
  local ok, err = pcall(function()
    if tab == "shop" then RenderShop()
    elseif tab == "donate" then RenderDonate()
    elseif tab == "req" then RenderReq()
    elseif manage then RenderManage()
    elseif cards then RenderWeek()
    else RenderHistory() end
  end)
  UI.rendering = false
  if not ok then error(err) end
end

function UI.SetTab(tab)
  UI.tab = tab
  UI.RefreshPlayer()
end

function UI.ChangePage(delta)
  local t = UI.tab
  if t == "week" and UI.weekSub ~= "dhist" then return end
  UI.page[t] = math.max(1, UI.page[t] + delta)
  UI.RefreshPlayer()
end

function UI.Message(text, good)
  if not UI.msg then Build() end
  UI.msg:SetText(text)
  if good then UI.msg:SetTextColor(C.green[1], C.green[2], C.green[3]) else UI.msg:SetTextColor(C.amber[1], C.amber[2], C.amber[3]) end
  if UI.frame and not UI.frame:IsShown() then AK.Print(string.gsub(text, "\n", " - ")) end
end

function UI.Say(text)
  if not UI.msg then Build() end
  UI.msg:SetText("\"" .. text .. "\"")
  UI.msg:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
end

------------------------------------------------------------------------------
-- Opening: click Grizzwick in range (or the little button), never from across the map
------------------------------------------------------------------------------
local function KeeperUnit(unit)
  if not (UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)) then return false end
  local kn = AK.KeeperName()
  return kn ~= nil and AK.Norm(UnitName(unit)) == AK.Norm(kn)
end

-- Trade range (about 11 yards). True only for the Keeper unit itself.
function UI.KeeperInRange(unit)
  unit = unit or "target"
  if not KeeperUnit(unit) then return false end
  if type(CheckInteractDistance) ~= "function" then return true end
  return CheckInteractDistance(unit, 2) and true or false
end

function UI.TryOpen(unit)
  Build()
  if UI.frame:IsShown() then UI.frame:Hide() return end
  if not UI.KeeperInRange(unit) then
    AK.Print("Move closer to the Quartermaster.")
    return
  end
  UI.frame:Show()
end

function UI.OnWorldRightClick()
  if AK.IsKeeper() then return end
  if KeeperUnit("mouseover") then UI.TryOpen("mouseover") end
end

local function InstallWorldClick()
  if UI.clickHooked or not WorldFrame then return end
  local ok = pcall(function()
    local old = WorldFrame:GetScript("OnMouseUp")
    WorldFrame:SetScript("OnMouseUp", function()
      if old then old() end
      if arg1 == "RightButton" then UI.OnWorldRightClick() end
    end)
  end)
  UI.clickHooked = ok
end

function UI.OnOpen()
  if AK.IsKeeper() then UI.RefreshPlayer() return end
  local now = AK.Clock()
  if now - UI.lastRefreshReq > 10 then
    UI.lastRefreshReq = now
    AK.Player.RefreshAll()
  end
  UI.RefreshPlayer()
end

function UI.TogglePlayer()
  Build()
  if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
end

-- "Open Quartermaster" button on the target frame + automatic open when you click him in range.
function UI.OnTargetChanged()
  if AK.IsKeeper() then return end
  if not UI.targetButton then
    local b = MakeButton(UIParent, 150, 24, "Open Quartermaster")
    if TargetFrame then b:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 10, 6) else b:SetPoint("CENTER", UIParent, "CENTER", 0, 200) end
    b:SetScript("OnClick", function() UI.TryOpen("target") end)
    b:Hide()
    UI.targetButton = b
  end
  local isKeeper = false
  if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
    local kn = AK.KeeperName()
    if kn and AK.Norm(UnitName("target")) == AK.Norm(kn) then isKeeper = true end
  end
  if isKeeper then
    UI.targetButton:Show()
    local now = AK.Clock()
    if AK.db and AK.db.config.debug then AK.Print("targeted the Keeper, inRange=" .. tostring(UI.KeeperInRange("target"))) end
    Build()
    if not UI.frame:IsShown() and now - (UI.lastClosed or 0) > 3 then
      if UI.KeeperInRange("target") then
        UI.frame:Show()
      elseif now - (UI.lastRangeNag or 0) > 5 then
        UI.lastRangeNag = now
        AK.Print("Move closer to the Quartermaster.")
      end
    end
  else
    UI.targetButton:Hide()
  end
end

-- Shift-clicking an item (bags or a chat link) while the Manage tab's Add box has focus puts its link there.
local function InstallLinkHooks()
  if UI.linkHooked then return end
  UI.linkHooked = true
  pcall(function()
    if type(ContainerFrameItemButton_OnClick) == "function" then
      local old = ContainerFrameItemButton_OnClick
      ContainerFrameItemButton_OnClick = function(button, ignoreShift)
        if button == "LeftButton" and not ignoreShift and IsShiftKeyDown and IsShiftKeyDown() and UI.addBox and UI.addBox.hasFocus then
          local link = GetContainerItemLink(this:GetParent():GetID(), this:GetID())
          if link then UI.addBox:SetText(link) return end
        end
        old(button, ignoreShift)
      end
    end
    if type(SetItemRef) == "function" then
      local oldRef = SetItemRef
      SetItemRef = function(link, text, button)
        if IsShiftKeyDown and IsShiftKeyDown() and UI.addBox and UI.addBox.hasFocus and text then
          UI.addBox:SetText(text)
          return
        end
        oldRef(link, text, button)
      end
    end
  end)
end

InstallWorldClick()
InstallLinkHooks()
