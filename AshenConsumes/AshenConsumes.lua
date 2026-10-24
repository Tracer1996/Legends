-- Ashen Consumes 2.2.1
-- WoW 1.12 / Lua 5.0 only. No Ace, no ClassicAPI required.
-- A user click / macro press can attempt AT MOST one bag item.

local STATUS_OK = "OK"
local STATUS_READY = "READY"
local STATUS_OUT = "OUT"
local STATUS_CD = "COOLDOWN"
local STATUS_DISABLED = "OFF"
local STATUS_UNCONFIGURED = "SET BUFF"
local STATUS_COVERED = "COVERED"
local ActiveClash, CycleHUD
local REFRESH_EVERY = 5.0
local DISPLAY_EVERY = 0.20
local MAX_ROWS = 6
local GRID_COLS = 10
local GRID_ROWS = 2

local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\FRIZQT__.TTF"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"

local C = {
    bg     = {0.055, 0.050, 0.070, 0.94},
    header = {0.100, 0.085, 0.130, 1},
    panel  = {0.100, 0.090, 0.120, 1},
    row    = {0.120, 0.105, 0.150, 0.70},
    border = {0.220, 0.190, 0.270, 1},
    accent = {0.720, 0.520, 1.000},
    text   = {0.920, 0.900, 0.950},
    dim    = {0.560, 0.530, 0.620},
    good   = {0.400, 0.950, 0.550},
    warn   = {1.000, 0.780, 0.300},
    bad    = {1.000, 0.400, 0.400},
}

-- Item name -> real buff name, for common consumes whose aura differs or is well known.
-- Anything not listed starts with buff = item name and is confirmed automatically on first use.
local KNOWN = {
    ["flask of the titans"] = "Flask of the Titans",
    ["flask of supreme power"] = "Supreme Power",
    ["flask of distilled wisdom"] = "Distilled Wisdom",
    ["elixir of the mongoose"] = "Elixir of the Mongoose",
    ["elixir of the giants"] = "Elixir of the Giants",
    ["elixir of brute force"] = "Elixir of Brute Force",
    ["elixir of greater agility"] = "Greater Agility",
    ["elixir of fortitude"] = "Health II",
    ["elixir of superior defense"] = "Greater Armor",
    ["elixir of shadow power"] = "Shadow Power",
    ["elixir of greater firepower"] = "Greater Firepower",
    ["greater arcane elixir"] = "Greater Arcane Elixir",
    ["mageblood potion"] = "Mana Regeneration",
    ["major troll's blood potion"] = "Regeneration",
    ["juju power"] = "Juju Power",
    ["juju might"] = "Juju Might",
    ["winterfall firewater"] = "Winterfall Firewater",
    ["rumsey rum black label"] = "Rumsey Rum Black Label",
    ["gift of arthas"] = "Gift of Arthas",
    ["spirit of zanza"] = "Spirit of Zanza",
    ["ground scorpok assay"] = "Strike of the Scorpok",
    ["r.o.i.d.s."] = "Rage of Ages",
    ["lung juice cocktail"] = "Spirit of Boar",
    ["cerebral cortex compound"] = "Infallible Mind",
    ["gizzard gum"] = "Spiritual Domination",
}
local IGNORE_LEARN = { ["food"] = true, ["drink"] = true }

-- Consumes inside one group overwrite each other, so only one per group may be in the lineup.
-- Matched as plain lower-case substrings of the item name. Food is handled separately (Well Fed).
-- Anything missing here is learned automatically: if using A knocks B's buff off, they're marked.
local GROUPS = {
    { "Flask", { "flask of " } },
    { "Stamina drink", { "rumsey rum", "gordok green grog", "merlot" } },
    { "Agility elixir", { "elixir of the mongoose", "elixir of greater agility", "elixir of agility", "elixir of lesser agility" } },
    { "Strength", { "elixir of the giants", "juju power" } },
    { "Attack power", { "juju might", "winterfall firewater" } },
    { "Zanza", { "spirit of zanza", "swiftness of zanza", "sheen of zanza" } },
    { "Armor elixir", { "elixir of superior defense", "elixir of greater defense", "elixir of defense", "elixir of minor defense" } },
    { "Arcane elixir", { "greater arcane elixir", "arcane elixir" } },
    { "Fire power", { "elixir of greater firepower", "elixir of firepower" } },
}

local SORTS = { "priority", "name", "missing", "time" }
local SORT_LABEL = { priority = "Sort: priority", name = "Sort: A-Z", missing = "Sort: missing first", time = "Sort: time left" }

-- Extra UI handles live in one table to stay under Lua 5.0's 32-upvalue limit.
local ui = {}

local main, hud, editor
local rows, gridButtons, listFrame, gridFrame, listEmpty, gridEmpty, listInfo
local soundButton, filterButton, thresholdText
local scrollOffset, gridOffset = 0, 0
local editIndex = nil
local initialized = false
local nextSnapshot = 0
local snapshot = {}
local bagCache = {}
local bagDirty = true
local nextBagSweep = 0
local bagList = {}
local bagListDirty = true
local classCache = {}
local pending = nil
local learn = nil
local recentUse = {}
local previousReady = {}
local previousAlertAt = 0
local lastNoActionAt = 0
local initAlertAt = nil
local scanTime = nil
local lastPickup = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function Trim(s)
    if not s then return "" end
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function Norm(s) return string.lower(Trim(s or "")) end

local function StripLink(s)
    s = Trim(s)
    local _, _, captured = string.find(s, "%[([^%]]+)%]")
    if captured then return Trim(captured) end
    return s
end

local function Say(s)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffb885ff[Ashen Consumes]|r " .. s)
    end
end

local function FormatDuration(seconds)
    if seconds == nil then return "--" end
    if seconds >= 100000 then return "active" end
    if seconds < 0 then seconds = 0 end
    local n = math.floor(seconds + 0.5)
    if n >= 3600 then return string.format("%dh %02dm", math.floor(n / 3600), math.floor(math.mod(n, 3600) / 60)) end
    return string.format("%d:%02d", math.floor(n / 60), math.mod(n, 60))
end

local function Short(sec)
    if not sec then return "--" end
    if sec >= 100000 then return "on" end
    if sec >= 3600 then return string.format("%dh%02d", math.floor(sec / 3600), math.floor(math.mod(sec, 3600) / 60)) end
    if sec >= 60 then return math.floor(sec / 60) .. "m" end
    return math.floor(sec) .. "s"
end

local function ItemNameFromLink(link)
    if not link then return nil end
    local _, _, name = string.find(link, "%[([^%]]+)%]")
    return name
end

---------------------------------------------------------------------------
-- Visual building blocks (flat style)
---------------------------------------------------------------------------
local function Flat(f, bg, border)
    f:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, tile = false, tileSize = 0, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    bg = bg or C.bg
    border = border or C.border
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function SetBorder(f, c, a)
    f:SetBackdropBorderColor(c[1], c[2], c[3], a or 1)
end

local function Text(parent, size, color, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if flags then fs:SetFont(FONT, size or 11, flags) else fs:SetFont(FONT, size or 11) end
    if not flags then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.9)
    end
    local c = color or C.text
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH("LEFT")
    return fs
end

local function Color(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end

local function Line(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(C.border[1], C.border[2], C.border[3], 1)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, y)
    return t
end

local function Tip(owner, title, lines)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if lines then
        for i = 1, table.getn(lines) do
            local l = lines[i]
            GameTooltip:AddLine(l[1], l[2] or 0.8, l[3] or 0.8, l[4] or 0.8, 1)
        end
    end
    GameTooltip:Show()
end

local function FlatButton(parent, label, w, h, onClick, tip)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w)
    b:SetHeight(h)
    Flat(b, C.panel, C.border)
    b.text = Text(b, 10, C.text)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.text:SetJustifyH("CENTER")
    b.text:SetText(label)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function()
        SetBorder(this, C.accent)
        if tip then Tip(this, tip) end
    end)
    b:SetScript("OnLeave", function()
        SetBorder(this, C.border)
        GameTooltip:Hide()
    end)
    return b
end

local function FlatCheck(parent, size)
    local c = CreateFrame("Button", nil, parent)
    c:SetWidth(size)
    c:SetHeight(size)
    Flat(c, {0, 0, 0, 0.6}, C.border)
    c.fill = c:CreateTexture(nil, "ARTWORK")
    c.fill:SetTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    c.fill:SetPoint("TOPLEFT", c, "TOPLEFT", 3, -3)
    c.fill:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -3, 3)
    c.SetOn = function(self, on)
        self.on = on and true or false
        if on then self.fill:Show() else self.fill:Hide() end
    end
    c:SetScript("OnEnter", function() SetBorder(this, C.accent) end)
    c:SetScript("OnLeave", function() SetBorder(this, C.border) end)
    return c
end

local function IconButton(parent, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(size)
    b:SetHeight(size)
    Flat(b, {0, 0, 0, 1}, C.border)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.count = Text(b, 9, C.text, "OUTLINE")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 2)
    b.count:SetJustifyH("RIGHT")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    return b
end

-- Dragging f moves target (default f). Lockable frames stay put while "Locked" is on.
local function MakeMovable(f, key, lockable, target)
    target = target or f
    target:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function()
        if CursorHasItem() or (lockable and AshenConsumesDB.locked) then return end
        target:StartMoving()
    end)
    f:SetScript("OnDragStop", function()
        target:StopMovingOrSizing()
        local cx, cy = target:GetCenter()
        local px, py = UIParent:GetCenter()
        if cx and px then AshenConsumesDB[key] = { x = cx - px, y = cy - py } end
    end)
end

local function Place(frame, saved, x, y)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", (saved and saved.x) or x, (saved and saved.y) or y)
end

---------------------------------------------------------------------------
-- Bags
---------------------------------------------------------------------------
local tooltip = CreateFrame("GameTooltip", "AshenConsumesHiddenTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltip:Hide()

local function TipLine(i)
    local l = getglobal("AshenConsumesHiddenTooltipTextLeft" .. i)
    return l and l:GetText()
end

local function RefreshBags()
    local now = GetTime()
    if not bagDirty and now < nextBagSweep then return end
    bagDirty = false
    nextBagSweep = now + 5
    local items = {}
    for bag = 0, 4 do
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local name = ItemNameFromLink(GetContainerItemLink(bag, slot))
            if name then
                local key = Norm(name)
                local tex, stack = GetContainerItemInfo(bag, slot)
                if not items[key] then
                    items[key] = {bag, slot, tex, stack or 1, stack or 1}
                else
                    items[key][5] = items[key][5] + (stack or 1)
                end
            end
        end
    end
    bagCache = items
end

local function FindBagItem(itemName)
    local needle = Norm(itemName)
    if needle == "" then return nil end
    RefreshBags()
    local data = bagCache[needle]
    if not data then return nil end
    local bag, slot, tex, stack = data[1], data[2], data[3], data[4]
    local start, duration, enabled = GetContainerItemCooldown(bag, slot)
    local remain = 0
    if start and duration and start > 0 and duration > 0 then
        remain = start + duration - GetTime()
        if remain < 0 then remain = 0 end
    end
    return bag, slot, tex, stack, remain, enabled
end

-- Total number of this item across all bags.
local function BagCount(itemName)
    RefreshBags()
    local data = bagCache[Norm(itemName)]
    return data and data[5] or 0
end

---------------------------------------------------------------------------
-- Stacking rules
---------------------------------------------------------------------------
local groupCache = {}
local function GroupOf(name)
    local n = Norm(name)
    local cached = groupCache[n]
    if cached ~= nil then return cached or nil end
    for i = 1, table.getn(GROUPS) do
        local pats = GROUPS[i][2]
        for j = 1, table.getn(pats) do
            if string.find(n, pats[j], 1, true) then groupCache[n] = GROUPS[i][1]; return GROUPS[i][1] end
        end
    end
    groupCache[n] = false
    return nil
end

-- Returns a short reason if the two items overwrite each other, else nil.
local function ConflictReason(nameA, foodA, nameB, foodB)
    if Norm(nameA) == Norm(nameB) then return nil end
    if foodA and foodB then return "both are food (Well Fed)" end
    local ga = GroupOf(nameA)
    if ga and ga == GroupOf(nameB) then return "both are " .. string.lower(ga) end
    local learned = AshenConsumesDB.conflicts[Norm(nameA)]
    if learned and learned[Norm(nameB)] then return "one removes the other's buff" end
    return nil
end

-- First lineup entry that the given item would clash with.
local function FindConflict(name, food, skipEntry)
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local e = entries[i]
        if e ~= skipEntry then
            local why = ConflictReason(name, food, e.item, e.food)
            if why then return e, why end
        end
    end
    return nil
end

local function MarkConflict(a, b)
    local na, nb = Norm(a), Norm(b)
    local c = AshenConsumesDB.conflicts
    if not c[na] then c[na] = {} end
    if not c[nb] then c[nb] = {} end
    c[na][nb] = true
    c[nb][na] = true
end

-- Works out whether a bag item is a usable consumable and whether it gives a timed buff.
local function Classify(bag, slot, link, name)
    local _, _, istr = string.find(link, "(item:%d+:%d+:%d+:%d+)")
    local key = istr or link
    if classCache[key] then return classCache[key] end
    local equipLoc
    if istr then
        local _, _, _, _, _, _, _, el = GetItemInfo(istr)
        equipLoc = el
    end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetBagItem(bag, slot)
    local useLine, food = nil, false
    for i = 1, tooltip:NumLines() do
        local t = TipLine(i)
        if t then
            if not useLine and string.find(t, "^Use:") then useLine = t end
            local lt = string.lower(t)
            if string.find(lt, "seated while eating") or string.find(lt, "well fed") then food = true end
        end
    end
    local c = {}
    c.usable = useLine ~= nil and (equipLoc == nil or equipLoc == "")
    c.food = food
    c.buff = false
    if c.usable then
        if food or KNOWN[Norm(name)] or string.find(useLine, "%d+ min") or string.find(useLine, "%d+ hour")
            or string.find(useLine, "%d+ hr") then
            c.buff = true
        end
    end
    classCache[key] = c
    return c
end

local function BuildBagList()
    local list, byName = {}, {}
    for bag = 0, 4 do
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local link = GetContainerItemLink(bag, slot)
            local name = ItemNameFromLink(link)
            if name then
                local c = Classify(bag, slot, link, name)
                if c.usable and (c.buff or AshenConsumesDB.showAllBag) then
                    local tex, count = GetContainerItemInfo(bag, slot)
                    local k = Norm(name)
                    local e = byName[k]
                    if e then
                        e.count = e.count + (count or 1)
                    else
                        e = { name = name, tex = tex, count = count or 1, bag = bag, slot = slot, food = c.food }
                        byName[k] = e
                        table.insert(list, e)
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    bagList = list
    bagListDirty = false
end

---------------------------------------------------------------------------
-- Buffs
---------------------------------------------------------------------------
local function ScanBuffs()
    local found = {}
    for i = 0, 31 do
        local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
        if buffIndex and buffIndex >= 0 then
            local timeleft = GetPlayerBuffTimeLeft(buffIndex) or 0
            local texture = GetPlayerBuffTexture(buffIndex)
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:ClearLines()
            tooltip:SetPlayerBuff(buffIndex)
            local name = TipLine(1)
            if name and name ~= "" then
                local key = Norm(name)
                local remains = timeleft
                if untilCancelled == 1 then remains = 999999 end
                if not found[key] or remains > found[key].left then
                    found[key] = { left = remains, texture = texture, name = name, index = buffIndex, group = GroupOf(name) }
                end
            end
        end
    end
    snapshot = found
    nextSnapshot = GetTime() + REFRESH_EVERY
end

-- Buff names that belong to known consumables (used to avoid learning the wrong buff).
local KNOWN_BUFF = {}
for _, v in pairs(KNOWN) do KNOWN_BUFF[string.lower(v)] = true end

local function SimilarName(k, item)
    return string.len(k) >= 5 and (string.find(k, item, 1, true) or string.find(item, k, 1, true))
end

-- If an item's buff isn't up but a buff with a similar name is (item "Mug of Blackroot Brew"
-- -> buff "Blackroot Brew"), that's its real buff name: adopt it.
local function AdoptSimilarBuffs()
    local entries = AshenConsumesDB and AshenConsumesDB.entries
    if not entries then return end
    for i = 1, table.getn(entries) do
        local e = entries[i]
        if not snapshot[Norm(e.buff)] and not e.food then
            local item = Norm(e.item)
            for k, v in pairs(snapshot) do
                if not IGNORE_LEARN[k] and SimilarName(k, item) then
                    e.buff = v.name
                    e.learned = true
                    Say("Matched " .. e.item .. " to the buff |cffffffff" .. v.name .. "|r.")
                    break
                end
            end
        end
    end
end

local function ForceScan()
    ScanBuffs()
    scanTime = GetTime()
    AdoptSimilarBuffs()
end

local function CheckBuff(entry, now)
    local b = snapshot[Norm(entry.buff)]
    if not b then return nil end
    if b.left >= 100000 then return b.left end
    local left = b.left - (now - (scanTime or now))
    if left < 0 then left = 0 end
    return left
end

-- Auto-learn: after using an unconfirmed item, whichever buff appears (or gets refreshed) is its buff.
local function BeginLearn(entry, now)
    if entry.learned then learn = nil; return end
    local before = {}
    for k, v in pairs(snapshot) do before[k] = v.left end
    learn = { entry = entry, before = before, untilTime = now + (entry.food and 25 or 6) }
end

local function CheckLearn(now)
    if not learn then return end
    local e = learn.entry
    if now > learn.untilTime then
        Say("Couldn't detect which buff " .. e.item .. " gives. Open /ac and click it to pick the buff.")
        recentUse[e] = now + 120
        learn = nil
        return
    end
    -- Buffs that belong to something else can't be this item's buff.
    local taken = {}
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        if entries[i] ~= e then taken[Norm(entries[i].buff)] = true end
    end
    local item = Norm(e.item)
    local found, n = nil, 0
    for k, v in pairs(snapshot) do
        local was = learn.before[k]
        local fresh = was == nil or (v.left < 100000 and v.left > was + 20)
        if fresh and not IGNORE_LEARN[k] then
            if SimilarName(k, item) then found, n = v, 1; break end
            if not taken[k] and not KNOWN_BUFF[k] then
                found = v
                n = n + 1
            end
        end
    end
    if n == 1 then
        if Norm(found.name) ~= Norm(e.buff) then
            Say("Learned: " .. e.item .. " gives |cffffffff" .. found.name .. "|r.")
        end
        e.buff = found.name
        e.learned = true
        learn = nil
    end
end

-- Lineup clash map, rebuilt whenever the lineup changes (kept out of SavedVariables).
local clashOf = {}
local function RebuildClashes()
    clashOf = {}
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local a = entries[i]
        for j = 1, table.getn(entries) do
            local b = entries[j]
            if i ~= j and ConflictReason(a.item, a.food, b.item, b.food) then
                if not clashOf[a] then clashOf[a] = {} end
                table.insert(clashOf[a], b)
            end
        end
    end
end

-- Is this active buff probably from a consumable (so a clash with it is meaningful)?
local function ConsumeLikeBuff(k, v)
    if v.group or KNOWN_BUFF[k] or BagCount(v.name) > 0 then return true end
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        if Norm(entries[i].buff) == k then return true end
    end
    return false
end

-- Auto-detect clashes: if using A makes buff B (with time left) vanish, they don't stack.
local function BeginWatch(entry, now)
    local others, any = {}, false
    local own = Norm(entry.buff)
    for k, v in pairs(snapshot) do
        if k ~= own and v.left > 30 and v.left < 100000 and ConsumeLikeBuff(k, v) then
            others[k] = v.name
            any = true
        end
    end
    ui.watch = any and { entry = entry, others = others, untilTime = now + (entry.food and 25 or 8) } or nil
end

local function CheckWatch(now)
    local w = ui.watch
    if not w then return end
    if now > w.untilTime then ui.watch = nil; return end
    if not snapshot[Norm(w.entry.buff)] then return end
    for k, name in pairs(w.others) do
        if not snapshot[k] then
            MarkConflict(w.entry.item, name)
            Say(w.entry.item .. " replaced " .. name .. ". They don't stack, so it won't be refreshed while " .. name .. " is up.")
        end
    end
    ui.watch = nil
    RebuildClashes()
end

---------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------
-- A clashing lineup item whose buff is currently up (so this one must not be used).
ActiveClash = function(entry, now)
    local clashes = clashOf[entry]
    if clashes then
        for i = 1, table.getn(clashes) do
            local o = clashes[i]
            if o.enabled and CheckBuff(o, now) then return o end
        end
    end
    -- Also anything active that isn't in the lineup (e.g. Merlot up while Rumsey is tracked).
    local own = Norm(entry.buff)
    local grp = GroupOf(entry.item)
    local learned = AshenConsumesDB.conflicts[Norm(entry.item)]
    for k, v in pairs(snapshot) do
        if k ~= own then
            if (grp and v.group == grp) or (learned and learned[k]) or (entry.food and k == "well fed") then
                return { item = v.name, enabled = true }
            end
        end
    end
    return nil
end

local function Status(entry, now)
    if not entry.enabled then return STATUS_DISABLED, nil end
    if Trim(entry.buff) == "" then return STATUS_UNCONFIGURED, nil end
    local left = CheckBuff(entry, now)
    if left and left > AshenConsumesDB.threshold then return STATUS_OK, left end
    local other = ActiveClash(entry, now)
    if other then return STATUS_COVERED, left, nil, other end
    local bag, slot, icon, stack, cd, cdEnabled = FindBagItem(entry.item)
    if not bag then return STATUS_OUT, left end
    if icon then entry.icon = icon end
    if (recentUse[entry] and now < recentUse[entry]) or (cd and cd > 0.05) or cdEnabled == 0 then
        return STATUS_CD, left, {bag, slot, icon, stack, cd}
    end
    return STATUS_READY, left, {bag, slot, icon, stack, 0}
end

local function IsEligible(entry, now)
    if not entry.enabled or Trim(entry.item) == "" or Trim(entry.buff) == "" then return false end
    -- Never overwrite a clashing consume that is already active.
    if ActiveClash(entry, now) then return false end
    local left = CheckBuff(entry, now)
    return left == nil or left <= AshenConsumesDB.threshold
end

local function ReadyCount(now)
    local total, runnable, low = 0, 0, 0
    local first, firstNeeded
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local e = entries[i]
        if IsEligible(e, now) then
            total = total + 1
            if not firstNeeded then firstNeeded = e end
            local st = Status(e, now)
            if st == STATUS_READY then
                runnable = runnable + 1
                if not first then first = e end
            elseif st == STATUS_OUT then
                low = low + 1
            end
        end
    end
    return total, runnable, first, low, firstNeeded
end

-- Flashing (pulsing borders + centre-screen warning): "raid" = only in a raid (default),
-- "always", or "off".
local FLASH_LABEL = { raid = "Flash: raid", always = "Flash: always", off = "Flash: off" }
local function FlashOn()
    local m = AshenConsumesDB.flashMode or "raid"
    if m == "off" then return false end
    if m == "always" then return true end
    return GetNumRaidMembers() > 0
end

local function Pulse(now)
    if FlashOn() then return 0.45 + 0.55 * math.abs(math.sin(now * 3)) end
    return 1
end

local function Alert(message)
    local now = GetTime()
    if now - previousAlertAt < 8 then return end
    previousAlertAt = now
    if AshenConsumesDB.sound then PlaySoundFile("Sound\\Interface\\RaidWarning.wav") end
    if FlashOn() and RaidWarningFrame and RaidNotice_AddMessage and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, "Consumes: " .. message, ChatTypeInfo["RAID_WARNING"])
    end
    Say(message)
end

local function UpdateNotices(now)
    local newReady, firstName, neededCount = false, nil, 0
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local e = entries[i]
        local newState = IsEligible(e, now) and 1 or 0
        if newState == 1 then
            neededCount = neededCount + 1
            if previousReady[e] == 0 then
                newReady = true
                if not firstName then firstName = e.item end
            end
        end
        previousReady[e] = newState
    end
    if initAlertAt and now >= initAlertAt then
        initAlertAt = nil
        if neededCount > 0 then
            Alert(neededCount .. " consumable(s) missing or running low.")
        end
    elseif newReady and firstName then
        Alert(firstName .. " needs a refresh.")
    end
end

---------------------------------------------------------------------------
-- Tracking list management
---------------------------------------------------------------------------
local RefreshUI -- forward

local function FindEntry(name)
    local n = Norm(name)
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        if Norm(entries[i].item) == n then return i end
    end
    return nil
end

local function TrackItem(name, tex, food)
    if FindEntry(name) then return false end
    local clash, why = FindConflict(name, food, nil)
    if clash then
        Say("|cffff6666Can't add " .. name .. "|r: it doesn't stack with " .. clash.item .. " (" .. why .. "). Remove that one first.")
        PlaySound("igQuestFailed")
        return false
    end
    local known = KNOWN[Norm(name)]
    local buff = (food and "Well Fed") or known or name
    table.insert(AshenConsumesDB.entries, {
        item = name, buff = buff, enabled = true, food = food and true or false,
        icon = tex, learned = (known or food) and true or false, want = 1,
    })
    RebuildClashes()
    scrollOffset = math.max(0, table.getn(AshenConsumesDB.entries) - MAX_ROWS)
    pending = nil
    if known or food then
        Say("Tracking " .. name .. " (buff: " .. buff .. ").")
    else
        Say("Tracking " .. name .. ". Its buff will be detected automatically the first time you use it.")
    end
    return true
end

local function UntrackIndex(i)
    local e = AshenConsumesDB.entries[i]
    if not e then return end
    table.remove(AshenConsumesDB.entries, i)
    if learn and learn.entry == e then learn = nil end
    RebuildClashes()
    scrollOffset = math.min(scrollOffset, math.max(0, table.getn(AshenConsumesDB.entries) - MAX_ROWS))
    if editor and editor:IsVisible() and editIndex == i then editor:Hide() end
    pending = nil
end

local function TrackFromBag(bag, slot, toggle)
    local link = GetContainerItemLink(bag, slot)
    local name = ItemNameFromLink(link)
    if not name then return end
    local idx = FindEntry(name)
    if idx then
        if toggle then
            UntrackIndex(idx)
            Say("Stopped tracking " .. name .. ".")
        else
            Say(name .. " is already tracked.")
        end
    else
        local tex = GetContainerItemInfo(bag, slot)
        local c = Classify(bag, slot, link, name)
        TrackItem(name, tex, c.food)
        ForceScan()
    end
    if RefreshUI then RefreshUI(GetTime()) end
end

-- Drag-and-drop support for any bag addon: remember the last bag slot that was picked up.
local origPickup = PickupContainerItem
PickupContainerItem = function(bag, slot)
    lastPickup = { bag = bag, slot = slot }
    return origPickup(bag, slot)
end

local function HandleDrop()
    if not CursorHasItem() or not lastPickup then return false end
    local bag, slot = lastPickup.bag, lastPickup.slot
    lastPickup = nil
    TrackFromBag(bag, slot, false)
    ClearCursor()
    return true
end

local function AcceptDrops(f)
    f:SetScript("OnReceiveDrag", function() HandleDrop() end)
    f:SetScript("OnMouseUp", function() if CursorHasItem() then HandleDrop() end end)
end

-- Alt + Right-click an item in your bags toggles tracking.
if ContainerFrameItemButton_OnClick then
    local origClick = ContainerFrameItemButton_OnClick
    ContainerFrameItemButton_OnClick = function(button, ignoreModifiers)
        if initialized and button == "RightButton" and IsAltKeyDown() then
            TrackFromBag(this:GetParent():GetID(), this:GetID(), true)
            return
        end
        return origClick(button, ignoreModifiers)
    end
end

---------------------------------------------------------------------------
-- Using items
---------------------------------------------------------------------------
local function UseEntry(entry, bag, slot, now)
    BeginLearn(entry, now)
    BeginWatch(entry, now)
    pending = { item = entry.item, buff = entry.buff, untilTime = now + (entry.food and 12 or 1.3) }
    recentUse[entry] = now + (entry.food and 15 or 10)
    ui.selfUse = true
    UseContainerItem(bag, slot)
    ui.selfUse = nil
    if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit("player") end
    Say("Using " .. entry.item .. ".")
    RefreshUI(GetTime())
end

-- Manual use (bags or action bar) of a lineup item also teaches the addon its buff
-- and which buffs it knocks off.
local function NoticeManualUse(name)
    if not initialized or ui.selfUse or not name then return end
    -- Right-clicking at a vendor, bank, mailbox or trade window isn't drinking it.
    local busy = { MerchantFrame, BankFrame, TradeFrame, SendMailFrame, AuctionFrame }
    for i = 1, 5 do
        if busy[i] and busy[i]:IsVisible() then return end
    end
    local idx = FindEntry(name)
    if not idx then return end
    local e = AshenConsumesDB.entries[idx]
    local now = GetTime()
    ForceScan()
    BeginLearn(e, now)
    BeginWatch(e, now)
    recentUse[e] = now + (e.food and 15 or 10)
end

local origUseContainerItem = UseContainerItem
UseContainerItem = function(bag, slot, onSelf)
    if not ui.selfUse then NoticeManualUse(ItemNameFromLink(GetContainerItemLink(bag, slot))) end
    return origUseContainerItem(bag, slot, onSelf)
end

local origUseAction = UseAction
UseAction = function(slot, checkCursor, onSelf)
    if initialized and not ui.selfUse and GetActionText(slot) == nil then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:ClearLines()
        tooltip:SetAction(slot)
        NoticeManualUse(TipLine(1))
    end
    return origUseAction(slot, checkCursor, onSelf)
end

-- Called by mouse button OR a spammable macro. Never called from OnUpdate.
function AshenConsumes_UseNext()
    if not initialized then return end
    local now = GetTime()
    if pending and now < pending.untilTime then return end
    pending = nil
    ForceScan()
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local entry = entries[i]
        if IsEligible(entry, now) then
            local st, _, bagData = Status(entry, now)
            if st == STATUS_READY and bagData then
                UseEntry(entry, bagData[1], bagData[2], now)
                return
            end
        end
    end
    if now - lastNoActionAt > 3 then
        lastNoActionAt = now
        if ReadyCount(now) == 0 then
            Say("All buffs have more than " .. math.floor(AshenConsumesDB.threshold / 60) .. "m left.")
        else
            Say("Nothing usable right now (missing from bags or on cooldown).")
        end
    end
    RefreshUI(now)
end

local function UseSpecific(entry)
    local now = GetTime()
    if pending and now < pending.untilTime then return end
    ForceScan()
    local st, left, bagData = Status(entry, now)
    if st == STATUS_READY and bagData then
        pending = nil
        UseEntry(entry, bagData[1], bagData[2], now)
    elseif st == STATUS_OK then
        Say(entry.item .. " still has " .. FormatDuration(left) .. " left.")
    elseif st == STATUS_OUT then
        Say("No " .. entry.item .. " in your bags.")
    elseif st == STATUS_CD then
        Say(entry.item .. " is on cooldown.")
    elseif st == STATUS_COVERED then
        local _, _, _, other = Status(entry, now)
        Say(other.item .. " is active and doesn't stack with " .. entry.item .. ".")
    end
end

local function AddWarriorPreset()
    local presets = {
        {"Flask of the Titans"}, {"Elixir of the Mongoose"}, {"Juju Power"}, {"Juju Might"},
        {"Rumsey Rum Black Label"}, {"Gift of Arthas"}, {"Smoked Desert Dumplings", true},
    }
    local added = 0
    for i = 1, table.getn(presets) do
        local p = presets[i]
        if not FindEntry(p[1]) and not FindConflict(p[1], p[2], nil) then
            local buff = p[2] and "Well Fed" or (KNOWN[Norm(p[1])] or p[1])
            table.insert(AshenConsumesDB.entries, { item = p[1], buff = buff, food = p[2] or false, enabled = true, learned = true, want = 1 })
            added = added + 1
        end
    end
    RebuildClashes()
    scrollOffset = 0
    Say("Added " .. added .. " warrior preset item(s). Items that clash with your lineup were skipped.")
    pending = nil
    ForceScan()
    RefreshUI(GetTime())
end

-- Lineup items with fewer in bags than you want to carry.
local function MissingList()
    local out = {}
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local e = entries[i]
        local want = e.want or 1
        if want > 0 and BagCount(e.item) < want then table.insert(out, e) end
    end
    return out
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------
local HUD_ICON = 26
local HUD_STEP = 29
local hudShown = ""

local function ToggleMain()
    if main:IsVisible() then main:Hide() else main:Show(); bagListDirty = true; RefreshUI(GetTime()) end
end

local function EntryTip(owner, e, now, extra)
    local st, left, _, other = Status(e, now)
    local lines = {}
    local sc = C.dim
    if st == STATUS_OK then sc = C.good elseif st == STATUS_READY then sc = C.warn
    elseif st == STATUS_OUT then sc = C.bad elseif st == STATUS_CD then sc = C.warn end
    table.insert(lines, { "Buff: " .. e.buff .. (e.learned and "" or "  (unconfirmed)"), C.accent[1], C.accent[2], C.accent[3] })
    local stText = "Time left: " .. FormatDuration(left)
    if st == STATUS_OUT then stText = stText .. "  -  none in bags"
    elseif st == STATUS_CD then stText = stText .. "  -  on cooldown"
    elseif st == STATUS_COVERED then stText = "Skipped: " .. other.item .. " is active (they don't stack)"
    elseif st == STATUS_READY then stText = stText .. "  -  ready to refresh" end
    table.insert(lines, { stText, sc[1], sc[2], sc[3] })
    local have, want = BagCount(e.item), e.want or 1
    local stc = (have >= want) and C.good or C.bad
    table.insert(lines, { "In bags: " .. have .. (want > 0 and ("  (want " .. want .. ")") or ""), stc[1], stc[2], stc[3] })
    local clashes = clashOf[e]
    if clashes then
        local names = {}
        for i = 1, table.getn(clashes) do table.insert(names, clashes[i].item) end
        table.insert(lines, { "Doesn't stack with: " .. table.concat(names, ", "), C.bad[1], C.bad[2], C.bad[3] })
    end
    if extra then
        for i = 1, table.getn(extra) do table.insert(lines, { extra[i], C.dim[1], C.dim[2], C.dim[3] }) end
    end
    Tip(owner, e.item, lines)
end

-- Tooltip for the main HUD square: the whole lineup at a glance.
local function LineupTip(owner)
    local now = GetTime()
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Ashen Consumes", C.accent[1], C.accent[2], C.accent[3])
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        local e = entries[i]
        if e.enabled then
            local st, left = Status(e, now)
            local c, t = C.good, FormatDuration(left)
            if st == STATUS_READY then c = C.warn
            elseif st == STATUS_CD then c, t = C.warn, "cooldown"
            elseif st == STATUS_OUT then c, t = C.bad, "none in bags"
            elseif st == STATUS_COVERED then c, t = C.dim, "covered" end
            GameTooltip:AddDoubleLine(e.item, t, 0.9, 0.9, 0.9, c[1], c[2], c[3])
        end
    end
    GameTooltip:AddLine("Click: use next   Right-click: settings", C.dim[1], C.dim[2], C.dim[3])
    GameTooltip:Show()
end

local function MakeHudIcon(i)
    local b = IconButton(hud, HUD_ICON)
    b:SetPoint("TOPLEFT", hud, "TOPLEFT", 47 + (i - 1) * HUD_STEP, -6)
    b.timer = Text(hud, 9, C.text, "OUTLINE")
    b.timer:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.timer:SetJustifyH("CENTER")
    b:SetScript("OnClick", function()
        if CursorHasItem() then HandleDrop(); return end
        if arg1 == "RightButton" then ToggleMain(); return end
        if this.entry then UseSpecific(this.entry) end
    end)
    b:SetScript("OnEnter", function()
        if this.entry then EntryTip(this, this.entry, GetTime(), { "Click: use now   Right-click: settings" }) end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MakeMovable(b, "hudPos", true, hud)
    hud.icons[i] = b
    return b
end

local function LayoutHUD(mode, n)
    local key = mode .. n
    if key == hudShown then return end
    hudShown = key
    local single = (mode == "single")
    for i = 1, table.getn(hud.icons) do
        hud.icons[i]:Hide()
        hud.icons[i].timer:Hide()
    end
    if single then
        hud:SetWidth(46)
        hud:SetHeight(46)
        hud.status:Hide(); hud.sep:Hide(); hud.gear:Hide()
    else
        hud:SetWidth(math.max(186, 47 + n * HUD_STEP + 4))
        hud:SetHeight(62)
        hud.status:Show(); hud.sep:Show(); hud.gear:Show()
    end
end

local function SetNext(nb, tex, border, alpha, dim, timer, timerColor)
    nb.icon:SetTexture(tex or QUESTION)
    if tex == CHECK then
        nb.icon:SetTexCoord(0, 1, 0, 1)
        nb.icon:SetVertexColor(C.good[1], C.good[2], C.good[3])
    else
        nb.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        nb.icon:SetVertexColor(dim or 1, dim or 1, dim or 1)
    end
    SetBorder(nb, border, alpha)
    hud.nextTimer:SetText(timer or "")
    if timerColor then Color(hud.nextTimer, timerColor) end
end

local function RefreshHUD(now)
    local mode = AshenConsumesDB.hudMode or "bar"
    local list = {}
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        if entries[i].enabled then table.insert(list, entries[i]) end
    end
    local n = table.getn(list)
    LayoutHUD(mode, n)
    local pulse = Pulse(now)
    local soonest, soonestLeft = nil, nil
    for i = 1, n do
        local e = list[i]
        local st, left, bagData = Status(e, now)
        if left and left < 100000 and st ~= STATUS_COVERED and (not soonestLeft or left < soonestLeft) then
            soonest, soonestLeft = e, left
        end
        if mode ~= "single" then
            local b = hud.icons[i] or MakeHudIcon(i)
            b.entry = e
            b:Show()
            b.timer:Show()
            b.icon:SetTexture((bagData and bagData[3]) or e.icon or QUESTION)
            b.count:SetText("")
            if st == STATUS_OK then
                b.icon:SetVertexColor(1, 1, 1); SetBorder(b, C.border)
                b.timer:SetText(Short(left)); Color(b.timer, C.text)
            elseif st == STATUS_COVERED then
                b.icon:SetVertexColor(0.35, 0.35, 0.35); SetBorder(b, C.border)
                b.timer:SetText(""); Color(b.timer, C.dim)
            elseif st == STATUS_READY then
                b.icon:SetVertexColor(1, 1, 1); SetBorder(b, C.warn, pulse)
                b.timer:SetText(Short(left)); Color(b.timer, C.warn)
            elseif st == STATUS_CD then
                b.icon:SetVertexColor(0.6, 0.6, 0.6); SetBorder(b, C.warn, 0.5)
                b.timer:SetText(left and Short(left) or "cd"); Color(b.timer, C.warn)
            else
                b.icon:SetVertexColor(0.35, 0.35, 0.35); SetBorder(b, C.bad)
                b.timer:SetText(left and Short(left) or "out"); Color(b.timer, C.bad)
            end
        end
    end

    local total, _, first, out, firstNeeded = ReadyCount(now)
    local nb = hud.next
    local label, lc
    hud.okMark:Hide()
    if pending and now < pending.untilTime then
        local idx = FindEntry(pending.item)
        SetNext(nb, idx and AshenConsumesDB.entries[idx].icon, C.accent, 1, 1, "...", C.accent)
        label, lc = "Applying " .. pending.item .. "...", C.accent
    elseif first then
        SetNext(nb, first.icon, C.warn, pulse, 1, CheckBuff(first, now) and Short(CheckBuff(first, now)) or "use", C.warn)
        label, lc = "Next: " .. first.item, C.warn
    elseif total > 0 then
        SetNext(nb, firstNeeded and firstNeeded.icon, C.bad, 1, 0.4, out > 0 and "out" or "cd", C.bad)
        if out > 0 then label = out .. " missing from bags" else label = "Waiting on cooldown" end
        lc = C.bad
    elseif n == 0 then
        SetNext(nb, CHECK, C.border, 1)
        label, lc = "Drag consumables here to track", C.dim
    elseif mode == "single" and soonest and soonestLeft <= AshenConsumesDB.threshold + 600 then
        -- Nothing to do yet: show what falls off next.
        SetNext(nb, soonest.icon, C.good, 1, 1, Short(soonestLeft), C.text)
        hud.okMark:Show()
        label, lc = "All good", C.good
    else
        SetNext(nb, CHECK, C.good, 0.8)
        label, lc = "All buffs healthy", C.good
    end
    hud.status:SetText(label)
    Color(hud.status, lc)
end

-- Well Fed box: its own small movable square.
local FOOD_ICON = "Interface\\Icons\\Spell_Misc_Food"

local function FoodEntry()
    local entries = AshenConsumesDB.entries
    for i = 1, table.getn(entries) do
        if entries[i].food and entries[i].enabled then return entries[i] end
    end
    return nil
end

local function RefreshFood(now)
    local f = ui.food
    if not f then return end
    if not AshenConsumesDB.showFood then f:Hide(); return end
    f:Show()
    local b = f.btn
    local fe = FoodEntry()
    local left = CheckBuff({ buff = "Well Fed" }, now)
    local pulse = Pulse(now)
    b.icon:SetTexture((fe and fe.icon) or (snapshot["well fed"] and snapshot["well fed"].texture) or FOOD_ICON)
    if left and left > AshenConsumesDB.threshold then
        b.icon:SetVertexColor(1, 1, 1)
        SetBorder(b, C.good)
        f.timer:SetText(Short(left)); Color(f.timer, C.text)
    elseif left then
        b.icon:SetVertexColor(1, 1, 1)
        SetBorder(b, C.warn, pulse)
        f.timer:SetText(Short(left)); Color(f.timer, C.warn)
    else
        local have = fe and BagCount(fe.item) or 0
        local v = (have > 0) and 1 or 0.35
        b.icon:SetVertexColor(v, v, v)
        SetBorder(b, C.bad, pulse)
        f.timer:SetText(have > 0 and "eat" or "none"); Color(f.timer, C.bad)
    end
end

local function FoodTip(owner)
    local now = GetTime()
    local fe = FoodEntry()
    local left = CheckBuff({ buff = "Well Fed" }, now)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Well Fed", 1, 1, 1)
    if left then
        GameTooltip:AddLine(FormatDuration(left) .. " left", C.good[1], C.good[2], C.good[3])
    else
        GameTooltip:AddLine("Not Well Fed", C.bad[1], C.bad[2], C.bad[3])
    end
    if fe then
        GameTooltip:AddLine(fe.item .. ": " .. BagCount(fe.item) .. " in bags", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Click: eat   Drag: move   Right-click: settings", C.dim[1], C.dim[2], C.dim[3])
    else
        GameTooltip:AddLine("Add a food to your lineup to eat from here.", C.dim[1], C.dim[2], C.dim[3])
    end
    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Main window
---------------------------------------------------------------------------
-- Indices of the lineup in the order chosen by the sort button (display only;
-- the use order is always the priority order).
local function SortedView(now)
    local entries = AshenConsumesDB.entries
    local view = {}
    for i = 1, table.getn(entries) do table.insert(view, i) end
    local mode = AshenConsumesDB.sortMode or "priority"
    if mode == "priority" then return view end
    local key = {}
    for i = 1, table.getn(entries) do
        local e = entries[i]
        if mode == "name" then
            key[i] = Norm(e.item)
        elseif mode == "missing" then
            key[i] = (BagCount(e.item) < (e.want or 1)) and 0 or 1
        else
            local left = CheckBuff(e, now)
            key[i] = left or -1
        end
    end
    table.sort(view, function(a, b)
        if key[a] ~= key[b] then return key[a] < key[b] end
        return a < b
    end)
    return view
end

local function RefreshList(now)
    local entries = AshenConsumesDB.entries
    local count = table.getn(entries)
    local view = SortedView(now)
    local manual = (AshenConsumesDB.sortMode or "priority") == "priority"
    if scrollOffset > math.max(0, count - MAX_ROWS) then scrollOffset = math.max(0, count - MAX_ROWS) end
    for r = 1, MAX_ROWS do
        local row = rows[r]
        local i = view[scrollOffset + r]
        local e = i and entries[i]
        if e then
            row.index = i
            row:Show()
            local st, left, bagData, other = Status(e, now)
            row.check:SetOn(e.enabled)
            row.icon.icon:SetTexture((bagData and bagData[3]) or e.icon or QUESTION)
            local v = e.enabled and 1 or 0.4
            row.icon.icon:SetVertexColor(v, v, v)
            row.name:SetText(e.item)
            Color(row.name, e.enabled and C.text or C.dim)
            local sub = e.buff
            if e.food then sub = sub .. "  |cff8f87a0- food|r" end
            if not e.learned then sub = sub .. "  |cffffc74d(auto-detect)|r" end
            if clashOf[e] then sub = "|cffff6666clashes with " .. clashOf[e][1].item .. "|r" end
            row.buff:SetText(sub)
            if st == STATUS_DISABLED then
                row.time:SetText("off"); Color(row.time, C.dim)
            elseif st == STATUS_OK then
                row.time:SetText(FormatDuration(left)); Color(row.time, C.good)
            elseif st == STATUS_COVERED then
                row.time:SetText("covered"); Color(row.time, C.dim)
            elseif st == STATUS_READY then
                row.time:SetText(left and FormatDuration(left) or "missing"); Color(row.time, C.warn)
            elseif st == STATUS_CD then
                row.time:SetText("cooldown"); Color(row.time, C.warn)
            elseif st == STATUS_OUT then
                row.time:SetText(left and FormatDuration(left) or "missing"); Color(row.time, C.bad)
            else
                row.time:SetText("set buff"); Color(row.time, C.bad)
            end
            local have, want = BagCount(e.item), e.want or 1
            if want > 0 then
                row.stock:SetText(have .. " / " .. want .. " in bags")
                Color(row.stock, have >= want and C.dim or C.bad)
            else
                row.stock:SetText(have .. " in bags")
                Color(row.stock, C.dim)
            end
            if manual then
                row.up:Show(); row.down:Show()
                row.up:SetAlpha(i > 1 and 1 or 0.25)
                row.down:SetAlpha(i < count and 1 or 0.25)
            else
                row.up:Hide(); row.down:Hide()
            end
        else
            row:Hide()
        end
    end
    if count == 0 then listEmpty:Show() else listEmpty:Hide() end
    if count > MAX_ROWS then
        listInfo:SetText((scrollOffset + 1) .. "-" .. math.min(count, scrollOffset + MAX_ROWS) .. " of " .. count)
    else
        listInfo:SetText(count == 1 and "1 item" or (count .. " items"))
    end
    ui.sortBtn.text:SetText(SORT_LABEL[AshenConsumesDB.sortMode or "priority"])

    -- Shopping list banner
    local miss = MissingList()
    local nm = table.getn(miss)
    if count == 0 then
        ui.missing:SetText("")
    elseif nm == 0 then
        ui.missing:SetText("Everything in your lineup is in your bags.")
        Color(ui.missing, C.good)
    else
        local names = {}
        for k = 1, math.min(3, nm) do table.insert(names, miss[k].item) end
        local more = (nm > 3) and ("  +" .. (nm - 3) .. " more") or ""
        ui.missing:SetText("Missing: " .. table.concat(names, ", ") .. more)
        Color(ui.missing, C.bad)
    end
end

local function RefreshGrid()
    if bagListDirty then BuildBagList() end
    local total = table.getn(bagList)
    local maxOffset = math.max(0, math.ceil(total / GRID_COLS) - GRID_ROWS)
    if gridOffset > maxOffset then gridOffset = maxOffset end
    for k = 1, GRID_COLS * GRID_ROWS do
        local b = gridButtons[k]
        local d = bagList[gridOffset * GRID_COLS + k]
        b.data = d
        if d then
            b:Show()
            b.icon:SetTexture(d.tex or QUESTION)
            b.count:SetText(d.count > 1 and d.count or "")
            b.clash = nil
            if FindEntry(d.name) then
                SetBorder(b, C.accent)
                b.check:Show()
                b.icon:SetVertexColor(1, 1, 1)
            else
                b.check:Hide()
                local clash, why = FindConflict(d.name, d.food, nil)
                if clash then
                    b.clash = clash.item .. " (" .. why .. ")"
                    SetBorder(b, C.bad, 0.6)
                    b.icon:SetVertexColor(0.3, 0.3, 0.3)
                else
                    SetBorder(b, C.border)
                    b.icon:SetVertexColor(0.85, 0.85, 0.85)
                end
            end
        else
            b:Hide()
        end
    end
    if total == 0 then gridEmpty:Show() else gridEmpty:Hide() end
    filterButton.text:SetText(AshenConsumesDB.showAllBag and "Show: all usable" or "Show: buffs only")
end

RefreshUI = function(now)
    if not initialized then return end
    if hud:IsVisible() then RefreshHUD(now) end
    RefreshFood(now)
    if main:IsVisible() then
        RefreshList(now)
        RefreshGrid()
        thresholdText:SetText(math.floor(AshenConsumesDB.threshold / 60) .. "m")
        soundButton.text:SetText(AshenConsumesDB.sound and "Sound on" or "Sound off")
        ui.hudBtn.text:SetText(AshenConsumesDB.showHUD and ("HUD: " .. (AshenConsumesDB.hudMode or "bar")) or "HUD: hidden")
        ui.foodBtn.text:SetText(AshenConsumesDB.showFood and "Food box: on" or "Food box: off")
        ui.lockBtn.text:SetText(AshenConsumesDB.locked and "Locked" or "Unlocked")
        ui.flashBtn.text:SetText(FLASH_LABEL[AshenConsumesDB.flashMode or "raid"])
        Color(ui.lockBtn.text, AshenConsumesDB.locked and C.warn or C.text)
        Color(soundButton.text, AshenConsumesDB.sound and C.text or C.dim)
    end
end

---------------------------------------------------------------------------
-- Buff picker (editor)
---------------------------------------------------------------------------
local editBox, editFood, editIcon, editName, buffButtons, buffEmpty

local function RefreshEditorBuffs()
    local n = 0
    for i = 0, 31 do
        local idx = GetPlayerBuff(i, "HELPFUL")
        if idx and idx >= 0 and n < table.getn(buffButtons) then
            n = n + 1
            local b = buffButtons[n]
            b.buffIndex = idx
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:ClearLines()
            tooltip:SetPlayerBuff(idx)
            b.buffName = TipLine(1)
            b.icon:SetTexture(GetPlayerBuffTexture(idx))
            if b.buffName and editBox and Norm(b.buffName) == Norm(editBox:GetText()) then
                SetBorder(b, C.accent)
            else
                SetBorder(b, C.border)
            end
            b:Show()
        end
    end
    for k = n + 1, table.getn(buffButtons) do buffButtons[k]:Hide() end
    if n == 0 then buffEmpty:Show() else buffEmpty:Hide() end
end

local function OpenEditor(index)
    local e = AshenConsumesDB.entries[index]
    if not e then return end
    editIndex = index
    editIcon.icon:SetTexture(e.icon or QUESTION)
    editName:SetText(e.item)
    editBox:SetText(e.buff or "")
    editFood:SetOn(e.food)
    ui.editWant = e.want or 1
    ui.wantText:SetText(ui.editWant)
    ForceScan()
    RefreshEditorBuffs()
    editor:ClearAllPoints()
    editor:SetPoint("TOPLEFT", main, "TOPRIGHT", 4, 0)
    editor:Show()
end

local function SaveEditor()
    local e = AshenConsumesDB.entries[editIndex]
    local buff = Trim(editBox:GetText())
    if e and buff ~= "" then
        e.buff = buff
        e.food = editFood.on
        e.want = ui.editWant or 1
        e.learned = true
        RebuildClashes()
        pending = nil
        ForceScan()
    end
    editBox:ClearFocus()
    editor:Hide()
    RefreshUI(GetTime())
end

---------------------------------------------------------------------------
-- Build UI
---------------------------------------------------------------------------
local W, H = 332, 364
local GY = -64 - MAX_ROWS * 26 - 6

local function BuildMainFrame()
    main = CreateFrame("Frame", "AshenConsumesConfigFrame", UIParent)
    main:SetWidth(W)
    main:SetHeight(H)
    main:SetFrameStrata("DIALOG")
    if main.SetToplevel then main:SetToplevel(true) end
    Flat(main, C.bg, C.border)
    MakeMovable(main, "mainPos")
    Place(main, AshenConsumesDB.mainPos, 0, 30)
    AcceptDrops(main)
    table.insert(UISpecialFrames, "AshenConsumesConfigFrame") -- Escape closes it

    local head = main:CreateTexture(nil, "BORDER")
    head:SetTexture(C.header[1], C.header[2], C.header[3], 1)
    head:SetPoint("TOPLEFT", main, "TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", main, "TOPRIGHT", -1, -1)
    head:SetHeight(26)
    Line(main, -27)
    local title = Text(main, 12, C.accent)
    title:SetPoint("TOPLEFT", main, "TOPLEFT", 10, -8)
    title:SetText("Ashen Consumes")
    local sub = Text(main, 9, C.dim)
    sub:SetPoint("LEFT", title, "RIGHT", 8, -1)
    sub:SetText("")
    FlatButton(main, "x", 16, 16, function() main:Hide() end, nil):SetPoint("TOPRIGHT", main, "TOPRIGHT", -6, -6)

    -- Tracked list
    local l1 = Text(main, 9, C.dim)
    l1:SetPoint("TOPLEFT", main, "TOPLEFT", 10, -36)
    l1:SetText("LINEUP")
    listInfo = Text(main, 9, C.dim)
    listInfo:SetPoint("LEFT", l1, "RIGHT", 8, 0)

    listFrame = CreateFrame("Frame", nil, main)
    listFrame:SetPoint("TOPLEFT", main, "TOPLEFT", 8, -64)
    listFrame:SetWidth(W - 16)
    listFrame:SetHeight(MAX_ROWS * 26)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function()
        local maxOff = math.max(0, table.getn(AshenConsumesDB.entries) - MAX_ROWS)
        scrollOffset = math.max(0, math.min(maxOff, scrollOffset - arg1))
        RefreshUI(GetTime())
    end)
    listEmpty = Text(listFrame, 10, C.dim)
    listEmpty:SetPoint("CENTER", listFrame, "CENTER", 0, 0)
    listEmpty:SetJustifyH("CENTER")
    listEmpty:SetText("Nothing tracked yet.\nClick a consumable below, or drag one onto this window.")

    rows = {}
    for r = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, listFrame)
        row:SetWidth(W - 16)
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -(r - 1) * 26)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture(C.row[1], C.row[2], C.row[3], C.row[4])
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(row)
        hl:SetTexture(C.accent[1], C.accent[2], C.accent[3], 0.10)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        row.check = FlatCheck(row, 12)
        row.check:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.check:SetScript("OnClick", function()
            local e = AshenConsumesDB.entries[row.index]
            if e then e.enabled = not e.enabled end
            pending = nil
            RefreshUI(GetTime())
        end)

        row.icon = IconButton(row, 20)
        row.icon:EnableMouse(false)
        row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)

        row.name = Text(row, 11, C.text)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 50, -2)
        row.name:SetWidth(132)
        row.name:SetHeight(12)
        row.buff = Text(row, 9, C.dim)
        row.buff:SetPoint("TOPLEFT", row, "TOPLEFT", 50, -14)
        row.buff:SetWidth(132)
        row.buff:SetHeight(10)
        row.time = Text(row, 10, C.good)
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -56, -2)
        row.time:SetWidth(76)
        row.time:SetJustifyH("RIGHT")
        row.stock = Text(row, 9, C.dim)
        row.stock:SetPoint("TOPRIGHT", row, "TOPRIGHT", -56, -14)
        row.stock:SetWidth(76)
        row.stock:SetJustifyH("RIGHT")

        row.del = FlatButton(row, "x", 14, 14, function()
            UntrackIndex(row.index)
            RefreshUI(GetTime())
        end, "Stop tracking")
        row.del:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        Color(row.del.text, C.bad)
        row.down = FlatButton(row, "-", 14, 14, function()
            local i, en = row.index, AshenConsumesDB.entries
            if i and i < table.getn(en) then en[i + 1], en[i] = en[i], en[i + 1]; pending = nil; RefreshUI(GetTime()) end
        end, "Lower priority")
        row.down:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.up = FlatButton(row, "+", 14, 14, function()
            local i, en = row.index, AshenConsumesDB.entries
            if i and i > 1 then en[i - 1], en[i] = en[i], en[i - 1]; pending = nil; RefreshUI(GetTime()) end
        end, "Higher priority")
        row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)

        row:SetScript("OnClick", function()
            if CursorHasItem() then HandleDrop(); return end
            OpenEditor(row.index)
        end)
        row:SetScript("OnEnter", function()
            local e = AshenConsumesDB.entries[row.index]
            if e then EntryTip(this, e, GetTime(), { "Click to edit (buff, how many to carry)" }) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rows[r] = row
    end

end

local function BuildBagSection()
    local gy = GY
    Line(main, gy)
    local l2 = Text(main, 9, C.dim)
    l2:SetPoint("TOPLEFT", main, "TOPLEFT", 10, gy - 8)
    l2:SetText("IN YOUR BAGS  -  click to add")
    filterButton = FlatButton(main, "", 96, 14, function()
        AshenConsumesDB.showAllBag = not AshenConsumesDB.showAllBag
        bagListDirty = true
        gridOffset = 0
        RefreshUI(GetTime())
    end, "Buffs only: consumables with a timed effect.\nAll usable: every item with a Use: effect.")
    filterButton:SetPoint("TOPRIGHT", main, "TOPRIGHT", -8, gy - 6)

    gridFrame = CreateFrame("Frame", nil, main)
    gridFrame:SetPoint("TOPLEFT", main, "TOPLEFT", 10, gy - 24)
    gridFrame:SetWidth(GRID_COLS * 31)
    gridFrame:SetHeight(GRID_ROWS * 31)
    gridFrame:EnableMouseWheel(true)
    gridFrame:SetScript("OnMouseWheel", function()
        local maxOff = math.max(0, math.ceil(table.getn(bagList) / GRID_COLS) - GRID_ROWS)
        gridOffset = math.max(0, math.min(maxOff, gridOffset - arg1))
        RefreshUI(GetTime())
    end)
    gridEmpty = Text(gridFrame, 10, C.dim)
    gridEmpty:SetPoint("CENTER", gridFrame, "CENTER", 0, 0)
    gridEmpty:SetJustifyH("CENTER")
    gridEmpty:SetText("No consumables in your bags.")
    gridButtons = {}
    for k = 1, GRID_COLS * GRID_ROWS do
        local b = IconButton(gridFrame, 28)
        local col = math.mod(k - 1, GRID_COLS)
        local rr = math.floor((k - 1) / GRID_COLS)
        b:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * 31, -rr * 31)
        b.check = b:CreateTexture(nil, "OVERLAY")
        b.check:SetTexture(CHECK)
        b.check:SetWidth(16)
        b.check:SetHeight(16)
        b.check:SetPoint("TOPRIGHT", b, "TOPRIGHT", 4, 4)
        b:SetScript("OnClick", function()
            if CursorHasItem() then HandleDrop(); return end
            local d = this.data
            if not d then return end
            local idx = FindEntry(d.name)
            if idx then
                UntrackIndex(idx)
            else
                TrackItem(d.name, d.tex, d.food)
                ForceScan()
            end
            RefreshUI(GetTime())
        end)
        b:SetScript("OnEnter", function()
            local d = this.data
            if not d then return end
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(d.bag, d.slot)
            if FindEntry(d.name) then
                GameTooltip:AddLine("In your lineup - click to remove", C.accent[1], C.accent[2], C.accent[3])
            elseif this.clash then
                GameTooltip:AddLine("Doesn't stack with " .. this.clash, C.bad[1], C.bad[2], C.bad[3], 1)
            else
                GameTooltip:AddLine("Click to add to your lineup", C.accent[1], C.accent[2], C.accent[3])
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        gridButtons[k] = b
    end
    local hint = Text(main, 9, C.dim)
    hint:SetPoint("TOPLEFT", gridFrame, "BOTTOMLEFT", 0, -5)
    hint:SetText("Alt + Right-click bag items to add - macro: /run AshenConsumes_UseNext()")

end

local function BuildFooter()
    Line(main, -(H - 30))
    local tl = Text(main, 10, C.dim)
    tl:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", 10, 10)
    tl:SetText("Refresh")
    local minus = FlatButton(main, "-", 16, 16, function()
        AshenConsumesDB.threshold = math.max(60, AshenConsumesDB.threshold - 60)
        RefreshUI(GetTime())
    end, nil)
    minus:SetPoint("LEFT", tl, "RIGHT", 6, 0)
    thresholdText = Text(main, 11, C.text)
    thresholdText:SetPoint("LEFT", minus, "RIGHT", 0, 0)
    thresholdText:SetWidth(30)
    thresholdText:SetJustifyH("CENTER")
    local plus = FlatButton(main, "+", 16, 16, function()
        AshenConsumesDB.threshold = math.min(1800, AshenConsumesDB.threshold + 60)
        RefreshUI(GetTime())
    end, nil)
    plus:SetPoint("LEFT", thresholdText, "RIGHT", 0, 0)
    local preset = FlatButton(main, "", 66, 18, function() CycleHUD() end,
        "HUD style:\nbar - every buff with its timer\nsingle - one square: next to use, what falls off next, or a green check\nhidden - macro only")
    preset:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -8, 7)
    ui.hudBtn = preset
    soundButton = FlatButton(main, "Sound on", 58, 18, function()
        AshenConsumesDB.sound = not AshenConsumesDB.sound
        RefreshUI(GetTime())
    end, "Play a raid-warning sound when something needs a refresh.")
    soundButton:SetPoint("RIGHT", preset, "LEFT", -4, 0)
    ui.flashBtn = FlatButton(main, "", 66, 18, function()
        local m = AshenConsumesDB.flashMode or "raid"
        if m == "raid" then m = "always" elseif m == "always" then m = "off" else m = "raid" end
        AshenConsumesDB.flashMode = m
        RefreshUI(GetTime())
    end, "Pulsing borders and centre-screen warnings.\nraid - only while you're in a raid\nalways - everywhere\noff - never (colours still change)")
    ui.flashBtn:SetPoint("RIGHT", soundButton, "LEFT", -4, 0)
    main:SetScript("OnHide", function() if editor then editor:Hide() end end)
    main:Hide()

end

local function BuildEditor()
    editor = CreateFrame("Frame", "AshenConsumesEditor", UIParent)
    editor:SetWidth(218)
    editor:SetHeight(248)
    editor:SetFrameStrata("DIALOG")
    editor:EnableMouse(true)
    Flat(editor, C.bg, C.border)
    editIcon = IconButton(editor, 24)
    editIcon:EnableMouse(false)
    editIcon:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -8)
    editName = Text(editor, 11, C.text)
    editName:SetPoint("LEFT", editIcon, "RIGHT", 6, 0)
    editName:SetWidth(170)
    local el = Text(editor, 9, C.dim)
    el:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -40)
    el:SetText("BUFF IT GIVES")
    editBox = CreateFrame("EditBox", nil, editor)
    editBox:SetWidth(202)
    editBox:SetHeight(20)
    editBox:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -52)
    Flat(editBox, {0, 0, 0, 0.6}, C.border)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetTextInsets(6, 6, 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(80)
    editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    editBox:SetScript("OnEnterPressed", function() SaveEditor() end)
    editBox:SetScript("OnEditFocusGained", function() SetBorder(this, C.accent) end)
    editBox:SetScript("OnEditFocusLost", function() SetBorder(this, C.border) end)
    editFood = FlatCheck(editor, 12)
    editFood:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -80)
    editFood:SetScript("OnClick", function() this:SetOn(not this.on) end)
    local fl = Text(editor, 10, C.text)
    fl:SetPoint("LEFT", editFood, "RIGHT", 6, 0)
    fl:SetText("Food (pause while eating)")
    local bl = Text(editor, 9, C.dim)
    bl:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -124)
    bl:SetText("OR CLICK ONE OF YOUR CURRENT BUFFS")
    buffButtons = {}
    for k = 1, 24 do
        local b = IconButton(editor, 22)
        local col = math.mod(k - 1, 8)
        local rr = math.floor((k - 1) / 8)
        b:SetPoint("TOPLEFT", editor, "TOPLEFT", 8 + col * 25, -138 - rr * 25)
        b:SetScript("OnClick", function()
            if this.buffName then
                editBox:SetText(this.buffName)
                RefreshEditorBuffs()
            end
        end)
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetPlayerBuff(this.buffIndex)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:Hide()
        buffButtons[k] = b
    end
    buffEmpty = Text(editor, 10, C.dim)
    buffEmpty:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -144)
    buffEmpty:SetText("You have no buffs right now.")
    FlatButton(editor, "Save", 60, 18, function() SaveEditor() end, nil):SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -8, 8)
    FlatButton(editor, "Cancel", 60, 18, function() editBox:ClearFocus(); editor:Hide() end, nil):SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -72, 8)
    editor:Hide()

end

local function BuildHUD()
    hud = CreateFrame("Frame", "AshenConsumesHUD", UIParent)
    hud:SetWidth(186)
    hud:SetHeight(62)
    hud:SetFrameStrata("MEDIUM")
    Flat(hud, C.bg, C.border)
    MakeMovable(hud, "hudPos", true)
    Place(hud, AshenConsumesDB.hudPos, 330, -140)
    AcceptDrops(hud)
    hud:SetScript("OnMouseUp", function()
        if CursorHasItem() then HandleDrop() elseif arg1 == "RightButton" then ToggleMain() end
    end)
    hud.icons = {}
    hud.next = IconButton(hud, 34)
    hud.next:SetPoint("TOPLEFT", hud, "TOPLEFT", 6, -6)
    hud.next:SetScript("OnClick", function()
        if CursorHasItem() then HandleDrop(); return end
        if arg1 == "RightButton" then ToggleMain() else AshenConsumes_UseNext() end
    end)
    hud.next:SetScript("OnEnter", function() LineupTip(this) end)
    MakeMovable(hud.next, "hudPos", true, hud)
    hud.nextTimer = Text(hud.next, 10, C.text, "OUTLINE")
    hud.nextTimer:SetPoint("BOTTOM", hud.next, "BOTTOM", 0, 2)
    hud.nextTimer:SetJustifyH("CENTER")
    hud.okMark = hud.next:CreateTexture(nil, "OVERLAY")
    hud.okMark:SetTexture(CHECK)
    hud.okMark:SetWidth(16)
    hud.okMark:SetHeight(16)
    hud.okMark:SetPoint("TOPRIGHT", hud.next, "TOPRIGHT", 5, 5)
    hud.okMark:SetVertexColor(C.good[1], C.good[2], C.good[3])
    hud.okMark:Hide()
    hud.next:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local sep = hud:CreateTexture(nil, "ARTWORK")
    sep:SetTexture(C.border[1], C.border[2], C.border[3], 1)
    sep:SetWidth(1)
    sep:SetPoint("TOPLEFT", hud, "TOPLEFT", 43, -6)
    sep:SetPoint("BOTTOMLEFT", hud, "TOPLEFT", 43, -40)
    hud.sep = sep
    hud.status = Text(hud, 9, C.dim)
    hud.status:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 7, 6)
    hud.status:SetPoint("RIGHT", hud, "RIGHT", -22, 0)
    hud.status:SetHeight(10)
    local gear = CreateFrame("Button", nil, hud)
    gear:SetWidth(13)
    gear:SetHeight(13)
    gear:SetPoint("BOTTOMRIGHT", hud, "BOTTOMRIGHT", -5, 4)
    local gt = gear:CreateTexture(nil, "ARTWORK")
    gt:SetAllPoints(gear)
    gt:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    gt:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    gt:SetVertexColor(0.7, 0.7, 0.7)
    gear:SetScript("OnClick", ToggleMain)
    hud.gear = gear
    gear:SetScript("OnEnter", function() gt:SetVertexColor(1, 1, 1); Tip(this, "Settings") end)
    gear:SetScript("OnLeave", function() gt:SetVertexColor(0.7, 0.7, 0.7); GameTooltip:Hide() end)

    if AshenConsumesDB.showHUD == false then hud:Hide() end
end

CycleHUD = function()
    local db = AshenConsumesDB
    if not db.showHUD then
        db.showHUD = true; db.hudMode = "bar"
    elseif (db.hudMode or "bar") == "bar" then
        db.hudMode = "single"
    else
        db.showHUD = false
    end
    if db.showHUD then hud:Show() else hud:Hide() end
    hudShown = ""
    RefreshUI(GetTime())
end

local function BuildExtras()
    -- Header: preset button
    local preset = FlatButton(main, "Preset", 50, 16, function() AddWarriorPreset() end,
        "Adds Flask of the Titans, Mongoose, Juju Power, Juju Might,\nRumsey, Gift of Arthas and dumplings (skips anything that clashes).")
    preset:SetPoint("TOPRIGHT", main, "TOPRIGHT", -26, -6)
    ui.lockBtn = FlatButton(main, "", 58, 16, function()
        AshenConsumesDB.locked = not AshenConsumesDB.locked
        Say(AshenConsumesDB.locked and "HUD and food box locked." or "HUD and food box unlocked - drag them anywhere.")
        RefreshUI(GetTime())
    end, "Lock the HUD and food box in place.")
    ui.lockBtn:SetPoint("RIGHT", preset, "LEFT", -4, 0)
    ui.foodBtn = FlatButton(main, "", 76, 16, function()
        AshenConsumesDB.showFood = not AshenConsumesDB.showFood
        RefreshUI(GetTime())
    end, "A separate square that only tracks Well Fed.")
    ui.foodBtn:SetPoint("RIGHT", ui.lockBtn, "LEFT", -4, 0)

    -- Lineup: sort button + missing banner
    ui.sortBtn = FlatButton(main, "", 112, 14, function()
        local cur = AshenConsumesDB.sortMode or "priority"
        local nextMode = SORTS[1]
        for i = 1, table.getn(SORTS) do
            if SORTS[i] == cur then nextMode = SORTS[math.mod(i, table.getn(SORTS)) + 1] end
        end
        AshenConsumesDB.sortMode = nextMode
        scrollOffset = 0
        RefreshUI(GetTime())
    end, "Change how the lineup is listed.\nThe use order is always the priority order (+ / -).")
    ui.sortBtn:SetPoint("TOPRIGHT", main, "TOPRIGHT", -8, -34)
    ui.missing = Text(main, 9, C.bad)
    ui.missing:SetPoint("TOPLEFT", main, "TOPLEFT", 10, -50)
    ui.missing:SetWidth(W - 20)
    ui.missing:SetHeight(11)

    -- Editor: how many to keep in bags
    local wl = Text(editor, 10, C.text)
    wl:SetPoint("TOPLEFT", editor, "TOPLEFT", 8, -102)
    wl:SetText("Keep in bags")
    ui.wantMinus = FlatButton(editor, "-", 16, 16, function()
        ui.editWant = math.max(0, (ui.editWant or 1) - 1)
        ui.wantText:SetText(ui.editWant)
    end, nil)
    ui.wantMinus:SetPoint("LEFT", wl, "RIGHT", 8, 0)
    ui.wantText = Text(editor, 11, C.text)
    ui.wantText:SetPoint("LEFT", ui.wantMinus, "RIGHT", 0, 0)
    ui.wantText:SetWidth(28)
    ui.wantText:SetJustifyH("CENTER")
    ui.wantPlus = FlatButton(editor, "+", 16, 16, function()
        ui.editWant = math.min(99, (ui.editWant or 1) + 1)
        ui.wantText:SetText(ui.editWant)
    end, nil)
    ui.wantPlus:SetPoint("LEFT", ui.wantText, "RIGHT", 0, 0)
    local wh = Text(editor, 9, C.dim)
    wh:SetPoint("LEFT", ui.wantPlus, "RIGHT", 6, 0)
    wh:SetText("(0 = don't check)")
end

local function BuildFood()
    local f = CreateFrame("Frame", "AshenConsumesFoodBox", UIParent)
    f:SetWidth(42)
    f:SetHeight(42)
    f:SetFrameStrata("MEDIUM")
    Flat(f, C.bg, C.border)
    MakeMovable(f, "foodPos", true)
    local hp = AshenConsumesDB.hudPos
    Place(f, AshenConsumesDB.foodPos, (hp and hp.x or 330), (hp and hp.y or -140) + 52)
    local b = IconButton(f, 32)
    b:SetPoint("CENTER", f, "CENTER", 0, 0)
    MakeMovable(b, "foodPos", true, f)
    b:SetScript("OnClick", function()
        if arg1 == "RightButton" then ToggleMain(); return end
        local fe = FoodEntry()
        if fe then UseSpecific(fe) else Say("Add a food to your lineup first (/ac).") end
    end)
    b:SetScript("OnEnter", function() FoodTip(this) end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.btn = b
    f.timer = Text(b, 10, C.text, "OUTLINE")
    f.timer:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
    f.timer:SetJustifyH("CENTER")
    ui.food = f
end

local function InitUI()
    BuildMainFrame()
    BuildBagSection()
    BuildFooter()
    BuildEditor()
    BuildHUD()
    BuildExtras()
    BuildFood()
end

---------------------------------------------------------------------------
-- Saved data, slash commands, events
---------------------------------------------------------------------------
local function LoadDB()
    if type(AshenConsumesDB) ~= "table" then AshenConsumesDB = {} end
    if type(AshenConsumesDB.entries) ~= "table" then AshenConsumesDB.entries = {} end
    if AshenConsumesDB.threshold == nil then AshenConsumesDB.threshold = 300 end
    if AshenConsumesDB.sound == nil then AshenConsumesDB.sound = true end
    if AshenConsumesDB.showHUD == nil then AshenConsumesDB.showHUD = true end
    if AshenConsumesDB.hudMode == nil then AshenConsumesDB.hudMode = "bar" end
    if AshenConsumesDB.sortMode == nil then AshenConsumesDB.sortMode = "priority" end
    if type(AshenConsumesDB.conflicts) ~= "table" then AshenConsumesDB.conflicts = {} end
    if AshenConsumesDB.showFood == nil then AshenConsumesDB.showFood = true end
    if AshenConsumesDB.flashMode == nil then AshenConsumesDB.flashMode = "raid" end
    for i = 1, table.getn(AshenConsumesDB.entries) do
        local e = AshenConsumesDB.entries[i]
        if e.enabled == nil then e.enabled = true end
        if not e.item then e.item = "" end
        if not e.buff then e.buff = e.item end
        if e.learned == nil then
            e.learned = (KNOWN[Norm(e.item)] ~= nil) or e.food or (Norm(e.buff) ~= Norm(e.item))
        end
        if e.want == nil then e.want = 1 end
        -- Repair: an item wrongly learned another consumable's buff (e.g. Blackroot Brew -> Winterfall Firewater).
        local nb = Norm(e.buff)
        if not e.food and nb ~= Norm(e.item) and KNOWN[nb] and not KNOWN[Norm(e.item)] then
            e.buff = e.item
            e.learned = false
        end
    end
    RebuildClashes()
end

local function ListBuffs()
    ForceScan()
    Say("Your current buffs:")
    local count = 0
    for _, v in pairs(snapshot) do
        count = count + 1
        Say("  " .. v.name .. " - " .. FormatDuration(v.left))
    end
    if count == 0 then Say("No readable buffs found.") end
end

local function Help()
    Say("/ac - settings | /ac use - use one item | /ac buffs - list your buffs")
    Say("/ac add ITEM ; BUFF | /ac remove N | /ac list | /ac preset | /ac threshold SECONDS | /ac sound | /ac hud | /ac food | /ac lock")
    Say("Alt + Right-click a bag item to track it. Macro: /run AshenConsumes_UseNext()")
end

SLASH_ASHENCONSUMES1 = "/ac"
SLASH_ASHENCONSUMES2 = "/ashenconsumes"
SlashCmdList["ASHENCONSUMES"] = function(msg)
    if not initialized then Say("Not initialized yet."); return end
    msg = Trim(msg)
    if msg == "" or msg == "config" or msg == "options" then ToggleMain(); return end
    local _, _, cmd, rest = string.find(msg, "^(%S+)%s*(.*)$")
    cmd = Norm(cmd)
    rest = Trim(rest)
    if cmd == "use" then AshenConsumes_UseNext()
    elseif cmd == "buffs" then ListBuffs()
    elseif cmd == "preset" then AddWarriorPreset()
    elseif cmd == "list" then
        for i = 1, table.getn(AshenConsumesDB.entries) do
            local e = AshenConsumesDB.entries[i]
            Say(i .. ". " .. e.item .. " -> " .. e.buff .. (e.enabled and "" or " [OFF]"))
        end
    elseif cmd == "add" then
        local sep = string.find(rest, ";", 1, true)
        local item = StripLink(sep and string.sub(rest, 1, sep - 1) or rest)
        if item == "" then Say("Usage: /ac add Item Name [; Buff Name]"); return end
        if TrackItem(item, nil, false) and sep then
            local e = AshenConsumesDB.entries[table.getn(AshenConsumesDB.entries)]
            local buff = Trim(string.sub(rest, sep + 1))
            if buff ~= "" then e.buff = buff; e.learned = true end
        end
        ForceScan()
        RefreshUI(GetTime())
    elseif cmd == "remove" then
        local n = tonumber(rest)
        if n and n >= 1 and n <= table.getn(AshenConsumesDB.entries) then
            UntrackIndex(n)
            RefreshUI(GetTime())
        else Say("Invalid item number. Try /ac list") end
    elseif cmd == "threshold" then
        local secs = tonumber(rest)
        if secs and secs >= 0 and secs <= 3600 then
            AshenConsumesDB.threshold = math.floor(secs)
            Say("Refreshing when " .. secs .. " seconds or less remain.")
            RefreshUI(GetTime())
        else Say("Threshold must be 0 to 3600 seconds (300 = five minutes).") end
    elseif cmd == "sound" then
        AshenConsumesDB.sound = not AshenConsumesDB.sound
        Say("Warning sound " .. (AshenConsumesDB.sound and "ON" or "OFF"))
        RefreshUI(GetTime())
    elseif cmd == "flash" then
        local m = Norm(rest)
        if m ~= "raid" and m ~= "always" and m ~= "off" then Say("Usage: /ac flash raid | always | off"); return end
        AshenConsumesDB.flashMode = m
        Say("Flashing: " .. m)
        RefreshUI(GetTime())
    elseif cmd == "lock" then
        AshenConsumesDB.locked = not AshenConsumesDB.locked
        Say(AshenConsumesDB.locked and "Locked." or "Unlocked.")
        RefreshUI(GetTime())
    elseif cmd == "food" then
        AshenConsumesDB.showFood = not AshenConsumesDB.showFood
        RefreshUI(GetTime())
    elseif cmd == "hud" then
        AshenConsumesDB.showHUD = not AshenConsumesDB.showHUD
        if AshenConsumesDB.showHUD then hud:Show(); hudShown = ""; RefreshUI(GetTime()) else hud:Hide() end
    else Help() end
end

local function AfterAuraChange(now)
    ForceScan()
    CheckLearn(now)
    CheckWatch(now)
    if pending and CheckBuff({ buff = pending.buff }, now) and
        CheckBuff({ buff = pending.buff }, now) > AshenConsumesDB.threshold then
        pending = nil
    end
end

local eventFrame = CreateFrame("Frame", "AshenConsumesCoreFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        if not initialized then
            LoadDB()
            InitUI()
            initialized = true
            ForceScan()
            initAlertAt = GetTime() + 6
            ui.stockNoticeAt = GetTime() + 8
            RefreshUI(GetTime())
            Say("Loaded. /ac for settings, Alt + Right-click bag items to track them.")
        end
    elseif initialized and (event == "PLAYER_AURAS_CHANGED" or event == "PLAYER_ENTERING_WORLD" or
        (event == "UNIT_AURA" and arg1 == "player")) then
        AfterAuraChange(GetTime())
        if editor:IsVisible() then RefreshEditorBuffs() end
        RefreshUI(GetTime())
    elseif initialized and event == "BAG_UPDATE" then
        bagDirty = true
        bagListDirty = true
        RefreshUI(GetTime())
    end
end)

local onUpdateElapsed, displayElapsed = 0, 0
eventFrame:SetScript("OnUpdate", function()
    if not initialized then return end
    local dt = arg1 or 0
    onUpdateElapsed = onUpdateElapsed + dt
    displayElapsed = displayElapsed + dt
    local now = GetTime()
    if onUpdateElapsed >= REFRESH_EVERY then
        onUpdateElapsed = 0
        AfterAuraChange(now)
        UpdateNotices(now)
    elseif learn and now > learn.untilTime then
        CheckLearn(now)
    end
    if ui.stockNoticeAt and now >= ui.stockNoticeAt then
        ui.stockNoticeAt = nil
        local miss = MissingList()
        if table.getn(miss) > 0 then
            local names = {}
            for i = 1, table.getn(miss) do table.insert(names, miss[i].item) end
            Say("|cffff6666Missing from your bags:|r " .. table.concat(names, ", "))
        end
        -- Warn about clashes left over from older versions.
        local entries = AshenConsumesDB.entries
        for i = 1, table.getn(entries) do
            local c = clashOf[entries[i]]
            if c and i < table.getn(entries) then
                for j = 1, table.getn(c) do
                    if FindEntry(c[j].item) > i then
                        Say(entries[i].item .. " and " .. c[j].item .. " don't stack. Only the one higher in your lineup will be used; remove the other.")
                    end
                end
            end
        end
    end
    if displayElapsed >= DISPLAY_EVERY then
        displayElapsed = 0
        RefreshUI(now)
    end
end)
