-- Ashen Announcement Filter
-- Turtle WoW / Vanilla 1.12 compatible
-- Locally hides matching achievement and badge announcements from guild chat.

AshenAnnouncementFilter = AshenAnnouncementFilter or {}
local AAF = AshenAnnouncementFilter

local ADDON_NAME = "AshenAnnouncementFilter"
local PREFIX = "|cFFFF7F00[Ashen Filter]|r "
local DEFAULT_ANGLE = 225
local MINIMAP_RADIUS = 80

local function Print(message)
  local text = PREFIX .. tostring(message or "")
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  end
end

local function EnsureDB()
  if type(AshenAnnouncementFilterDB) ~= "table" then
    AshenAnnouncementFilterDB = {}
  end

  if AshenAnnouncementFilterDB.hideAchievements == nil then
    AshenAnnouncementFilterDB.hideAchievements = false
  end
  if AshenAnnouncementFilterDB.hideBadges == nil then
    AshenAnnouncementFilterDB.hideBadges = false
  end
  if type(AshenAnnouncementFilterDB.minimapAngle) ~= "number" then
    AshenAnnouncementFilterDB.minimapAngle = DEFAULT_ANGLE
  end

  return AshenAnnouncementFilterDB
end

local function ContainsPlain(text, needle)
  return type(text) == "string" and string.find(text, needle, 1, true) ~= nil
end

function AAF:IsAchievementAnnouncement(message)
  if type(message) ~= "string" or message == "" then
    return false
  end

  return ContainsPlain(message, "|Hleafve_ach:")
    and ContainsPlain(string.lower(message), "has earned the achievement")
end

function AAF:IsBadgeAnnouncement(message)
  if type(message) ~= "string" or message == "" then
    return false
  end

  if not ContainsPlain(message, "|Hleafve_badge:") then
    return false
  end

  local lowerMessage = string.lower(message)
  return string.sub(lowerMessage, 1, 7) == "earned "
    or ContainsPlain(lowerMessage, " has earned ")
    or string.sub(lowerMessage, 1, 11) == "has earned "
end

function AAF:ShouldHideGuildMessage(message)
  local db = EnsureDB()

  if db.hideAchievements and self:IsAchievementAnnouncement(message) then
    return true
  end

  if db.hideBadges and self:IsBadgeAnnouncement(message) then
    return true
  end

  return false
end

function AAF:RefreshPanel()
  local db = EnsureDB()
  local panel = self.panel
  if not panel then return end

  if panel.achievementCheck then
    panel.achievementCheck:SetChecked(db.hideAchievements and 1 or nil)
  end
  if panel.badgeCheck then
    panel.badgeCheck:SetChecked(db.hideBadges and 1 or nil)
  end

  if panel.status then
    local achievementStatus = db.hideAchievements and "|cFF66FF66Hidden|r" or "|cFFFFFFFFShown|r"
    local badgeStatus = db.hideBadges and "|cFF66FF66Hidden|r" or "|cFFFFFFFFShown|r"
    panel.status:SetText("Achievements: " .. achievementStatus .. "     Badges: " .. badgeStatus)
  end
end

function AAF:SetBothHidden(hidden)
  local db = EnsureDB()
  db.hideAchievements = hidden and true or false
  db.hideBadges = hidden and true or false
  self:RefreshPanel()

  if hidden then
    Print("Achievement and badge announcements are now hidden locally.")
  else
    Print("Achievement and badge announcements are now shown.")
  end
end

function AAF:ToggleBoth()
  local db = EnsureDB()
  local bothHidden = db.hideAchievements and db.hideBadges
  self:SetBothHidden(not bothHidden)
end

function AAF:BuildPanel()
  if self.panel then return self.panel end

  local panel = CreateFrame("Frame", "AshenAnnouncementFilterFrame", UIParent)
  panel:SetWidth(390)
  panel:SetHeight(245)
  panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  panel:SetFrameStrata("DIALOG")
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function()
    this:StartMoving()
  end)
  panel:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
  end)
  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
  })
  panel:Hide()

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", panel, "TOP", 0, -18)
  title:SetText("Ashen Announcement Filter")

  local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
  subtitle:SetWidth(340)
  subtitle:SetJustifyH("CENTER")
  subtitle:SetText("These settings only affect your own chat window. They are saved automatically.")

  local achievementCheck = CreateFrame("CheckButton", "AshenAnnouncementFilterAchievementCheck", panel, "UICheckButtonTemplate")
  achievementCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 34, -82)
  local achievementText = getglobal(achievementCheck:GetName() .. "Text")
  if achievementText then
    achievementText:SetText("Hide achievement announcements")
  end
  achievementCheck:SetScript("OnClick", function()
    local db = EnsureDB()
    db.hideAchievements = this:GetChecked() and true or false
    AAF:RefreshPanel()
  end)
  panel.achievementCheck = achievementCheck

  local achievementHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  achievementHelp:SetPoint("TOPLEFT", achievementCheck, "BOTTOMLEFT", 30, 2)
  achievementHelp:SetText("Filters clickable achievement links containing 'has earned the achievement'.")

  local badgeCheck = CreateFrame("CheckButton", "AshenAnnouncementFilterBadgeCheck", panel, "UICheckButtonTemplate")
  badgeCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 34, -132)
  local badgeText = getglobal(badgeCheck:GetName() .. "Text")
  if badgeText then
    badgeText:SetText("Hide badge announcements")
  end
  badgeCheck:SetScript("OnClick", function()
    local db = EnsureDB()
    db.hideBadges = this:GetChecked() and true or false
    AAF:RefreshPanel()
  end)
  panel.badgeCheck = badgeCheck

  local badgeHelp = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  badgeHelp:SetPoint("TOPLEFT", badgeCheck, "BOTTOMLEFT", 30, 2)
  badgeHelp:SetText("Filters clickable badge links generated by the badge announcement system.")

  local status = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("BOTTOM", panel, "BOTTOM", 0, 38)
  status:SetWidth(340)
  status:SetJustifyH("CENTER")
  panel.status = status

  local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOM", panel, "BOTTOM", 0, 19)
  hint:SetText("Minimap: Left-click settings  |  Right-click quick toggle  |  Drag to move")

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)

  if UISpecialFrames then
    table.insert(UISpecialFrames, panel:GetName())
  end

  self.panel = panel
  self:RefreshPanel()
  return panel
end

function AAF:TogglePanel()
  local panel = self:BuildPanel()
  if panel:IsShown() then
    panel:Hide()
  else
    self:RefreshPanel()
    panel:Show()
  end
end

function AAF:UpdateMinimapButtonPosition()
  if not self.minimapButton or not Minimap then return end

  local db = EnsureDB()
  local angle = math.rad(db.minimapAngle or DEFAULT_ANGLE)
  local x = math.cos(angle) * MINIMAP_RADIUS
  local y = math.sin(angle) * MINIMAP_RADIUS

  self.minimapButton:ClearAllPoints()
  self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function AAF:UpdateMinimapAngleFromCursor()
  if not Minimap then return end

  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale() or 1
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  local centerX, centerY = Minimap:GetCenter()
  if not centerX or not centerY then return end

  local dx = cursorX - centerX
  local dy = cursorY - centerY
  local atan2 = math.atan2 or math.atan
  local angle

  if math.atan2 then
    angle = math.deg(math.atan2(dy, dx))
  elseif dx == 0 then
    angle = dy >= 0 and 90 or -90
  else
    angle = math.deg(atan2(dy / dx))
    if dx < 0 then angle = angle + 180 end
  end

  EnsureDB().minimapAngle = angle
  self:UpdateMinimapButtonPosition()
end

function AAF:BuildMinimapButton()
  if self.minimapButton or not Minimap then return self.minimapButton end

  local button = CreateFrame("Button", "AshenAnnouncementFilterMinimapButton", Minimap)
  button:SetWidth(32)
  button:SetHeight(32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
  button.icon = icon

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetWidth(54)
  border:SetHeight(54)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", -11, 11)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  button.border = border

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetWidth(24)
  highlight:SetHeight(24)
  highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")

  button:SetScript("OnClick", function()
    if this.wasDragged then
      this.wasDragged = false
      return
    end
    if arg1 == "RightButton" then
      AAF:ToggleBoth()
    else
      AAF:TogglePanel()
    end
  end)

  button:SetScript("OnDragStart", function()
    this.dragging = true
    this.wasDragged = true
  end)
  button:SetScript("OnDragStop", function()
    this.dragging = false
  end)
  button:SetScript("OnUpdate", function()
    if this.dragging then
      AAF:UpdateMinimapAngleFromCursor()
    end
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("Ashen Announcement Filter", 1.0, 0.5, 0.0)
    GameTooltip:AddLine("Left-click: Open settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Hide/show both", 1, 1, 1)
    GameTooltip:AddLine("Drag: Move button", 0.75, 0.75, 0.75)
    local db = EnsureDB()
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Achievements: " .. (db.hideAchievements and "Hidden" or "Shown"), 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Badges: " .. (db.hideBadges and "Hidden" or "Shown"), 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  self.minimapButton = button
  self:UpdateMinimapButtonPosition()
  button:Show()
  return button
end

-- Preferred filter API when the client provides it.
function AAF:InstallMessageFilter()
  if self.messageFilterInstalled then return true end
  if type(ChatFrame_AddMessageEventFilter) ~= "function" then return false end

  self.messageFilterFunction = function(chatFrame, eventName, message, author, language, channelName, target, flags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid)
    if eventName == "CHAT_MSG_GUILD" and AAF:ShouldHideGuildMessage(message) then
      return true
    end
    return false
  end

  ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", self.messageFilterFunction)
  self.messageFilterInstalled = true
  return true
end

-- Vanilla fallback: hook each visible chat frame's OnEvent handler.
function AAF:HookChatFrame(frame)
  if not frame or not frame.GetScript or not frame.SetScript then return end

  local currentHandler = frame:GetScript("OnEvent")
  if not currentHandler then return end
  if frame.AAFOnEventWrapper and currentHandler == frame.AAFOnEventWrapper then return end

  local originalHandler = currentHandler
  local wrapper = function()
    if event == "CHAT_MSG_GUILD" and AAF:ShouldHideGuildMessage(arg1) then
      return
    end
    return originalHandler()
  end

  frame.AAFOnEventWrapper = wrapper
  frame:SetScript("OnEvent", wrapper)
end

function AAF:InstallLegacyChatHooks()
  local count = NUM_CHAT_WINDOWS or 7
  local i
  for i = 1, count do
    self:HookChatFrame(getglobal("ChatFrame" .. i))
  end
end

function AAF:InstallChatFiltering()
  self:InstallMessageFilter()
  self:InstallLegacyChatHooks()
end

function AAF:ShowStatus()
  local db = EnsureDB()
  Print("Achievements: " .. (db.hideAchievements and "hidden" or "shown") .. "; Badges: " .. (db.hideBadges and "hidden" or "shown") .. ".")
end

SLASH_ASHENANNOUNCEMENTFILTER1 = "/ashenfilter"
SLASH_ASHENANNOUNCEMENTFILTER2 = "/aaf"
SlashCmdList["ASHENANNOUNCEMENTFILTER"] = function(message)
  local command = string.lower(tostring(message or ""))
  command = string.gsub(command, "^%s+", "")
  command = string.gsub(command, "%s+$", "")

  if command == "hide" or command == "on" or command == "all" then
    AAF:SetBothHidden(true)
  elseif command == "show" or command == "off" or command == "none" then
    AAF:SetBothHidden(false)
  elseif command == "status" then
    AAF:ShowStatus()
  else
    AAF:TogglePanel()
  end
end

local eventFrame = CreateFrame("Frame", "AshenAnnouncementFilterEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
eventFrame.elapsed = 0

eventFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    EnsureDB()
    AAF:BuildPanel()
    AAF:BuildMinimapButton()
    AAF:InstallChatFiltering()
    return
  end

  if event == "PLAYER_LOGIN" then
    EnsureDB()
    AAF:BuildMinimapButton()
    AAF:InstallChatFiltering()
    return
  end

  if event == "UPDATE_CHAT_WINDOWS" then
    AAF:InstallLegacyChatHooks()
  end
end)

-- Re-check hooks occasionally because other chat addons may replace handlers after login.
eventFrame:SetScript("OnUpdate", function()
  local elapsed = arg1 or 0
  this.elapsed = (this.elapsed or 0) + elapsed
  if this.elapsed >= 5 then
    this.elapsed = 0
    AAF:InstallLegacyChatHooks()
  end
end)
