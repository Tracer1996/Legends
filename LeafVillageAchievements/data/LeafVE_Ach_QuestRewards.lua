-- LeafVE_Ach_QuestRewards.lua
-- Quest reward item achievements for iconic classic quest rewards.
-- Requires LeafVillageAchievements.lua to be loaded first.

local QUEST_REWARD_EQUIP_ACHIEVEMENTS = {
  {
    id = "item_quelserrar_blade_awakened",
    name = "Blade Awakened",
    desc = "Reforge the ancient blade through The Ancient Blade Reforged and take up Quel'Serrar, proving the dragon-forged steel answers to your hand.",
    points = 90,
    icon = "Interface\\Icons\\INV_Sword_40",
    items = {"Quel'Serrar"},
  },
  {
    id = "item_rhokdelar_keeper_of_the_ancient_bow",
    name = "Keeper of the Ancient Bow",
    desc = "Earn Rhok'delar, Longbow of the Ancient Keepers and bear the trial-forged bow of a true hunter.",
    points = 90,
    icon = "Interface\\Icons\\INV_Weapon_Bow_07",
    items = {"Rhok'delar, Longbow of the Ancient Keepers"},
  },
  {
    id = "item_benediction_balance_of_faith",
    name = "Balance of Faith",
    desc = "Claim Benediction through the priest's sacred trial and wield the staff that walks the line between grace and ruin.",
    points = 90,
    icon = "Interface\\Icons\\INV_Staff_30",
    items = {"Benediction", "Anathema"},
  },
  {
    id = "item_drakefire_key_to_the_wyrmqueen",
    name = "Key to the Wyrmqueen",
    desc = "Complete the path to the broodmother and wear Drakefire Amulet, the mark of one admitted to Onyxia's lair.",
    points = 60,
    icon = "Interface\\Icons\\INV_Jewelry_Necklace_19",
    items = {"Drakefire Amulet"},
  },
  {
    id = "item_linkens_sword_mastery_proven",
    name = "Mastery Proven",
    desc = "Finish Linken's journey and wield Linken's Sword of Mastery, a relic worthy of Un'Goro's strangest legend.",
    points = 55,
    icon = "Interface\\Icons\\INV_Sword_41",
    items = {"Linken's Sword of Mastery"},
  },
  {
    id = "item_carrot_and_stick",
    name = "Carrot and Stick",
    desc = "Earn Carrot on a Stick and wear the trinket every rider in Azeroth wishes they had found first.",
    points = 35,
    icon = "Interface\\Icons\\INV_Misc_Food_54",
    items = {"Carrot on a Stick"},
  },
  {
    id = "item_song_of_the_cyclone",
    name = "Song of the Cyclone",
    desc = "Survive the warrior's trial and heft Whirlwind Axe, the storm's answer to hesitation.",
    points = 55,
    icon = "Interface\\Icons\\INV_Axe_09",
    items = {"Whirlwind Axe"},
  },
  {
    id = "item_trial_of_the_silver_hand",
    name = "Trial of the Silver Hand",
    desc = "Complete the paladin's test and raise Verigan's Fist, a hammer earned through duty rather than inheritance.",
    points = 55,
    icon = "Interface\\Icons\\INV_Hammer_05",
    items = {"Verigan's Fist"},
  },
  {
    id = "item_goldblood_oath",
    name = "Goldblood Oath",
    desc = "Bind yourself to darker powers and don Enchanted Gold Bloodrobe, a garment stitched with sacrifice and ambition.",
    points = 55,
    icon = "Interface\\Icons\\INV_Chest_Cloth_04",
    items = {"Enchanted Gold Bloodrobe"},
  },
  {
    id = "item_moonfangs_legacy",
    name = "Moonfang's Legacy",
    desc = "Break the fang's circle and claim Crescent Staff, a druidic relic wrested from the heart of Wailing Caverns.",
    points = 40,
    icon = "Interface\\Icons\\INV_Staff_27",
    items = {"Crescent Staff"},
  },
  {
    id = "item_stormwinds_seal",
    name = "Stormwind's Seal",
    desc = "Stand with the crown of Stormwind and wear Seal of Wrynn, a mark reserved for those who served the kingdom well.",
    points = 35,
    icon = "Interface\\Icons\\INV_Jewelry_Ring_15",
    items = {"Seal of Wrynn"},
  },
  {
    id = "item_dark_ladys_favor",
    name = "Dark Lady's Favor",
    desc = "Carry the will of the Forsaken by wearing Seal of Sylvanas, a gift touched by the Banshee Queen's regard.",
    points = 35,
    icon = "Interface\\Icons\\INV_Jewelry_Ring_14",
    items = {"Seal of Sylvanas"},
  },
  {
    id = "item_captains_mark",
    name = "Captain's Mark",
    desc = "Wear Rune of the Guard Captain and carry the soldier's reward of one who was trusted to stand the line.",
    points = 35,
    icon = "Interface\\Icons\\INV_Jewelry_Ring_21",
    items = {"Rune of the Guard Captain"},
  },
}

local QUEST_REWARD_USE_ACHIEVEMENTS = {
  {
    id = "item_the_hero_returns",
    name = "The Hero Returns",
    desc = "Complete Linken's tale and loose Linken's Boomerang, proving some legends always find their way back.",
    points = 40,
    icon = "Interface\\Icons\\INV_Weapon_ShortBlade_10",
    items = {"Linken's Boomerang"},
  },
  {
    id = "item_stolen_seconds",
    name = "Stolen Seconds",
    desc = "Use Nifty Stopwatch and turn a hard-won Badlands prize into a burst of borrowed time.",
    points = 35,
    icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    items = {"Nifty Stopwatch"},
  },
  {
    id = "item_dinner_bell",
    name = "Dinner Bell",
    desc = "Sound the call of old nobility by using Barov Peasant Caller and summoning servants long after their master's fall.",
    points = 45,
    icon = "Interface\\Icons\\INV_Bell_01",
    items = {"Barov Peasant Caller"},
  },
  {
    id = "item_the_house_still_serves",
    name = "The House Still Serves",
    desc = "Use Barov Servant Caller and command the lingering obedience of a house that never truly learned how to die.",
    points = 45,
    icon = "Interface\\Icons\\INV_Bell_01",
    items = {"Barov Servant Caller"},
  },
  {
    id = "item_borrowed_fur",
    name = "Borrowed Fur",
    desc = "Use Dartol's Rod of Transformation and walk for a while in the shape of another people.",
    points = 35,
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
    items = {"Dartol's Rod of Transformation"},
  },
  {
    id = "item_doom_runner",
    name = "Doom Runner",
    desc = "Use Skull of Impending Doom and accept that some relics are most useful when they are most unwise.",
    points = 45,
    icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    items = {"Skull of Impending Doom"},
  },
  {
    id = "item_whateverosaur",
    name = "Whateverosaur",
    desc = "Use Luffa and make good on one of Azeroth's strangest rewards by turning absurdity into preparation.",
    points = 30,
    icon = "Interface\\Icons\\INV_Misc_Herb_19",
    items = {"Luffa"},
  },
}

local EQUIP_LOOKUP = {}
local USE_LOOKUP = {}
local hooksInstalled = false

local function smatch(str, pattern)
  local s, _, c1, c2, c3 = string.find(str, pattern)
  if s then return c1 or true, c2, c3 end
  return nil
end

local function NormalizeName(name)
  if not name then return "" end
  return string.lower(name)
end

local function GetItemNameFromLink(link)
  return smatch(link or "", "%[(.-)%]")
end

local function AddLookupEntries(lookup, achId, itemNames)
  for _, itemName in ipairs(itemNames or {}) do
    lookup[NormalizeName(itemName)] = achId
  end
end

for _, ach in ipairs(QUEST_REWARD_EQUIP_ACHIEVEMENTS) do
  AddLookupEntries(EQUIP_LOOKUP, ach.id, ach.items)
end
for _, ach in ipairs(QUEST_REWARD_USE_ACHIEVEMENTS) do
  AddLookupEntries(USE_LOOKUP, ach.id, ach.items)
end

local function RegisterQuestRewardAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end

  for _, ach in ipairs(QUEST_REWARD_EQUIP_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(ach.id, {
      id = ach.id,
      name = ach.name,
      desc = ach.desc,
      category = "Quests",
      points = ach.points,
      icon = ach.icon,
    })
  end

  for _, ach in ipairs(QUEST_REWARD_USE_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(ach.id, {
      id = ach.id,
      name = ach.name,
      desc = ach.desc,
      category = "Quests",
      points = ach.points,
      icon = ach.icon,
    })
  end
end

local function AwardQuestRewardUse(itemName)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement then return end
  local achId = USE_LOOKUP[NormalizeName(itemName)]
  if achId then
    LeafVE_AchTest:AwardAchievement(achId)
  end
end

local function ScanQuestRewardEquipment(silent)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement or not GetInventoryItemLink then return end
  local awarded = {}
  for slot = 1, 19 do
    local itemName = GetItemNameFromLink(GetInventoryItemLink("player", slot))
    local achId = EQUIP_LOOKUP[NormalizeName(itemName)]
    if achId and not awarded[achId] then
      awarded[achId] = true
      LeafVE_AchTest:AwardAchievement(achId, silent)
    end
  end
end

local function InstallQuestRewardUseHooks()
  if hooksInstalled then return end
  hooksInstalled = true

  if UseContainerItem then
    local oldUseContainerItem = UseContainerItem
    UseContainerItem = function(bag, slot, onSelf)
      local itemName = GetItemNameFromLink(GetContainerItemLink and GetContainerItemLink(bag, slot))
      oldUseContainerItem(bag, slot, onSelf)
      if LeafVE_AchTest and LeafVE_AchTest.initialized and itemName then
        AwardQuestRewardUse(itemName)
      end
    end
  end

  if UseInventoryItem then
    local oldUseInventoryItem = UseInventoryItem
    UseInventoryItem = function(slot)
      local itemName = GetItemNameFromLink(GetInventoryItemLink and GetInventoryItemLink("player", slot))
      oldUseInventoryItem(slot)
      if LeafVE_AchTest and LeafVE_AchTest.initialized and itemName then
        AwardQuestRewardUse(itemName)
      end
    end
  end
end

local rewardFrame = CreateFrame("Frame")
rewardFrame:RegisterEvent("ADDON_LOADED")
rewardFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rewardFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

rewardFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    RegisterQuestRewardAchievements()
    InstallQuestRewardUseHooks()
  elseif event == "PLAYER_ENTERING_WORLD" then
    ScanQuestRewardEquipment(true)
  elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" and LeafVE_AchTest and LeafVE_AchTest.initialized then
    ScanQuestRewardEquipment(false)
  end
end)
