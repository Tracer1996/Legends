LeafVE_Colors = LeafVE_Colors or {}

local COLORS = LeafVE_Colors

COLORS.PRIMARY = {
  darkest = {r = 0.07, g = 0.05, b = 0.05, hex = "#120D0D"},
  dark = {r = 0.13, g = 0.09, b = 0.09, hex = "#211717"},
  medium = {r = 0.20, g = 0.15, b = 0.14, hex = "#342624"},
  light = {r = 0.31, g = 0.23, b = 0.20, hex = "#4F3B33"},
  accent = {r = 0.86, g = 0.66, b = 0.37, hex = "#DBA95E"},
}

COLORS.SECONDARY = {
  purple_dark = {r = 0.41, g = 0.15, b = 0.10, hex = "#68261A"},
  purple_light = {r = 0.67, g = 0.28, b = 0.17, hex = "#AB482B"},
}

COLORS.TEXT = {
  bright_white = {r = 1.00, g = 1.00, b = 1.00, hex = "#FFFFFF"},
  off_white = {r = 0.94, g = 0.92, b = 0.88, hex = "#F0EADF"},
  muted_gray = {r = 0.71, g = 0.67, b = 0.63, hex = "#B5AAA0"},
  gold = {r = 0.86, g = 0.66, b = 0.37, hex = "#DBA95E"},
  warning = {r = 0.94, g = 0.52, b = 0.19, hex = "#F18530"},
}

COLORS.QUALITY = {
  poor = {r = 0.62, g = 0.62, b = 0.62, hex = "#9D9D9D"},
  common = {r = 1.00, g = 1.00, b = 1.00, hex = "#FFFFFF"},
  uncommon = {r = 0.12, g = 1.00, b = 0.00, hex = "#1EFF00"},
  rare = {r = 0.00, g = 0.70, b = 0.87, hex = "#0070DD"},
  epic = {r = 0.64, g = 0.21, b = 0.93, hex = "#A335EE"},
  legendary = {r = 1.00, g = 0.50, b = 0.00, hex = "#FF8000"},
}

COLORS.CLASS = {
  WARRIOR = {r = 0.78, g = 0.61, b = 0.43, hex = "#C69B7D"},
  PALADIN = {r = 0.96, g = 0.55, b = 0.73, hex = "#F48CBA"},
  HUNTER = {r = 0.67, g = 0.83, b = 0.45, hex = "#ABD473"},
  ROGUE = {r = 1.00, g = 0.96, b = 0.41, hex = "#FFF468"},
  PRIEST = {r = 1.00, g = 1.00, b = 1.00, hex = "#FFFFFF"},
  SHAMAN = {r = 0.14, g = 0.35, b = 1.00, hex = "#0070DD"},
  MAGE = {r = 0.41, g = 0.80, b = 0.94, hex = "#69CCF0"},
  WARLOCK = {r = 0.58, g = 0.51, b = 0.79, hex = "#9482CA"},
  DRUID = {r = 1.00, g = 0.49, b = 0.04, hex = "#FF7D0A"},
  DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23, hex = "#C41E3A"},
}

COLORS.STATUS = {
  success = {r = 0.72, g = 0.78, b = 0.49, hex = "#B7C77C"},
  warning = {r = 0.94, g = 0.76, b = 0.36, hex = "#F0C25D"},
  error = {r = 0.82, g = 0.31, b = 0.24, hex = "#D14F3D"},
  info = {r = 0.76, g = 0.62, b = 0.45, hex = "#C29D73"},
  disabled = {r = 0.36, g = 0.34, b = 0.34, hex = "#5C5757"},
}

-- Compatibility aliases for existing modules
COLORS.QUALITY_COLORS = COLORS.QUALITY
COLORS.BG_COLORS = COLORS.PRIMARY
COLORS.TEXT_COLORS = {
  bright = COLORS.TEXT.bright_white,
  normal = COLORS.TEXT.off_white,
  muted = COLORS.TEXT.muted_gray,
  dark = COLORS.STATUS.disabled,
  gold = COLORS.TEXT.gold,
  bright_white = COLORS.TEXT.bright_white,
  off_white = COLORS.TEXT.off_white,
  muted_gray = COLORS.TEXT.muted_gray,
  warning = COLORS.TEXT.warning,
}
COLORS.CLASS_COLORS_HEX = {}
for token, classColor in pairs(COLORS.CLASS) do
  COLORS.CLASS_COLORS_HEX[token] = classColor.hex
end
COLORS.STATUS_COLORS = COLORS.STATUS

function COLORS:HexToRGB(hex)
  if type(hex) ~= "string" then
    return 1, 1, 1
  end
  local clean = string.gsub(hex, "#", "")
  if string.len(clean) ~= 6 then
    return 1, 1, 1
  end
  local r = tonumber(string.sub(clean, 1, 2), 16) or 255
  local g = tonumber(string.sub(clean, 3, 4), 16) or 255
  local b = tonumber(string.sub(clean, 5, 6), 16) or 255
  return r / 255, g / 255, b / 255
end

function COLORS:GetClassColor(classToken)
  local token = classToken and string.upper(classToken) or ""
  return self.CLASS[token] or self.TEXT_COLORS.normal
end

function COLORS:GetQualityColor(quality)
  if not quality then
    return self.QUALITY_COLORS.common
  end
  return self.QUALITY_COLORS[string.lower(quality)] or self.QUALITY_COLORS.common
end
