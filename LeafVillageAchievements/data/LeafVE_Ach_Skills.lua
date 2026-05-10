-- LeafVE_Ach_Skills.lua
-- Profession and weapon-skill achievements (300 only).
-- Adapted from KeijinAchievementMonitor for LeafVE.
-- Requires LeafVillageAchievements.lua to be loaded first.

-- ============================================================
-- Achievement Definitions
-- ============================================================

local PROFESSIONS = {
  {id="ALCHEMY",        name="Alchemy",        icon="Interface\\Icons\\Trade_Alchemy"},
  {id="BLACKSMITHING",  name="Blacksmithing",  icon="Interface\\Icons\\Trade_BlackSmithing"},
  {id="COOKING",        name="Cooking",        icon="Interface\\Icons\\INV_Misc_Food_15"},
  {id="ENCHANTING",     name="Enchanting",     icon="Interface\\Icons\\Trade_Engraving"},
  {id="ENGINEERING",    name="Engineering",    icon="Interface\\Icons\\Trade_Engineering"},
  {id="FIRSTAID",       name="First Aid",      icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice"},
  {id="FISHING",        name="Fishing",        icon="Interface\\Icons\\Trade_Fishing"},
  {id="HERBALISM",      name="Herbalism",      icon="Interface\\Icons\\Trade_Herbalism"},
  {id="LEATHERWORKING", name="Leatherworking", icon="Interface\\Icons\\Trade_LeatherWorking"},
  {id="MINING",         name="Mining",         icon="Interface\\Icons\\Trade_Mining"},
  {id="SKINNING",       name="Skinning",       icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01"},
  {id="TAILORING",      name="Tailoring",      icon="Interface\\Icons\\Trade_Tailoring"},
  {id="JEWELCRAFTING",  name="Jewelcrafting",  icon="Interface\\Icons\\INV_Misc_Gem_01"},
}

local PROF_STEPS = {
  {value=300, title="Artisan",    points=25},
}

local WEAPONS = {
  {id="UNARMED",   name="Unarmed",           icon="Interface\\Icons\\INV_Gauntlets_09"},
  {id="DEFENSE",   name="Defense",           icon="Interface\\Icons\\INV_Shield_09"},
  {id="CROSSBOWS", name="Crossbows",         icon="Interface\\Icons\\INV_Weapon_Crossbow_04"},
  {id="DAGGERS",   name="Daggers",           icon="Interface\\Icons\\INV_Weapon_ShortBlade_15"},
  {id="GUNS",      name="Guns",              icon="Interface\\Icons\\INV_Weapon_Rifle_05"},
  {id="MACES",     name="Maces",             icon="Interface\\Icons\\INV_Hammer_09"},
  {id="POLEARMS",  name="Polearms",          icon="Interface\\Icons\\INV_Spear_08"},
  {id="THROWN",    name="Thrown",            icon="Interface\\Icons\\INV_ThrowingKnife_02"},
  {id="2HAXES",    name="Two-Handed Axes",   icon="Interface\\Icons\\INV_Axe_22"},
  {id="2HMACES",   name="Two-Handed Maces",  icon="Interface\\Icons\\INV_Hammer_Unique_Sulfuras"},
  {id="2HSWORDS",  name="Two-Handed Swords", icon="Interface\\Icons\\INV_Sword_39"},
  {id="WANDS",     name="Wands",             icon="Interface\\Icons\\INV_Wand_09"},
  {id="FIST",      name="Fist Weapons",      icon="Interface\\Icons\\INV_Gauntlets_05"},
  {id="STAVES",    name="Staves",            icon="Interface\\Icons\\INV_Staff_30"},
  {id="SWORDS",    name="Swords",            icon="Interface\\Icons\\INV_Sword_27"},
  {id="AXES",      name="Axes",              icon="Interface\\Icons\\INV_Axe_10"},
}

local WEAPON_STEPS = {
  {value=300, title="Master", points=20},
}

local function RegisterSkillAchievements()
  if not LeafVE_AchTest or type(LeafVE_AchTest.AddAchievement) ~= "function" then return end
  for _, prof in ipairs(PROFESSIONS) do
    for _, step in ipairs(PROF_STEPS) do
      local achId = "prof_"..string.lower(prof.id).."_"..step.value
      LeafVE_AchTest:AddAchievement(achId, {
        id=achId,
        name=prof.name.." "..step.title,
        desc="Reach "..step.value.." skill points in "..prof.name..".",
        category="Professions",
        points=step.points,
        icon=prof.icon,
      })
    end
  end

  for _, w in ipairs(WEAPONS) do
    for _, step in ipairs(WEAPON_STEPS) do
      local achId = "weapon_"..string.lower(w.id).."_"..step.value
      LeafVE_AchTest:AddAchievement(achId, {
        id=achId,
        name=w.name.." "..step.title,
        desc="Reach "..step.value.." in "..w.name.." weapon skill.",
        category="Skills",
        points=step.points,
        icon=w.icon,
      })
    end
  end
end

-- ============================================================
-- Skill Checking Helper
-- Scans all GetSkillLineInfo entries and awards milestones.
-- Called on CHAT_MSG_SKILL (every skill-up) and on ADDON_LOADED
-- (backlog check).
-- ============================================================
local PROF_MILESTONES = {300}
local WEAPON_MILESTONES = {300}

-- Maps display name -> canonical id prefix for professions
local PROF_ID_MAP = {}
for _, p in ipairs(PROFESSIONS) do
  PROF_ID_MAP[p.name] = string.lower(p.id)
end

-- Maps display name -> canonical id prefix for weapons
local WEAPON_ID_MAP = {}
for _, w in ipairs(WEAPONS) do
  WEAPON_ID_MAP[w.name] = string.lower(w.id)
end

local function CheckSkillMilestones(silent)
  if not LeafVE_AchTest or type(LeafVE_AchTest.AwardAchievement) ~= "function" then return end
  local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
  for i = 1, numSkills do
    local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
    if skillName and not isHeader and skillRank then
      local profKey = PROF_ID_MAP[skillName]
      if profKey then
        for _, threshold in ipairs(PROF_MILESTONES) do
          if skillRank >= threshold then
            LeafVE_AchTest:AwardAchievement("prof_"..profKey.."_"..threshold, silent)
          end
        end
      end
      local weapKey = WEAPON_ID_MAP[skillName]
      if weapKey then
        for _, threshold in ipairs(WEAPON_MILESTONES) do
          if skillRank >= threshold then
            LeafVE_AchTest:AwardAchievement("weapon_"..weapKey.."_"..threshold, silent)
          end
        end
      end
    end
  end
end

-- ============================================================
-- Event Handler
-- ============================================================

-- Startup guard: remains false until a short delay after PLAYER_ENTERING_WORLD
-- so that SKILL_LINES_CHANGED events fired during the initial login data load
-- are always treated as silent (no guild-chat announcements).
local skillCheckReady = false

local skillDelayFrame = CreateFrame("Frame")
local skillDelayElapsed = 0

local skillFrame = CreateFrame("Frame")
skillFrame:RegisterEvent("CHAT_MSG_SKILL")        -- fires on every skill-up
skillFrame:RegisterEvent("SKILL_LINES_CHANGED")   -- fires when skill list updates
skillFrame:RegisterEvent("ADDON_LOADED")           -- backlog check on load
skillFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- initial scan on login/reload

skillFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    if LeafVE_AchTest and LeafVE_AchTest.AddAchievement then
      RegisterSkillAchievements()
    end
    CheckSkillMilestones(true)  -- silent: backlog check on load
  elseif event == "PLAYER_ENTERING_WORLD" then
    CheckSkillMilestones(true)  -- silent: initial scan on login/reload
    -- Reset the guard on each login/reload so the delay applies again,
    -- then allow live skill-up announcements after the burst settles.
    skillCheckReady = false
    skillDelayElapsed = 0
    skillDelayFrame:SetScript("OnUpdate", function()
      skillDelayElapsed = skillDelayElapsed + arg1
      if skillDelayElapsed >= 3 then
        skillCheckReady = true
        skillDelayFrame:SetScript("OnUpdate", nil)
      end
    end)
  elseif event == "CHAT_MSG_SKILL" then
    CheckSkillMilestones(false) -- not silent: live skill-up, show popup
  elseif event == "SKILL_LINES_CHANGED" then
    -- Only announce non-silently once the startup delay has elapsed.
    if skillCheckReady then
      CheckSkillMilestones(false)
    else
      CheckSkillMilestones(true)
    end
  end
end)
