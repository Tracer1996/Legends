-- LeafVillageLegends / Ashen Banner tiled main background
-- Kept out of Core.lua so Vanilla Lua 5.0 does not hit the 200 local variable limit.

ASHEN_BG_TILE_ROWS = 4
ASHEN_BG_TILE_COLS = 8

function LeafVE_GetAshenBGLayout()
  LeafVE_AshenBGLayout = LeafVE_AshenBGLayout or {}
  if LeafVE_AshenBGLayout.x == nil then LeafVE_AshenBGLayout.x = 510 end
  if LeafVE_AshenBGLayout.y == nil then LeafVE_AshenBGLayout.y = 20 end
  if LeafVE_AshenBGLayout.w == nil then LeafVE_AshenBGLayout.w = -1040 end
  if LeafVE_AshenBGLayout.h == nil then LeafVE_AshenBGLayout.h = -20 end
  if LeafVE_AshenBGLayout.tileW == nil then LeafVE_AshenBGLayout.tileW = 137 end
  if LeafVE_AshenBGLayout.tileH == nil then LeafVE_AshenBGLayout.tileH = 92 end
  if LeafVE_AshenBGLayout.alpha == nil then LeafVE_AshenBGLayout.alpha = 1 end
  return LeafVE_AshenBGLayout
end

function LeafVE_CreateAshenTileBackground(parent)
  if not parent then return end

  local cfg = LeafVE_GetAshenBGLayout()
  if not parent.ashenBgTiles then parent.ashenBgTiles = {} end

  if not parent._ashenBgHolder then
    parent._ashenBgHolder = CreateFrame("Frame", nil, parent)
    if parent._ashenBgHolder.SetFrameLevel and parent.GetFrameLevel then
      parent._ashenBgHolder:SetFrameLevel((parent:GetFrameLevel() or 1) + 1)
    end
  end

  local pw = parent:GetWidth() or 928
  local ph = parent:GetHeight() or 820
  if pw < 1 then pw = 928 end
  if ph < 1 then ph = 820 end

  local holderW = pw + (cfg.w or 0)
  local holderH = ph + (cfg.h or 0)
  local autoTile = holderH / ASHEN_BG_TILE_ROWS
  local tileW, tileH, totalW, totalH, offsetX, offsetY

  parent._ashenBgHolder:ClearAllPoints()
  parent._ashenBgHolder:SetPoint("TOPLEFT", parent, "TOPLEFT", cfg.x or 0, cfg.y or 0)
  parent._ashenBgHolder:SetWidth(holderW)
  parent._ashenBgHolder:SetHeight(holderH)
  parent._ashenBgHolder:Show()

  -- Default mode keeps the art unstretched: every 256x256 source tile displays square.
  -- Use /abbgtile w h only if you intentionally want manual non-square scaling.
  if cfg.tileW and cfg.tileW ~= 0 then tileW = cfg.tileW else tileW = autoTile end
  if cfg.tileH and cfg.tileH ~= 0 then tileH = cfg.tileH else tileH = autoTile end

  parent._ashenBgTileW = tileW
  parent._ashenBgTileH = tileH
  totalW = tileW * ASHEN_BG_TILE_COLS
  totalH = tileH * ASHEN_BG_TILE_ROWS
  offsetX = math.floor((holderW - totalW) / 2)
  offsetY = math.floor((holderH - totalH) / 2)
  parent._ashenBgOffsetX = offsetX
  parent._ashenBgOffsetY = offsetY

  local row, col, i, tex, suffix
  for row = 1, ASHEN_BG_TILE_ROWS do
    for col = 1, ASHEN_BG_TILE_COLS do
      i = ((row - 1) * ASHEN_BG_TILE_COLS) + col
      tex = parent.ashenBgTiles[i]
      if not tex then
        tex = parent._ashenBgHolder:CreateTexture(nil, "BACKGROUND")
        parent.ashenBgTiles[i] = tex
      end

      suffix = tostring(i)
      if i < 10 then suffix = "0" .. suffix end

      tex:ClearAllPoints()
      tex:SetTexture("Interface\\AddOns\\LeafVillageLegends\\Textures\\ab_bg_" .. suffix)
      tex:SetTexCoord(0, 1, 0, 1)
      tex:SetWidth((tileW or 157) + 1)
      tex:SetHeight((tileH or 157) + 1)

      if row == 1 and col == 1 then
        tex:SetPoint("TOPLEFT", parent._ashenBgHolder, "TOPLEFT", offsetX, offsetY)
      elseif col == 1 then
        tex:SetPoint("TOPLEFT", parent.ashenBgTiles[((row - 2) * ASHEN_BG_TILE_COLS) + 1], "BOTTOMLEFT", 0, 0)
      else
        tex:SetPoint("TOPLEFT", parent.ashenBgTiles[i - 1], "TOPRIGHT", 0, 0)
      end

      tex:SetVertexColor(1, 1, 1, cfg.alpha or 1)
      tex:Show()
    end
  end

  for i = 33, 64 do
    if parent.ashenBgTiles[i] then parent.ashenBgTiles[i]:Hide() end
  end
end

function LeafVE_RefreshAshenBG()
  if LeafVE and LeafVE.UI and LeafVE.UI.frame then
    LeafVE_CreateAshenTileBackground(LeafVE.UI.frame)
  end
end

function LeafVE_DumpAshenBG()
  local c = LeafVE_GetAshenBGLayout()
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenBG:|r x=" .. tostring(c.x or 0) .. " y=" .. tostring(c.y or 0) .. " w=" .. tostring(c.w or 0) .. " h=" .. tostring(c.h or 0) .. " tileW=" .. tostring(c.tileW or 0) .. " tileH=" .. tostring(c.tileH or 0) .. " alpha=" .. tostring(c.alpha or 1))
  end
end

function LeafVE_NudgeAshenBG(field, amount)
  local c = LeafVE_GetAshenBGLayout()
  c[field] = (tonumber(c[field]) or 0) + amount
  LeafVE_RefreshAshenBG()
  LeafVE_DumpAshenBG()
end

function LeafVE_ResetAshenBG()
  LeafVE_AshenBGLayout = { x = 510, y = 20, w = -1040, h = -20, tileW = 137, tileH = 92, alpha = 1 }
  LeafVE_RefreshAshenBG()
  LeafVE_DumpAshenBG()
end

function LeafVE_SetAshenBGFromMsg(msg, fieldA, fieldB)
  local _, _, a, b = string.find(msg or "", "(-?%d+)%s+(-?%d+)")
  local c = LeafVE_GetAshenBGLayout()
  if a then c[fieldA] = tonumber(a) or 0 end
  if b then c[fieldB] = tonumber(b) or 0 end
  LeafVE_RefreshAshenBG()
  LeafVE_DumpAshenBG()
end


function LeafVE_NudgeAshenBGScale(dw, dh)
  local c = LeafVE_GetAshenBGLayout()
  local f = LeafVE and LeafVE.UI and LeafVE.UI.frame
  local curW = tonumber(c.tileW) or 0
  local curH = tonumber(c.tileH) or 0
  if curW == 0 then
    if f and f._ashenBgTileW then curW = math.floor(f._ashenBgTileW) else curW = 157 end
  end
  if curH == 0 then
    if f and f._ashenBgTileH then curH = math.floor(f._ashenBgTileH) else curH = 157 end
  end
  curW = curW + (dw or 0)
  curH = curH + (dh or 0)
  if curW < 48 then curW = 48 end
  if curH < 48 then curH = 48 end
  c.tileW = curW
  c.tileH = curH
  LeafVE_RefreshAshenBG()
  LeafVE_DumpAshenBG()
end

function LeafVE_SetAshenBGScaleFromMsg(msg)
  local _, _, a, b = string.find(msg or "", "(-?%d+)%s*(-?%d*)")
  if not a then return end
  local n1 = tonumber(a)
  local n2 = tonumber(b)
  local c = LeafVE_GetAshenBGLayout()
  if n1 and n2 then
    c.tileW = n1
    c.tileH = n2
  elseif n1 then
    c.tileW = n1
    c.tileH = n1
  end
  LeafVE_RefreshAshenBG()
  LeafVE_DumpAshenBG()
end

function LeafVE_CreateAshenBGEditor()
  if LeafVE_AshenBGEditor and LeafVE_AshenBGEditor:IsVisible() then
    LeafVE_AshenBGEditor:Hide()
    return
  end

  local f = LeafVE_AshenBGEditor
  if not f then
    f = CreateFrame("Frame", "LeafVE_AshenBGEditor", UIParent)
    LeafVE_AshenBGEditor = f
    f:SetWidth(250)
    f:SetHeight(315)
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
    title:SetText("Ashen BG Editor")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    local function MakeBtn(txt, x, y, field, amt)
      local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      b:SetWidth(52)
      b:SetHeight(22)
      b:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
      b:SetText(txt)
      b:SetScript("OnClick", function() LeafVE_NudgeAshenBG(field, amt) end)
      return b
    end

    local function MakeLabel(txt, y)
      local l = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      l:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
      l:SetText(txt)
      return l
    end

    MakeLabel("Move", -38)
    MakeBtn("X-", 70, -34, "x", -10); MakeBtn("X+", 126, -34, "x", 10); MakeBtn("Y+", 182, -34, "y", 10)
    MakeBtn("Y-", 182, -58, "y", -10)

    MakeLabel("Size", -88)
    MakeBtn("W-", 70, -84, "w", -20); MakeBtn("W+", 126, -84, "w", 20)
    MakeBtn("H-", 70, -108, "h", -20); MakeBtn("H+", 126, -108, "h", 20)

    MakeLabel("Tile", -138)
    MakeBtn("TW-", 70, -134, "tileW", -5); MakeBtn("TW+", 126, -134, "tileW", 5)
    MakeBtn("TH-", 70, -158, "tileH", -5); MakeBtn("TH+", 126, -158, "tileH", 5)

    MakeLabel("Overall Scale", -188)
    local scaleDown = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scaleDown:SetWidth(80); scaleDown:SetHeight(22); scaleDown:SetPoint("TOPLEFT", f, "TOPLEFT", 70, -184)
    scaleDown:SetText("Scale -")
    scaleDown:SetScript("OnClick", function() LeafVE_NudgeAshenBGScale(-8, -8) end)

    local scaleUp = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scaleUp:SetWidth(80); scaleUp:SetHeight(22); scaleUp:SetPoint("LEFT", scaleDown, "RIGHT", 8, 0)
    scaleUp:SetText("Scale +")
    scaleUp:SetScript("OnClick", function() LeafVE_NudgeAshenBGScale(8, 8) end)

    local dump = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    dump:SetWidth(70); dump:SetHeight(24); dump:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 14); dump:SetText("Dump")
    dump:SetScript("OnClick", LeafVE_DumpAshenBG)

    local reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reset:SetWidth(70); reset:SetHeight(24); reset:SetPoint("LEFT", dump, "RIGHT", 8, 0); reset:SetText("Reset")
    reset:SetScript("OnClick", LeafVE_ResetAshenBG)

    local refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refresh:SetWidth(70); refresh:SetHeight(24); refresh:SetPoint("LEFT", reset, "RIGHT", 8, 0); refresh:SetText("Refresh")
    refresh:SetScript("OnClick", LeafVE_RefreshAshenBG)
  end
  f:Show()
  LeafVE_RefreshAshenBG()
end

SLASH_LEAFVE_BGDEBUG1 = "/abbgdebug"
SlashCmdList["LEAFVE_BGDEBUG"] = function()
  local f = LeafVE and LeafVE.UI and LeafVE.UI.frame
  if not f then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenBG:|r main frame not built yet")
    return
  end
  LeafVE_CreateAshenTileBackground(f)
  DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenBG:|r using 8x4 safe ROOT tiles, aspect-correct")
  DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenBG:|r holder=" .. math.floor(f._ashenBgHolder:GetWidth() or 0) .. "x" .. math.floor(f._ashenBgHolder:GetHeight() or 0) .. " tile=" .. math.floor(f._ashenBgTileW or 0) .. "x" .. math.floor(f._ashenBgTileH or 0) .. " offset=" .. tostring(f._ashenBgOffsetX or 0) .. "," .. tostring(f._ashenBgOffsetY or 0))
  if f.ashenBgTiles and f.ashenBgTiles[1] and f.ashenBgTiles[1].GetTexture then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenBG:|r first tile=" .. tostring(f.ashenBgTiles[1]:GetTexture()))
  end
  LeafVE_DumpAshenBG()
end

SLASH_LEAFVE_BGEDITOR1 = "/abbgeditor"
SlashCmdList["LEAFVE_BGEDITOR"] = LeafVE_CreateAshenBGEditor

SLASH_LEAFVE_BGDUMP1 = "/abbgdump"
SlashCmdList["LEAFVE_BGDUMP"] = LeafVE_DumpAshenBG

SLASH_LEAFVE_BGMOVE1 = "/abbgmove"
SlashCmdList["LEAFVE_BGMOVE"] = function(msg) LeafVE_SetAshenBGFromMsg(msg, "x", "y") end

SLASH_LEAFVE_BGSIZE1 = "/abbgsize"
SlashCmdList["LEAFVE_BGSIZE"] = function(msg) LeafVE_SetAshenBGFromMsg(msg, "w", "h") end

SLASH_LEAFVE_BGTILE1 = "/abbgtile"
SlashCmdList["LEAFVE_BGTILE"] = function(msg) LeafVE_SetAshenBGFromMsg(msg, "tileW", "tileH") end

SLASH_LEAFVE_BGSCALE1 = "/abbgscale"
SlashCmdList["LEAFVE_BGSCALE"] = LeafVE_SetAshenBGScaleFromMsg
