-- LeafVillageLegends / Ashen Banner: Frame skins
-- Vanilla WoW / Lua 5.0 friendly.
-- IMPORTANT: WoW texture paths do NOT include .tga.

LeafVE_FrameSkins = LeafVE_FrameSkins or {}

-- Set your addon folder here. The default is TheAshenBanner because this UI is branded that way.
-- If your actual folder is different, change ONLY this value.
LeafVE_FrameSkins.ADDON_FOLDER = LeafVE_FrameSkins.ADDON_FOLDER or "LeafVillageLegends"
LeafVE_FrameSkins.TEXTURE_ROOT = "Interface\\AddOns\\" .. LeafVE_FrameSkins.ADDON_FOLDER .. "\\Textures\\"

LeafVE_FrameSkins.TEXTURES = {
  bgSolid       = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_bg_solid",
  bgSmoke       = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_bg_smoke",
  header        = LeafVE_FrameSkins.TEXTURE_ROOT .. "ph",
  panelBorder   = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_panel_border",
  button        = LeafVE_FrameSkins.TEXTURE_ROOT .. "ab_btn",
  buttonHover   = LeafVE_FrameSkins.TEXTURE_ROOT .. "ab_btn_h",
  buttonDown    = LeafVE_FrameSkins.TEXTURE_ROOT .. "ab_btn_d",
  rankPlate     = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_rank_plate",
  scrollTrack   = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_scroll_track",
  scrollThumb   = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_scroll_thumb",
  scrollUp      = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_scroll_arrow_up",
  scrollDown    = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_scroll_arrow_down",
  lockedOverlay = LeafVE_FrameSkins.TEXTURE_ROOT .. "ashen_icon_locked_overlay",
}

local function SafeSetTexCoord(tex, left, right, top, bottom)
  if tex and tex.SetTexCoord and left then
    tex:SetTexCoord(left, right, top, bottom)
  end
end

local function BringForward(frame, level)
  if not frame then return end
  if frame.SetFrameStrata then frame:SetFrameStrata("DIALOG") end
  if frame.SetFrameLevel then frame:SetFrameLevel(level or 80) end
end

local function ClearButtonRegions(btn)
  if not btn then return end
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if btn.SetPushedTexture then btn:SetPushedTexture("") end
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
  if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
end

local function HookOrSetScript(frame, scriptName, fn)
  if not frame or not fn then return end
  if frame.HookScript then
    frame:HookScript(scriptName, fn)
    return
  end
  local old = frame:GetScript(scriptName)
  if old then
    frame:SetScript(scriptName, function()
      old()
      fn(this)
    end)
  else
    frame:SetScript(scriptName, fn)
  end
end

local function AddTexture(frame, key, layer, path, alpha)
  if not frame or not frame.CreateTexture or not path then return nil end
  local tex = frame[key]
  if not tex then
    tex = frame:CreateTexture(nil, layer or "BACKGROUND")
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame[key] = tex
  end
  tex:SetTexture(path)
  tex:SetVertexColor(1, 1, 1, alpha or 1)
  tex:Show()
  return tex
end

local function SetPlainBacking(frame, r, g, b, a)
  if not frame or not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(r or 0.03, g or 0.025, b or 0.02, a or 1)
  frame:SetBackdropBorderColor(0.55, 0.36, 0.18, 1)
end

function LeafVE_FrameSkins.ApplyMainPanel(frame)
  if not frame then return end
  BringForward(frame, 80)
  SetPlainBacking(frame, 0.015, 0.012, 0.010, 1.0)

  -- These two big textures are padded to 1024x1024 for Vanilla compatibility.
  -- Crop to the painted 4:3 area using SetTexCoord.
  local bg = AddTexture(frame, "_leafVE_AshenBg", "BACKGROUND", LeafVE_FrameSkins.TEXTURES.bgSolid, 1.0)
  SafeSetTexCoord(bg, 0, 1, 0, 0.75)

  local border = AddTexture(frame, "_leafVE_AshenBorder", "BORDER", LeafVE_FrameSkins.TEXTURES.panelBorder, 1.0)
  SafeSetTexCoord(border, 0, 1, 0, 0.75)
end

function LeafVE_FrameSkins.ApplyInsetPanel(frame)
  if not frame then return end
  SetPlainBacking(frame, 0.025, 0.022, 0.020, 0.98)
  local tex = AddTexture(frame, "_leafVE_AshenSmoke", "BACKGROUND", LeafVE_FrameSkins.TEXTURES.bgSmoke, 0.88)
  SafeSetTexCoord(tex, 0, 1, 0, 1)
end

function LeafVE_FrameSkins.ApplyHeaderPanel(frame)
  if not frame then return end
  local tex = AddTexture(frame, "_leafVE_AshenHeader", "BACKGROUND", LeafVE_FrameSkins.TEXTURES.header, 1.0)
  SafeSetTexCoord(tex, 0, 1, 0, 1)
end

function LeafVE_FrameSkins.ApplyRankPlate(frame)
  if not frame then return end
  local tex = AddTexture(frame, "_leafVE_AshenRank", "BACKGROUND", LeafVE_FrameSkins.TEXTURES.rankPlate, 1.0)
  SafeSetTexCoord(tex, 0, 1, 0, 1)
end

function LeafVE_FrameSkins.ApplyButton(btn)
  if not btn then return end
  ClearButtonRegions(btn)
  if btn.SetBackdrop then
    btn:SetBackdrop(nil)
  end
  if btn.SetNormalTexture then btn:SetNormalTexture(LeafVE_FrameSkins.TEXTURES.button) end
  if btn.SetPushedTexture then btn:SetPushedTexture(LeafVE_FrameSkins.TEXTURES.buttonDown) end
  if btn.SetHighlightTexture then btn:SetHighlightTexture(LeafVE_FrameSkins.TEXTURES.buttonHover) end

  local fs = btn.GetFontString and btn:GetFontString()
  if fs then
    fs:SetTextColor(1.0, 0.82, 0.15, 1)
  elseif btn.SetTextColor then
    btn:SetTextColor(1.0, 0.82, 0.15, 1)
  end
end

function LeafVE_FrameSkins.ApplyTab(tab, isActive)
  LeafVE_FrameSkins.ApplyButton(tab)
  local fs = tab and tab.GetFontString and tab:GetFontString()
  if fs then
    if isActive then
      fs:SetTextColor(1.0, 0.86, 0.22, 1)
    else
      fs:SetTextColor(0.88, 0.78, 0.62, 1)
    end
  end
end

function LeafVE_FrameSkins.ApplyScrollArrow(btn, dir)
  if not btn then return end
  local tex = dir == "down" and LeafVE_FrameSkins.TEXTURES.scrollDown or LeafVE_FrameSkins.TEXTURES.scrollUp
  if btn.SetNormalTexture then btn:SetNormalTexture(tex) end
  if btn.SetPushedTexture then btn:SetPushedTexture(tex) end
  if btn.SetHighlightTexture then btn:SetHighlightTexture(tex) end
end

function LeafVE_FrameSkins.ApplyScrollThumb(tex)
  if not tex or not tex.SetTexture then return end
  tex:SetTexture(LeafVE_FrameSkins.TEXTURES.scrollThumb)
  tex:SetVertexColor(1, 1, 1, 1)
  -- thumb is padded to 128x512; painted area is 384px tall.
  SafeSetTexCoord(tex, 0, 1, 0, 0.75)
end

function LeafVE_FrameSkins.ApplyScrollBar(scrollBar)
  if not scrollBar then return end
  local name = scrollBar.GetName and scrollBar:GetName()
  local track = AddTexture(scrollBar, "_leafVE_AshenScrollTrack", "BACKGROUND", LeafVE_FrameSkins.TEXTURES.scrollTrack, 1.0)
  SafeSetTexCoord(track, 0, 1, 0, 1)
  if name then
    LeafVE_FrameSkins.ApplyScrollArrow(getglobal(name .. "ScrollUpButton") or getglobal(name .. "UpButton"), "up")
    LeafVE_FrameSkins.ApplyScrollArrow(getglobal(name .. "ScrollDownButton") or getglobal(name .. "DownButton"), "down")
    local thumb = getglobal(name .. "ThumbTexture")
    LeafVE_FrameSkins.ApplyScrollThumb(thumb)
  end
end

function LeafVE_FrameSkins.ApplyLockedIconOverlay(parent)
  if not parent then return nil end
  return AddTexture(parent, "_leafVE_AshenLocked", "OVERLAY", LeafVE_FrameSkins.TEXTURES.lockedOverlay, 1.0)
end

function LeafVE_FrameSkins.ApplyHeader(fontString)
  if not fontString then return end
  fontString:SetFontObject(GameFontNormal)
  fontString:SetTextColor(1.0, 0.80, 0.18, 1)
end

function LeafVE_FrameSkins.ApplySubHeader(fontString)
  if not fontString then return end
  fontString:SetFontObject(GameFontNormalSmall)
  fontString:SetTextColor(0.86, 0.78, 0.65, 1)
end

function LeafVE_FrameSkins.ApplyDivider(frame)
  if not frame or not frame.CreateTexture then return end
  local line = frame._leafVE_AshenDivider
  if not line then
    line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    line:SetPoint("LEFT", frame, "LEFT", 0, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetHeight(1)
    frame._leafVE_AshenDivider = line
  end
  line:SetVertexColor(0.82, 0.45, 0.18, 0.85)
  line:Show()
end

-- Aggressive auto-skin pass.
-- This is here because your main UI already exists elsewhere and may not call every skin helper directly.
-- It scans the currently visible addon window and skins the largest Ashen Banner-looking panel plus buttons.
local function LooksLikeButton(f)
  if not f then return false end
  if f.GetText and f:GetText() then return true end
  if f.GetObjectType and f:GetObjectType() == "Button" then return true end
  return false
end

local function SkinChildren(parent, depth)
  if not parent or depth > 4 or not parent.GetChildren then return end
  local children = { parent:GetChildren() }
  local i
  for i = 1, table.getn(children) do
    local child = children[i]
    if child then
      if LooksLikeButton(child) then
        LeafVE_FrameSkins.ApplyButton(child)
      elseif child.GetWidth and child.GetHeight then
        local w = child:GetWidth() or 0
        local h = child:GetHeight() or 0
        if w > 180 and h > 70 and child.SetBackdrop then
          LeafVE_FrameSkins.ApplyInsetPanel(child)
        end
      end
      SkinChildren(child, depth + 1)
    end
  end
end

function LeafVE_FrameSkins.ForceSkinVisibleWindows()
  if not UIParent or not UIParent.GetChildren then return end
  local children = { UIParent:GetChildren() }
  local i
  for i = 1, table.getn(children) do
    local f = children[i]
    if f and f.IsVisible and f:IsVisible() and f.GetWidth and f.GetHeight then
      local w = f:GetWidth() or 0
      local h = f:GetHeight() or 0
      -- Your main addon window is large. This avoids touching normal small Blizzard frames.
      if w >= 850 and h >= 500 then
        LeafVE_FrameSkins.ApplyMainPanel(f)
        SkinChildren(f, 1)
      end
    end
  end
end

function LeafVE_FrameSkins.InstallAutoSkin()
  -- Disabled on purpose. The Ashen Dossier uses targeted modular textures.
  -- Leaving this no-op prevents the old global scanner from stretching textures over every panel.
end

-- Auto-skin disabled: the dossier now uses targeted modular textures.
-- LeafVE_FrameSkins.InstallAutoSkin()
