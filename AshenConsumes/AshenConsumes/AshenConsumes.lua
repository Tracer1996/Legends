-- Ashen Consumes 1.0.0
-- WoW 1.12 / Lua 5.0 only. No Ace, no ClassicAPI required.
-- A user click / macro press can attempt AT MOST one bag item.

local A = {}
local STATUS_OK = "OK"
local STATUS_READY = "READY"
local STATUS_OUT = "OUT"
local STATUS_CD = "COOLDOWN"
local STATUS_DISABLED = "OFF"
local STATUS_UNCONFIGURED = "SET BUFF"
local REFRESH_EVERY = 5.0
local DISPLAY_EVERY = 0.20
local MAX_ROWS = 6
local main, hud, useButton, hudText, rows, editor, editItem, editBuff, editFood, editTitle
local statusLine, soundButton, warningText
local scrollOffset = 0
local editIndex = nil
local initialized = false
local nextSnapshot = 0
local snapshot = {}
local bagCache = {}
local bagDirty = true
local nextBagSweep = 0
local pending = nil
local recentUse = {}  -- prevents burning duplicates if a realm sends a late/unknown aura
local previousReady = {}
local previousAlertAt = 0
local lastNoActionAt = 0
local initAlertAt = nil

local function Trim(s)
    if not s then return "" end
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

local function Norm(s)
    return string.lower(Trim(s or ""))
end

local function StripLink(s)
    s = Trim(s)
    local _, _, captured = string.find(s, "%[([^%]]+)%]")
    if captured then return Trim(captured) end
    return s
end

local function Say(s)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffc995ef[Ashen Consumes]|r " .. s)
    end
end

local function FormatDuration(seconds)
    if seconds == nil then return "MISSING" end
    if seconds >= 100000 then return "ACTIVE" end
    if seconds < 0 then seconds = 0 end
    local n = math.floor(seconds + 0.5)
    if n >= 3600 then return string.format("%dh %02dm", math.floor(n / 3600), math.floor(math.mod(n, 3600) / 60)) end
    return string.format("%d:%02d", math.floor(n / 60), math.mod(n, 60))
end

local function Backdrop(f, alpha)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    f:SetBackdropColor(0.075, 0.063, 0.10, alpha or 0.96)
    f:SetBackdropBorderColor(0.53, 0.34, 0.69, 0.9)
end

local function Font(parent, style, text, point, relative, relativePoint, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", style or "GameFontNormal")
    fs:SetPoint(point or "TOPLEFT", relative or parent, relativePoint or point or "TOPLEFT", x or 0, y or 0)
    fs:SetText(text or "")
    return fs
end

local function MakeButton(parent, text, width, height, point, rel, relpoint, x, y, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetWidth(width)
    b:SetHeight(height)
    b:SetPoint(point, rel, relpoint, x, y)
    b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end

local function RepositionSaved(frame, saved, xDefault, yDefault)
    frame:ClearAllPoints()
    local xx = (saved and saved.x) or xDefault
    local yy = (saved and saved.y) or yDefault
    frame:SetPoint("CENTER", UIParent, "CENTER", xx, yy)
end

local function SavePosition(frame, key)
    local cx, cy = frame:GetCenter()
    local px, py = UIParent:GetCenter()
    if cx and cy and px and py then
        AshenConsumesDB[key] = { x = cx-px, y = cy-py }
    end
end

local function ItemNameFromLink(link)
    if not link then return nil end
    local _, _, name = string.find(link, "%[([^%]]+)%]")
    return name
end

local function RefreshBags()
    local now = GetTime()
    if not bagDirty and now < nextBagSweep then return end
    bagDirty = false
    nextBagSweep = now + 5
    local items = {}
    for bag = 0, 4 do
        local count = GetContainerNumSlots(bag) or 0
        for slot = 1, count do
            local link = GetContainerItemLink(bag, slot)
            local name = ItemNameFromLink(link)
            if name then
                local key = Norm(name)
                if not items[key] then
                    local tex, stack = GetContainerItemInfo(bag, slot)
                    items[key] = {bag,slot,tex,stack or 1}
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

local tooltip = CreateFrame("GameTooltip", "AshenConsumesHiddenTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
tooltip:Hide()

-- Native 1.12 GetPlayerBuff and SetPlayerBuff use the same HELPFUL filter.
local function ScanBuffs()
    local found = {}
    for i = 0, 31 do
        local buffIndex, untilCancelled = GetPlayerBuff(i, "HELPFUL")
        if buffIndex and buffIndex >= 0 then
            local timeleft = GetPlayerBuffTimeLeft(buffIndex) or 0
            local texture = GetPlayerBuffTexture(buffIndex)
            tooltip:ClearLines()
            tooltip:SetPlayerBuff(buffIndex)
            local titleLine = getglobal("AshenConsumesHiddenTooltipTextLeft1")
            local name = titleLine and titleLine:GetText()
            if name and name ~= "" then
                local key = Norm(name)
                local remains = timeleft
                if untilCancelled == 1 then remains = 999999 end
                -- Prefer the longest remaining buff when names are duplicated.
                if not found[key] or remains > found[key].left then
                    found[key] = {left = remains, texture = texture, name = name}
                end
            end
        end
    end
    snapshot = found
    nextSnapshot = GetTime() + REFRESH_EVERY
end

local function CheckBuff(entry, now)
    local b = snapshot[Norm(entry.buff)]
    if not b then return nil end
    if b.left >= 100000 then return b.left end
    local elapsed = now - (A.scanTime or now)
    local left = b.left - elapsed
    if left < 0 then left = 0 end
    return left
end

local function ForceScan()
    ScanBuffs()
    A.scanTime = GetTime()
end

local function Status(entry, now)
    if not entry.enabled then return STATUS_DISABLED, nil end
    if Trim(entry.buff) == "" then return STATUS_UNCONFIGURED, nil end
    local left = CheckBuff(entry, now)
    if left and left > AshenConsumesDB.threshold then
        return STATUS_OK, left
    end
    local bag, slot, icon, stack, cd, cdEnabled = FindBagItem(entry.item)
    if not bag then return STATUS_OUT, left end
    if (recentUse[entry] and now < recentUse[entry]) or (cd and cd > 0.05) or cdEnabled == 0 then
        return STATUS_CD, left, {bag,slot,icon,stack,cd}
    end
    return STATUS_READY, left, {bag,slot,icon,stack,0}
end

local function IsEligible(entry, now)
    if not entry.enabled or Trim(entry.item) == "" or Trim(entry.buff) == "" then return false end
    local left = CheckBuff(entry, now)
    return left == nil or left <= AshenConsumesDB.threshold
end

local function ReadyCount(now)
    local total = 0
    local runnable = 0
    local first = nil
    local firstIndex = nil
    local low = 0
    for i = 1, table.getn(AshenConsumesDB.entries) do
        local e = AshenConsumesDB.entries[i]
        if IsEligible(e, now) then
            total = total + 1
            local st = Status(e, now)
            if st == STATUS_READY then
                runnable = runnable + 1
                if not first then first, firstIndex = e, i end
            end
            if st == STATUS_OUT then low = low + 1 end
        end
    end
    return total, runnable, first, firstIndex, low
end

local function Alert(message)
    local now = GetTime()
    if now - previousAlertAt < 8 then return end
    previousAlertAt = now
    if AshenConsumesDB.sound then PlaySoundFile("Sound\\Interface\\RaidWarning.wav") end
    if RaidWarningFrame and RaidNotice_AddMessage and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, "Consumes: " .. message, ChatTypeInfo["RAID_WARNING"])
    end
    Say(message)
end

local function UpdateNotices(now)
    local newReady = false
    local firstName = nil
    local neededCount = 0
    for i = 1, table.getn(AshenConsumesDB.entries) do
        local e = AshenConsumesDB.entries[i]
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
            Alert(neededCount .. " consumable(s) missing or below your refresh threshold. Press consume key.")
        end
    elseif newReady and firstName then
        Alert(firstName .. " is missing or needs refresh.")
    end
end

local function RefreshUI(now)
    if not initialized then return end
    local total, runnable, first, _, out = ReadyCount(now)
    local label
    if pending and now < pending.untilTime then
        label = "APPLYING: " .. pending.item
        useButton:SetText("WAIT...")
    elseif first then
        label = first.item .. " - press to use"
        useButton:SetText("USE NEXT CONSUME")
    elseif total == 0 then
        label = "All tracked buffs healthy"
        useButton:SetText("ALL SET")
    elseif out > 0 then
        label = "Need " .. total .. " / missing " .. out .. " from bags"
        useButton:SetText("NO READY ITEM")
    else
        label = "Need " .. total .. " / items on cooldown"
        useButton:SetText("WAIT FOR COOLDOWN")
    end
    hudText:SetText(label)
    if total > 0 then
        hudText:SetTextColor(1, 0.76, 0.38)
    else
        hudText:SetTextColor(0.44, 0.94, 0.56)
    end
    if main:IsVisible() then
        local entries = AshenConsumesDB.entries
        for rowNum = 1, MAX_ROWS do
            local row = rows[rowNum]
            local i = scrollOffset + rowNum
            local entry = entries[i]
            if entry then
                row:Show()
                row.index = i
                local st, left, bagData = Status(entry, now)
                row.item:SetText(entry.item)
                row.aura:SetText(entry.buff)
                row.check:SetChecked(entry.enabled)
                row.icon:SetTexture((bagData and bagData[3]) or (snapshot[Norm(entry.buff)] and snapshot[Norm(entry.buff)].texture) or "Interface\\Icons\\INV_Potion_51")
                if not entry.enabled then
                    row.time:SetText("OFF")
                    row.time:SetTextColor(.55,.55,.55)
                elseif st == STATUS_UNCONFIGURED then
                    row.time:SetText("SET BUFF")
                    row.time:SetTextColor(1,.3,.3)
                elseif st == STATUS_OK then
                    row.time:SetText(FormatDuration(left))
                    row.time:SetTextColor(.35,1,.4)
                elseif st == STATUS_CD then
                    row.time:SetText((left and FormatDuration(left) or "MISSING") .. " CD")
                    row.time:SetTextColor(.97,.8,.35)
                elseif st == STATUS_OUT then
                    row.time:SetText((left and FormatDuration(left) or "MISSING") .. " OUT")
                    row.time:SetTextColor(1,.43,.42)
                else
                    row.time:SetText(left and FormatDuration(left) or "MISSING")
                    row.time:SetTextColor(1,.74,.25)
                end
                row.timeLabel:SetText(entry.food and "FOOD" or st)
            else
                row:Hide()
            end
        end
        statusLine:SetText(string.format("%d item(s) need a refresh  |  %d ready to use  |  %d not in bags", total, runnable, out))
        soundButton:SetText(AshenConsumesDB.sound and "Sound: ON" or "Sound: OFF")
        warningText:SetText("Refresh at " .. math.floor(AshenConsumesDB.threshold / 60) .. "m or less | High-priority items first")
    end
end

-- Called by mouse button OR a spammable macro. Never called from OnUpdate.
function AshenConsumes_UseNext()
    if not initialized then return end
    local now = GetTime()
    if pending and now < pending.untilTime then return end
    pending = nil
    -- A scan on a press prevents stale data from burning an already refreshed item.
    -- The guard above prevents repeatedly scanning/casting during a food buff cast.
    if now >= nextSnapshot then ForceScan() end
    for i = 1, table.getn(AshenConsumesDB.entries) do
        local entry = AshenConsumesDB.entries[i]
        if IsEligible(entry, now) then
            local st, left, bagData = Status(entry, now)
            if st == STATUS_READY and bagData then
                local bag, slot = bagData[1], bagData[2]
                local name = entry.item
                -- Set pending BEFORE consuming in case aura events fire during use.
                -- Food buff is often applied only after 10sec uninterrupted eating.
                pending = {item=name, buff=entry.buff, untilTime=now+(entry.food and 12 or 1.3)}
                recentUse[entry] = now + (entry.food and 15 or 10)
                UseContainerItem(bag, slot)
                if SpellIsTargeting and SpellIsTargeting() then
                    SpellTargetUnit("player")
                end
                Say("Using " .. name .. ".")
                RefreshUI(GetTime())
                return
            end
        end
    end
    if now - lastNoActionAt > 3 then
        lastNoActionAt = now
        local total = ReadyCount(now)
        if total == 0 then Say("All configured buffs have more than " .. math.floor(AshenConsumesDB.threshold / 60) .. "m remaining.")
        else Say("Nothing usable right now. Check bags, cooldowns, and configuration.") end
    end
    RefreshUI(now)
end

local function AddEntry(item, buff, food)
    item = StripLink(item)
    buff = Trim(buff)
    if item == "" or buff == "" then
        Say("Item name and its ACTUAL buff name are both required.")
        return false
    end
    table.insert(AshenConsumesDB.entries, { item = item, buff = buff, enabled = true, food = food and true or false })
    pending = nil
    scrollOffset = math.max(0, table.getn(AshenConsumesDB.entries)-MAX_ROWS)
    return true
end

local function AddWarriorPreset()
    local presets = {
        {"Flask of the Titans", "Flask of the Titans"},
        {"Elixir of the Mongoose", "Elixir of the Mongoose"},
        {"Juju Power", "Juju Power"},
        {"Juju Might", "Juju Might"},
        {"Winterfall Firewater", "Winterfall Firewater"},
        {"Rumsey Rum Black Label", "Rumsey Rum Black Label"},
        {"Gift of Arthas", "Gift of Arthas"},
        {"Smoked Desert Dumplings", "Well Fed", true}
    }
    local added = 0
    for i = 1, table.getn(presets) do
        local p = presets[i]
        local exists = false
        for j = 1, table.getn(AshenConsumesDB.entries) do
            if Norm(AshenConsumesDB.entries[j].item) == Norm(p[1]) then exists = true end
        end
        if not exists then
            table.insert(AshenConsumesDB.entries, {item=p[1], buff=p[2], food=p[3] or false, enabled=true})
            added = added + 1
        end
    end
    scrollOffset = 0
    Say("Added " .. added .. " warrior preset item(s). Disable, edit or remove items you do not use.")
    Say("Food uses the generic 'Well Fed' aura; different foods sharing it cannot be distinguished without additional rules.")
    pending = nil
    ForceScan()
    RefreshUI(GetTime())
end

local function MakeEditField(parent, x, y, label)
    local f = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    f:SetWidth(352)
    f:SetHeight(28)
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetAutoFocus(false)
    f:SetMaxLetters(160)
    f:SetScript("OnEscapePressed", function() f:ClearFocus() end)
    f:SetScript("OnEnterPressed", function() f:ClearFocus() end)
    local lbl = Font(parent, "GameFontNormalSmall", label, "BOTTOMLEFT", f, x == 0 and "TOPLEFT" or "TOPLEFT", 0, 3)
    lbl:SetTextColor(.8,.67,1)
    return f
end

local function OpenEditor(index)
    editIndex = index
    local current = index and AshenConsumesDB.entries[index] or nil
    editTitle:SetText(current and "EDIT CONSUMABLE" or "ADD CONSUMABLE")
    editItem:SetText(current and current.item or "")
    editBuff:SetText(current and current.buff or "")
    editFood:SetChecked(current and current.food or false)
    editor:Show()
    editItem:SetFocus()
    editItem:HighlightText()
end

local function InitUI()
    main = CreateFrame("Frame", "AshenConsumesConfigFrame", UIParent)
    main:SetWidth(570)
    main:SetHeight(452)
    Backdrop(main, .97)
    main:SetMovable(true)
    main:EnableMouse(true)
    main:RegisterForDrag("LeftButton")
    main:SetScript("OnDragStart", function() main:StartMoving() end)
    main:SetScript("OnDragStop", function() main:StopMovingOrSizing(); SavePosition(main, "mainPos") end)
    RepositionSaved(main, AshenConsumesDB.mainPos, 0, 30)
    main:SetFrameStrata("DIALOG")
    Font(main,"GameFontNormalLarge","ASHEN CONSUMES","TOPLEFT",main, "TOPLEFT", 20, -14)
    Font(main,"GameFontHighlightSmall","One key press = at most one item. Edit item/buff mappings below.","TOPLEFT",main, "TOPLEFT",20,-40)
    MakeButton(main,"X",27,23,"TOPRIGHT",main,"TOPRIGHT",-12,-11,function() main:Hide() end)
    MakeButton(main,"Add",68,23,"TOPLEFT",main,"TOPLEFT",20,-64,function() OpenEditor(nil) end)
    MakeButton(main,"Warrior Preset",123,23,"TOPLEFT",main,"TOPLEFT",96,-64,function() AddWarriorPreset() end)
    soundButton = MakeButton(main,"Sound: ON",112,23,"TOPRIGHT",main,"TOPRIGHT",-15,-64,function()
        AshenConsumesDB.sound = not AshenConsumesDB.sound
        RefreshUI(GetTime())
    end)
    Font(main,"GameFontNormalSmall","ON | ITEM / BUFF","TOPLEFT",main,"TOPLEFT",20,-97)
    Font(main,"GameFontNormalSmall","DURATION","TOPLEFT",main,"TOPLEFT",344,-97)
    Font(main,"GameFontNormalSmall","SETTINGS","TOPLEFT",main,"TOPLEFT",444,-97)
    rows = {}
    for n = 1, MAX_ROWS do
        local row = CreateFrame("Frame",nil,main)
        row:SetWidth(536)
        row:SetHeight(44)
        row:SetPoint("TOPLEFT",main,"TOPLEFT",17,-113 - (n-1)*43)
        local bg = row:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(row)
        bg:SetTexture(.15,.12,.19,.68)
        row.check = CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate")
        row.check:SetWidth(23); row.check:SetHeight(23)
        row.check:SetPoint("LEFT",row,"LEFT",1,0)
        row.check:SetScript("OnClick",function()
            local e = AshenConsumesDB.entries[row.index]
            if e then e.enabled = row.check:GetChecked() and true or false end
            pending = nil
            RefreshUI(GetTime())
        end)
        row.icon = row:CreateTexture(nil,"ARTWORK")
        row.icon:SetWidth(27); row.icon:SetHeight(27)
        row.icon:SetPoint("LEFT",row,"LEFT",27,0)
        row.item = Font(row,"GameFontNormalSmall","","TOPLEFT",row,"TOPLEFT",60,-7)
        row.item:SetWidth(256)
        row.item:SetJustifyH("LEFT")
        row.aura = Font(row,"GameFontHighlightSmall","","TOPLEFT",row,"TOPLEFT",60,-25)
        row.aura:SetWidth(254)
        row.aura:SetJustifyH("LEFT")
        row.aura:SetTextColor(.64,.61,.67)
        row.time = Font(row,"GameFontNormalSmall","","TOPLEFT",row,"TOPLEFT",324,-7)
        row.time:SetWidth(110)
        row.time:SetJustifyH("LEFT")
        row.timeLabel = Font(row,"GameFontHighlightSmall","","TOPLEFT",row,"TOPLEFT",324,-25)
        row.timeLabel:SetTextColor(.63,.58,.7)
        MakeButton(row,"E",26,24,"LEFT",row,"LEFT",426,0,function() OpenEditor(row.index) end)
        MakeButton(row,"^",26,24,"LEFT",row,"LEFT",454,0,function()
            local i=row.index
            if i and i > 1 then
                local entries=AshenConsumesDB.entries
                entries[i-1],entries[i]=entries[i],entries[i-1]
                pending=nil
                RefreshUI(GetTime())
            end
        end)
        MakeButton(row,"X",26,24,"LEFT",row,"LEFT",482,0,function()
            local i=row.index
            if i then
                table.remove(AshenConsumesDB.entries,i)
                if scrollOffset > math.max(0,table.getn(AshenConsumesDB.entries)-MAX_ROWS) then
                    scrollOffset = math.max(0,table.getn(AshenConsumesDB.entries)-MAX_ROWS)
                end
                pending=nil
                RefreshUI(GetTime())
            end
        end)
        rows[n]=row
    end
    MakeButton(main,"Previous",84,23,"BOTTOMLEFT",main,"BOTTOMLEFT",18,58,function()
        scrollOffset = math.max(0, scrollOffset - MAX_ROWS)
        RefreshUI(GetTime())
    end)
    MakeButton(main,"Next",84,23,"BOTTOMLEFT",main,"BOTTOMLEFT",109,58,function()
        scrollOffset = math.min(math.max(0,table.getn(AshenConsumesDB.entries)-MAX_ROWS),scrollOffset+MAX_ROWS)
        RefreshUI(GetTime())
    end)
    statusLine=Font(main,"GameFontHighlightSmall","","BOTTOMLEFT",main,"BOTTOMLEFT",20,34)
    warningText=Font(main,"GameFontHighlightSmall","","BOTTOMLEFT",main,"BOTTOMLEFT",20,17)
    warningText:SetTextColor(.68,.55,.79)
    main:Hide()

    editor = CreateFrame("Frame","AshenConsumesEditor",UIParent)
    editor:SetWidth(420); editor:SetHeight(270)
    Backdrop(editor,1)
    editor:SetPoint("CENTER",UIParent,"CENTER",0,40)
    editor:SetFrameStrata("FULLSCREEN_DIALOG")
    editor:EnableMouse(true)
    editTitle=Font(editor,"GameFontNormalLarge","ADD CONSUMABLE","TOPLEFT",editor,"TOPLEFT",20,-17)
    Font(editor,"GameFontHighlightSmall","Names must match the item in bags and the buff on your character.","TOPLEFT",editor,"TOPLEFT",20,-46)
    editItem=MakeEditField(editor,26,-89,"Item name (exact)")
    editBuff=MakeEditField(editor,26,-150,"Buff name (exact; use /ac buffs to inspect)")
    editFood=CreateFrame("CheckButton",nil,editor,"UICheckButtonTemplate")
    editFood:SetWidth(24); editFood:SetHeight(24)
    editFood:SetPoint("TOPLEFT",editor,"TOPLEFT",20,-181)
    Font(editor,"GameFontHighlightSmall","Food (wait up to 12 sec for eating)","LEFT",editFood,"RIGHT",2,0)
    MakeButton(editor,"Cancel",82,25,"BOTTOMRIGHT",editor,"BOTTOMRIGHT",-17,16,function() editor:Hide() end)
    MakeButton(editor,"Save",82,25,"BOTTOMRIGHT",editor,"BOTTOMRIGHT",-109,16,function()
        local item=StripLink(editItem:GetText())
        local buff=Trim(editBuff:GetText())
        if item=="" or buff=="" then
            Say("Both fields are required. Buff name is the tooltip name of the EFFECT, not always the item name.")
            return
        end
        if editIndex and AshenConsumesDB.entries[editIndex] then
            local e=AshenConsumesDB.entries[editIndex]
            e.item=item; e.buff=buff; e.food=editFood:GetChecked() and true or false
        else
            AddEntry(item,buff,editFood:GetChecked())
        end
        editor:Hide()
        pending=nil
        ForceScan()
        RefreshUI(GetTime())
    end)
    editor:Hide()

    hud = CreateFrame("Frame","AshenConsumesHUD",UIParent)
    hud:SetWidth(280); hud:SetHeight(91)
    Backdrop(hud,.9)
    hud:SetMovable(true); hud:EnableMouse(true)
    hud:RegisterForDrag("LeftButton")
    hud:SetScript("OnDragStart",function() hud:StartMoving() end)
    hud:SetScript("OnDragStop",function() hud:StopMovingOrSizing();SavePosition(hud,"hudPos") end)
    RepositionSaved(hud,AshenConsumesDB.hudPos,330,-140)
    hud:SetFrameStrata("MEDIUM")
    Font(hud,"GameFontNormalSmall","ASHEN CONSUMES - drag here","TOPLEFT",hud,"TOPLEFT",10,-9)
    MakeButton(hud,"O",23,20,"TOPRIGHT",hud,"TOPRIGHT",-8,-5,function() if main:IsVisible() then main:Hide() else main:Show(); RefreshUI(GetTime()) end end)
    useButton=CreateFrame("Button","AshenConsumesUseButton",hud,"UIPanelButtonTemplate")
    useButton:SetWidth(258);useButton:SetHeight(30)
    useButton:SetPoint("TOP",hud,"TOP",0,-31)
    useButton:SetText("USE NEXT CONSUME")
    useButton:SetScript("OnClick",function() AshenConsumes_UseNext() end)
    hudText=Font(hud,"GameFontHighlightSmall","Configuring...","BOTTOM",hud,"BOTTOM",0,10)
    hudText:SetWidth(255)
    hudText:SetJustifyH("CENTER")
    hudText:SetTextColor(.95,.76,.36)

    if AshenConsumesDB.showHUD == false then hud:Hide() end
end

local function LoadDB()
    if type(AshenConsumesDB) ~= "table" then AshenConsumesDB={} end
    if type(AshenConsumesDB.entries) ~= "table" then AshenConsumesDB.entries={} end
    if AshenConsumesDB.threshold == nil then AshenConsumesDB.threshold=300 end
    if AshenConsumesDB.sound == nil then AshenConsumesDB.sound=true end
    if AshenConsumesDB.showHUD == nil then AshenConsumesDB.showHUD=true end
    for i = 1, table.getn(AshenConsumesDB.entries) do
        local e=AshenConsumesDB.entries[i]
        if e.enabled==nil then e.enabled=true end
        if not e.item then e.item="" end
        if not e.buff then e.buff=e.item end
    end
end

local function ListBuffs()
    ForceScan()
    Say("Current helpful buffs (from the native 1.12 tooltip API):")
    local count=0
    for i=0,31 do
        local index=GetPlayerBuff(i,"HELPFUL")
        if index and index>=0 then
            tooltip:ClearLines()
            tooltip:SetPlayerBuff(index)
            local line=getglobal("AshenConsumesHiddenTooltipTextLeft1")
            local name=line and line:GetText()
            if name then
                count=count+1
                Say(name .. " - " .. FormatDuration(GetPlayerBuffTimeLeft(index)))
            end
        end
    end
    if count==0 then Say("No readable helpful buffs found.") end
end

local function Help()
    Say("/ac - settings | /ac use - use one ready item | /ac buffs - show actual buff names")
    Say("/ac add ITEM ; BUFF | /ac remove NUMBER | /ac list | /ac preset")
    Say("/ac threshold 300 (seconds) | /ac sound | /ac hud")
    Say("Recommended macro: /run AshenConsumes_UseNext()")
end

SLASH_ASHENCONSUMES1 = "/ac"
SLASH_ASHENCONSUMES2 = "/ashenconsumes"
SlashCmdList["ASHENCONSUMES"] = function(msg)
    if not initialized then Say("Not initialized yet."); return end
    msg=Trim(msg)
    if msg=="" or msg=="config" or msg=="options" then
        if main:IsVisible() then main:Hide() else main:Show(); RefreshUI(GetTime()) end
        return
    end
    local _,_,cmd,rest=string.find(msg,"^(%S+)%s*(.*)$")
    cmd=Norm(cmd)
    rest=Trim(rest)
    if cmd=="use" then AshenConsumes_UseNext()
    elseif cmd=="buffs" then ListBuffs()
    elseif cmd=="preset" then AddWarriorPreset()
    elseif cmd=="list" then
        for i=1,table.getn(AshenConsumesDB.entries) do
            local e=AshenConsumesDB.entries[i]
            Say(i .. ". " .. e.item .. " -> " .. e.buff .. (e.enabled and "" or " [OFF]"))
        end
    elseif cmd=="add" then
        local sep=string.find(rest,";",1,true)
        if not sep then Say("Usage: /ac add Item Name ; Buff Name")
        elseif AddEntry(string.sub(rest,1,sep-1),string.sub(rest,sep+1),false) then
            Say("Added. One press uses at most one eligible consume.")
            RefreshUI(GetTime())
        end
    elseif cmd=="remove" then
        local n=tonumber(rest)
        if n and n>=1 and n<=table.getn(AshenConsumesDB.entries) then
            table.remove(AshenConsumesDB.entries,n); pending=nil
            scrollOffset=0; RefreshUI(GetTime())
        else Say("Invalid item number. Try /ac list") end
    elseif cmd=="threshold" then
        local secs=tonumber(rest)
        if secs and secs>=0 and secs<=3600 then
            AshenConsumesDB.threshold=math.floor(secs)
            Say("Consumables become eligible at " .. secs .. " seconds or less.")
            RefreshUI(GetTime())
        else Say("Threshold must be 0 to 3600 seconds (300 = five minutes).") end
    elseif cmd=="sound" then
        AshenConsumesDB.sound=not AshenConsumesDB.sound
        Say("Warning sound " .. (AshenConsumesDB.sound and "ON" or "OFF"))
        RefreshUI(GetTime())
    elseif cmd=="hud" then
        AshenConsumesDB.showHUD=not AshenConsumesDB.showHUD
        if AshenConsumesDB.showHUD then hud:Show() else hud:Hide() end
    elseif cmd=="help" then Help()
    else Help() end
end

local eventFrame = CreateFrame("Frame","AshenConsumesCoreFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_AURAS_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent",function()
    -- Lua 5.0 in Vanilla uses global event and arg1 for event handlers.
    if event=="PLAYER_LOGIN" then
        if not initialized then
            LoadDB()
            InitUI()
            initialized=true
            ForceScan()
            -- Startup warning once rather than spamming every missing entry.
            initAlertAt=GetTime()+6
            RefreshUI(GetTime())
            Say("Loaded. Click the mini HUD or type /ac. Macro: /run AshenConsumes_UseNext()")
        end
    elseif initialized and (event=="PLAYER_AURAS_CHANGED" or event=="PLAYER_ENTERING_WORLD" or
        (event=="UNIT_AURA" and arg1=="player")) then
        ForceScan()
        if pending and CheckBuff({buff=pending.buff},GetTime()) and
           CheckBuff({buff=pending.buff},GetTime()) > AshenConsumesDB.threshold then
            pending=nil
        end
        RefreshUI(GetTime())
    elseif initialized and event=="BAG_UPDATE" then
        bagDirty = true
        RefreshUI(GetTime())
    end
end)

local onUpdateElapsed=0
local displayElapsed=0
eventFrame:SetScript("OnUpdate",function()
    if not initialized then return end
    local dt=arg1 or 0  -- Lua 5.0 OnUpdate elapsed in global arg1.
    onUpdateElapsed=onUpdateElapsed+dt
    displayElapsed=displayElapsed+dt
    local now=GetTime()
    if onUpdateElapsed >= REFRESH_EVERY then
        onUpdateElapsed=0
        ForceScan()
        if pending and CheckBuff({buff=pending.buff},now) and
            CheckBuff({buff=pending.buff},now) > AshenConsumesDB.threshold then
            pending=nil
        end
        UpdateNotices(now)
    end
    if displayElapsed >= DISPLAY_EVERY then
        displayElapsed=0
        RefreshUI(now)
    end
end)
