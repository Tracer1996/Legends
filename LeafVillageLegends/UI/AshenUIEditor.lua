-- LeafVillageLegends / Ashen Banner main UI size editor
-- Kept separate from Core.lua to avoid Vanilla Lua local limits.

function LeafVE_DumpMainUISize()
  local f = LeafVE and LeafVE.UI and LeafVE.UI.frame
  if not f then
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenUI:|r main frame not built yet") end
    return
  end
  local scale = 1
  if LeafVE_DB and LeafVE_DB.ui and LeafVE_DB.ui.scale then scale = LeafVE_DB.ui.scale end
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenUI:|r w=" .. tostring(math.floor(f:GetWidth() or 0)) .. " h=" .. tostring(math.floor(f:GetHeight() or 0)) .. " scale=" .. tostring(scale))
  end
end

function LeafVE_ApplyMainUISize(w, h)
  if not LeafVE or not LeafVE.ApplyUISize then return end
  LeafVE:ApplyUISize(w, h)
  if LeafVE_RefreshAshenBG then LeafVE_RefreshAshenBG() end
  LeafVE_DumpMainUISize()
end

function LeafVE_NudgeMainUISize(dw, dh)
  local f = LeafVE and LeafVE.UI and LeafVE.UI.frame
  if not f then return end
  local w = (f:GetWidth() or 1050) + (dw or 0)
  local h = (f:GetHeight() or 760) + (dh or 0)
  LeafVE_ApplyMainUISize(w, h)
end

function LeafVE_SetMainUISizeFromMsg(msg)
  local _, _, a, b = string.find(msg or "", "(-?%d+)%s+(-?%d+)")
  if a and b then
    LeafVE_ApplyMainUISize(tonumber(a), tonumber(b))
  else
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenUI:|r usage: /abuisize width height") end
  end
end

function LeafVE_NudgeMainUIScale(ds)
  if not LeafVE or not LeafVE.ApplyUIScale then return end
  local cur = 1
  if LeafVE_DB and LeafVE_DB.ui and LeafVE_DB.ui.scale then cur = LeafVE_DB.ui.scale end
  LeafVE:ApplyUIScale(cur + (ds or 0))
  if LeafVE_RefreshAshenBG then LeafVE_RefreshAshenBG() end
  LeafVE_DumpMainUISize()
end

function LeafVE_SetMainUIScaleFromMsg(msg)
  local s = tonumber(msg or "")
  if s then
    LeafVE:ApplyUIScale(s)
    if LeafVE_RefreshAshenBG then LeafVE_RefreshAshenBG() end
    LeafVE_DumpMainUISize()
  else
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenUI:|r usage: /abuiscale 0.85") end
  end
end

function LeafVE_FitMainUIToAshenBG()
  local c = LeafVE_GetAshenBGLayout and LeafVE_GetAshenBGLayout()
  if not c then return end
  local tw = tonumber(c.tileW) or 137
  local th = tonumber(c.tileH) or 92
  -- Fit width to the full 8-tile background. Height remains at least the addon minimum.
  local w = tw * 8
  local h = th * 4
  if LeafVE and LeafVE.uiMinHeight and h < LeafVE.uiMinHeight then h = LeafVE.uiMinHeight end
  LeafVE_ApplyMainUISize(w, h)
end

function LeafVE_CreateMainUIEditor()
  if LeafVE_MainUIEditor and LeafVE_MainUIEditor:IsVisible() then
    LeafVE_MainUIEditor:Hide()
    return
  end

  local f = LeafVE_MainUIEditor
  if not f then
    f = CreateFrame("Frame", "LeafVE_MainUIEditor", UIParent)
    LeafVE_MainUIEditor = f
    f:SetWidth(260)
    f:SetHeight(230)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.92)
    f:SetBackdropBorderColor(0.8, 0.55, 0.2, 1)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("Ashen UI Size")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    local function Btn(txt, x, y, fn)
      local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      b:SetWidth(70); b:SetHeight(22); b:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
      b:SetText(txt); b:SetScript("OnClick", fn); return b
    end
    local function Label(txt, y)
      local l = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      l:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y); l:SetText(txt); return l
    end

    Label("Frame Width", -40)
    Btn("W -", 95, -36, function() LeafVE_NudgeMainUISize(-20, 0) end)
    Btn("W +", 170, -36, function() LeafVE_NudgeMainUISize(20, 0) end)

    Label("Frame Height", -72)
    Btn("H -", 95, -68, function() LeafVE_NudgeMainUISize(0, -20) end)
    Btn("H +", 170, -68, function() LeafVE_NudgeMainUISize(0, 20) end)

    Label("UI Scale", -104)
    Btn("S -", 95, -100, function() LeafVE_NudgeMainUIScale(-0.02) end)
    Btn("S +", 170, -100, function() LeafVE_NudgeMainUIScale(0.02) end)

    Btn("Fit BG", 12, -140, LeafVE_FitMainUIToAshenBG)
    Btn("Dump", 95, -140, LeafVE_DumpMainUISize)
    Btn("BG Dump", 170, -140, function() if LeafVE_DumpAshenBG then LeafVE_DumpAshenBG() end end)
  end
  f:Show()
  LeafVE_DumpMainUISize()
end

SLASH_LEAFVE_UIEDITOR1 = "/abuieditor"
SlashCmdList["LEAFVE_UIEDITOR"] = LeafVE_CreateMainUIEditor

SLASH_LEAFVE_UISIZE1 = "/abuisize"
SlashCmdList["LEAFVE_UISIZE"] = LeafVE_SetMainUISizeFromMsg

SLASH_LEAFVE_UISCALE1 = "/abuiscale"
SlashCmdList["LEAFVE_UISCALE"] = LeafVE_SetMainUIScaleFromMsg

SLASH_LEAFVE_UIDUMP1 = "/abuidump"
SlashCmdList["LEAFVE_UIDUMP"] = LeafVE_DumpMainUISize

SLASH_LEAFVE_UIFITBG1 = "/abuifitbg"
SlashCmdList["LEAFVE_UIFITBG"] = LeafVE_FitMainUIToAshenBG
