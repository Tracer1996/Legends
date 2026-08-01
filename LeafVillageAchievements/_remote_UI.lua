-- WotLK-style Relationships Achievement UI
-- Left column: categories with per-category progress (Summary + real categories).
-- Right side: either a summary landing panel or a scrolling list of achievements.

local FRAME_W, FRAME_H = 840, 620
local ROW_H = 72
local VISIBLE_ROWS = 7
local RECENT_COUNT = 14
local RECENT_ROW_H = 34

local selectedCategory = 0
local scrollOffset = 0

local rows = {}
local catButtons = {}
local displayCats = {}
local summaryPanel
local listPanel

local function FormatDate(t)
    if not t then return "" end
    return date("%m/%d/%y", t)
end

local function GetAchievementsForCategory(catId)
    local out = {}
    for i = 1, table.getn(RelationshipsAchievements_List) do
        if RelationshipsAchievements_List[i].cat == catId then
            table.insert(out, RelationshipsAchievements_List[i])
        end
    end
    return out
end

local function BuildDisplayCats()
    displayCats = { { id = 0, name = "Summary" } }
    for i = 1, table.getn(RelationshipsAchievements_Categories) do
        table.insert(displayCats, RelationshipsAchievements_Categories[i])
    end
end

-- ============ Progress bar helper ============
-- Text is parented to the StatusBar itself at OVERLAY so it always renders
-- ABOVE the green fill texture (which is on the bar at ARTWORK layer).
local function CreateProgressBar(parent, width, height)
    local wrap = CreateFrame("Frame", nil, parent)
    if width  then wrap:SetWidth(width)  end
    if height then wrap:SetHeight(height) end
    wrap:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    wrap:SetBackdropColor(0, 0, 0, 0.7)
    wrap:SetBackdropBorderColor(0.4, 0.3, 0.1, 1)

    local bar = CreateFrame("StatusBar", nil, wrap)
    bar:SetPoint("TOPLEFT",     wrap, "TOPLEFT",      3, -3)
    bar:SetPoint("BOTTOMRIGHT", wrap, "BOTTOMRIGHT", -3,  3)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.15, 0.65, 0.15)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    -- Text is a child of the bar at OVERLAY so it draws above the fill.
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1)
    text:SetDrawLayer("OVERLAY", 7)

    wrap.bar  = bar
    wrap.text = text
    wrap.SetMinMaxValues   = function(self, a, b)      bar:SetMinMaxValues(a, b) end
    wrap.SetValue          = function(self, v)         bar:SetValue(v)           end
    wrap.SetStatusBarColor = function(self, r,g,b,a)   bar:SetStatusBarColor(r,g,b,a) end

    return wrap
end

-- ============ Category buttons ============

local function UpdateCategoryButtons()
    for i = 1, table.getn(displayCats) do
        local btn = catButtons[i]
        local cat = displayCats[i]
        if btn then
            if cat.id == 0 then
                btn.text:SetText("Summary")
            else
                local done, total = RelationshipsAchievements:CategoryProgress(cat.id)
                btn.text:SetText(cat.name.." ("..done.."/"..total..")")
            end
            if cat.id == selectedCategory then
                btn.highlight:Show()
                btn.text:SetTextColor(1, 0.82, 0)
            else
                btn.highlight:Hide()
                btn.text:SetTextColor(1, 1, 1)
            end
        end
    end
end

-- ============ Achievement rows ============

local function UpdateRows()
    local list = GetAchievementsForCategory(selectedCategory)
    local n = table.getn(list)
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > math.max(0, n - VISIBLE_ROWS) then
        scrollOffset = math.max(0, n - VISIBLE_ROWS)
    end

    for i = 1, VISIBLE_ROWS do
        local row = rows[i]
        local ach = list[i + scrollOffset]
        if ach then
            row.ach = ach
            row.icon:SetTexture(ach.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.title:SetText(ach.name)
            row.desc:SetText(ach.desc or "")
            if ach.points and ach.points > 0 then
                row.points:SetText(ach.points)
            else
                row.points:SetText("")
            end

            local unlocked = RelationshipsAchievements:IsUnlocked(ach.id)
            if unlocked then
                row.icon:SetVertexColor(1, 1, 1)
                row.title:SetTextColor(0.15, 0.75, 0.15)
                row.desc:SetTextColor(1, 1, 1)
                row.date:SetText(FormatDate(RelationshipsAchievements:GetUnlockTime(ach.id)))
                row.bg:SetVertexColor(0.2, 0.15, 0.05, 0.8)
            else
                row.icon:SetVertexColor(0.35, 0.35, 0.35)
                row.title:SetTextColor(0.6, 0.6, 0.6)
                row.desc:SetTextColor(0.5, 0.5, 0.5)
                row.date:SetText("")
                row.bg:SetVertexColor(0.1, 0.1, 0.1, 0.6)
            end

            if ach.account then row.acctTag:Show() else row.acctTag:Hide() end

            local cur, max = RelationshipsAchievements:GetProgress(ach.id)
            if cur and max and not unlocked then
                row.progressBar:SetMinMaxValues(0, max)
                row.progressBar:SetValue(cur)
                row.progressBar.text:SetText(cur.."/"..max)
                row.progressBar:Show()
            else
                row.progressBar:Hide()
            end

            row:Show()
        else
            row:Hide()
        end
    end
end

-- ============ Summary landing page ============

local function CollectRecentUnlocks(limit)
    local all = {}
    for i = 1, table.getn(RelationshipsAchievements_List) do
        local a = RelationshipsAchievements_List[i]
        local t = RelationshipsAchievements:GetUnlockTime(a.id)
        if t then
            table.insert(all, { ach = a, time = t })
        end
    end
    table.sort(all, function(x, y) return x.time > y.time end)
    local out = {}
    for i = 1, math.min(limit, table.getn(all)) do
        table.insert(out, all[i])
    end
    return out
end

local function UpdateSummary()
    if not summaryPanel then return end

    local recent = CollectRecentUnlocks(RECENT_COUNT)
    for i = 1, RECENT_COUNT do
        local r = summaryPanel.recentRows[i]
        local entry = recent[i]
        if entry then
            r.icon:SetTexture(entry.ach.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            r.title:SetText(entry.ach.name)
            r.date:SetText(FormatDate(entry.time))
            r.points:SetText((entry.ach.points and entry.ach.points > 0) and entry.ach.points or "")
            r.ach = entry.ach
            r:Show()
        else
            r:Hide()
        end
    end
    if table.getn(recent) == 0 and summaryPanel.emptyLabel then
        summaryPanel.emptyLabel:Show()
    elseif summaryPanel.emptyLabel then
        summaryPanel.emptyLabel:Hide()
    end
end

local function ApplySelectionVisibility()
    if selectedCategory == 0 then
        if summaryPanel then summaryPanel:Show() end
        if listPanel then listPanel:Hide() end
    else
        if summaryPanel then summaryPanel:Hide() end
        if listPanel then listPanel:Show() end
    end
end

function RelationshipsAchievements_RefreshUI()
    UpdateCategoryButtons()
    ApplySelectionVisibility()
    if selectedCategory == 0 then
        UpdateSummary()
    else
        UpdateRows()
    end
    if RelationshipsAchievementFrame then
        local total = RelationshipsAchievements:TotalAvailable()
        local done = RelationshipsAchievements:TotalUnlocked()
        local pts = RelationshipsAchievements:TotalPoints()
        if RelationshipsAchievementFrame.summary then
            RelationshipsAchievementFrame.summary:SetText(done.."/"..total.." achievements   |cffffd200"..pts.."|r points")
        end
        if RelationshipsAchievementFrame.overallBar then
            RelationshipsAchievementFrame.overallBar:SetMinMaxValues(0, total)
            RelationshipsAchievementFrame.overallBar:SetValue(done)
            RelationshipsAchievementFrame.overallBar.text:SetText(done.." / "..total)
        end
    end
end

-- Clicking a row in the main list should NOT open the popup box; the row
-- is already visible in the panel. Left intentionally as a no-op so future
-- selection/highlight logic can hook in without re-introducing the popup.
local function OnRowClick()
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(600); row:SetHeight(ROW_H - 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -((index - 1) * ROW_H) - 6)
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", OnRowClick)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.6)
    row.bg = bg

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(44); icon:SetHeight(44)
    icon:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)
    row.icon = icon

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    title:SetJustifyH("LEFT")
    row.title = title

    local desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", row, "RIGHT", -60, 0)
    desc:SetJustifyH("LEFT")
    desc:SetHeight(18)
    row.desc = desc

    local pbar = CreateProgressBar(row, nil, 16)
    pbar:SetHeight(16)
    pbar:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",   62, 6)
    pbar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -60, 6)
    pbar:Hide()
    row.progressBar = pbar

    local points = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    points:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -6)
    points:SetTextColor(1, 0.82, 0)
    row.points = points

    local date = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    date:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 6)
    date:SetTextColor(0.7, 0.7, 0.7)
    row.date = date

    local acctTag = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    acctTag:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -110, 6)
    acctTag:SetTextColor(0.4, 0.7, 1)
    acctTag:SetText("Account-wide")
    row.acctTag = acctTag

    return row
end

local function CreateCategoryButton(parent, index, cat)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(170); btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -((index - 1) * 24) - 4)

    local hl = btn:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints(btn)
    hl:SetTexture("Interface\\Buttons\\WHITE8x8")
    hl:SetVertexColor(0.4, 0.3, 0.1, 0.7)
    hl:Hide()
    btn.highlight = hl

    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("LEFT", btn, "LEFT", 8, 0)
    t:SetJustifyH("LEFT")
    btn.text = t

    btn:SetScript("OnClick", function()
        selectedCategory = cat.id
        scrollOffset = 0
        RelationshipsAchievements_RefreshUI()
    end)

    return btn
end

-- ============ Summary panel construction ============

local function CreateSummaryPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0, 0, 0, 0.6)
    panel:SetBackdropBorderColor(0.4, 0.3, 0.1, 1)

    local RIGHT_INSET = 14
    local recentHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    recentHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
    recentHeader:SetText("Most Recent Achievements")
    recentHeader:SetTextColor(1, 0.82, 0)

    panel.recentRows = {}
    for i = 1, RECENT_COUNT do
        local r = CreateFrame("Button", nil, panel)
        r:SetHeight(RECENT_ROW_H - 2)
        r:SetPoint("TOPLEFT", recentHeader, "BOTTOMLEFT", 0, -6 - ((i - 1) * RECENT_ROW_H))
        r:SetPoint("RIGHT", panel, "RIGHT", -RIGHT_INSET, 0)
        r:RegisterForClicks("LeftButtonUp")

        local bg = r:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(r)
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        bg:SetVertexColor(0.2, 0.15, 0.05, 0.7)

        local icon = r:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(20); icon:SetHeight(20)
        icon:SetPoint("LEFT", r, "LEFT", 4, 0)
        r.icon = icon

        local title = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        title:SetTextColor(0.15, 0.75, 0.15)
        r.title = title

        -- Fixed width + right-justify so the LEFT edge of the points field
        -- stays put whether the value is "5", "10", "25" or "50". Without a
        -- fixed width, a shorter number shifts the date column right and
        -- knocks the row out of alignment.
        local pts = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pts:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        pts:SetWidth(28)
        pts:SetJustifyH("RIGHT")
        pts:SetTextColor(1, 0.82, 0)
        r.points = pts

        local date = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        date:SetPoint("RIGHT", pts, "LEFT", -14, 0)
        date:SetWidth(64)
        date:SetJustifyH("RIGHT")
        date:SetTextColor(0.7, 0.7, 0.7)
        r.date = date

        r:SetScript("OnClick", function()
            if this and this.ach then
                local ach = this.ach
                selectedCategory = ach.cat or 0
                local list = GetAchievementsForCategory(selectedCategory)
                local idx = 1
                for j = 1, table.getn(list) do
                    if list[j] == ach then idx = j; break end
                end
                scrollOffset = idx - 1
                local maxOff = math.max(0, table.getn(list) - VISIBLE_ROWS)
                if scrollOffset > maxOff then scrollOffset = maxOff end
                RelationshipsAchievements_RefreshUI()
                -- Do not open the popup; the user is taken to the achievement
                -- inside the main UI (category selected + scrolled into view).
            end
        end)

        panel.recentRows[i] = r
    end

    local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("TOPLEFT", recentHeader, "BOTTOMLEFT", 4, -10)
    empty:SetText("No achievements earned yet. Get out there!")
    empty:SetTextColor(0.7, 0.7, 0.7)
    empty:Hide()
    panel.emptyLabel = empty


    return panel
end

local function CreateAchievementFrame()
    BuildDisplayCats()

    local f = CreateFrame("Frame", "RelationshipsAchievementFrame", UIParent)
    f:SetWidth(FRAME_W); f:SetHeight(FRAME_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(false); f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(460); titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", f, "TOP", 0, 12)

    -- Center vertically inside the gold title header texture (which is 64px tall
    -- anchored 12px above the frame top, so its visual center sits ~20px above f:TOP).
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", f, "TOP", 0, -8)
    title:SetText("Relationships Achievements")
    title:SetTextColor(1, 0.82, 0)

    local summary = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    summary:SetPoint("TOP", f, "TOP", 0, -28)
    f.summary = summary

    local overall = CreateProgressBar(f, FRAME_W - 60, 16)
    overall:SetPoint("TOP", f, "TOP", 0, -48)
    f.overallBar = overall

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Category panel
    local catPanel = CreateFrame("Frame", nil, f)
    catPanel:SetWidth(180); catPanel:SetHeight(FRAME_H - 105)
    catPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -76)
    catPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    catPanel:SetBackdropColor(0, 0, 0, 0.6)
    catPanel:SetBackdropBorderColor(0.4, 0.3, 0.1, 1)

    for i = 1, table.getn(displayCats) do
        catButtons[i] = CreateCategoryButton(catPanel, i, displayCats[i])
    end

    local host = CreateFrame("Frame", nil, f)
    host:SetPoint("TOPLEFT", catPanel, "TOPRIGHT", 8, 0)
    host:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 29)

    listPanel = CreateFrame("Frame", nil, host)
    listPanel:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    listPanel:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    listPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    listPanel:SetBackdropColor(0, 0, 0, 0.6)
    listPanel:SetBackdropBorderColor(0.4, 0.3, 0.1, 1)

    for i = 1, VISIBLE_ROWS do
        rows[i] = CreateRow(listPanel, i)
    end

    listPanel:EnableMouseWheel(true)
    listPanel:SetScript("OnMouseWheel", function()
        local delta = arg1 or 0
        scrollOffset = scrollOffset - delta
        UpdateRows()
    end)

    summaryPanel = CreateSummaryPanel(host)

    tinsert(UISpecialFrames, "RelationshipsAchievementFrame")

    return f
end

function RelationshipsAchievements_Toggle()
    if not RelationshipsAchievementFrame then
        CreateAchievementFrame()
    end
    if RelationshipsAchievementFrame:IsVisible() then
        RelationshipsAchievementFrame:Hide()
    else
        RelationshipsAchievementFrame:Show()
        if RelationshipsAchievements and not RelationshipsAchievements:IsUnlocked(104) then
            RelationshipsAchievements:Unlock(104)
        end
        RelationshipsAchievements_RefreshUI()
    end
end
