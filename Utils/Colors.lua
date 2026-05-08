LeafVE_Colors = LeafVE_Colors or {}

local COLORS = LeafVE_Colors

COLORS.PRIMARY = {
  darkest = {r = 0.05, g = 0.08, b = 0.18, hex = "#0D1530"},
  dark = {r = 0.12, g = 0.15, b = 0.28, hex = "#1F2645"},
  medium = {r = 0.18, g = 0.22, b = 0.35, hex = "#2D3856"},
  light = {r = 0.25, g = 0.30, b = 0.45, hex = "#3D4D72"},
  accent = {r = 1.00, g = 0.84, b = 0.00, hex = "#FFD700"},
}

COLORS.SECONDARY = {
  purple_dark = {r = 0.25, g = 0.15, b = 0.40, hex = "#401D66"},
  purple_light = {r = 0.45, g = 0.30, b = 0.60, hex = "#734D99"},
}

COLORS.TEXT = {
  bright_white = {r = 1.00, g = 1.00, b = 1.00, hex = "#FFFFFF"},
  off_white = {r = 0.92, g = 0.92, b = 0.94, hex = "#EBEBF0"},
  muted_gray = {r = 0.65, g = 0.65, b = 0.70, hex = "#A6A6B2"},
  gold = {r = 1.00, g = 0.84, b = 0.00, hex = "#FFD700"},
  warning = {r = 1.00, g = 0.67, b = 0.00, hex = "#FFAA00"},
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
  success = {r = 0.20, g = 0.90, b = 0.20, hex = "#33E633"},
  warning = {r = 1.00, g = 0.82, b = 0.00, hex = "#FFD100"},
  error = {r = 1.00, g = 0.33, b = 0.33, hex = "#FF5555"},
  info = {r = 0.20, g = 0.70, b = 0.95, hex = "#33B2F0"},
  disabled = {r = 0.40, g = 0.40, b = 0.42, hex = "#666B6C"},
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
