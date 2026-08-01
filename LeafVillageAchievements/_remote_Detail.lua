-- Achievement detail popup — a movable/closable frame that shows a single
-- achievement's icon, name, description, points, and unlock date. Opened by
-- clicking an achievement chat link, the toast, or a row in the panel.

local popups = {}
local MAX_POPUPS = 6

local function FormatDate(t)
    if not t then return "" end
    return date("%m/%d/%y", t)
end

local function CreatePopup(index)
    local f = CreateFrame("Frame", "RelationshipsAchievementDetailPopup"..index, UIParent)
    f:SetWidth(340); f:SetHeight(96)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -60 - ((index - 1) * 110))
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    f:SetBackdropColor(0, 0, 0, 0.9)

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOP", f, "TOP", 0, -8)
    header:SetText("Achievement")
    header:SetTextColor(1, 0.82, 0)
    f.header = header

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(48); icon:SetHeight(48)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -24)
    f.icon = icon

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    title:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 0.82, 0)
    f.title = title

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(1, 1, 1)
    f.desc = desc

    local date = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    date:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 8)
    date:SetTextColor(0.7, 0.7, 0.7)
    f.date = date

    local points = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    points:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 8)
    points:SetTextColor(1, 0.82, 0)
    f.points = points

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    if not UISpecialFrames then UISpecialFrames = {} end
    tinsert(UISpecialFrames, "RelationshipsAchievementDetailPopup"..index)

    return f
end

local function AcquirePopup()
    for i = 1, table.getn(popups) do
        if not popups[i]:IsVisible() then
            return popups[i]
        end
    end
    if table.getn(popups) < MAX_POPUPS then
        local p = CreatePopup(table.getn(popups) + 1)
        table.insert(popups, p)
        return p
    end
    return popups[1]
end

function RelationshipsAchievements_ShowDetail(ach)
    if not ach then return end
    local f = AcquirePopup()

    local unlocked = RelationshipsAchievements and RelationshipsAchievements:IsUnlocked(ach.id)
    if unlocked then
        f.header:SetText("Achievement Earned")
    else
        f.header:SetText("Achievement")
    end
    f.title:SetText(ach.name or "")
    f.desc:SetText(ach.desc or "")
    f.icon:SetTexture(ach.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if ach.points and ach.points > 0 then
        f.points:SetText(ach.points.." pts")
    else
        f.points:SetText("")
    end
    if unlocked then
        local t = RelationshipsAchievements:GetUnlockTime(ach.id)
        f.date:SetText(FormatDate(t))
    else
        f.date:SetText("Not yet earned")
    end
    f:Show()
    f:Raise()
end

-- ============ Chat hyperlink handling ============

local function HandleAchievementLink(link)
    if not link then return false end
    if string.sub(link, 1, 6) ~= "relach" then return false end
    -- link format: "relach:<id>"
    local _, _, idStr = string.find(link, "^relach:(%d+)")
    local id = tonumber(idStr)
    if id and RelationshipsAchievements_ById and RelationshipsAchievements_ById[id] then
        RelationshipsAchievements_ShowDetail(RelationshipsAchievements_ById[id])
        return true
    end
    return true
end

local orig_SetItemRef = SetItemRef
function SetItemRef(link, text, button)
    if HandleAchievementLink(link) then return end
    if orig_SetItemRef then
        return orig_SetItemRef(link, text, button)
    end
end

-- Safely install a script handler. Vanilla 1.12 ChatFrames only support
-- OnHyperlinkClick; OnHyperlinkShow was added in later clients and setting
-- it here throws "ChatFrameN doesn't have a 'OnHyperlinkShow' script".
-- Wrapping in pcall lets us support both without erroring on 1.12.
local function SafeHookScript(frame, scriptName, newFn)
    local prev
    pcall(function() prev = frame:GetScript(scriptName) end)
    local ok = pcall(function()
        frame:SetScript(scriptName, function()
            if HandleAchievementLink(arg1) then return end
            if prev then prev() end
        end)
    end)
    return ok
end

local function InstallChatHooks()
    local num = NUM_CHAT_WINDOWS or 7
    for i = 1, num do
        local cf = getglobal("ChatFrame"..i)
        if cf then
            if cf.SetHyperlinksEnabled then
                pcall(function() cf:SetHyperlinksEnabled(true) end)
            end
            SafeHookScript(cf, "OnHyperlinkClick")
            SafeHookScript(cf, "OnHyperlinkShow")
        end
    end
end

InstallChatHooks()

local _hookFrame = CreateFrame("Frame")
_hookFrame:RegisterEvent("PLAYER_LOGIN")
_hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
_hookFrame:SetScript("OnEvent", function()
    InstallChatHooks()
end)
