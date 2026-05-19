-- LeafVE_Ach_Companions.lua
-- Turtle WoW companion achievements sourced from:
-- https://docs.google.com/spreadsheets/d/1hPBrCGuE4aXiAipxzW1XX8qWsK14aMOd2Bt4ebWlxgE
-- Requires LeafVillageAchievements.lua to be loaded first.

local COMPANION_CATEGORY = "Companions"
local COMPANION_ICON = "Interface\\Icons\\INV_Misc_Toy_07"

local COMPANION_SOURCE_DATA = [[
Dream Frog
Infinite Frog
Azure Frog
Bullfrog
Dart Frog
Golden Frog
Island Frog
Pink Frog
Poison Frog
Pond Frog
Snow Frog
Tree Frog
Wood Frog
Gilnean Raven
Little Ball of Spider Web
Midnight
Mr. Bigglesworth
A Jubling's Tiny Home
Albino Snake
Albino Snapjaw
Amani Eagle
Ancona Chicken
Arcane Elemental
Azure Whelpling
Baby Shark
Beaky
Black Kingsnake
Black Piglet
Black Tabby
Black-Footed Fox
Blitzen
Bombay
Bone Golem
Brightwing
Bronze Whelpling
Brown Snake
Caravan Kodo
Cheeky Monkey
Cockatiel
Core Hound Pup
Cornish Rex
Corrupted Kitten
Cottontail Rabbit
Cracked Raptor Egg
Crimson Snake
Crimson Whelpling
Dalaran Cloud Familiar
Dark Whelpling
Darkmoon Tonk
Diablo Stone
Eagle Owl
Egg of Turtlhu
Emerald Whelpling
Enchanted Broom
Field Repair Bot 75B
Finn the Shark
Flipper
Forworn Mule
Frostwolf Ghostpup
Glitterwing
Golden Dragonhawk Hatchling
Great Horned Owl
Green Helper Box
Green Steam Tonk
Green Water Snake
Green Wing Macaw
Gurky
Hawk Owl
Hawksbill Snapjaw
Hedwig
High Elf Orphan Whistle
Hippogryph Hatchling
Hyacinth Macaw
Hyjal Bear Cub
Infinite Whelpling
Jingling Bell
Kirin Tor Familiar
Leatherback Snapjaw
Lil' K.T.
Lil' Ragnaros
Little Fawn
Little Pony
Loggerhead Snapjaw
Lost Farm Sheep
Lovely Pink Fox
Lulu
Mechanical Auctioneer
Mechanical Chicken
Mini Krampus
Moonkin Hatchling
Murky
Mysterious Fortune Teller
Olive Snapjaw
Orange Tabby
Panda Collar
Peddlefeet
Pengu
Phoenix Hatchling
Piglet's Collar
Poley
Prairie Dog Whistle
Prince Herman II
Purple Steam Tonk
Red Dragon Orb
Red Helper Box
Scarlet Snake
Scotty
Senegal
Siamese
Silver Tabby
Smolderweb Hatchling
Snowshoe
Snowy Owl
Spectral Cub
Spectral Faeling
Speedy
Sprite Darter Hatchling
Summon: Auctioneer
Summon: Barber
Summon: Surgeon
Sunscale Hatchling
Teldrassil Sproutling
Terky
Thalassian Tender
Tiny Green Dragon
Tiny Pterodactyl
Tiny Shore Crab
Tiny Snowman
Tiny Warp Stalker
Tirisfal Bat
Undercity Cockroach
Water Waveling
Westfall Chicken
Whiskers the Rat
White Kitten
White Tiger Cub
Worg Pup
Zergling Leash
]]

local COMPANION_MILESTONES = {
  {
    id = "casual_pet_collector",
    name = "Companion Tender",
    desc = "Collect 10 Turtle WoW companions.",
    goal = 10,
    points = 15,
  },
  {
    id = "casual_pet_fanatic",
    name = "Companion Handler",
    desc = "Collect 25 Turtle WoW companions.",
    goal = 25,
    points = 30,
  },
  {
    id = "companion_collector_50",
    name = "Companion Tamer",
    desc = "Collect 50 Turtle WoW companions.",
    goal = 50,
    points = 50,
  },
  {
    id = "companion_collector_75",
    name = "Companion Wrangler",
    desc = "Collect 75 Turtle WoW companions.",
    goal = 75,
    points = 70,
  },
  {
    id = "companion_collector_100",
    name = "Companion Menagerist",
    desc = "Collect 100 Turtle WoW companions.",
    goal = 100,
    points = 90,
  },
}

local COMPANION_TITLE_DEFS = {
  {
    id = "title_companion_tender",
    name = "Tender",
    achievement = "casual_pet_collector",
    desc = "Awarded for collecting 10 Turtle WoW companions.",
  },
  {
    id = "title_companion_tamer",
    name = "Tamer",
    achievement = "companion_collector_50",
    desc = "Awarded for collecting 50 Turtle WoW companions.",
  },
  {
    id = "title_companion_wrangler",
    name = "Wrangler",
    achievement = "companion_collector_75",
    desc = "Awarded for collecting 75 Turtle WoW companions.",
  },
  {
    id = "title_companion_menagerist",
    name = "Menagerist",
    achievement = "companion_collector_100",
    desc = "Awarded for collecting 100 Turtle WoW companions.",
  },
}

local function Slugify(text)
  local slug = string.lower(tostring(text or ""))
  slug = string.gsub(slug, "'", "")
  slug = string.gsub(slug, "[^a-z0-9]+", "_")
  slug = string.gsub(slug, "^_+", "")
  slug = string.gsub(slug, "_+$", "")
  return slug
end

local function Trim(text)
  local s = tostring(text or "")
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

local function SMatch(text, pattern)
  local _, _, c1, c2, c3 = string.find(tostring(text or ""), pattern)
  if c1 ~= nil then return c1, c2, c3 end
  return nil
end

local function GetItemNameFromLink(link)
  return SMatch(link, "%[(.-)%]")
end

local function GetCompanionModuleState()
  if not LeafVE_AchTest_DB then return nil end
  if not LeafVE_AchTest_DB.companionTracker then
    LeafVE_AchTest_DB.companionTracker = {}
  end
  return LeafVE_AchTest_DB.companionTracker
end

local COMPANION_BY_ACH_ID = {}
local COMPANION_IDS = {}
local COMPANION_LOOKUP = {}

local MANUAL_COMPANION_ALIASES = {
  ["a_jublings_tiny_home"] = {"jubling", "summon_jubling"},
  ["diablo_stone"] = {"diablo"},
  ["egg_of_turtlhu"] = {"turtlhu"},
  ["green_helper_box"] = {"green_helper"},
  ["high_elf_orphan_whistle"] = {"high_elf_orphan"},
  ["panda_collar"] = {"panda"},
  ["piglets_collar"] = {"piglet"},
  ["prairie_dog_whistle"] = {"prairie_dog"},
  ["red_dragon_orb"] = {"red_dragon"},
  ["red_helper_box"] = {"red_helper"},
  ["zergling_leash"] = {"zergling"},
}

local function RegisterCompanionLookup(name, achievementId)
  local key = Slugify(name)
  if key == "" or not achievementId or achievementId == "" then return end
  if not COMPANION_LOOKUP[key] then
    COMPANION_LOOKUP[key] = achievementId
  end
end

for rawName in string.gfind(COMPANION_SOURCE_DATA, "[^\r\n]+") do
  local name = Trim(rawName)
  if name ~= "" then
    local achievementId = "companion_"..Slugify(name)
    table.insert(COMPANION_IDS, achievementId)
    COMPANION_BY_ACH_ID[achievementId] = {
      id = achievementId,
      name = name,
      desc = "Collect the companion "..name..".",
      category = COMPANION_CATEGORY,
      points = 1,
      icon = COMPANION_ICON,
    }
    RegisterCompanionLookup(name, achievementId)

    local key = Slugify(name)
    local aliases = MANUAL_COMPANION_ALIASES[key]
    if aliases then
      for _, alias in ipairs(aliases) do
        RegisterCompanionLookup(alias, achievementId)
      end
    end

    local summonless = string.gsub(key, "^summon_", "")
    if summonless ~= key and summonless ~= "" then
      RegisterCompanionLookup(summonless, achievementId)
    end
  end
end

local COMPANION_TOTAL = table.getn(COMPANION_IDS)

table.insert(COMPANION_MILESTONES, {
  id = "companion_collector_all",
  name = "A Complete Menagerie",
  desc = "Collect all "..COMPANION_TOTAL.." Turtle WoW companions.",
  goal = COMPANION_TOTAL,
  points = 140,
})

table.insert(COMPANION_TITLE_DEFS, {
  id = "title_companion_master",
  name = "Companionmaster",
  achievement = "companion_collector_all",
  desc = "Awarded for collecting every Turtle WoW companion.",
})

local function RegisterCompanionAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end

  for _, achievementId in ipairs(COMPANION_IDS) do
    local data = COMPANION_BY_ACH_ID[achievementId]
    LeafVE_AchTest:AddAchievement(achievementId, {
      id = data.id,
      name = data.name,
      desc = data.desc,
      category = data.category,
      points = data.points,
      icon = data.icon,
      companionType = "individual",
    })
  end

  for _, milestone in ipairs(COMPANION_MILESTONES) do
    LeafVE_AchTest:AddAchievement(milestone.id, {
      id = milestone.id,
      name = milestone.name,
      desc = milestone.desc,
      category = COMPANION_CATEGORY,
      points = milestone.points,
      icon = COMPANION_ICON,
      companionType = "milestone",
    })
    if LeafVE_AchTest.RegisterProgressDef then
      LeafVE_AchTest:RegisterProgressDef(milestone.id, {
        counter = "companions",
        goal = milestone.goal,
      })
    end
  end

  if LeafVE_AchTest.AddTitle then
    for _, titleData in ipairs(COMPANION_TITLE_DEFS) do
      LeafVE_AchTest:AddTitle({
        id = titleData.id,
        name = titleData.name,
        chatName = titleData.name,
        achievement = titleData.achievement,
        prefix = false,
        category = COMPANION_CATEGORY,
        icon = COMPANION_ICON,
        desc = titleData.desc,
      })
    end
  end
end

local function FindCompanionAchievementId(name)
  local key = Slugify(name)
  if key == "" then return nil end
  return COMPANION_LOOKUP[key]
end

local function AddDetectedCompanion(seen, name)
  local achievementId = FindCompanionAchievementId(name)
  if achievementId then
    seen[achievementId] = true
  end
end

local function ScanBagRange(seen, bagStart, bagEnd)
  if not GetContainerNumSlots or not GetContainerItemLink then return end
  for bag = bagStart, bagEnd do
    local slotCount = GetContainerNumSlots(bag) or 0
    for slot = 1, slotCount do
      local itemName = GetItemNameFromLink(GetContainerItemLink(bag, slot))
      if itemName and itemName ~= "" then
        AddDetectedCompanion(seen, itemName)
      end
    end
  end
end

local function IsBankAccessible()
  if not GetContainerNumSlots then return false end
  return (GetContainerNumSlots(-1) or 0) > 0
end

local function ScanSpellbook(seen)
  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellName then return end
  local tabCount = GetNumSpellTabs() or 0
  for tabIndex = 1, tabCount do
    local _, _, offset, spellCount = GetSpellTabInfo(tabIndex)
    offset = offset or 0
    spellCount = spellCount or 0
    for spellOffset = 1, spellCount do
      local spellName = GetSpellName(offset + spellOffset, BOOKTYPE_SPELL or "spell")
      if spellName and spellName ~= "" then
        AddDetectedCompanion(seen, spellName)
      end
    end
  end
end

local function CountOwnedCompanions(playerName)
  local count = 0
  for _, achievementId in ipairs(COMPANION_IDS) do
    if LeafVE_AchTest:HasAchievement(playerName, achievementId) then
      count = count + 1
    end
  end
  return count
end

local function AwardCompanionMilestones(totalOwned, silent)
  for _, milestone in ipairs(COMPANION_MILESTONES) do
    if totalOwned >= milestone.goal then
      LeafVE_AchTest:AwardAchievement(milestone.id, silent)
    end
  end
end

local function ScanCompanions(forceSilent, includeSpellbook, includeBank)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement or not LeafVE_AchTest.SetCounter then return end
  local me = LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  if not me then return end

  local moduleState = GetCompanionModuleState()
  if not moduleState then return end

  local bankAccessible = includeBank and IsBankAccessible()
  local isSeedScan = not moduleState.seeded
  local isBankSeedScan = bankAccessible and not moduleState.bankSeeded
  local silent = forceSilent or isSeedScan or isBankSeedScan
  local seen = {}

  ScanBagRange(seen, 0, 4)
  if bankAccessible then
    ScanBagRange(seen, -1, -1)
    ScanBagRange(seen, 5, 10)
  end
  if includeSpellbook then
    ScanSpellbook(seen)
  end

  for achievementId in pairs(seen) do
    LeafVE_AchTest:AwardAchievement(achievementId, silent)
  end

  local totalOwned = CountOwnedCompanions(me)
  LeafVE_AchTest.SetCounter(me, "companions", totalOwned)
  AwardCompanionMilestones(totalOwned, silent)

  moduleState.seeded = true
  if bankAccessible then
    moduleState.bankSeeded = true
  end
end

local companionFrame = CreateFrame("Frame")
companionFrame:RegisterEvent("ADDON_LOADED")
companionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
companionFrame:RegisterEvent("BAG_UPDATE")
companionFrame:RegisterEvent("SPELLS_CHANGED")
companionFrame:RegisterEvent("BANKFRAME_OPENED")
companionFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")

local companionReady = false

companionFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    RegisterCompanionAchievements()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    companionReady = true
    ScanCompanions(true, true, true)
    return
  end

  if not companionReady then return end

  if event == "BAG_UPDATE" then
    ScanCompanions(false, false, true)
  elseif event == "SPELLS_CHANGED" then
    ScanCompanions(false, true, false)
  elseif event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then
    ScanCompanions(false, false, true)
  end
end)
