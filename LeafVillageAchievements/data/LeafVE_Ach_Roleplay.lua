-- LeafVE_Ach_Roleplay.lua
-- Roleplay-flavored interaction achievements.
-- Requires LeafVillageAchievements.lua to be loaded first.

local RP_INTERACTION_ACHIEVEMENTS = {
  {
    id = "rp_emperor_of_the_depths",
    name = "Emperor of the Depths",
    desc = "Ascend the Imperial Throne in Blackrock Depths and claim the seat of Shadowforge for a fleeting moment.",
    zone = "Blackrock Depths",
    triggerName = "Imperial Throne",
    points = 20,
    icon = "Interface\\Icons\\INV_Crown_01",
  },
  {
    id = "rp_judged_in_shadowforge",
    name = "Judged in Shadowforge",
    desc = "Present yourself before High Justice Grimstone and answer the brutal law of Shadowforge.",
    zone = "Blackrock Depths",
    triggerName = "High Justice Grimstone",
    points = 15,
    icon = "Interface\\Icons\\INV_Hammer_20",
  },
  {
    id = "rp_keeper_of_the_lyceum",
    name = "Keeper of the Lyceum",
    desc = "Walk the burning halls of the Lyceum and touch one of Shadowforge's guarded sanctums.",
    zone = "Blackrock Depths",
    triggerName = "The Lyceum",
    points = 15,
    icon = "Interface\\Icons\\INV_Misc_Book_11",
  },
  {
    id = "rp_master_of_the_black_anvil",
    name = "Master of the Black Anvil",
    desc = "Stand at the Black Anvil in Blackrock Depths, where empires once forged their instruments of war.",
    zone = "Blackrock Depths",
    triggerName = "The Black Anvil",
    points = 15,
    icon = "Interface\\Icons\\Trade_BlackSmithing",
  },
  {
    id = "rp_audience_with_the_warchief",
    name = "Audience with the Warchief",
    desc = "Enter Grommash Hold and stand before Thrall, voice of the Horde and Warchief of Orgrimmar.",
    zone = "Orgrimmar",
    triggerName = "Thrall",
    points = 10,
    icon = "Interface\\Icons\\Ability_Warrior_WarCry",
  },
  {
    id = "rp_at_the_banshee_queens_feet",
    name = "At the Banshee Queen's Feet",
    desc = "Descend into the Royal Quarter and bow your head before Lady Sylvanas Windrunner.",
    zone = "Undercity",
    triggerName = "Lady Sylvanas Windrunner",
    points = 10,
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
  },
  {
    id = "rp_before_the_high_seat",
    name = "Before the High Seat",
    desc = "Approach the High Seat of Ironforge and earn an audience with King Magni Bronzebeard.",
    zone = "Ironforge",
    triggerName = "King Magni Bronzebeard",
    points = 10,
    icon = "Interface\\Icons\\INV_Hammer_09",
  },
  {
    id = "rp_court_of_stormwind",
    name = "Court of Stormwind",
    desc = "Walk the halls of Stormwind Keep and stand in the presence of Highlord Bolvar Fordragon.",
    zone = "Stormwind City",
    triggerName = "Highlord Bolvar Fordragon",
    points = 10,
    icon = "Interface\\Icons\\INV_Sword_27",
  },
  {
    id = "rp_beneath_the_earthmothers_gaze",
    name = "Beneath the Earthmother's Gaze",
    desc = "Climb the mesas of Thunder Bluff and seek the wisdom of Cairne Bloodhoof beneath the open sky.",
    zone = "Thunder Bluff",
    triggerName = "Cairne Bloodhoof",
    points = 10,
    icon = "Interface\\Icons\\Ability_WarStomp",
  },
  {
    id = "rp_under_elunes_grace",
    name = "Under Elune's Grace",
    desc = "Cross the moonlit boughs of Darnassus and stand before Tyrande Whisperwind in reverence.",
    zone = "Darnassus",
    triggerName = "Tyrande Whisperwind",
    points = 10,
    icon = "Interface\\Icons\\INV_Staff_43",
  },
  {
    id = "rp_historians_ear",
    name = "Historian's Ear",
    desc = "Listen to the old stones through Royal Historian Archesonus and take your place among Azeroth's keepers of memory.",
    zone = "Ironforge",
    triggerName = "Royal Historian Archesonus",
    points = 10,
    icon = "Interface\\Icons\\INV_Misc_Book_09",
  },
}

local RP_META_ACHIEVEMENTS = {
  {
    id = "rp_courts_of_azeroth",
    name = "Courts of Azeroth",
    desc = "Stand before the rulers of Azeroth and be recognized in every great capital court.",
    points = 40,
    icon = "Interface\\Icons\\INV_Misc_Map_01",
    criteria_ids = {
      "rp_audience_with_the_warchief",
      "rp_at_the_banshee_queens_feet",
      "rp_before_the_high_seat",
      "rp_court_of_stormwind",
      "rp_beneath_the_earthmothers_gaze",
      "rp_under_elunes_grace",
    },
  },
  {
    id = "rp_sovereign_of_shadowforge",
    name = "Sovereign of Shadowforge",
    desc = "Claim the symbols of rule within Blackrock Depths and leave no corner of Shadowforge unconquered.",
    points = 60,
    icon = "Interface\\Icons\\INV_Crown_02",
    criteria_ids = {
      "rp_emperor_of_the_depths",
      "rp_judged_in_shadowforge",
      "rp_keeper_of_the_lyceum",
      "rp_master_of_the_black_anvil",
    },
  },
}

local RP_TITLE_REWARDS = {
  {
    id = "title_emperor_of_the_depths",
    name = "the Emperor of the Depths",
    achievement = "rp_emperor_of_the_depths",
    prefix = false,
    category = "Roleplay",
    icon = "Interface\\Icons\\INV_Crown_01",
  },
  {
    id = "title_court_envoy",
    name = "the Court Envoy",
    achievement = "rp_courts_of_azeroth",
    prefix = false,
    category = "Roleplay",
    icon = "Interface\\Icons\\INV_Misc_Map_01",
  },
  {
    id = "title_shadowforge_sovereign",
    name = "Shadowforge Sovereign",
    achievement = "rp_sovereign_of_shadowforge",
    prefix = false,
    category = "Roleplay",
    icon = "Interface\\Icons\\INV_Crown_02",
  },
}

local function NormalizeText(text)
  if not text then return "" end
  text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
  text = string.gsub(text, "|r", "")
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return string.lower(text)
end

local function GetCurrentZoneName()
  if GetRealZoneText then
    local zone = GetRealZoneText()
    if zone and zone ~= "" then return zone end
  end
  if GetZoneText then
    local zone = GetZoneText()
    if zone and zone ~= "" then return zone end
  end
  return ""
end

local function GetCurrentSubZoneName()
  if GetSubZoneText then
    local subZone = GetSubZoneText()
    if subZone and subZone ~= "" then return subZone end
  end
  return ""
end

local function GetCurrentInteractionName()
  if GossipFrameNpcNameText and GossipFrameNpcNameText.GetText then
    local text = GossipFrameNpcNameText:GetText()
    if text and text ~= "" then
      return text
    end
  end

  if QuestFrameNpcNameText and QuestFrameNpcNameText.GetText then
    local text = QuestFrameNpcNameText:GetText()
    if text and text ~= "" then
      return text
    end
  end

  if UnitName then
    local targetName = UnitName("target")
    if targetName and targetName ~= "" then
      return targetName
    end
  end

  return ""
end

local function MatchesZone(ach, zoneName, subZoneName)
  if ach.zone and NormalizeText(zoneName) ~= NormalizeText(ach.zone) then
    return false
  end
  if ach.subzone and NormalizeText(subZoneName) ~= NormalizeText(ach.subzone) then
    return false
  end
  return true
end

local function RegisterRoleplayAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end

  for _, ach in ipairs(RP_INTERACTION_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(ach.id, {
      id = ach.id,
      name = ach.name,
      desc = ach.desc,
      category = "Roleplay",
      points = ach.points,
      icon = ach.icon,
    })
  end

  for _, ach in ipairs(RP_META_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(ach.id, {
      id = ach.id,
      name = ach.name,
      desc = ach.desc,
      category = "Roleplay",
      points = ach.points,
      icon = ach.icon,
      criteria_type = "ach_meta",
      criteria_ids = ach.criteria_ids,
    })
  end

  if LeafVE_AchTest.AddTitle then
    for _, title in ipairs(RP_TITLE_REWARDS) do
      LeafVE_AchTest:AddTitle(title)
    end
  end
end

local function CheckRoleplayInteractionAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement then return end

  local zoneName = GetCurrentZoneName()
  local subZoneName = GetCurrentSubZoneName()
  local interactionName = NormalizeText(GetCurrentInteractionName())
  if zoneName == "" or interactionName == "" then return end

  for _, ach in ipairs(RP_INTERACTION_ACHIEVEMENTS) do
    if MatchesZone(ach, zoneName, subZoneName)
      and interactionName == NormalizeText(ach.triggerName) then
      LeafVE_AchTest:AwardAchievement(ach.id)
    end
  end
end

local rpFrame = CreateFrame("Frame")
rpFrame:RegisterEvent("ADDON_LOADED")
rpFrame:RegisterEvent("GOSSIP_SHOW")
rpFrame:RegisterEvent("QUEST_GREETING")
rpFrame:RegisterEvent("QUEST_DETAIL")
rpFrame:RegisterEvent("QUEST_PROGRESS")
rpFrame:RegisterEvent("QUEST_COMPLETE")

rpFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    RegisterRoleplayAchievements()
    if LeafVE_AchTest and LeafVE_AchTest.CheckAchievementMetaAchievements then
      LeafVE_AchTest:CheckAchievementMetaAchievements(true)
    end
  elseif event == "GOSSIP_SHOW"
    or event == "QUEST_GREETING"
    or event == "QUEST_DETAIL"
    or event == "QUEST_PROGRESS"
    or event == "QUEST_COMPLETE" then
    CheckRoleplayInteractionAchievements()
  end
end)
