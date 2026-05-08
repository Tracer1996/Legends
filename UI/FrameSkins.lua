-- LeafVillageLegends: Frame skins

local BORDER = {0.18, 0.30, 0.20, 1.0}
local BG_MAIN = {0.03, 0.05, 0.08, 0.97}
local BG_INSET = {0.06, 0.09, 0.13, 0.92}

local function EnsureBackdrop(frame)
  if not frame or type(frame.SetBackdrop) ~= "function" then
    return false
  end

  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = {left = 3, right = 3, top = 3, bottom = 3},
  })
  return true
end

local function HookOrSetScript(frame, scriptName, fn)
  if not frame or type(fn) ~= "function" then
    return
  end
  if type(frame.HookScript) == "function" then
    frame:HookScript(scriptName, fn)
    return
  end
  local existing = frame:GetScript(scriptName)
  if existing then
    frame:SetScript(scriptName, function(self, ...)
      local args = arg
      local argCount = args and (args.n or table.getn(args)) or 0
      if argCount > 0 then
        existing(self, unpack(args, 1, argCount))
        fn(self, unpack(args, 1, argCount))
      else
        existing(self)
        fn(self)
      end
    end)
  else
    frame:SetScript(scriptName, fn)
  end
end

LeafVE_FrameSkins = LeafVE_FrameSkins or {}

function LeafVE_FrameSkins.ApplyMainPanel(frame)
  if not EnsureBackdrop(frame) then
    return
  end
  frame:SetBackdropColor(BG_MAIN[1], BG_MAIN[2], BG_MAIN[3], BG_MAIN[4])
  frame:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
end

function LeafVE_FrameSkins.ApplyInsetPanel(frame)
  if not EnsureBackdrop(frame) then
    return
  end
  frame:SetBackdropColor(BG_INSET[1], BG_INSET[2], BG_INSET[3], BG_INSET[4])
  frame:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
end

function LeafVE_FrameSkins.ApplyButton(btn, variant)
  if not btn or type(btn.SetBackdrop) ~= "function" then
    return
  end

  local normal = {0.08, 0.12, 0.09, 1.0}
  if variant == "accent" then
    normal = {0.10, 0.35, 0.15, 1.0}
  elseif variant == "danger" then
    normal = {0.30, 0.06, 0.06, 1.0}
  end

  btn:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = {left = 3, right = 3, top = 3, bottom = 3},
  })
  btn:SetBackdropColor(normal[1], normal[2], normal[3], normal[4])
  btn:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])

  if type(btn.SetNormalTexture) == "function" then
    btn:SetNormalTexture(nil)
  end
  if type(btn.SetPushedTexture) == "function" then
    btn:SetPushedTexture(nil)
  end
  if type(btn.SetHighlightTexture) == "function" then
    btn:SetHighlightTexture(nil)
  end

  if btn.GetFontString and btn:GetFontString() then
    btn:GetFontString():SetTextColor(0.92, 0.92, 0.92, 1.0)
  elseif btn.SetTextColor then
    btn:SetTextColor(0.92, 0.92, 0.92, 1.0)
  end

  HookOrSetScript(btn, "OnEnter", function(self)
    self:SetBackdropColor(0.15, 0.40, 0.20, 0.8)
  end)
  HookOrSetScript(btn, "OnLeave", function(self)
    self:SetBackdropColor(normal[1], normal[2], normal[3], normal[4])
  end)
  HookOrSetScript(btn, "OnMouseDown", function(self)
    self:SetBackdropColor(normal[1] * 0.8, normal[2] * 0.8, normal[3] * 0.8, normal[4])
  end)
  HookOrSetScript(btn, "OnMouseUp", function(self)
    self:SetBackdropColor(normal[1], normal[2], normal[3], normal[4])
  end)
end

function LeafVE_FrameSkins.ApplyTab(tab, isActive)
  if not tab or type(tab.SetBackdrop) ~= "function" then
    return
  end

  tab:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = {left = 3, right = 3, top = 3, bottom = 3},
  })

  if isActive then
    tab:SetBackdropColor(0.10, 0.18, 0.12, 0.95)
    tab:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 1.0)
  else
    tab:SetBackdropColor(0.04, 0.06, 0.05, 0.7)
    tab:SetBackdropBorderColor(BORDER[1], BORDER[2], BORDER[3], 0.6)
  end

  local text = tab.GetFontString and tab:GetFontString()
  if text then
    if isActive then
      text:SetTextColor(0.95, 0.95, 0.95, 1.0)
    else
      text:SetTextColor(0.65, 0.65, 0.68, 1.0)
    end
  end

  if not tab._leafVEUnderline then
    local underline = tab:CreateTexture(nil, "ARTWORK")
    underline:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 3, 3)
    underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -3, 3)
    underline:SetHeight(2)
    tab._leafVEUnderline = underline
  end

  if isActive then
    tab._leafVEUnderline:SetVertexColor(0.15, 0.65, 0.25, 1.0)
    tab._leafVEUnderline:Show()
  else
    tab._leafVEUnderline:Hide()
  end
end

function LeafVE_FrameSkins.ApplyHeader(fontString)
  if not fontString then
    return
  end
  fontString:SetFontObject(GameFontNormal)
  fontString:SetTextColor(1.00, 0.84, 0.00, 1.0)
end

function LeafVE_FrameSkins.ApplySubHeader(fontString)
  if not fontString then
    return
  end
  fontString:SetFontObject(GameFontNormalSmall)
  fontString:SetTextColor(0.85, 0.85, 0.85, 1.0)
end

function LeafVE_FrameSkins.ApplyDivider(frame)
  if not frame or type(frame.CreateTexture) ~= "function" then
    return
  end
  if not frame._leafVEDivider then
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    line:SetPoint("LEFT", frame, "LEFT", 0, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetHeight(1)
    frame._leafVEDivider = line
  end
  frame._leafVEDivider:SetVertexColor(0.18, 0.30, 0.20, 0.6)
  frame._leafVEDivider:Show()
end
