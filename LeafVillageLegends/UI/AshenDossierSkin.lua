-- LeafVillageLegends / The Ashen Banner
-- Targeted Banner Dossier texture skin.
-- Vanilla WoW 1.12 / Lua 5.0 friendly.
-- Texture paths intentionally omit .tga.

LeafVE_AshenDossierSkin = LeafVE_AshenDossierSkin or {}
LeafVE_AshenDossierSkin.ADDON_FOLDER = LeafVE_AshenDossierSkin.ADDON_FOLDER or "LeafVillageLegends"
LeafVE_AshenDossierSkin.PATH = "Interface\\AddOns\\" .. LeafVE_AshenDossierSkin.ADDON_FOLDER .. "\\Textures\\"

-- Global helper used by Core.lua for Banner Champion rank icons.
-- Keep this global because Core.lua calls GetAshenRankIcon(rank) directly.
function GetAshenRankIcon(rank)
  rank = tonumber(rank)
  if rank and rank >= 1 and rank <= 5 then
    return "Interface\\AddOns\\LeafVillageLegends\\Textures\\ashen_rank_" .. rank
  end
  return nil
end

function LeafVE_AshenDossierSkin:GetAshenRankIcon(rank)
  return GetAshenRankIcon(rank)
end


-- SavedVariables-style table for live in-game layout tuning.
-- Commands below write into this table so you can /abdump the final values.
LeafVE_AshenDossierLayout = LeafVE_AshenDossierLayout or {}

LeafVE_AshenDossierSkin.DEFAULT_LAYOUT = {
  hero         = { x = 2,   y = 0,    w = 26,  h = 282, bleed = 0  },
  note         = { x = 18,  y = -108, w = 136, h = 134, bleed = 0  },
  wisdom       = { x = -16, y = -110, w = 144, h = 136, bleed = 2  },
  portrait     = { x = 0,   y = -102, w = 126, h = 156, bleed = 0  },
  rank         = { x = -4,  y = -270, w = 382, h = 30,  bleed = 4  },
  recent       = { x = 16,  y = -44,  w = 210, h = 280, bleed = 28 },
  achievements = { x = 10,  y = -22,  w = 228, h = 322, bleed = 8  },
  name         = { x = -4,  y = -25,  w = 30,  h = 22,  bleed = 0, align = "CENTER" },
  classText    = { x = -4,  y = -54,  w = 360, h = 34,  bleed = 0, align = "CENTER" },
  topSpec      = { x = 0,   y = -48,  w = 220, h = 16,  bleed = 0, align = "CENTER" },
  specBtn      = { x = 130, y = -66,  w = 116, h = 20,  bleed = 0, align = "CENTER" },
  wisdomTitle  = { x = -4,  y = -4,   w = 118, h = 0,   bleed = 0, align = "CENTER" },
  wisdomQuote  = { x = 8,   y = -38,  w = 112, h = 0,   bleed = 0, align = "CENTER" },
  wisdomAuthor = { x = 8,   y = -88,  w = 112, h = 0,   bleed = 0, align = "CENTER" },
  recentText   = { x = 12,  y = -16,  w = 186, h = 0,   bleed = 0, align = "LEFT" },
  recentBadges = { x = 4,   y = -36,  w = 188, h = 150, bleed = 0  },
  recentView   = { x = 2,   y = -190, w = 178, h = 24,  bleed = 0, align = "CENTER" },
  recentGear   = { x = 2,   y = -222, w = 178, h = 24,  bleed = 0, align = "CENTER" },
  recentProf   = { x = 2,   y = -256, w = 178, h = 24,  bleed = 0, align = "CENTER" },
  achPoints    = { x = 0,   y = -26,  w = 188, h = 0,   bleed = 0, align = "LEFT" },
  achSummary   = { x = 20,  y = -42,  w = 188, h = 0,   bleed = 0, align = "LEFT" },
  achList      = { x = -20, y = -64,  w = 188, h = 118, bleed = 0  },
  achView      = { x = 28,  y = -212, w = 178, h = 26,  bleed = 0, align = "CENTER" },
  achTalent    = { x = -28, y = -244, w = 178, h = 26,  bleed = 0, align = "CENTER" },
  achWork      = { x = 28,  y = -280, w = 178, h = 24,  bleed = 0, align = "CENTER" },
  pageHeader   = { x = -1,  y = -32,  w = 134, h = 56,  bleed = 0, align = "CENTER" },
  headerMe         = { x = -9,  y = -30, w = 510, h = 126, bleed = 0, align = "CENTER" },
  headerWeek       = { x = 15,  y = 28,  w = 510, h = 112, bleed = 0, align = "CENTER" },
  headerLife       = { x = -15, y = -42, w = 510, h = 142, bleed = 0, align = "CENTER" },
  headerAch        = { x = 15,  y = 34,  w = 510, h = 122, bleed = 0, align = "CENTER" },
  headerRep        = { x = -17, y = -38, w = 504, h = 136, bleed = 0, align = "CENTER" },
  headerBadges     = { x = 15,  y = 34,  w = 520, h = 140, bleed = 0, align = "CENTER" },
  headerTitles     = { x = 15,  y = -26, w = 520, h = 120, bleed = 0, align = "CENTER" },
  headerRoster     = { x = 9,   y = -4,  w = 520, h = 92,  bleed = 0, align = "CENTER" },
  headerShoutouts  = { x = -21, y = -50, w = 552, h = 170, bleed = 0, align = "CENTER" },
  headerWelcome    = { x = -15, y = -4,  w = 598, h = 184, bleed = 0, align = "CENTER" },
}

LeafVE_AshenDossierSkin.EDITOR_PIECES = {
  "hero", "note", "wisdom", "portrait", "rank", "recent", "achievements",
  "name", "classText", "topSpec", "specBtn",
  "wisdomTitle", "wisdomQuote", "wisdomAuthor",
  "recentText", "recentBadges", "recentView", "recentGear", "recentProf",
  "achPoints", "achSummary", "achList", "achView", "achTalent", "achWork", "pageHeader",
}

LeafVE_AshenDossierSkin.EDITOR_LABELS = {
  hero = "Hero", note = "Note", wisdom = "Wisdom", portrait = "Portrait", rank = "Rank", recent = "Recent", achievements = "Achieve",
  name = "Name", classText = "Level", topSpec = "TopSpec", specBtn = "Spec Btn",
  wisdomTitle = "WisTitle", wisdomQuote = "WisQuote", wisdomAuthor = "WisAuth",
  recentText = "R Text", recentBadges = "R Badges", recentView = "R View", recentGear = "R Gear", recentProf = "R Prof",
  achPoints = "A Points", achSummary = "A Summary", achList = "A List", achView = "A View", achTalent = "A Talent", achWork = "A Work", pageHeader = "Header",
}

LeafVE_AshenDossierSkin.PAGE_HEADER_LAYOUT_KEYS = {
  me = "headerMe",
  leaderWeek = "headerWeek",
  leaderLife = "headerLife",
  achievements = "headerAch",
  shinobiReputation = "headerRep",
  badges = "headerBadges",
  titles = "headerTitles",
  roster = "headerRoster",
  shoutouts = "headerShoutouts",
  welcome = "headerWelcome",
  workOrderRep = "headerRep",
  shinobiDuties = "headerWeek",
  bannerDutyBoard = "headerRep",
  bannerDutyLive = "headerRoster",
}

LeafVE_AshenDossierSkin.PAGE_HEADER_TEXTURES = {}

LeafVE_AshenDossierSkin.PAGE_HEADER_EDITOR_PIECES = {
  "headerMe", "headerWeek", "headerLife", "headerAch", "headerRep",
  "headerBadges", "headerTitles", "headerRoster", "headerShoutouts", "headerWelcome",
}

LeafVE_AshenDossierSkin.PAGE_HEADER_EDITOR_LABELS = {
  headerMe = "H MyStats",
  headerWeek = "H Weekly",
  headerLife = "H Lifetime",
  headerAch = "H Achieve",
  headerRep = "H Rep",
  headerBadges = "H Badges",
  headerTitles = "H Titles",
  headerRoster = "H Roster",
  headerShoutouts = "H Shouts",
  headerWelcome = "H Welcome",
}

-- Hardcode the approved layout once so older SavedVariables from the live editor do not override it.
LeafVE_AshenDossierSkin.LAYOUT_VERSION = 35
if LeafVE_AshenDossierLayout.__layoutVersion ~= LeafVE_AshenDossierSkin.LAYOUT_VERSION then
  local k, v
  for k, v in pairs(LeafVE_AshenDossierSkin.DEFAULT_LAYOUT) do
    LeafVE_AshenDossierLayout[k] = {
      x = v.x,
      y = v.y,
      w = v.w,
      h = v.h,
      bleed = v.bleed,
      align = v.align,
    }
  end
  LeafVE_AshenDossierLayout.editorButton = { x = 375, y = 25 }
  LeafVE_AshenDossierLayout.editorFrame = { x = 488, y = 18 }
  LeafVE_AshenDossierLayout.__layoutVersion = LeafVE_AshenDossierSkin.LAYOUT_VERSION
end

function LeafVE_AshenDossierSkin:Print(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700AshenLayout:|r " .. tostring(msg)) end
end

function LeafVE_AshenDossierSkin:GetLayout(piece)
  if not piece then return nil end
  if not LeafVE_AshenDossierLayout[piece] then LeafVE_AshenDossierLayout[piece] = {} end
  return LeafVE_AshenDossierLayout[piece]
end

function LeafVE_AshenDossierSkin:GetDefault(piece)
  return self.DEFAULT_LAYOUT and self.DEFAULT_LAYOUT[piece]
end

function LeafVE_AshenDossierSkin:GetVal(piece, key)
  local d = self:GetDefault(piece)
  local l = self:GetLayout(piece)
  if l and l[key] ~= nil then return l[key] end
  if d then return d[key] end
  return nil
end

function LeafVE_AshenDossierSkin:SetVal(piece, key, val)
  if not self.DEFAULT_LAYOUT[piece] then self:Print("Unknown piece: " .. tostring(piece)); return end
  local l = self:GetLayout(piece)
  l[key] = val
end

function LeafVE_AshenDossierSkin:PieceList()
  local out = ""
  local i
  for i = 1, table.getn(self.EDITOR_PIECES) do
    if i > 1 then out = out .. ", " end
    out = out .. self.EDITOR_PIECES[i]
  end
  return out
end

-- Original art size vs padded power-of-two file size.
-- The files in Textures/ are padded for Vanilla compatibility; SetTexCoord crops the transparent padding.
LeafVE_AshenDossierSkin.CROP = {
  ashen_button_red            = {179, 48, 256, 64},
  ashen_button_red_down       = {180, 48, 256, 64},
  ashen_button_red_hover      = {195, 48, 256, 64},
  dossier_bg                  = {329, 193, 512, 256},
  dossier_border              = {316, 179, 512, 256},
  dbor_1                      = {256, 256, 256, 256},
  dbor_2                      = {256, 256, 256, 256},
  ph                          = {256, 30, 256, 256},
  th_01                       = {0, 512, 0, 128, 512, 128},
  th_02                       = {0, 512, 0, 128, 512, 128},
  th_03                       = {0, 512, 0, 128, 512, 128},
  th_04                       = {0, 512, 0, 128, 512, 128},
  th_05                       = {0, 512, 0, 128, 512, 128},
  th_06                       = {0, 512, 0, 128, 512, 128},
  th_07                       = {0, 512, 0, 128, 512, 128},
  th_08                       = {0, 512, 0, 128, 512, 128},
  th_09                       = {0, 512, 0, 128, 512, 128},
  th_10                       = {0, 512, 0, 128, 512, 128},
  dossier_bottom_bg           = {512, 256, 512, 256},
  dossier_bottom_border       = {512, 256, 512, 256},
  -- These use 6-value crop mode: left, right, top, bottom, fileWidth, fileHeight.
  -- This crops away transparent margin and visually zooms the custom panels into the box.
  recent_badges_panel_full    = {0, 256, 0, 512, 256, 512},
  achievements_panel_full     = {0, 256, 0, 512, 256, 512},
  dossier_name_underline      = {258, 34, 512, 64},
  dossier_note_button         = {185, 42, 256, 64},
  dossier_note_button_down    = {185, 42, 256, 64},
  dossier_note_button_hover   = {185, 42, 256, 64},
  dossier_note_header         = {185, 12, 256, 16},
  dossier_note_panel          = {205, 250, 256, 256},
  dossier_portrait_bg         = {158, 249, 256, 256},
  dossier_portrait_frame      = {176, 273, 256, 512},
  dossier_portrait_pedestal   = {231, 56, 256, 64},
  dossier_rank_icon           = {65, 65, 128, 128},
  ashen_rank_1                = {64, 64, 64, 64},
  ashen_rank_2                = {64, 64, 64, 64},
  ashen_rank_3                = {64, 64, 64, 64},
  ashen_rank_4                = {64, 64, 64, 64},
  ashen_rank_5                = {64, 64, 64, 64},
  dossier_rank_plate          = {412, 59, 512, 64},
  dossier_side_banner_left    = {102, 270, 128, 512},
  dossier_side_banner_right   = {105, 270, 128, 512},
  dossier_spec_button         = {0, 256, 0, 64, 256, 64},
  dossier_spec_button_down    = {0, 256, 0, 64, 256, 64},
  dossier_spec_button_hover   = {0, 256, 0, 64, 256, 64},
  dossier_title_tab           = {259, 66, 512, 128},
  dossier_wisdom_emblem       = {122, 85, 128, 128},
  dossier_wisdom_header       = {188, 13, 256, 16},
  dossier_wisdom_panel        = {212, 278, 256, 512},
}

function LeafVE_AshenDossierSkin:Tex(name)
  return self.PATH .. name
end

function LeafVE_AshenDossierSkin:Crop(tex, name)
  if not tex or not tex.SetTexCoord then return end
  local c = self.CROP[name]
  if c then
    if table.getn(c) >= 6 then
      tex:SetTexCoord(c[1] / c[5], c[2] / c[5], c[3] / c[6], c[4] / c[6])
    else
      tex:SetTexCoord(0, c[1] / c[3], 0, c[2] / c[4])
    end
  else
    tex:SetTexCoord(0, 1, 0, 1)
  end
end

function LeafVE_AshenDossierSkin:SetTexture(tex, name, alpha)
  if not tex then return nil end
  tex:SetTexture(self:Tex(name))
  self:Crop(tex, name)
  if tex.SetVertexColor then
    tex:SetVertexColor(1, 1, 1, alpha or 1)
  end
  tex:Show()
  return tex
end

function LeafVE_AshenDossierSkin:ClearBackdrop(frame)
  if frame and frame.SetBackdrop then
    frame:SetBackdrop(nil)
  end
end

function LeafVE_AshenDossierSkin:MakeTexture(frame, key, layer, name, alpha)
  if not frame or not frame.CreateTexture then return nil end
  local tex = frame[key]
  if not tex then
    tex = frame:CreateTexture(nil, layer or "BACKGROUND")
    frame[key] = tex
  end
  tex:ClearAllPoints()
  tex:SetAllPoints(frame)
  self:SetTexture(tex, name, alpha)
  return tex
end

function LeafVE_AshenDossierSkin:MakeAnchoredTexture(parent, key, layer, name, width, height, point, relativeTo, relativePoint, x, y, alpha)
  if not parent or not parent.CreateTexture then return nil end
  local tex = parent[key]
  if not tex then
    tex = parent:CreateTexture(nil, layer or "ARTWORK")
    parent[key] = tex
  end
  tex:ClearAllPoints()
  tex:SetWidth(width)
  tex:SetHeight(height)
  tex:SetPoint(point or "CENTER", relativeTo or parent, relativePoint or point or "CENTER", x or 0, y or 0)
  self:SetTexture(tex, name, alpha)
  return tex
end

function LeafVE_AshenDossierSkin:SkinButton(button, normalName, hoverName, downName)
  if not button then return end
  if button.SetBackdrop then button:SetBackdrop(nil) end

  if button.SetNormalTexture then button:SetNormalTexture(self:Tex(normalName)) end
  if button.GetNormalTexture and button:GetNormalTexture() then self:Crop(button:GetNormalTexture(), normalName) end

  if button.SetHighlightTexture then button:SetHighlightTexture(self:Tex(hoverName or normalName)) end
  if button.GetHighlightTexture and button:GetHighlightTexture() then self:Crop(button:GetHighlightTexture(), hoverName or normalName) end

  if button.SetPushedTexture then button:SetPushedTexture(self:Tex(downName or normalName)) end
  if button.GetPushedTexture and button:GetPushedTexture() then self:Crop(button:GetPushedTexture(), downName or normalName) end

  local fs = button.GetFontString and button:GetFontString()
  if fs then
    fs:SetTextColor(1.0, 0.82, 0.28)
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
  end
end


function LeafVE_AshenDossierSkin:HideLabel(widget)
  if not widget then return end
  if widget.Hide then widget:Hide() end
end

function LeafVE_AshenDossierSkin:HideButtonText(button)
  if not button then return end
  local fs = button.GetFontString and button:GetFontString()
  if fs then
    fs:SetText("")
    if fs.SetAlpha then fs:SetAlpha(0) end
    if fs.Hide then fs:Hide() end
  end
end

function LeafVE_AshenDossierSkin:BringFrameAbove(frame, referenceFrame, bump)
  if not frame or not frame.SetFrameLevel then return end
  local base = 1
  if referenceFrame and referenceFrame.GetFrameLevel then
    base = referenceFrame:GetFrameLevel() or 1
  end
  frame:SetFrameLevel(base + (bump or 10))
end

function LeafVE_AshenDossierSkin:HideFrameTextures(frame)
  if not frame or not frame.GetRegions then return end
  local regions = { frame:GetRegions() }
  local i
  for i = 1, table.getn(regions) do
    local r = regions[i]
    if r and r.GetObjectType and r:GetObjectType() == "Texture" and r.Hide then
      r:Hide()
    end
  end
end

function LeafVE_AshenDossierSkin:SkinBottomPanel(panel, assetName)
  if not panel then return end
  self:ClearBackdrop(panel)
  self:HideFrameTextures(panel)

  -- Solid dark fill behind the custom art. This fixes transparent/cleaned areas
  -- and prevents the white checkerboard-looking source background from showing.
  local fill = panel._abSectionDarkFill
  if not fill then
    fill = panel:CreateTexture(nil, "BACKGROUND")
    panel._abSectionDarkFill = fill
  end
  fill:ClearAllPoints()
  fill:SetAllPoints(panel)
  fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  if fill.SetVertexColor then fill:SetVertexColor(0, 0, 0, 1) end
  fill:Show()

  local art = panel._abSectionArt
  if not art then
    art = panel:CreateTexture(nil, "BORDER")
    panel._abSectionArt = art
  end
  art:ClearAllPoints()
  -- Let the art bleed slightly past the panel edges so the frame fills the box.
  local piece = panel._abLayoutPiece or "recent"
  local bleed = self:GetVal(piece, "bleed") or 10
  art:SetPoint("TOPLEFT", panel, "TOPLEFT", -bleed, bleed)
  art:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", bleed, -bleed)
  self:SetTexture(art, assetName, 1)
  art:Show()
end

function LeafVE_AshenDossierSkin:SkinDossierShell(ui)
  local hero = ui and ui.cardHeroPanel
  if not hero then return end

  self:ClearBackdrop(hero)
  self:MakeTexture(hero, "_abDossierBG", "BACKGROUND", "dossier_bg", 1)

  -- New custom dossier border is split into short 256x256 root-safe textures.
  -- Keep dossier_bg underneath; these are only the transparent top/side border art.
  if hero._abDossierBorder and hero._abDossierBorder.Hide then
    hero._abDossierBorder:Hide()
  end

  local borderL = hero._abDossierBorderL
  if not borderL then
    borderL = hero:CreateTexture(nil, "BORDER")
    hero._abDossierBorderL = borderL
  end
  borderL:ClearAllPoints()
  borderL:SetPoint("TOPLEFT", hero, "TOPLEFT", -3, 3)
  borderL:SetPoint("BOTTOMRIGHT", hero, "BOTTOM", 0, -3)
  self:SetTexture(borderL, "dbor_1", 1)

  local borderR = hero._abDossierBorderR
  if not borderR then
    borderR = hero:CreateTexture(nil, "BORDER")
    hero._abDossierBorderR = borderR
  end
  borderR:ClearAllPoints()
  borderR:SetPoint("TOPLEFT", hero, "TOP", 0, 3)
  borderR:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 3, -3)
  self:SetTexture(borderR, "dbor_2", 1)

  if ui.cardHeroAccent then ui.cardHeroAccent:Hide() end
  if ui.cardHeroGlow then ui.cardHeroGlow:Hide() end

  local tab = self:MakeAnchoredTexture(hero, "_abDossierTitleTab", "ARTWORK", "dossier_title_tab", 172, 40, "TOPLEFT", hero, "TOPLEFT", 10, -3, 1)
  if ui.cardTitle then
    ui.cardTitle:ClearAllPoints()
    ui.cardTitle:SetParent(hero)
    ui.cardTitle:SetPoint("LEFT", tab, "LEFT", 20, -1)
    ui.cardTitle:SetTextColor(1.0, 0.82, 0.36)
    if ui.cardTitle.SetShadowColor then ui.cardTitle:SetShadowColor(0, 0, 0, 1) end
    if ui.cardTitle.SetShadowOffset then ui.cardTitle:SetShadowOffset(1, -1) end
    self:HideLabel(ui.cardTitle)
  end

  if ui.cardName then
    ui.cardName:ClearAllPoints()
    ui.cardName:SetParent(hero)
    ui.cardName:SetPoint("TOP", hero, "TOP", 0, -1)
  end
  if ui.cardClassLevelRank then
    ui.cardClassLevelRank:ClearAllPoints()
    ui.cardClassLevelRank:SetParent(hero)
    ui.cardClassLevelRank:SetPoint("TOP", ui.cardName or hero, ui.cardName and "BOTTOM" or "TOP", 0, ui.cardName and -2 or -28)
  end
  if ui.cardTopSpecText then
    ui.cardTopSpecText:ClearAllPoints()
    ui.cardTopSpecText:SetParent(hero)
    ui.cardTopSpecText:SetPoint("TOP", ui.cardClassLevelRank or hero, "BOTTOM", 0, -2)
  end

  self:MakeAnchoredTexture(hero, "_abDossierNameUnderline", "ARTWORK", "dossier_name_underline", 180, 22, "TOP", hero, "TOP", 0, -45, 0.9)
end

function LeafVE_AshenDossierSkin:SkinNote(ui)
  local box = ui and (ui.cardNotesBox or (ui.cardNotesEdit and ui.cardNotesEdit:GetParent()))
  if not box then return end
  self:ClearBackdrop(box)
  self:HideFrameTextures(box)
  box:SetWidth(138)
  box:SetHeight(116)
  box:ClearAllPoints()
  box:SetPoint("TOPLEFT", ui.cardHeroPanel, "TOPLEFT", 18, -102)
  self:MakeTexture(box, "_abNotePanel", "ARTWORK", "dossier_note_panel", 1)

  if ui.cardNotesEdit then
    ui.cardNotesEdit:ClearAllPoints()
    ui.cardNotesEdit:SetPoint("TOPLEFT", box, "TOPLEFT", 12, -34)
    ui.cardNotesEdit:SetWidth(112)
    ui.cardNotesEdit:SetHeight(56)
    ui.cardNotesEdit:SetTextColor(0.72, 0.72, 1.0, 1)
    if ui.cardNotesEdit.SetBackdrop then ui.cardNotesEdit:SetBackdrop(nil) end
    self:BringFrameAbove(ui.cardNotesEdit, box, 8)
  end

  if ui.cardSaveNoteBtn then
    self:BringFrameAbove(ui.cardSaveNoteBtn, box, 12)
    ui.cardSaveNoteBtn:ClearAllPoints()
    ui.cardSaveNoteBtn:SetPoint("BOTTOM", box, "BOTTOM", 0, 8)
    ui.cardSaveNoteBtn:SetWidth(102)
    ui.cardSaveNoteBtn:SetHeight(20)
    self:SkinButton(ui.cardSaveNoteBtn, "dossier_note_button", "dossier_note_button_hover", "dossier_note_button_down")
    self:HideButtonText(ui.cardSaveNoteBtn)
  end
end

function LeafVE_AshenDossierSkin:SkinWisdom(ui)
  local box = ui and ui.cardWisdomBox
  if not box then return end

  self:ClearBackdrop(box)
  self:HideFrameTextures(box)
  box:SetWidth(138)
  box:SetHeight(116)
  box:ClearAllPoints()
  box:SetPoint("TOPRIGHT", ui.cardHeroPanel, "TOPRIGHT", -18, -102)
  self:MakeTexture(box, "_abWisdomPanel", "ARTWORK", "dossier_wisdom_panel", 1)

  self:MakeAnchoredTexture(box, "_abWisdomEmblem", "OVERLAY", "dossier_wisdom_emblem", 42, 30, "BOTTOM", box, "BOTTOM", 0, 6, 0.9)
end

function LeafVE_AshenDossierSkin:SkinPortrait(ui)
  local p = ui and ui.cardPortraitContainer
  local hero = ui and ui.cardHeroPanel
  if not p or not hero then return end

  self:ClearBackdrop(p)
  p:SetWidth(134)
  p:SetHeight(150)
  -- Do not force the point here. ShowPlayerCard positions it based on spec visibility.

  local blackFill = p._abPortraitBlackFill
  if not blackFill then
    blackFill = p:CreateTexture(nil, "BACKGROUND")
    p._abPortraitBlackFill = blackFill
  end
  blackFill:ClearAllPoints()
  blackFill:SetAllPoints(p)
  blackFill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  if blackFill.SetVertexColor then blackFill:SetVertexColor(0, 0, 0, 1) end
  blackFill:Show()

  if ui.cardModelBG then
    ui.cardModelBG:ClearAllPoints()
    ui.cardModelBG:SetAllPoints(p)
    self:SetTexture(ui.cardModelBG, "dossier_portrait_bg", 1)
    ui.cardModelBG:Show()
  else
    self:MakeTexture(p, "_abPortraitBG", "BACKGROUND", "dossier_portrait_bg", 1)
  end

  -- Dedicated overlay frame so the portrait frame and side banners can sit ABOVE
  -- the Player Note and Wisdom panels instead of being hidden behind them.
  local overlay = hero._abPortraitOverlay
  if not overlay then
    overlay = CreateFrame("Frame", nil, hero)
    hero._abPortraitOverlay = overlay
  end
  overlay:ClearAllPoints()
  overlay:SetAllPoints(hero)
  if overlay.SetFrameLevel then overlay:SetFrameLevel((hero:GetFrameLevel() or 1) + 40) end
  if overlay.EnableMouse then overlay:EnableMouse(nil) end

  local frameTex = overlay._abPortraitFrame
  if not frameTex then
    frameTex = overlay:CreateTexture(nil, "OVERLAY")
    overlay._abPortraitFrame = frameTex
  end
  frameTex:ClearAllPoints()
  frameTex:SetPoint("TOPLEFT", p, "TOPLEFT", -12, 16)
  frameTex:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 12, -12)
  self:SetTexture(frameTex, "dossier_portrait_frame", 1)

  self:MakeAnchoredTexture(overlay, "_abPortraitLeftBanner", "OVERLAY", "dossier_side_banner_left", 34, 118, "RIGHT", p, "LEFT", -2, -1, 1)
  self:MakeAnchoredTexture(overlay, "_abPortraitRightBanner", "OVERLAY", "dossier_side_banner_right", 34, 118, "LEFT", p, "RIGHT", 2, -1, 1)

  self:BringFrameAbove(p, hero, 45)
  if ui.cardModel then self:BringFrameAbove(ui.cardModel, p, 1) end
  if ui.cardClassIconFrame then self:BringFrameAbove(ui.cardClassIconFrame, p, 1) end
end

function LeafVE_AshenDossierSkin:SkinRank(ui)
  local panel = ui and ui.cardStatusPanel
  if not panel then return end
  self:ClearBackdrop(panel)
  panel:SetHeight(30)
  self:MakeTexture(panel, "_abRankPlate", "BACKGROUND", "dossier_rank_plate", 1)

  if ui.cardStatusAccent then ui.cardStatusAccent:Hide() end

  if ui.cardWorkOrderRepBadge then
    self:ClearBackdrop(ui.cardWorkOrderRepBadge)
    ui.cardWorkOrderRepBadge:SetHeight(20)
    ui.cardWorkOrderRepBadge:SetWidth(156)
    self:SkinButton(ui.cardWorkOrderRepBadge, "dossier_rank_plate", "dossier_rank_plate", "dossier_rank_plate")
  end
  if ui.cardWorkOrderRepBadgeIcon then
    ui.cardWorkOrderRepBadgeIcon:SetTexture(self:Tex("ashen_rank_1"))
    self:Crop(ui.cardWorkOrderRepBadgeIcon, "ashen_rank_1")
    ui.cardWorkOrderRepBadgeIcon:SetVertexColor(1, 1, 1, 1)
  end
end

function LeafVE_AshenDossierSkin:SkinSpec(ui)
  if not ui then return end
  if ui.cardSpecCycleBtn then
    ui.cardSpecCycleBtn:SetWidth(116)
    ui.cardSpecCycleBtn:SetHeight(20)
    self:SkinButton(ui.cardSpecCycleBtn, "dossier_spec_button", "dossier_spec_button_hover", "dossier_spec_button_down")
  end
end

function LeafVE_AshenDossierSkin:SkinBottomShell(ui)
  if not ui then return end

  local left = ui.cardRecentBadgesPanel
  local right = ui.cardAchievementsPanel
  if not left or not right then return end

  left._abLayoutPiece = "recent"
  right._abLayoutPiece = "achievements"
  self:SkinBottomPanel(left, "recent_badges_panel_full")
  self:SkinBottomPanel(right, "achievements_panel_full")

  if ui.cardRecentBadgesLabel then self:HideLabel(ui.cardRecentBadgesLabel) end
  if ui.cardAchievementsLabel then self:HideLabel(ui.cardAchievementsLabel) end

  if ui.cardRecentBadgesSummary then
    ui.cardRecentBadgesSummary:ClearAllPoints()
    ui.cardRecentBadgesSummary:SetPoint("TOPLEFT", left, "TOPLEFT", 16, -42)
    ui.cardRecentBadgesSummary:SetWidth(188)
  end
  if ui.cardRecentBadgesFrame and ui.cardRecentBadgesSummary then
    ui.cardRecentBadgesFrame:ClearAllPoints()
    ui.cardRecentBadgesFrame:SetPoint("TOPLEFT", ui.cardRecentBadgesSummary, "BOTTOMLEFT", 0, -12)
    ui.cardRecentBadgesFrame:SetWidth(188)
    ui.cardRecentBadgesFrame:SetHeight(150)
  end

  if ui.cardAchPoints then
    ui.cardAchPoints:ClearAllPoints()
    ui.cardAchPoints:SetPoint("TOPLEFT", right, "TOPLEFT", 16, -42)
    ui.cardAchPoints:SetWidth(188)
  end
  if ui.cardAchSummary then
    ui.cardAchSummary:ClearAllPoints()
    ui.cardAchSummary:SetPoint("TOPLEFT", ui.cardAchPoints, "BOTTOMLEFT", 0, -4)
    ui.cardAchSummary:SetWidth(188)
  end

  -- Hide the duplicated small section title only if we can locate it as a region fontstring.
  local regions = { right:GetRegions() }
  local i
  for i = 1, table.getn(regions) do
    local r = regions[i]
    if r and r.GetObjectType and r:GetObjectType() == "FontString" and r.GetText then
      local txt = r:GetText()
      if txt and string.find(txt, "Recent Achievements") then
        r:Hide()
      end
    end
  end

  if ui.cardRecentAchFrame and ui.cardAchSummary then
    ui.cardRecentAchFrame:ClearAllPoints()
    ui.cardRecentAchFrame:SetPoint("TOPLEFT", ui.cardAchSummary, "BOTTOMLEFT", 0, -16)
    ui.cardRecentAchFrame:SetWidth(188)
    ui.cardRecentAchFrame:SetHeight(116)
  end

  -- Keep bottom action buttons above the decorative panel art.
  self:BringFrameAbove(ui.viewAllBadgesBtn, left, 20)
  self:BringFrameAbove(ui.cardGearBtn, left, 20)
  self:BringFrameAbove(ui.cardProfessionBtn, left, 20)
  self:BringFrameAbove(ui.cardViewAllBtn, right, 20)
  self:BringFrameAbove(ui.cardTalentBtn, right, 20)
  self:BringFrameAbove(ui.cardWorkOrderBtn, right, 20)
end


function LeafVE_AshenDossierSkin:ApplyTextLayout(fs, piece, parent, point, relPoint)
  if not fs or not parent then return end
  local x = self:GetVal(piece, "x") or 0
  local y = self:GetVal(piece, "y") or 0
  local w = self:GetVal(piece, "w") or 0
  local h = self:GetVal(piece, "h") or 0
  local align = self:GetVal(piece, "align") or "LEFT"
  fs:ClearAllPoints()
  fs:SetPoint(point or "TOPLEFT", parent, relPoint or point or "TOPLEFT", x, y)
  if w and w > 0 and fs.SetWidth then fs:SetWidth(w) end
  if h and h > 0 and fs.SetHeight then fs:SetHeight(h) end
  if fs.SetJustifyH then fs:SetJustifyH(align) end
end

function LeafVE_AshenDossierSkin:ApplyFrameLayout(frame, piece, parent)
  if not frame or not parent then return end
  local x = self:GetVal(piece, "x") or 0
  local y = self:GetVal(piece, "y") or 0
  self:SetFrameSize(frame, piece)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end

function LeafVE_AshenDossierSkin:ApplyTopCenterLayout(frame, piece, parent)
  if not frame or not parent then return end
  local x = self:GetVal(piece, "x") or 0
  local y = self:GetVal(piece, "y") or 0
  self:SetFrameSize(frame, piece)
  frame:ClearAllPoints()
  frame:SetPoint("TOP", parent, "TOP", x, y)
end

function LeafVE_AshenDossierSkin:ApplyButtonTextAlign(button, piece)
  if not button or not button.GetFontString then return end
  local fs = button:GetFontString()
  if fs and fs.SetJustifyH then fs:SetJustifyH(self:GetVal(piece, "align") or "CENTER") end
end

function LeafVE_AshenDossierSkin:SetFrameSize(frame, piece)
  if not frame then return end
  local w = self:GetVal(piece, "w")
  local h = self:GetVal(piece, "h")
  if w and w > 0 and frame.SetWidth then frame:SetWidth(w) end
  if h and h > 0 and frame.SetHeight then frame:SetHeight(h) end
end

function LeafVE_AshenDossierSkin:ApplyLayout(ui)
  if not ui or not ui.cardHeroPanel then return end
  local hero = ui.cardHeroPanel
  local card = ui.card or (hero.GetParent and hero:GetParent())

  if card then
    self:SetFrameSize(hero, "hero")
    hero:ClearAllPoints()
    hero:SetPoint("TOPLEFT", card, "TOPLEFT", 10 + (self:GetVal("hero", "x") or 0), -10 + (self:GetVal("hero", "y") or 0))
    hero:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10 + (self:GetVal("hero", "x") or 0), -10 + (self:GetVal("hero", "y") or 0))
  end

  if ui.cardName then self:ApplyTopCenterLayout(ui.cardName, "name", hero) end
  if ui.cardClassLevelRank then self:ApplyTopCenterLayout(ui.cardClassLevelRank, "classText", hero) end
  if ui.cardTopSpecText then self:ApplyTopCenterLayout(ui.cardTopSpecText, "topSpec", hero) end
  if ui.cardSpecCycleBtn then
    self:ApplyTopCenterLayout(ui.cardSpecCycleBtn, "specBtn", hero)
    self:ApplyButtonTextAlign(ui.cardSpecCycleBtn, "specBtn")
  end

  local note = ui.cardNotesBox
  if note then
    self:SetFrameSize(note, "note")
    note:ClearAllPoints()
    note:SetPoint("TOPLEFT", hero, "TOPLEFT", self:GetVal("note", "x") or 18, self:GetVal("note", "y") or -102)
    if ui.cardNotesEdit then self:BringFrameAbove(ui.cardNotesEdit, note, 10) end
    if ui.cardSaveNoteBtn then self:BringFrameAbove(ui.cardSaveNoteBtn, note, 12) end
  end

  local wisdom = ui.cardWisdomBox
  if wisdom then
    self:SetFrameSize(wisdom, "wisdom")
    wisdom:ClearAllPoints()
    wisdom:SetPoint("TOPRIGHT", hero, "TOPRIGHT", self:GetVal("wisdom", "x") or -18, self:GetVal("wisdom", "y") or -102)
    if ui.cardWisdomLabel then self:ApplyTextLayout(ui.cardWisdomLabel, "wisdomTitle", wisdom, "TOPLEFT", "TOPLEFT"); self:BringFrameAbove(ui.cardWisdomLabel, wisdom, 10) end
    if ui.cardWisdomQuoteText then self:ApplyTextLayout(ui.cardWisdomQuoteText, "wisdomQuote", wisdom, "TOPLEFT", "TOPLEFT"); self:BringFrameAbove(ui.cardWisdomQuoteText, wisdom, 10) end
    if ui.cardWisdomAttribution then self:ApplyTextLayout(ui.cardWisdomAttribution, "wisdomAuthor", wisdom, "TOPLEFT", "TOPLEFT"); self:BringFrameAbove(ui.cardWisdomAttribution, wisdom, 10) end
  end

  local portrait = ui.cardPortraitContainer
  if portrait then
    self:SetFrameSize(portrait, "portrait")
    portrait:ClearAllPoints()
    portrait:SetPoint("TOP", hero, "TOP", self:GetVal("portrait", "x") or 0, self:GetVal("portrait", "y") or -112)
  end

  -- Layering: keep Player Note as-is, but let Wisdom sit ABOVE the portrait area.
  if note and note.SetFrameLevel then note:SetFrameLevel((hero:GetFrameLevel() or 1) + 8) end
  if portrait and portrait.SetFrameLevel then portrait:SetFrameLevel((hero:GetFrameLevel() or 1) + 45) end
  if hero._abPortraitOverlay and hero._abPortraitOverlay.SetFrameLevel then
    hero._abPortraitOverlay:SetFrameLevel((hero:GetFrameLevel() or 1) + 46)
  end
  if wisdom and wisdom.SetFrameLevel then wisdom:SetFrameLevel((hero:GetFrameLevel() or 1) + 60) end
  if ui.cardWisdomLabel then self:BringFrameAbove(ui.cardWisdomLabel, wisdom, 8) end
  if ui.cardWisdomQuoteText then self:BringFrameAbove(ui.cardWisdomQuoteText, wisdom, 8) end
  if ui.cardWisdomAttribution then self:BringFrameAbove(ui.cardWisdomAttribution, wisdom, 8) end

  local rank = ui.cardStatusPanel
  if rank then
    self:SetFrameSize(rank, "rank")
    rank:ClearAllPoints()
    rank:SetPoint("TOPLEFT", hero, "TOPLEFT", self:GetVal("rank", "x") or 18, self:GetVal("rank", "y") or -226)
    rank:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -(self:GetVal("rank", "x") or 18), self:GetVal("rank", "y") or -226)
  end

  local recent = ui.cardRecentBadgesPanel
  if recent then
    self:SetFrameSize(recent, "recent")
    recent:ClearAllPoints()
    recent:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", self:GetVal("recent", "x") or 8, self:GetVal("recent", "y") or -14)
    recent._abLayoutPiece = "recent"
    if ui.cardRecentBadgesSummary then self:ApplyTextLayout(ui.cardRecentBadgesSummary, "recentText", recent, "TOPLEFT", "TOPLEFT") end
    if ui.cardRecentBadgesFrame then self:ApplyFrameLayout(ui.cardRecentBadgesFrame, "recentBadges", recent) end
    if ui.viewAllBadgesBtn then self:ApplyFrameLayout(ui.viewAllBadgesBtn, "recentView", recent); self:ApplyButtonTextAlign(ui.viewAllBadgesBtn, "recentView") end
    if ui.cardGearBtn then self:ApplyFrameLayout(ui.cardGearBtn, "recentGear", recent); self:ApplyButtonTextAlign(ui.cardGearBtn, "recentGear") end
    if ui.cardProfessionBtn then self:ApplyFrameLayout(ui.cardProfessionBtn, "recentProf", recent); self:ApplyButtonTextAlign(ui.cardProfessionBtn, "recentProf") end
  end

  local ach = ui.cardAchievementsPanel
  if ach then
    self:SetFrameSize(ach, "achievements")
    ach:ClearAllPoints()
    ach:SetPoint("TOPRIGHT", hero, "BOTTOMRIGHT", self:GetVal("achievements", "x") or -8, self:GetVal("achievements", "y") or -14)
    ach._abLayoutPiece = "achievements"
    if ui.cardAchPoints then self:ApplyTextLayout(ui.cardAchPoints, "achPoints", ach, "TOPLEFT", "TOPLEFT") end
    if ui.cardAchSummary then self:ApplyTextLayout(ui.cardAchSummary, "achSummary", ach, "TOPLEFT", "TOPLEFT") end
    if ui.cardRecentAchFrame then self:ApplyFrameLayout(ui.cardRecentAchFrame, "achList", ach) end
    if ui.cardViewAllBtn then self:ApplyFrameLayout(ui.cardViewAllBtn, "achView", ach); self:ApplyButtonTextAlign(ui.cardViewAllBtn, "achView") end
    if ui.cardTalentBtn then self:ApplyFrameLayout(ui.cardTalentBtn, "achTalent", ach); self:ApplyButtonTextAlign(ui.cardTalentBtn, "achTalent") end
    if ui.cardWorkOrderBtn then self:ApplyFrameLayout(ui.cardWorkOrderBtn, "achWork", ach); self:ApplyButtonTextAlign(ui.cardWorkOrderBtn, "achWork") end
  end

  -- Re-apply bottom panel texture anchors after size/position changes.
  if recent and recent._abSectionArt then
    local b = self:GetVal("recent", "bleed") or 10
    recent._abSectionArt:ClearAllPoints()
    recent._abSectionArt:SetPoint("TOPLEFT", recent, "TOPLEFT", -b, b)
    recent._abSectionArt:SetPoint("BOTTOMRIGHT", recent, "BOTTOMRIGHT", b, -b)
  end
  if ach and ach._abSectionArt then
    local b2 = self:GetVal("achievements", "bleed") or 10
    ach._abSectionArt:ClearAllPoints()
    ach._abSectionArt:SetPoint("TOPLEFT", ach, "TOPLEFT", -b2, b2)
    ach._abSectionArt:SetPoint("BOTTOMRIGHT", ach, "BOTTOMRIGHT", b2, -b2)
  end

  -- Keep buttons above the decorative panel art.
  local buttons = {
    ui.viewAllBadgesBtn, ui.cardGearBtn, ui.cardProfessionBtn,
    ui.cardViewAllBtn, ui.cardTalentBtn, ui.cardWorkOrderBtn,
    ui.cardSaveNoteBtn, ui.cardSpecCycleBtn, ui.cardWorkOrderRepBadge,
  }
  local i
  for i = 1, table.getn(buttons) do
    if buttons[i] and buttons[i].SetFrameLevel then
      buttons[i]:SetFrameLevel((hero:GetFrameLevel() or 1) + 35)
    end
  end
end

function LeafVE_AshenDossierSkin:SkinActionButtons(ui)
  if not ui then return end
  self:SkinButton(ui.viewAllBadgesBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
  self:SkinButton(ui.cardGearBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
  self:SkinButton(ui.cardProfessionBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
  self:SkinButton(ui.cardViewAllBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
  self:SkinButton(ui.cardTalentBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
  self:SkinButton(ui.cardWorkOrderBtn, "ashen_button_red", "ashen_button_red_hover", "ashen_button_red_down")
end


function LeafVE_AshenDossierSkin:FixDynamicHeader(ui)
  if not ui or not ui.cardHeroPanel then return end
  local hero = ui.cardHeroPanel
  local me = nil
  if UnitName then me = UnitName("player") end
  if me and ShortName then me = ShortName(me) end
  local current = ui.cardCurrentPlayer
  local isSelf = false
  if me and current and Lower then
    isSelf = Lower(me) == Lower(current)
  end

  if ui.cardName then
    ui.cardName:ClearAllPoints()
    ui.cardName:SetParent(hero)
    ui.cardName:SetPoint("TOP", hero, "TOP", -4, -14)
    ui.cardName:SetWidth(380)
    if ui.cardName.SetHeight then ui.cardName:SetHeight(22) end
    if ui.cardName.SetJustifyH then ui.cardName:SetJustifyH("CENTER") end
    if ui.cardName.SetDrawLayer then ui.cardName:SetDrawLayer("OVERLAY", 7) end
  end

  if ui.cardClassLevelRank then
    ui.cardClassLevelRank:ClearAllPoints()
    ui.cardClassLevelRank:SetParent(hero)
    ui.cardClassLevelRank:SetPoint("TOP", hero, "TOP", -4, -42)
    ui.cardClassLevelRank:SetWidth(360)
    if ui.cardClassLevelRank.SetHeight then ui.cardClassLevelRank:SetHeight(34) end
    if ui.cardClassLevelRank.SetJustifyH then ui.cardClassLevelRank:SetJustifyH("CENTER") end
    if ui.cardClassLevelRank.SetDrawLayer then ui.cardClassLevelRank:SetDrawLayer("OVERLAY", 7) end
  end

  if ui.cardTopSpecText then
    ui.cardTopSpecText:ClearAllPoints()
    ui.cardTopSpecText:SetParent(hero)
    ui.cardTopSpecText:SetPoint("TOP", hero, "TOP", 0, -80)
    ui.cardTopSpecText:SetWidth(220)
    if ui.cardTopSpecText.SetHeight then ui.cardTopSpecText:SetHeight(16) end
    if ui.cardTopSpecText.SetJustifyH then ui.cardTopSpecText:SetJustifyH("CENTER") end
    if ui.cardTopSpecText.SetDrawLayer then ui.cardTopSpecText:SetDrawLayer("OVERLAY", 7) end
  end

  if ui.cardSpecCycleBtn then
    ui.cardSpecCycleBtn:ClearAllPoints()
    ui.cardSpecCycleBtn:SetParent(hero)
    -- Keep the spec button controlled by the Ashen Layout Editor for EVERY player card.
    -- Select "Spec Button" or "SpecBtn" in the editor, move it, then Dump.
    local sx = self:GetVal("specBtn", "x") or 170
    local sy = self:GetVal("specBtn", "y") or -66
    local sw = self:GetVal("specBtn", "w") or 116
    local sh = self:GetVal("specBtn", "h") or 20
    ui.cardSpecCycleBtn:SetPoint("TOP", hero, "TOP", sx, sy)
    ui.cardSpecCycleBtn:SetWidth(sw)
    ui.cardSpecCycleBtn:SetHeight(sh)
    self:ApplyButtonTextAlign(ui.cardSpecCycleBtn, "specBtn")
    ui.cardSpecCycleBtn:Show()
    ui.cardSpecCycleBtn:Enable()
    if ui.cardTopSpecText then ui.cardTopSpecText:Hide() end
  end

  if ui.cardPortraitContainer then
    -- Keep portrait controlled by the dossier layout instead of shifting down when another player's spec/rank text has extra lines.
    ui.cardPortraitContainer:ClearAllPoints()
    ui.cardPortraitContainer:SetPoint("TOP", hero, "TOP", 0, -102)
  end
end

function LeafVE_AshenDossierSkin:Apply(ui)
  if not ui or not ui.cardHeroPanel then return end
  self:SkinDossierShell(ui)
  self:SkinSpec(ui)
  self:SkinNote(ui)
  self:SkinWisdom(ui)
  self:SkinPortrait(ui)
  self:SkinRank(ui)
  self:SkinBottomShell(ui)
  self:SkinActionButtons(ui)
  self:ApplyLayout(ui)
  self:FixDynamicHeader(ui)
  self:CreateLayoutEditorButton()
end

function LeafVE_AshenDossierSkin:DebugSwatches()
  if LeafVE_AshenDossierDebugFrame and LeafVE_AshenDossierDebugFrame:IsVisible() then
    LeafVE_AshenDossierDebugFrame:Hide()
    return
  end

  local f = LeafVE_AshenDossierDebugFrame or CreateFrame("Frame", "LeafVE_AshenDossierDebugFrame", UIParent)
  LeafVE_AshenDossierDebugFrame = f
  f:SetWidth(560)
  f:SetHeight(420)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.02, 0.02, 0.018, 0.96)
  f:SetBackdropBorderColor(0.7, 0.45, 0.18, 1)

  if not f.title then
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetText("Ashen Dossier Texture Debug")
  end

  local names = {
    "dossier_bg", "dossier_border", "dossier_title_tab", "dossier_note_panel",
    "dossier_wisdom_panel", "dossier_portrait_bg", "dossier_portrait_frame",
    "dossier_side_banner_left", "dossier_side_banner_right", "dossier_rank_plate",
    "dossier_rank_icon", "ashen_rank_1", "ashen_rank_2", "ashen_rank_3", "ashen_rank_4", "ashen_rank_5", "dossier_spec_button", "ashen_button_red",
    "recent_badges_panel_full", "achievements_panel_full",
  }

  f.swatches = f.swatches or {}
  local i
  for i = 1, table.getn(names) do
    local row = f.swatches[i]
    if not row then
      row = CreateFrame("Frame", nil, f)
      row:SetWidth(250)
      row:SetHeight(52)
      row.tex = row:CreateTexture(nil, "ARTWORK")
      row.tex:SetWidth(74)
      row.tex:SetHeight(42)
      row.tex:SetPoint("LEFT", row, "LEFT", 0, 0)
      row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      row.label:SetPoint("LEFT", row.tex, "RIGHT", 8, 0)
      row.label:SetWidth(160)
      row.label:SetJustifyH("LEFT")
      f.swatches[i] = row
    end
    row:ClearAllPoints()
    local col = math.mod(i - 1, 2)
    local r = math.floor((i - 1) / 2)
    row:SetPoint("TOPLEFT", f, "TOPLEFT", 24 + col * 270, -46 - r * 52)
    self:SetTexture(row.tex, names[i], 1)
    row.label:SetText(names[i])
    row:Show()
  end
  f:Show()
end


function LeafVE_AshenDossierSkin:PanelInfo()
  local ui = LeafVE and LeafVE.UI
  if not ui then return end
  local function P(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end end
  local function frameLine(label, f)
    if not f then P(label .. ": nil") return end
    local shown = f.IsShown and f:IsShown() or "?"
    local w = f.GetWidth and f:GetWidth() or 0
    local h = f.GetHeight and f:GetHeight() or 0
    local lvl = f.GetFrameLevel and f:GetFrameLevel() or "?"
    P(label .. ": shown=" .. tostring(shown) .. " size=" .. tostring(math.floor(w)) .. "x" .. tostring(math.floor(h)) .. " level=" .. tostring(lvl))
  end
  P("|cFFFFD700Ashen panel info|r")
  P("Path: " .. self.PATH)
  frameLine("Recent panel", ui.cardRecentBadgesPanel)
  frameLine("Achievements panel", ui.cardAchievementsPanel)
  frameLine("Recent bg tex", ui.cardRecentBadgesPanel and ui.cardRecentBadgesPanel._abSectionBG)
  frameLine("Achievements bg tex", ui.cardAchievementsPanel and ui.cardAchievementsPanel._abSectionBG)
end

function LeafVE_AshenDossierSkin:PanelTest()
  local ui = LeafVE and LeafVE.UI
  if not ui then return end
  local function testPanel(panel, r, g, b)
    if not panel then return end
    self:ClearBackdrop(panel)
    local tex = panel._abDebugSolid
    if not tex then
      tex = panel:CreateTexture(nil, "BACKGROUND")
      panel._abDebugSolid = tex
    end
    tex:ClearAllPoints()
    tex:SetAllPoints(panel)
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    tex:SetVertexColor(r, g, b, 1)
    tex:Show()
  end
  testPanel(ui.cardRecentBadgesPanel, 0.35, 0.05, 0.05)
  testPanel(ui.cardAchievementsPanel, 0.05, 0.12, 0.35)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Ashen panel test colors applied. If you see red/blue blocks, layering works and the issue was texture loading/size/path.") end
end

function LeafVE_AshenDossierSkin:PanelTextureDebug()
  if LeafVE_AshenPanelDebugFrame and LeafVE_AshenPanelDebugFrame:IsVisible() then
    LeafVE_AshenPanelDebugFrame:Hide()
    return
  end
  local f = LeafVE_AshenPanelDebugFrame or CreateFrame("Frame", "LeafVE_AshenPanelDebugFrame", UIParent)
  LeafVE_AshenPanelDebugFrame = f
  f:SetWidth(620)
  f:SetHeight(360)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.02, 0.02, 0.018, 0.96)
  f:SetBackdropBorderColor(0.7, 0.45, 0.18, 1)

  if not f.title then
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -12)
    f.title:SetText("Ashen Bottom Panel Texture Debug")
  end
  f.rows = f.rows or {}
  local names = {"recent_badges_panel_full", "achievements_panel_full", "dossier_bottom_bg", "dossier_bottom_border", "dossier_bg", "dossier_border"}
  local i
  for i = 1, table.getn(names) do
    local row = f.rows[i]
    if not row then
      row = CreateFrame("Frame", nil, f)
      row:SetWidth(580)
      row:SetHeight(48)
      row.tex = row:CreateTexture(nil, "ARTWORK")
      row.tex:SetWidth(80)
      row.tex:SetHeight(44)
      row.tex:SetPoint("LEFT", row, "LEFT", 0, 0)
      row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      row.label:SetPoint("LEFT", row.tex, "RIGHT", 10, 0)
      row.label:SetWidth(480)
      row.label:SetJustifyH("LEFT")
      f.rows[i] = row
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -45 - ((i - 1) * 48))
    self:SetTexture(row.tex, names[i], 1)
    row.label:SetText(names[i] .. "  ->  " .. self:Tex(names[i]))
    row:Show()
  end
  f:Show()
end


-- Small on-screen visual layout editor.  This wraps the slash commands in buttons so you can tune the UI live.
function LeafVE_AshenDossierSkin:GetSelectedPiece()
  if not self.editorSelectedPiece then self.editorSelectedPiece = "recent" end
  return self.editorSelectedPiece
end

function LeafVE_AshenDossierSkin:SelectPiece(piece)
  if not self.DEFAULT_LAYOUT[piece] then return end
  self.editorSelectedPiece = piece
  if self.editorSelectedLabel then self.editorSelectedLabel:SetText("Selected: " .. piece) end
  if self.editorInfoLabel then self:UpdateEditorInfo() end
end

function LeafVE_AshenDossierSkin:SelectActivePageHeader()
  local tab = nil
  if LeafVE and LeafVE.UI then tab = LeafVE.UI.activeTab end
  local piece = nil
  if tab and self.PAGE_HEADER_LAYOUT_KEYS then piece = self.PAGE_HEADER_LAYOUT_KEYS[tab] end
  if not piece then piece = "headerMe" end
  self:SelectPiece(piece)
  self:Print("Editing active tab header: " .. tostring(piece))
end

function LeafVE_AshenDossierSkin:GetHeaderLayoutPiece(panel)
  if not panel then return "pageHeader" end
  local key = panel._ashenHeaderKey
  if key and self.PAGE_HEADER_LAYOUT_KEYS and self.PAGE_HEADER_LAYOUT_KEYS[key] then
    return self.PAGE_HEADER_LAYOUT_KEYS[key]
  end
  return "pageHeader"
end

function LeafVE_AshenDossierSkin:GetHeaderTextureName(panel)
  if not panel then return "ph" end
  local key = panel._ashenHeaderKey
  if key and self.PAGE_HEADER_TEXTURES and self.PAGE_HEADER_TEXTURES[key] then
    return self.PAGE_HEADER_TEXTURES[key]
  end
  return "ph"
end

function LeafVE_AshenDossierSkin:GetCropRect(name)
  local c = self.CROP[name]
  if c then
    if table.getn(c) >= 6 then
      return c[1] / c[5], c[2] / c[5], c[3] / c[6], c[4] / c[6]
    else
      return 0, c[1] / c[3], 0, c[2] / c[4]
    end
  end
  return 0, 1, 0, 1
end

function LeafVE_AshenDossierSkin:ApplyPageHeaderToPanel(panel)
  -- v17.4: all page headers are text-only; no custom TGA header art.
  -- The old custom .tga header art could fail to render or cover the UI on Vanilla/Turtle.
  -- Keep the font strings visible and keep the header texture hidden for every panel.
  if not panel then return end
  local headerBG = panel._ashenHeaderBG
  if headerBG then
    if headerBG.SetTexture then headerBG:SetTexture(nil) end
    if headerBG.SetAlpha then headerBG:SetAlpha(0) end
    if headerBG.Hide then headerBG:Hide() end
  end
  -- Defensive cleanup for any older header art texture fields left on rebuilt panels.
  local names = {"_ashenHeaderBG", "_abPageHeader", "_abHeaderArt", "_abDossierHeader", "_abDossierTitleArt"}
  local i
  for i = 1, table.getn(names) do
    local t = panel[names[i]]
    if t and t.SetTexture then t:SetTexture(nil) end
    if t and t.SetAlpha then t:SetAlpha(0) end
    if t and t.Hide then t:Hide() end
  end
  if panel._ashenHeaderTitle and panel._ashenHeaderTitle.Show then panel._ashenHeaderTitle:Show() end
  if panel._ashenHeaderSubtitle and panel._ashenHeaderSubtitle.Show then panel._ashenHeaderSubtitle:Show() end
end

function LeafVE_AshenDossierSkin:ApplyPageHeaderToAllPanels()
  if not LeafVE or not LeafVE.UI or not LeafVE.UI.panels then return end
  local k, panel
  for k, panel in pairs(LeafVE.UI.panels) do
    if panel then
      self:ApplyPageHeaderToPanel(panel)
    end
  end
end

function LeafVE_AshenDossierSkin:RefreshFromEditor()
  if LeafVE and LeafVE.UI then
    self:Apply(LeafVE.UI)
    self:ApplyPageHeaderToAllPanels()
  end
  self:UpdateEditorInfo()
end

function LeafVE_AshenDossierSkin:EditorMove(dx, dy)
  local piece = self:GetSelectedPiece()
  local x = (self:GetVal(piece, "x") or 0) + dx
  local y = (self:GetVal(piece, "y") or 0) + dy
  self:SetVal(piece, "x", x)
  self:SetVal(piece, "y", y)
  self:RefreshFromEditor()
end

function LeafVE_AshenDossierSkin:EditorResize(dw, dh)
  local piece = self:GetSelectedPiece()
  local w = (self:GetVal(piece, "w") or 0) + dw
  local h = (self:GetVal(piece, "h") or 0) + dh
  if w < 0 then w = 0 end
  if h < 0 then h = 0 end
  self:SetVal(piece, "w", w)
  self:SetVal(piece, "h", h)
  self:RefreshFromEditor()
end

function LeafVE_AshenDossierSkin:EditorScale(delta)
  local piece = self:GetSelectedPiece()
  local w = (self:GetVal(piece, "w") or 0) + delta
  local h = (self:GetVal(piece, "h") or 0) + delta
  if w < 0 then w = 0 end
  if h < 0 then h = 0 end
  self:SetVal(piece, "w", w)
  self:SetVal(piece, "h", h)
  self:RefreshFromEditor()
end

function LeafVE_AshenDossierSkin:EditorBleed(delta)
  local piece = self:GetSelectedPiece()
  local b = (self:GetVal(piece, "bleed") or 0) + delta
  if b < 0 then b = 0 end
  self:SetVal(piece, "bleed", b)
  self:RefreshFromEditor()
end

function LeafVE_AshenDossierSkin:EditorAlign(align)
  local piece = self:GetSelectedPiece()
  self:SetVal(piece, "align", align)
  self:RefreshFromEditor()
end

function LeafVE_AshenDossierSkin:DumpLayout()
  local pieces = {}
  local seen = {}
  local i, pc
  self:Print("Copy these values back to ChatGPT:")
  for i = 1, table.getn(self.EDITOR_PIECES or {}) do
    pc = self.EDITOR_PIECES[i]
    pieces[table.getn(pieces) + 1] = pc
    seen[pc] = true
  end
  for i = 1, table.getn(self.PAGE_HEADER_EDITOR_PIECES or {}) do
    pc = self.PAGE_HEADER_EDITOR_PIECES[i]
    if not seen[pc] then
      pieces[table.getn(pieces) + 1] = pc
      seen[pc] = true
    end
  end
  for i = 1, table.getn(pieces) do
    pc = pieces[i]
    local x = self:GetVal(pc, "x") or 0
    local y = self:GetVal(pc, "y") or 0
    local w = self:GetVal(pc, "w") or 0
    local h = self:GetVal(pc, "h") or 0
    local b = self:GetVal(pc, "bleed") or 0
    local a = self:GetVal(pc, "align")
    local line = pc .. " x=" .. x .. " y=" .. y .. " w=" .. w .. " h=" .. h .. " bleed=" .. b
    if a then line = line .. " align=" .. a end
    self:Print(line)
  end
  if LeafVE_AshenDossierLayout and LeafVE_AshenDossierLayout.editorButton then
    self:Print("editorButton x=" .. (LeafVE_AshenDossierLayout.editorButton.x or 0) .. " y=" .. (LeafVE_AshenDossierLayout.editorButton.y or 250))
  end
  if LeafVE_AshenDossierLayout and LeafVE_AshenDossierLayout.editorFrame then
    self:Print("editorFrame x=" .. (LeafVE_AshenDossierLayout.editorFrame.x or 260) .. " y=" .. (LeafVE_AshenDossierLayout.editorFrame.y or 20))
  end
end

function LeafVE_AshenDossierSkin:UpdateEditorInfo()
  local piece = self:GetSelectedPiece()
  if self.editorSelectedLabel then self.editorSelectedLabel:SetText("Selected: " .. piece) end
  if self.editorInfoLabel then
    local x = self:GetVal(piece, "x") or 0
    local y = self:GetVal(piece, "y") or 0
    local w = self:GetVal(piece, "w") or 0
    local h = self:GetVal(piece, "h") or 0
    local b = self:GetVal(piece, "bleed") or 0
    local a = self:GetVal(piece, "align") or "-"
    self.editorInfoLabel:SetText("x=" .. x .. "  y=" .. y .. "  w=" .. w .. "  h=" .. h .. "  bleed=" .. b .. "  align=" .. a)
  end
end

function LeafVE_AshenDossierSkin:CreateSmallButton(parent, text, width, height, point, rel, relPoint, x, y, onclick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(width or 60)
  b:SetHeight(height or 20)
  b:SetPoint(point or "TOPLEFT", rel or parent, relPoint or point or "TOPLEFT", x or 0, y or 0)
  b:SetText(text or "")
  if b:GetFontString() and b:GetFontString().SetFont then
    b:GetFontString():SetFont(STANDARD_TEXT_FONT, 9, "")
  end
  if onclick then b:SetScript("OnClick", onclick) end
  return b
end

function LeafVE_AshenDossierSkin:CreateLayoutEditorButton()
  -- Layout editor button removed from the live UI.
  if LeafVE_AshenLayoutButton then
    LeafVE_AshenLayoutButton:Hide()
  end
end

function LeafVE_AshenDossierSkin:ToggleLayoutEditor()
  if LeafVE_AshenLayoutEditor and LeafVE_AshenLayoutEditor:IsVisible() then
    LeafVE_AshenLayoutEditor:Hide()
    return
  end
  self:CreateLayoutEditor()
  LeafVE_AshenLayoutEditor:Show()
  self:UpdateEditorInfo()
end

function LeafVE_AshenDossierSkin:CreateLayoutEditor()
  if LeafVE_AshenLayoutEditor then return end

  local f = CreateFrame("Frame", "LeafVE_AshenLayoutEditor", UIParent)
  LeafVE_AshenLayoutEditor = f
  LeafVE_AshenDossierLayout = LeafVE_AshenDossierLayout or {}
  LeafVE_AshenDossierLayout.editorFrame = LeafVE_AshenDossierLayout.editorFrame or { x = 513, y = 51 }

  f:SetWidth(540)
  f:SetHeight(590)
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", LeafVE_AshenDossierLayout.editorFrame.x or 260, LeafVE_AshenDossierLayout.editorFrame.y or 20)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.02, 0.02, 0.018, 0.96)
  f:SetBackdropBorderColor(0.75, 0.48, 0.18, 1)

  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    LeafVE_AshenDossierLayout = LeafVE_AshenDossierLayout or {}
    LeafVE_AshenDossierLayout.editorFrame = LeafVE_AshenDossierLayout.editorFrame or {}
    local fx, fy = this:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if fx and fy and ux and uy then
      LeafVE_AshenDossierLayout.editorFrame.x = math.floor((fx - ux) + 0.5)
      LeafVE_AshenDossierLayout.editorFrame.y = math.floor((fy - uy) + 0.5)
      LeafVE_AshenDossierSkin:Print("Ashen editor moved: x=" .. LeafVE_AshenDossierLayout.editorFrame.x .. " y=" .. LeafVE_AshenDossierLayout.editorFrame.y)
    end
  end)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", f, "TOP", 0, -12)
  f.title:SetText("Ashen Layout Editor")

  local dragHint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  dragHint:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
  dragHint:SetText("Drag this window. Select a piece, move/resize/align, then Dump.")
  dragHint:SetTextColor(0.85, 0.7, 0.35)

  self:CreateSmallButton(f, "X", 24, 20, "TOPRIGHT", f, "TOPRIGHT", -8, -8, function() f:Hide() end)

  self.editorSelectedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.editorSelectedLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -48)
  self.editorSelectedLabel:SetText("Selected: recent")

  self.editorInfoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.editorInfoLabel:SetPoint("TOPLEFT", self.editorSelectedLabel, "BOTTOMLEFT", 0, -4)
  self.editorInfoLabel:SetWidth(400)
  self.editorInfoLabel:SetJustifyH("LEFT")
  self.editorInfoLabel:SetText("x=0 y=0 w=0 h=0 bleed=0 align=-")

  -- Dedicated shortcuts for shared pieces.
  self:CreateSmallButton(f, "Move Spec Button", 128, 20, "TOPRIGHT", f, "TOPRIGHT", -42, -48, function()
    LeafVE_AshenDossierSkin:SelectPiece("specBtn")
  end)
  self:CreateSmallButton(f, "Move Current Header", 128, 20, "TOPRIGHT", f, "TOPRIGHT", -42, -72, function()
    LeafVE_AshenDossierSkin:SelectActivePageHeader()
  end)

  local headerLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  headerLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 414, -104)
  headerLbl:SetText("Tab header pieces")

  local headerHint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerHint:SetPoint("TOPLEFT", headerLbl, "BOTTOMLEFT", 0, -2)
  headerHint:SetText("Select one, then use Move / W / H / S buttons below")
  headerHint:SetTextColor(0.85, 0.7, 0.35)

  local headerPieces = self.PAGE_HEADER_EDITOR_PIECES or {}
  local hi
  for hi = 1, table.getn(headerPieces) do
    local pc = headerPieces[hi]
    local col = math.mod(hi - 1, 2)
    local row = math.floor((hi - 1) / 2)
    local label = (self.PAGE_HEADER_EDITOR_LABELS and self.PAGE_HEADER_EDITOR_LABELS[pc]) or pc
    self:CreateSmallButton(f, label, 96, 20, "TOPLEFT", f, "TOPLEFT", 330 + (col * 100), -124 - (row * 24), function() LeafVE_AshenDossierSkin:SelectPiece(pc) end)
  end

  local pieces = self.EDITOR_PIECES
  local i
  for i = 1, table.getn(pieces) do
    local col = math.mod(i - 1, 4)
    local row = math.floor((i - 1) / 4)
    local pc = pieces[i]
    local label = (self.EDITOR_LABELS and self.EDITOR_LABELS[pc]) or pc
    self:CreateSmallButton(f, label, 92, 20, "TOPLEFT", f, "TOPLEFT", 14 + (col * 100), -82 - (row * 24), function() LeafVE_AshenDossierSkin:SelectPiece(pc) end)
  end

  local yBase = -352
  local stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  stepLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, yBase + 20)
  stepLabel:SetText("Move selected piece")

  self:CreateSmallButton(f, "Up", 54, 22, "TOPLEFT", f, "TOPLEFT", 82, yBase, function() LeafVE_AshenDossierSkin:EditorMove(0, 2) end)
  self:CreateSmallButton(f, "Left", 54, 22, "TOPLEFT", f, "TOPLEFT", 28, yBase - 24, function() LeafVE_AshenDossierSkin:EditorMove(-2, 0) end)
  self:CreateSmallButton(f, "Right", 54, 22, "TOPLEFT", f, "TOPLEFT", 136, yBase - 24, function() LeafVE_AshenDossierSkin:EditorMove(2, 0) end)
  self:CreateSmallButton(f, "Down", 54, 22, "TOPLEFT", f, "TOPLEFT", 82, yBase - 48, function() LeafVE_AshenDossierSkin:EditorMove(0, -2) end)

  local resizeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  resizeLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 214, yBase + 20)
  resizeLabel:SetText("Resize / Scale")
  self:CreateSmallButton(f, "W-", 42, 22, "TOPLEFT", f, "TOPLEFT", 214, yBase, function() LeafVE_AshenDossierSkin:EditorResize(-2, 0) end)
  self:CreateSmallButton(f, "W+", 42, 22, "TOPLEFT", f, "TOPLEFT", 262, yBase, function() LeafVE_AshenDossierSkin:EditorResize(2, 0) end)
  self:CreateSmallButton(f, "H-", 42, 22, "TOPLEFT", f, "TOPLEFT", 214, yBase - 26, function() LeafVE_AshenDossierSkin:EditorResize(0, -2) end)
  self:CreateSmallButton(f, "H+", 42, 22, "TOPLEFT", f, "TOPLEFT", 262, yBase - 26, function() LeafVE_AshenDossierSkin:EditorResize(0, 2) end)
  self:CreateSmallButton(f, "S-", 42, 22, "TOPLEFT", f, "TOPLEFT", 214, yBase - 52, function() LeafVE_AshenDossierSkin:EditorScale(-2) end)
  self:CreateSmallButton(f, "S+", 42, 22, "TOPLEFT", f, "TOPLEFT", 262, yBase - 52, function() LeafVE_AshenDossierSkin:EditorScale(2) end)

  local alignLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  alignLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 318, yBase + 20)
  alignLabel:SetText("Text align")
  self:CreateSmallButton(f, "L", 30, 22, "TOPLEFT", f, "TOPLEFT", 318, yBase, function() LeafVE_AshenDossierSkin:EditorAlign("LEFT") end)
  self:CreateSmallButton(f, "C", 30, 22, "TOPLEFT", f, "TOPLEFT", 352, yBase, function() LeafVE_AshenDossierSkin:EditorAlign("CENTER") end)
  self:CreateSmallButton(f, "R", 30, 22, "TOPLEFT", f, "TOPLEFT", 386, yBase, function() LeafVE_AshenDossierSkin:EditorAlign("RIGHT") end)

  local quickLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  quickLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 318, yBase - 52)
  quickLabel:SetText("Header Quick Size")
  self:CreateSmallButton(f, "W-10", 46, 22, "TOPLEFT", f, "TOPLEFT", 318, yBase - 76, function() LeafVE_AshenDossierSkin:EditorResize(-10, 0) end)
  self:CreateSmallButton(f, "W+10", 46, 22, "TOPLEFT", f, "TOPLEFT", 368, yBase - 76, function() LeafVE_AshenDossierSkin:EditorResize(10, 0) end)
  self:CreateSmallButton(f, "H-10", 46, 22, "TOPLEFT", f, "TOPLEFT", 418, yBase - 76, function() LeafVE_AshenDossierSkin:EditorResize(0, -10) end)
  self:CreateSmallButton(f, "H+10", 46, 22, "TOPLEFT", f, "TOPLEFT", 468, yBase - 76, function() LeafVE_AshenDossierSkin:EditorResize(0, 10) end)

  local bleedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bleedLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -444)
  bleedLabel:SetText("Texture edge bleed / zoom")
  self:CreateSmallButton(f, "Bleed-", 70, 22, "TOPLEFT", f, "TOPLEFT", 14, -464, function() LeafVE_AshenDossierSkin:EditorBleed(-2) end)
  self:CreateSmallButton(f, "Bleed+", 70, 22, "TOPLEFT", f, "TOPLEFT", 90, -464, function() LeafVE_AshenDossierSkin:EditorBleed(2) end)

  self:CreateSmallButton(f, "Dump", 70, 24, "BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12, function() LeafVE_AshenDossierSkin:DumpLayout() end)
  self:CreateSmallButton(f, "Reset", 70, 24, "BOTTOMLEFT", f, "BOTTOMLEFT", 92, 12, function()
    LeafVE_AshenDossierLayout = {}
    LeafVE_AshenDossierSkin:RefreshFromEditor()
    if LeafVE_AshenLayoutButton then
      LeafVE_AshenDossierLayout.editorButton = { x = 375, y = 25 }
      LeafVE_AshenLayoutButton:ClearAllPoints()
      LeafVE_AshenLayoutButton:SetPoint("CENTER", UIParent, "CENTER", 375, 255)
    end
    LeafVE_AshenDossierLayout.editorFrame = { x = 488, y = 18 }
    if LeafVE_AshenLayoutEditor then
      LeafVE_AshenLayoutEditor:ClearAllPoints()
      LeafVE_AshenLayoutEditor:SetPoint("CENTER", UIParent, "CENTER", 513, 51)
    end
    LeafVE_AshenDossierSkin:Print("Layout reset to defaults.")
  end)
  self:CreateSmallButton(f, "Apply", 70, 24, "BOTTOMLEFT", f, "BOTTOMLEFT", 170, 12, function() LeafVE_AshenDossierSkin:RefreshFromEditor() end)
  self:CreateSmallButton(f, "Hide", 70, 24, "BOTTOMLEFT", f, "BOTTOMLEFT", 248, 12, function() f:Hide() end)

  self:SelectPiece("recent")
end

SLASH_ABEDITOR1 = "/abeditor"
SlashCmdList["ABEDITOR"] = function()
  if LeafVE_AshenDossierSkin then
    LeafVE_AshenDossierSkin:CreateLayoutEditorButton()
    LeafVE_AshenDossierSkin:ToggleLayoutEditor()
  end
end

SLASH_ABDOSSIER1 = "/abdossier"
SlashCmdList["ABDOSSIER"] = function()
  if LeafVE and LeafVE.UI and LeafVE_AshenDossierSkin then
    LeafVE_AshenDossierSkin:Apply(LeafVE.UI)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Ashen Dossier skin applied.") end
  end
end

SLASH_ABDOSSIERDEBUG1 = "/abdossierdebug"
SlashCmdList["ABDOSSIERDEBUG"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:DebugSwatches() end
end

SLASH_ABBOTTOM1 = "/abbottom"
SlashCmdList["ABBOTTOM"] = function()
  if LeafVE and LeafVE.UI and LeafVE_AshenDossierSkin then
    LeafVE_AshenDossierSkin:SkinBottomShell(LeafVE.UI)
    LeafVE_AshenDossierSkin:ApplyLayout(LeafVE.UI)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Ashen bottom panels applied.") end
  end
end


SLASH_ABPANELINFO1 = "/abpanelinfo"
SlashCmdList["ABPANELINFO"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:PanelInfo() end
end

SLASH_ABPANELTEST1 = "/abpaneltest"
SlashCmdList["ABPANELTEST"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:PanelTest() end
end

SLASH_ABPANELDEBUG1 = "/abpaneldebug"
SlashCmdList["ABPANELDEBUG"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:PanelTextureDebug() end
end


SLASH_ABLIST1 = "/ablist"
SlashCmdList["ABLIST"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:Print("Pieces: " .. LeafVE_AshenDossierSkin:PieceList()) end
end

local function AB_ParseWords(msg)
  local t = {}
  local w
  for w in string.gfind(msg or "", "%S+") do table.insert(t, w) end
  return t
end

local function AB_Refresh()
  if LeafVE and LeafVE.UI and LeafVE_AshenDossierSkin then
    LeafVE_AshenDossierSkin:Apply(LeafVE.UI)
  end
end

SLASH_ABMOVE1 = "/abmove"
SlashCmdList["ABMOVE"] = function(msg)
  local a = AB_ParseWords(msg)
  local piece, dx, dy = a[1], tonumber(a[2]), tonumber(a[3])
  if not piece or not dx or not dy then
    LeafVE_AshenDossierSkin:Print("Usage: /abmove piece dx dy  | pieces: " .. LeafVE_AshenDossierSkin:PieceList())
    return
  end
  local x = (LeafVE_AshenDossierSkin:GetVal(piece, "x") or 0) + dx
  local y = (LeafVE_AshenDossierSkin:GetVal(piece, "y") or 0) + dy
  LeafVE_AshenDossierSkin:SetVal(piece, "x", x)
  LeafVE_AshenDossierSkin:SetVal(piece, "y", y)
  AB_Refresh()
  LeafVE_AshenDossierSkin:Print(piece .. " moved to x=" .. x .. " y=" .. y)
end

SLASH_ABSIZE1 = "/absize"
SlashCmdList["ABSIZE"] = function(msg)
  local a = AB_ParseWords(msg)
  local piece, w, h = a[1], tonumber(a[2]), tonumber(a[3])
  if not piece or not w or not h then
    LeafVE_AshenDossierSkin:Print("Usage: /absize piece width height")
    return
  end
  LeafVE_AshenDossierSkin:SetVal(piece, "w", w)
  LeafVE_AshenDossierSkin:SetVal(piece, "h", h)
  AB_Refresh()
  LeafVE_AshenDossierSkin:Print(piece .. " size w=" .. w .. " h=" .. h)
end

SLASH_ABBLEED1 = "/abbleed"
SlashCmdList["ABBLEED"] = function(msg)
  local a = AB_ParseWords(msg)
  local piece, b = a[1], tonumber(a[2])
  if not piece or not b then
    LeafVE_AshenDossierSkin:Print("Usage: /abbleed recent 10  OR  /abbleed achievements 10")
    return
  end
  LeafVE_AshenDossierSkin:SetVal(piece, "bleed", b)
  AB_Refresh()
  LeafVE_AshenDossierSkin:Print(piece .. " bleed=" .. b)
end

SLASH_ABALIGN1 = "/abalign"
SlashCmdList["ABALIGN"] = function(msg)
  local a = AB_ParseWords(msg)
  local piece, align = a[1], a[2]
  if not piece or not align then
    LeafVE_AshenDossierSkin:Print("Usage: /abalign piece LEFT|CENTER|RIGHT")
    return
  end
  align = string.upper(align)
  if align ~= "LEFT" and align ~= "CENTER" and align ~= "RIGHT" then
    LeafVE_AshenDossierSkin:Print("Align must be LEFT, CENTER, or RIGHT")
    return
  end
  LeafVE_AshenDossierSkin:SetVal(piece, "align", align)
  AB_Refresh()
  LeafVE_AshenDossierSkin:Print(piece .. " align=" .. align)
end

SLASH_ABDUMP1 = "/abdump"
SlashCmdList["ABDUMP"] = function()
  if LeafVE_AshenDossierSkin then LeafVE_AshenDossierSkin:DumpLayout() end
end

SLASH_ABRESETLAYOUT1 = "/abresetlayout"
SlashCmdList["ABRESETLAYOUT"] = function()
  LeafVE_AshenDossierLayout = {}
  AB_Refresh()
  LeafVE_AshenDossierSkin:Print("Layout reset to v21 defaults.")
end
