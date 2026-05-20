-- LeafVE_Ach_Probe.lua
-- Lightweight opt-in probe mode for researching new achievement ideas.
-- Requires LeafVillageAchievements.lua to be loaded first.

local function ProbePrint(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF69CCF0[AchProbe]|r "..tostring(msg))
  end
end

local function Trim(text)
  local s = tostring(text or "")
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

local function Lower(text)
  return string.lower(Trim(text))
end

local function SMatch(text, pattern)
  local _, _, c1, c2, c3 = string.find(tostring(text or ""), pattern)
  if c1 ~= nil then return c1, c2, c3 end
  return nil
end

local function Now()
  return time and time() or 0
end

local function ShortName(name)
  if LeafVE_AchTest and LeafVE_AchTest.ShortName then
    return LeafVE_AchTest.ShortName(name)
  end
  local raw = Trim(name)
  local dash = string.find(raw, "-", 1, true)
  if dash then
    return string.sub(raw, 1, dash - 1)
  end
  return raw
end

local function CountMapKeys(map)
  local total = 0
  if not map then return total end
  for _ in pairs(map) do
    total = total + 1
  end
  return total
end

local function GetProbeDB()
  LeafVE_AchTest_DB = LeafVE_AchTest_DB or {}
  if not LeafVE_AchTest_DB.probe then
    LeafVE_AchTest_DB.probe = {}
  end
  local probe = LeafVE_AchTest_DB.probe
  if probe.enabled == nil then probe.enabled = false end
  if not probe.current then
    probe.current = {}
  end
  if probe.current.startedAt == nil then probe.current.startedAt = 0 end
  if probe.current.total == nil then probe.current.total = 0 end
  if not probe.current.categories then probe.current.categories = {} end
  if not probe.current.recent then probe.current.recent = {} end
  return probe
end

local function ResetProbeCurrent()
  local probe = GetProbeDB()
  probe.current = {
    startedAt = probe.enabled and Now() or 0,
    total = 0,
    categories = {},
    recent = {},
  }
end

local function EnsureProbeCurrent()
  local probe = GetProbeDB()
  if not probe.current or not probe.current.categories or not probe.current.recent then
    ResetProbeCurrent()
  end
  if probe.enabled and (probe.current.startedAt or 0) <= 0 then
    probe.current.startedAt = Now()
  end
  return probe.current
end

local function GetZoneName()
  if GetRealZoneText then
    local zone = Trim(GetRealZoneText())
    if zone ~= "" then return zone end
  end
  if GetZoneText then
    return Trim(GetZoneText())
  end
  return ""
end

local function GetSubZoneName()
  if GetSubZoneText then
    return Trim(GetSubZoneText())
  end
  return ""
end

local function AddRecent(category, label, detail)
  local current = EnsureProbeCurrent()
  table.insert(current.recent, {
    at = Now(),
    category = category,
    label = label,
    detail = detail,
  })
  while table.getn(current.recent) > 60 do
    table.remove(current.recent, 1)
  end
end

local function RecordProbe(category, label, detail)
  local probe = GetProbeDB()
  if not probe.enabled then return end

  local current = EnsureProbeCurrent()
  local safeCategory = Trim(category or "Misc")
  local safeLabel = Trim(label or "Unknown")
  local safeKey = Lower(safeLabel)
  if safeKey == "" then safeKey = "__unknown__" end
  if safeLabel == "" then safeLabel = "Unknown" end

  local bucket = current.categories[safeCategory]
  if not bucket then
    bucket = {total = 0, entries = {}}
    current.categories[safeCategory] = bucket
  end

  local entry = bucket.entries[safeKey]
  if not entry then
    entry = {
      label = safeLabel,
      count = 0,
      first = Now(),
      last = 0,
      detail = detail,
    }
    bucket.entries[safeKey] = entry
  end

  bucket.total = (bucket.total or 0) + 1
  current.total = (current.total or 0) + 1
  entry.count = (entry.count or 0) + 1
  entry.last = Now()
  if detail and detail ~= "" then
    entry.detail = detail
  end

  AddRecent(safeCategory, safeLabel, detail)
end

local function MakeSummaryList(entries)
  local list = {}
  if entries then
    local key, entry
    for key, entry in pairs(entries) do
      table.insert(list, {
        key = key,
        label = entry.label,
        count = entry.count,
        first = entry.first,
        last = entry.last,
        detail = entry.detail,
      })
    end
  end
  table.sort(list, function(a, b)
    if a.count ~= b.count then return a.count > b.count end
    return string.lower(a.label or "") < string.lower(b.label or "")
  end)
  while table.getn(list) > 12 do
    table.remove(list)
  end
  return list
end

local function BuildSuggestions(summary)
  local suggestions = {}
  local category, data

  category = "Collection"
  data = summary[category]
  if data and data.unique >= 5 then
    table.insert(suggestions, category..": collected "..data.unique.." unique items; possible collection achievement line.")
  end

  category = "Combat"
  data = summary[category]
  if data and data.top and data.top[1] and data.top[1].count >= 3 then
    table.insert(suggestions, category..": repeated "..data.top[1].label.." "..data.top[1].count.." times; possible repeat-kill achievement.")
  end

  category = "Exploration"
  data = summary[category]
  if data and data.unique >= 4 then
    table.insert(suggestions, category..": visited "..data.unique.." unique zones/subzones; possible explorer milestone.")
  end

  category = "Quests"
  data = summary[category]
  if data and data.unique >= 3 then
    table.insert(suggestions, category..": completed "..data.unique.." unique quests; possible questline or streak achievement.")
  end

  category = "Professions"
  data = summary[category]
  if data and data.unique >= 1 then
    table.insert(suggestions, category..": profession progress detected; possible profession milestone achievement.")
  end

  category = "Reputation"
  data = summary[category]
  if data and data.unique >= 1 then
    table.insert(suggestions, category..": reputation changes detected; possible faction achievement.")
  end

  category = "Actions"
  data = summary[category]
  if data and data.top and data.top[1] and data.top[1].count >= 5 then
    table.insert(suggestions, category..": used "..data.top[1].label.." "..data.top[1].count.." times; possible use-count achievement.")
  end

  category = "Social"
  data = summary[category]
  if data and data.unique >= 2 then
    table.insert(suggestions, category..": social/emote variety detected; possible vanity achievement.")
  end

  return suggestions
end

local function BuildDump()
  local probe = GetProbeDB()
  local current = EnsureProbeCurrent()
  local summary = {}
  local category, bucket

  if current.categories then
    for category, bucket in pairs(current.categories) do
      summary[category] = {
        total = bucket.total or 0,
        unique = CountMapKeys(bucket.entries),
        top = MakeSummaryList(bucket.entries),
      }
    end
  end

  local duration = 0
  if (current.startedAt or 0) > 0 then
    duration = Now() - current.startedAt
    if duration < 0 then duration = 0 end
  end

  probe.lastDump = {
    generatedAt = date and date("%Y-%m-%d %H:%M:%S") or tostring(Now()),
    session = {
      startedAt = current.startedAt or 0,
      total = current.total or 0,
      durationSeconds = duration,
      player = ShortName(UnitName("player")),
      level = UnitLevel and (UnitLevel("player") or 0) or 0,
      zone = GetZoneName(),
      subZone = GetSubZoneName(),
    },
    categories = summary,
    suggestions = BuildSuggestions(summary),
    recent = current.recent,
  }

  return probe.lastDump
end

local function ProbeStatus()
  local probe = GetProbeDB()
  local current = EnsureProbeCurrent()
  ProbePrint("Status: "..(probe.enabled and "ON" or "OFF")..", observations="..tostring(current.total or 0)..", categories="..tostring(CountMapKeys(current.categories))..".")
  if probe.lastDump and probe.lastDump.generatedAt then
    ProbePrint("Last dump: "..probe.lastDump.generatedAt)
  end
end

local function RecordZoneProbe()
  local zone = GetZoneName()
  local subZone = GetSubZoneName()
  if zone ~= "" then
    RecordProbe("Exploration", zone, "zone")
  end
  if subZone ~= "" and subZone ~= zone then
    RecordProbe("Exploration", subZone, "subzone of "..zone)
  end
end

local function ExtractQuestName(msg)
  local name = SMatch(msg, 'Quest "([^"]+)" completed%.')
            or SMatch(msg, "Quest '([^']+)' completed%.")
  if name and name ~= "" then return Trim(name) end
  return nil
end

local function ExtractLootName(msg)
  local item = SMatch(msg, "^You receive loot: %[(.-)%]")
            or SMatch(msg, "^You loot %[(.-)%]")
            or SMatch(msg, "^You create: %[(.-)%]")
  if item and item ~= "" then return Trim(item) end
  return nil
end

local function ExtractKillName(msg)
  local name = SMatch(msg, "^You have slain (.+)!$")
            or SMatch(msg, "^Your party has slain (.+)!$")
            or SMatch(msg, "^Your raid has slain (.+)!$")
            or SMatch(msg, "^(.+) dies%.$")
            or SMatch(msg, "^(.+) has been slain%.$")
  if name and name ~= "" then return Trim(name) end
  return nil
end

local function ExtractFactionName(msg)
  local faction = SMatch(msg, "^Reputation with (.+) increased")
  if faction and faction ~= "" then return Trim(faction), "reputation increased" end
  local standing, withFaction = SMatch(msg, "^You are now (.+) with (.+)%.?$")
  if withFaction and withFaction ~= "" then
    return Trim(withFaction), Trim(standing)
  end
  return nil, nil
end

local function ExtractSkillName(msg)
  local skill, rank = SMatch(msg, "^Your skill in (.+) has increased to (%d+)%.?$")
  if skill and skill ~= "" then
    return Trim(skill), "rank "..tostring(rank or "")
  end
  return nil, nil
end

local function RunProbeSlashCommand(msg)
  local command = Lower(msg)
  if command == "" or command == "help" then
    ProbePrint("Commands: /achprobe on, /achprobe off, /achprobe status, /achprobe dump, /achprobe clear")
    return
  end

  if command == "on" or command == "start" then
    local probe = GetProbeDB()
    probe.enabled = true
    EnsureProbeCurrent()
    ProbePrint("Research mode enabled.")
    return
  end

  if command == "off" or command == "stop" then
    local probe = GetProbeDB()
    probe.enabled = false
    ProbePrint("Research mode disabled.")
    return
  end

  if command == "status" then
    ProbeStatus()
    return
  end

  if command == "clear" or command == "reset" then
    local probe = GetProbeDB()
    local wasEnabled = probe.enabled and true or false
    probe.lastDump = nil
    probe.enabled = wasEnabled
    ResetProbeCurrent()
    ProbePrint("Probe session cleared.")
    return
  end

  if command == "dump" or command == "report" then
    local dump = BuildDump()
    ProbePrint("Dumped "..tostring(dump.session.total or 0).." observations into LeafVE_AchTest_DB.probe.lastDump.")
    if dump.suggestions and table.getn(dump.suggestions) > 0 then
      local i
      for i = 1, table.getn(dump.suggestions) do
        ProbePrint(dump.suggestions[i])
        if i >= 5 then break end
      end
    else
      ProbePrint("No suggestions yet. Keep the probe running a bit longer.")
    end
    return
  end

  ProbePrint("Commands: /achprobe on, /achprobe off, /achprobe status, /achprobe dump, /achprobe clear")
end

LeafVE_AchTest.RunProbeCommand = RunProbeSlashCommand
LeafVE_AchTest.ProbeRecord = RecordProbe
LeafVE_AchTest.IsProbeEnabled = function()
  return GetProbeDB().enabled and true or false
end

local probeFrame = CreateFrame("Frame")
probeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
probeFrame:RegisterEvent("PLAYER_LEVEL_UP")
probeFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
probeFrame:RegisterEvent("ZONE_CHANGED")
probeFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
probeFrame:RegisterEvent("CHAT_MSG_SYSTEM")
probeFrame:RegisterEvent("CHAT_MSG_LOOT")
probeFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
probeFrame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
probeFrame:RegisterEvent("CHAT_MSG_SKILL")
probeFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
probeFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
probeFrame:SetScript("OnEvent", function()
  local probe = GetProbeDB()

  if event == "PLAYER_ENTERING_WORLD" then
    if probe.enabled then
      EnsureProbeCurrent()
      RecordZoneProbe()
      local level = UnitLevel and (UnitLevel("player") or 0) or 0
      if level > 0 then
        RecordProbe("Leveling", "Reached level "..level, "login snapshot")
      end
    end
    return
  end

  if not probe.enabled then return end

  if event == "PLAYER_LEVEL_UP" then
    local level = tonumber(arg1) or (UnitLevel and UnitLevel("player")) or 0
    if level > 0 then
      RecordProbe("Leveling", "Reached level "..level, "live level up")
    end
    return
  end

  if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
    RecordZoneProbe()
    return
  end

  if event == "CHAT_MSG_SYSTEM" then
    local questName = ExtractQuestName(arg1 or "")
    if questName then
      RecordProbe("Quests", questName, "quest completion")
    end
    return
  end

  if event == "CHAT_MSG_LOOT" then
    local itemName = ExtractLootName(arg1 or "")
    if itemName then
      RecordProbe("Collection", itemName, "loot or create")
    end
    return
  end

  if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
    local mobName = ExtractKillName(arg1 or "")
    if mobName then
      RecordProbe("Combat", mobName, "kill event")
    end
    return
  end

  if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    local factionName, detail = ExtractFactionName(arg1 or "")
    if factionName then
      RecordProbe("Reputation", factionName, detail)
    end
    return
  end

  if event == "CHAT_MSG_SKILL" then
    local skillName, detail = ExtractSkillName(arg1 or "")
    if skillName then
      RecordProbe("Professions", skillName, detail)
    end
    return
  end

  if event == "CHAT_MSG_TEXT_EMOTE" then
    local senderName = arg2 and SMatch(arg2, "^([^%-]+)") or ""
    local me = ShortName(UnitName("player"))
    if me and ShortName(senderName) == me then
      local emoteText = Trim(arg1 or "")
      if emoteText ~= "" then
        RecordProbe("Social", emoteText, "text emote")
      end
    end
    return
  end

  if event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
    local spellName = Trim(arg2 or "")
    if spellName ~= "" then
      RecordProbe("Actions", spellName, "spell cast")
    end
  end
end)

SLASH_ACHPROBE1 = "/achprobe"
SlashCmdList["ACHPROBE"] = RunProbeSlashCommand
