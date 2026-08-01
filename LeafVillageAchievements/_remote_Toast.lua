-- Achievement toast popup (the "gold banner" that appears on unlock)

local TOAST_DURATION = 5.0
local FADE_DURATION = 1.0

local toast

local function CreateToast()
    local f = CreateFrame("Button", "RelationshipsAchievementToast", UIParent)
    f:SetWidth(320)
    f:SetHeight(80)
    f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp")
    f:SetScript("OnClick", function()
        if this.ach and RelationshipsAchievements_ShowDetail then
            RelationshipsAchievements_ShowDetail(this.ach)
        end
    end)
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
    header:SetText("Achievement Unlocked!")
    header:SetTextColor(1, 0.82, 0)
    f.header = header

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(48); icon:SetHeight(48)
    icon:SetPoint("LEFT", f, "LEFT", 14, -6)
    f.icon = icon

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -2)
    title:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 1, 1)
    f.title = title

    local points = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    points:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 8)
    points:SetTextColor(1, 0.82, 0)
    f.points = points

    f.state = "hidden"
    f.stateTime = 0

    f:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        this.stateTime = this.stateTime + elapsed
        if this.state == "showing" then
            local a = this.stateTime / 0.4
            if a >= 1 then a = 1; this.state = "shown"; this.stateTime = 0 end
            this:SetAlpha(a)
        elseif this.state == "shown" then
            if this.stateTime >= TOAST_DURATION then
                this.state = "hiding"; this.stateTime = 0
            end
        elseif this.state == "hiding" then
            local a = 1 - (this.stateTime / FADE_DURATION)
            if a <= 0 then
                a = 0
                this:Hide()
                this.state = "hidden"
            end
            this:SetAlpha(a)
        end
    end)

    return f
end

function RelationshipsAchievements_ShowToast(ach)
    if not ach then return end
    if not toast then toast = CreateToast() end
    toast.ach = ach
    toast.title:SetText(ach.name)
    toast.icon:SetTexture(ach.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if ach.points and ach.points > 0 then
        toast.points:SetText(ach.points.." points")
    else
        toast.points:SetText("")
    end
    toast:SetAlpha(0)
    toast:Show()
    toast.state = "showing"
    toast.stateTime = 0
    PlaySoundFile("Sound\\Interface\\LevelUp.wav")
end
