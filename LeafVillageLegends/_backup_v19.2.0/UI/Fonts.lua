-- LeafVillageLegends: Font styles

LeafVE_Fonts = LeafVE_Fonts or {}

LeafVE_Fonts.STYLES = {
  header_large = {font = "Fonts\\MORPHEUS.TTF", size = 18, flags = "OUTLINE"},
  header = {font = "Fonts\\MORPHEUS.TTF", size = 14, flags = "OUTLINE"},
  subheader = {font = "Fonts\\FRIZQT__.TTF", size = 11, flags = "OUTLINE"},
  body = {font = "Fonts\\FRIZQT__.TTF", size = 11, flags = ""},
  body_small = {font = "Fonts\\FRIZQT__.TTF", size = 10, flags = ""},
  small = {font = "Fonts\\ARIALN.TTF", size = 10, flags = ""},
  tabLabel = {font = "Fonts\\FRIZQT__.TTF", size = 10, flags = "OUTLINE"},
  button = {font = "Fonts\\FRIZQT__.TTF", size = 10, flags = "OUTLINE"},
  mono = {font = "Fonts\\ARIALN.TTF", size = 10, flags = ""},
}

function LeafVE_Fonts:Apply(fontString, styleKey, flags)
  if not fontString or type(fontString.SetFont) ~= "function" then
    return false
  end

  local style = self.STYLES[styleKey] or self.STYLES.body
  if not style or not style.font or not style.size then
    return false
  end

  local ok = fontString:SetFont(style.font, style.size, flags or style.flags or "")
  return ok and true or false
end
