-- Movable / hideable minimap button.
-- Named "RelationshipsAchievementsMinimapButton" and parented to Minimap so
-- MinimapButtonBag and MinimapButtonFrame automatically discover and manage it.

local MMB = CreateFrame("Button", "RelationshipsAchievementsMinimapButton", Minimap)
MMB:SetFrameStrata("MEDIUM")
MMB:SetWidth(31); MMB:SetHeight(31)
MMB:SetFrameLevel(8)
MMB:RegisterForClicks("LeftButtonUp", "RightButtonUp")
MMB:RegisterForDrag("LeftButton")
MMB:SetMovable(true)
MMB:SetClampedToScreen(true)

-- Ring (matches other minimap addons like Cartographer / Titan)
local overlay = MMB:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53); overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", MMB, "TOPLEFT", 0, 0)

-- Icon
local icon = MMB:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20); icon:SetHeight(20)
icon:SetTexture("Interface\\Icons\\Achievement_General")
icon:SetPoint("CENTER", MMB, "CENTER", 0, 1)
MMB.icon = icon

-- Highlight
local hi = MMB:CreateTexture(nil, "HIGHLIGHT")
hi:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
hi:SetWidth(31); hi:SetHeight(31)
hi:SetPoint("CENTER", MMB, "CENTER", 0, 1)
hi:SetBlendMode("ADD")

local function GetDB()
    RelationshipsAchievementsDB = RelationshipsAchievementsDB or {}
    if not RelationshipsAchievementsDB.minimap then
        RelationshipsAchievementsDB.minimap = { angle = 200, radius = 80, hide = false, free = false, x = 0, y = 0 }
    end
    local m = RelationshipsAchievementsDB.minimap
    if m.angle  == nil then m.angle  = 200 end
    if m.radius == nil then m.radius = 80  end
    if m.hide   == nil then m.hide   = false end
    if m.free   == nil then m.free   = false end
    return m
end

local function ApplyPosition()
    local m = GetDB()
    MMB:ClearAllPoints()
    if m.free then
        MMB:SetPoint("CENTER", UIParent, "CENTER", m.x or 0, m.y or 0)
    else
        local a = math.rad(m.angle or 200)
        local r = m.radius or 80
        MMB:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(a) * r, math.sin(a) * r)
    end
end

local function ApplyVisibility()
    local m = GetDB()
    if m.hide then MMB:Hide() else MMB:Show() end
end

-- Drag around the minimap ring (or free-drag anywhere with Shift held).
local function MoveOnUpdate()
    local m = GetDB()
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    if IsShiftKeyDown() then
        m.free = true
        local ux, uy = UIParent:GetCenter()
        local uscale = UIParent:GetEffectiveScale()
        local px, py = GetCursorPosition()
        m.x = px / uscale - ux
        m.y = py / uscale - uy
    else
        m.free = false
        local dx, dy = cx - mx, cy - my
        m.angle = math.deg(math.atan2(dy, dx))
    end
    ApplyPosition()
end

MMB:SetScript("OnDragStart", function()
    this:LockHighlight()
    this:SetScript("OnUpdate", MoveOnUpdate)
end)
MMB:SetScript("OnDragStop", function()
    this:UnlockHighlight()
    this:SetScript("OnUpdate", nil)
end)

MMB:SetScript("OnClick", function()
    if arg1 == "RightButton" then
        if RelationshipsAchievements_MinimapMenu then
            RelationshipsAchievements_MinimapMenu()
        else
            local m = GetDB()
            m.hide = true
            ApplyVisibility()
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Relationships Achievements:|r minimap button hidden. Type |cff00ff00/rach minimap show|r to restore.")
        end
    else
        if RelationshipsAchievements_Toggle then RelationshipsAchievements_Toggle() end
    end
end)

MMB:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Relationships Achievements")
    local pts = RelationshipsAchievements and RelationshipsAchievements.TotalPoints and RelationshipsAchievements:TotalPoints() or 0
    GameTooltip:AddLine("|cffffd200Points:|r "..pts, 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: open panel", 0.6, 0.8, 1)
    GameTooltip:AddLine("Right-click: hide button", 0.6, 0.8, 1)
    GameTooltip:AddLine("Drag: move around minimap", 0.6, 0.8, 1)
    GameTooltip:AddLine("Shift+Drag: free-place anywhere", 0.6, 0.8, 1)
    GameTooltip:Show()
end)
MMB:SetScript("OnLeave", function() GameTooltip:Hide() end)

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
    ApplyPosition()
    ApplyVisibility()
end)

function RelationshipsAchievements_Minimap_Show()
    local m = GetDB(); m.hide = false; ApplyVisibility()
end
function RelationshipsAchievements_Minimap_Hide()
    local m = GetDB(); m.hide = true; ApplyVisibility()
end
function RelationshipsAchievements_Minimap_Toggle()
    local m = GetDB(); m.hide = not m.hide; ApplyVisibility()
end
function RelationshipsAchievements_Minimap_Reset()
    RelationshipsAchievementsDB = RelationshipsAchievementsDB or {}
    RelationshipsAchievementsDB.minimap = { angle = 200, radius = 80, hide = false, free = false, x = 0, y = 0 }
    ApplyPosition(); ApplyVisibility()
end
