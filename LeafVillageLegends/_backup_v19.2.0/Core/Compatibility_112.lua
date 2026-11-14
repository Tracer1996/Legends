-- LeafVillageLegends: WoW 1.12 compatibility shims

local hasRegisterAddonMessagePrefix = type(RegisterAddonMessagePrefix) == "function"
local hasStringMatch = type(string.match) == "function"
local hasUnitFactionGroup = type(UnitFactionGroup) == "function"
local legacyStringFind = string.find
local legacyStringGFind = string.gfind

LEAFVE_COMPAT_112 = (not hasRegisterAddonMessagePrefix) or (not hasStringMatch) or (not hasUnitFactionGroup)

if type(RegisterAddonMessagePrefix) ~= "function" then
  function RegisterAddonMessagePrefix()
    return true
  end
end

if type(string.match) ~= "function" then
  function string.match(text, pattern, init)
    if text == nil or pattern == nil then
      return nil
    end

    text = tostring(text)
    pattern = tostring(pattern)

    local startIndex = tonumber(init)
    if startIndex and startIndex > 1 then
      text = string.sub(text, startIndex)
    end

    if type(legacyStringGFind) == "function" then
      local iterator = legacyStringGFind(text, pattern)
      if iterator then
        return iterator()
      end
    end

    if type(legacyStringFind) ~= "function" then
      return nil
    end

    local results = { legacyStringFind(text, pattern) }
    if not results[1] then
      return nil
    end

    if table.getn(results) <= 2 then
      return string.sub(text, results[1], results[2])
    end

    return unpack(results, 3, table.getn(results))
  end
end

if type(string.gmatch) ~= "function" and type(legacyStringGFind) == "function" then
  string.gmatch = legacyStringGFind
end

if type(UnitFactionGroup) ~= "function" and type(UnitRace) == "function" then
  local allianceRaces = {
    Human = true,
    Dwarf = true,
    NightElf = true,
    Gnome = true,
  }

  function UnitFactionGroup(unit)
    local raceName, raceToken = UnitRace(unit)
    local raceKey = raceToken or raceName
    if not raceKey then
      return nil
    end
    if allianceRaces[raceKey] then
      return "Alliance"
    end
    return "Horde"
  end
end
