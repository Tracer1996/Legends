-- LeafVE_Ach_Reputation.lua
-- Faction reputation achievements (Revered / Exalted).
-- Adapted from KeijinAchievementMonitor for LeafVE.
-- Requires LeafVillageAchievements.lua to be loaded first.
--
-- Standing IDs in WoW 1.12:
--   1=Hated 2=Hostile 3=Unfriendly 4=Neutral
--   5=Friendly 6=Honored 7=Revered 8=Exalted

-- ============================================================
-- Achievement Definitions
-- ============================================================

local FACTIONS = {
  -- Neutral factions
  {id="argentdawn",    name="Argent Dawn",      icon="Interface\\Icons\\Spell_Holy_HolyProtection"},
  {id="timbermaw",     name="Timbermaw Hold",   icon="Interface\\Icons\\Spell_Nature_ForceOfNature"},
  {id="ratchet",       name="Ratchet",          icon="Interface\\Icons\\INV_Misc_Coin_02"},
  {id="gadgetzan",     name="Gadgetzan",        icon="Interface\\Icons\\INV_Misc_Coin_03"},
  {id="everlook",      name="Everlook",         icon="Interface\\Icons\\INV_Misc_Coin_04"},
  {id="bootybay",      name="Booty Bay",        icon="Interface\\Icons\\INV_Misc_Coin_01"},
  {id="cenarion",      name="Cenarion Circle",  icon="Interface\\Icons\\Spell_Nature_Regeneration"},
  {id="thorium",       name="Thorium Brotherhood", icon="Interface\\Icons\\Trade_BlackSmithing"},
  {id="hydraxian",     name="Hydraxian Waterlords", icon="Interface\\Icons\\Spell_Frost_SummonWaterElemental_2"},
  {id="wintersaber",   name="Wintersaber Trainers", icon="Interface\\Icons\\Ability_Hunter_Pet_Bear"},
  -- Horde
  {id="orgrimmar",     name="Orgrimmar",        icon="Interface\\Icons\\INV_BannerPVP_01"},
  {id="thunderbluff",  name="Thunder Bluff",    icon="Interface\\Icons\\INV_BannerPVP_02"},
  {id="undercity",     name="Undercity",        icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  {id="darkspear",     name="Darkspear Trolls", icon="Interface\\Icons\\Racial_Troll_Berserk"},
  -- Alliance
  {id="stormwind",     name="Stormwind",        icon="Interface\\Icons\\INV_BannerPVP_01"},
  {id="ironforge",     name="Ironforge",        icon="Interface\\Icons\\INV_BannerPVP_02"},
  {id="darnassus",     name="Darnassus",        icon="Interface\\Icons\\Spell_Nature_WispSplode"},
  {id="gnomeregan",    name="Gnomeregan Exiles",icon="Interface\\Icons\\INV_Misc_Gear_01"},
  -- Raid/Instance
  {id="zandalari",     name="Zandalar Tribe",   icon="Interface\\Icons\\INV_Misc_Idol_02"},
  {id="ahnqiraj",      name="Brood of Nozdormu",icon="Interface\\Icons\\INV_Qiraj_JewelBlessed"},
  {id="wardensoftime", name="Wardens of Time",  icon="Interface\\Icons\\INV_Misc_PocketWatch_01", aliases={"Keepers of Time"}},
  {id="scarlet",       name="Scarlet Crusade",  icon="Interface\\Icons\\Spell_Holy_PowerWordShield"},
  {id="defias",        name="Syndicate",        icon="Interface\\Icons\\INV_Misc_EngGizmos_19"},
}

local STANDINGS = {
  {standingID=7, suffix="revered",  label="Revered",  points=15},
  {standingID=8, suffix="exalted",  label="Exalted",  points=25},
}

-- Standing ID -> friendly label (for achievement names)
local STANDING_NAMES = {"Hated","Hostile","Unfriendly","Neutral","Friendly","Honored","Revered","Exalted"}

local function RegisterReputationAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  for _, faction in ipairs(FACTIONS) do
    for _, standing in ipairs(STANDINGS) do
      local achId = "rep_"..faction.id.."_"..standing.suffix
      local standingLabel = STANDING_NAMES[standing.standingID] or standing.label
      LeafVE_AchTest:AddAchievement(achId, {
        id=achId,
        name=faction.name..": "..standingLabel,
        desc="Reach "..standingLabel.." standing with "..faction.name..".",
        category="Reputation",
        points=standing.points,
        icon=faction.icon,
        _faction=faction.name,
        _standingID=standing.standingID,
      })
    end
  end
end

-- ============================================================
-- Reputation Checking Helper
-- Scans GetFactionInfo for all known factions and awards
-- any standing milestones that have been reached.
-- ============================================================

-- Build lookup: lowercase faction name -> faction table entry
local FACTION_LOOKUP = {}
for _, f in ipairs(FACTIONS) do
  FACTION_LOOKUP[string.lower(f.name)] = f
  if f.aliases then
    for _, alias in ipairs(f.aliases) do
      FACTION_LOOKUP[string.lower(alias)] = f
    end
  end
end

local function CheckReputationMilestones()
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement then return end
  local numFactions = GetNumFactions and GetNumFactions() or 0
  for i = 1, numFactions do
    local name, _, standingID = GetFactionInfo(i)
    if name and standingID then
      local fEntry = FACTION_LOOKUP[string.lower(name)]
      if fEntry then
        for _, standing in ipairs(STANDINGS) do
          if standingID >= standing.standingID then
            local achId = "rep_"..fEntry.id.."_"..standing.suffix
            LeafVE_AchTest:AwardAchievement(achId, true)
          end
        end
      end
    end
  end
end

-- ============================================================
-- Event Handler
-- ============================================================
local repFrame = CreateFrame("Frame")
repFrame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")  -- fires when rep changes
repFrame:RegisterEvent("ADDON_LOADED")                     -- backlog check

repFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
    CheckReputationMilestones()
  elseif event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    if LeafVE_AchTest and LeafVE_AchTest.AddAchievement then
      RegisterReputationAchievements()
    end
    CheckReputationMilestones()
  end
end)
