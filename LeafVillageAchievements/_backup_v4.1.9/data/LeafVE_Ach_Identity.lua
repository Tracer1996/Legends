-- LeafVE_Ach_Identity.lua
-- Race and class identity achievements.
-- Adapted from KeijinAchievementMonitor for LeafVE.
-- Requires LeafVillageAchievements.lua to be loaded first.

-- ============================================================
-- Achievement Definitions
-- ============================================================

local RACE_ACHIEVEMENTS = {
  {id="race_human",    name="First Steps: Human",       desc="Play as a Human character.",    race="Human",     icon="Interface\\Icons\\Spell_Holy_HolyProtection"},
  {id="race_dwarf",    name="Stout Heart: Dwarf",        desc="Play as a Dwarf character.",    race="Dwarf",     icon="Interface\\Icons\\Racial_Dwarf_FindTreasure"},
  {id="race_nightelf", name="Shadow of the Woods",       desc="Play as a Night Elf.",          race="Night Elf", icon="Interface\\Icons\\Ability_Ambush"},
  {id="race_gnome",    name="Tinkerer Born: Gnome",      desc="Play as a Gnome character.",    race="Gnome",     icon="Interface\\Icons\\Trade_Engineering"},
  {id="race_orc",      name="Blood Fury: Orc",           desc="Play as an Orc character.",     race="Orc",       icon="Interface\\Icons\\Ability_Warrior_WarCry"},
  {id="race_troll",    name="Jungle Spirit: Troll",      desc="Play as a Troll character.",    race="Troll",     icon="Interface\\Icons\\Racial_Troll_Berserk"},
  {id="race_tauren",   name="Earth's Ward: Tauren",      desc="Play as a Tauren character.",   race="Tauren",    icon="Interface\\Icons\\Spell_Nature_Tranquility"},
  {id="race_undead",   name="Forsaken Path: Undead",     desc="Play as an Undead character.",  race="Scourge",   icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  {id="race_highelf",  name="Silver Bough: High Elf",    desc="Play as a High Elf character.", race="High Elf",  icon="Interface\\Icons\\Spell_Frost_FrostBrand"},
  {id="race_goblin",   name="Trade Prince's Path: Goblin",desc="Play as a Goblin character.", race="Goblin",    icon="Interface\\Icons\\INV_Misc_Coin_01"},
}

local CLASS_ACHIEVEMENTS = {
  {id="class_warrior", name="Path of Strength: Warrior",   desc="Play as a Warrior.",  class="Warrior",   icon="Interface\\Icons\\INV_Axe_22"},
  {id="class_paladin", name="Light's Initiate: Paladin",   desc="Play as a Paladin.",  class="Paladin",   icon="Interface\\Icons\\Spell_Holy_SealOfWrath"},
  {id="class_hunter",  name="Eyes of the Wild: Hunter",    desc="Play as a Hunter.",   class="Hunter",    icon="Interface\\Icons\\Ability_Hunter_EagleEye"},
  {id="class_rogue",   name="Silent Step: Rogue",          desc="Play as a Rogue.",    class="Rogue",     icon="Interface\\Icons\\Ability_Rogue_Rupture"},
  {id="class_priest",  name="Faith's Candle: Priest",      desc="Play as a Priest.",   class="Priest",    icon="Interface\\Icons\\Spell_Holy_InnerFire"},
  {id="class_shaman",  name="Voice of Elements: Shaman",   desc="Play as a Shaman.",   class="Shaman",    icon="Interface\\Icons\\Spell_Fire_Elemental_Totem"},
  {id="class_mage",    name="First Spark: Mage",           desc="Play as a Mage.",     class="Mage",      icon="Interface\\Icons\\Spell_Fire_Fire"},
  {id="class_warlock", name="Pact Signed: Warlock",        desc="Play as a Warlock.",  class="Warlock",   icon="Interface\\Icons\\Spell_Shadow_SummonFelHunter"},
  {id="class_druid",   name="Circle's Seed: Druid",        desc="Play as a Druid.",    class="Druid",     icon="Interface\\Icons\\Ability_Druid_DemoralizingRoar"},
}

local function RegisterIdentityAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  for _, a in ipairs(RACE_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(a.id, {
      id=a.id, name=a.name, desc=a.desc,
      category="Identity", points=5, icon=a.icon,
      _race=a.race,
    })
  end

  for _, a in ipairs(CLASS_ACHIEVEMENTS) do
    LeafVE_AchTest:AddAchievement(a.id, {
      id=a.id, name=a.name, desc=a.desc,
      category="Identity", points=5, icon=a.icon,
      _class=a.class,
    })
  end
end

-- ============================================================
-- Event Handler
-- ============================================================
local function CheckIdentity()
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement then return end
  local raceName = UnitRace("player")    -- e.g. "Human", "Night Elf", "Scourge"
  local className = UnitClass("player")  -- e.g. "Warrior", "Mage"
  if not raceName or not className then return end

  for _, a in ipairs(RACE_ACHIEVEMENTS) do
    if string.lower(raceName) == string.lower(a.race) then
      LeafVE_AchTest:AwardAchievement(a.id, true)
    end
  end
  for _, a in ipairs(CLASS_ACHIEVEMENTS) do
    if string.lower(className) == string.lower(a.class) then
      LeafVE_AchTest:AwardAchievement(a.id, true)
    end
  end
end

local identityFrame = CreateFrame("Frame")
identityFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
identityFrame:RegisterEvent("ADDON_LOADED")

identityFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    CheckIdentity()
  elseif event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    if LeafVE_AchTest and LeafVE_AchTest.AddAchievement then
      RegisterIdentityAchievements()
    end
    CheckIdentity()
  end
end)