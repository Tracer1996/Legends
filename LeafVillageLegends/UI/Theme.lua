-- LeafVillageLegends: Theme overrides

local Colors = _G.LeafVE_Colors or {}
local classColors = (Colors and Colors.CLASS) or {
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

LEAFVE_STYLE = LEAFVE_STYLE or {}
LEAFVE_STYLE.colors = {
  border = {0.18, 0.30, 0.20, 1.0},
  bgDark = {0.03, 0.05, 0.08, 0.97},
  bgPanel = {0.06, 0.09, 0.13, 0.92},
  uncommon = {0.15, 0.65, 0.25, 1.0},
  rare = {0.10, 0.50, 0.22, 1.0},
  soft = {0.15, 0.20, 0.18, 1.0},
  epic = {0.64, 0.21, 0.93, 1.0},
  white = {0.95, 0.95, 0.95, 1.0},
}
LEAFVE_STYLE.classColors = classColors

_G.LeafVE_Styles = LEAFVE_STYLE
