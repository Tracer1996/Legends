-- LeafVE_Ach_Quests.lua
-- Notable quest-chain and one-off quest achievements with persistent per-step progress.
-- Quest completions are forwarded from the main addon turn-in tracker.
-- Requires LeafVillageAchievements.lua to be loaded first.

-- Normalize quest names so punctuation/quote variants still match.
-- Also strips a "[DEPRECATED]" prefix so old/new variants can share progress.
local function NormalizeQuestKey(name)
  if type(name) ~= "string" then return nil end
  local n = string.lower(name)
  n = string.gsub(n, "\\'", "'")
  n = string.gsub(n, "^%s*%[deprecated%]%s*", "")
  n = string.gsub(n, "[^%w%s]", " ")
  n = string.gsub(n, "%s+", " ")
  n = string.gsub(n, "^%s+", "")
  n = string.gsub(n, "%s+$", "")
  if n == "" then return nil end
  return n
end

local function LegacyQuestKey(name)
  if type(name) ~= "string" then return nil end
  local n = string.lower(name)
  if n == "" then return nil end
  return n
end

local function ReadQuestCount(value)
  if type(value) == "number" then
    if value < 0 then return 0 end
    return value
  end
  if value then return 1 end
  return 0
end

-- Step can be:
--   "Quest Name"
--   {name="Quest Name", count=3}
local function GetStepData(step)
  if type(step) == "string" then return step, 1 end
  if type(step) == "table" then
    local name = step.name or step[1]
    if type(name) ~= "string" or name == "" then return nil, nil end
    local needed = tonumber(step.count) or tonumber(step.required) or 1
    if needed < 1 then needed = 1 end
    return name, needed
  end
  return nil, nil
end

local function GetQuestCompletionCount(completedMap, stepName)
  if not completedMap then return 0 end
  local norm = NormalizeQuestKey(stepName)
  local count = 0
  if norm then
    count = ReadQuestCount(completedMap[norm])
  end
  local legacy = LegacyQuestKey(stepName)
  if legacy and legacy ~= norm then
    local legacyCount = ReadQuestCount(completedMap[legacy])
    if legacyCount > count then count = legacyCount end
  end
  return count
end

-- ============================================================
-- Quest chain definitions
-- ============================================================

local QUEST_CHAINS = {

  -- Alliance: Onyxia's Lair Attunement
  {
    id     = "quest_onyxia_alliance",
    name   = "The Great Masquerade",
    desc   = "Complete the Onyxia's Lair attunement quest chain (Alliance).",
    points = 100,
    icon   = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    title  = {id="title_onyxia_bane", name="Onyxia's Bane", prefix=false},
    steps  = {
      "Dragonkin Menace",
      "The True Masters",
      "Marshal Windsor",
      "Abandoned Hope",
      "A Crumpled Up Note",
      "A Shred of Hope",
      "Handing Over the Goods",
      "For the Marshal!",
      "The Great Masquerade",
      "The Dragon's Eye",
      "Drakefire Amulet",
    },
  },

  -- Horde: Onyxia's Lair Attunement
  {
    id     = "quest_onyxia_horde",
    name   = "Blood of the Black Dragon Champion",
    desc   = "Complete the Onyxia's Lair attunement quest chain (Horde).",
    points = 100,
    icon   = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    title  = {id="title_bloodbound", name="the Bloodbound", prefix=false},
    steps  = {
      "Warlord's Command",
      "Eitrigg's Wisdom",
      "For The Horde!",
      "What the Wind Carries",
      "The Champion of the Horde",
      "Mistress of Deception",
      "Oculus Illusions",
      "Emberstrife",
      "The Test of Skulls, Axtroz",
      "The Test of Skulls, Somnus",
      "The Test of Skulls, Chronalis",
      "The Test of Skulls, Scryer",
      "Blood of the Black Dragon Champion",
    },
  },

  -- Thunderfury, Blessed Blade of the Windseeker
  {
    id     = "quest_thunderfury",
    name   = "The Windseeker's Legacy",
    desc   = "Forge Thunderfury by completing the elemental weapon quest chain.",
    points = 150,
    icon   = "Interface\\Icons\\INV_Sword_39",
    title  = {id="title_windseeker", name="the Windseeker", prefix=false},
    steps  = {
      "Vessel of Rebirth",
      "Thunderaan's Oculus",
      "Arcanite Crystal",
      "Heart of Thunderaan",
      "Thunderfury, Blessed Blade of the Windseeker",
    },
  },

  -- Linken's Adventure (Un'Goro Crater)
  {
    id     = "quest_linken",
    name   = "Hero of Un'Goro Crater",
    desc   = "Help Linken recover his memory and complete his epic adventure chain.",
    points = 50,
    icon   = "Interface\\Icons\\INV_Misc_Note_06",
    title  = {id="title_ungoro_adventurer", name="the Un'Goro Adventurer", prefix=false},
    steps  = {
      "It's a Secret to Everybody",
      "The Videre Elixir",
      "Meet at the Grave",
      "A Grave Situation",
      "Linken's Sword",
      "A Gnome's Respite",
      "Linken's Memory",
      "Silver Heart",
      "Aquementas",
      "Linken's Boomerang",
    },
  },

  -- The Missing Diplomat (Alliance)
  {
    id     = "quest_missing_diplomat",
    name   = "A Diplomat's Journey",
    desc   = "Unravel the disappearance of King Varian Wrynn across Azeroth.",
    points = 75,
    icon   = "Interface\\Icons\\INV_Misc_Map_02",
    title  = {id="title_kingfinder", name="the Kingfinder", prefix=false},
    steps  = {
      "A Fishy Peril",
      "Further Concerns",
      "What Lurks Beneath",
      "Cloak of Unending Life",
      "Bazil Thredd",
      "The Tulal Oasis",
      "Mennet Cadelan",
      "The Second Rebellion",
      "Stoley's Debt",
      "Keep An Eye Out",
      "The Scepter of Light",
      "The Absent Minded Prospector",
      "Dazed and Confused",
    },
  },

  -- Rhok'delar, Longbow of the Ancient Keepers (Hunter)
  {
    id     = "quest_rhokdelar",
    name   = "Bow of the Ancient Keepers",
    desc   = "Slay four ancient demons and claim Rhok'delar from the demigod Remulos.",
    points = 75,
    icon   = "Interface\\Icons\\INV_Weapon_Bow_13",
    title  = {id="title_beastmaster", name="the Beastmaster", prefix=false},
    steps  = {
      "The Ancient Leaf",
      "Stave of the Ancients",
      "Rhok'delar, Longbow of the Ancient Keepers",
    },
  },

  -- Benediction / Anathema (Priest)
  {
    id     = "quest_benediction",
    name   = "The Light's Chosen Staff",
    desc   = "Balance Light and Shadow to forge Benediction (or Anathema).",
    points = 75,
    icon   = "Interface\\Icons\\INV_Staff_30",
    title  = {id="title_lightbringer", name="the Lightbringer", prefix=false},
    steps  = {
      "Redemption",
      "The Balance of Light and Shadow",
      "Benediction",
    },
  },

  -- Darrowshire (Eastern / Western Plaguelands)
  {
    id     = "quest_darrowshire",
    name   = "Echoes of Darrowshire",
    desc   = "Relive the tragic Battle of Darrowshire and lay its ghosts to rest.",
    points = 75,
    icon   = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    title  = {id="title_darrowshire_hero", name="the Darrowshire Hero", prefix=false},
    steps  = {
      "Little Pamela",
      "Pamela's Doll",
      "Auntie Marlene",
      "A Strange Historian",
      "The Annals of Darrowshire",
      "Brother Carlin",
      "The Battle of Darrowshire",
    },
  },

  -- Molten Core Attunement
  {
    id     = "quest_mc_attunement",
    name   = "Attunement to the Core",
    desc   = "Complete Attunement to the Core, or enter Molten Core while already attuned from an earlier era.",
    points = 75,
    icon   = "Interface\\Icons\\Spell_Fire_LavaSpawn",
    title  = {id="title_core_seeker", name="Core Seeker", prefix=false},
    steps  = {
      "Attunement to the Core",
    },
  },

  -- Blackwing Lair Attunement
  {
    id     = "quest_bwl_attunement",
    name   = "Blackhand's Command",
    desc   = "Complete Blackhand's Command, or enter Blackwing Lair while already attuned from an earlier era.",
    points = 75,
    icon   = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    steps  = {
      "Blackhand's Command",
    },
  },

  -- Princess Theradras Chain (Maraudon)
  {
    id     = "quest_princess_theradras",
    name   = "Earth's Bane",
    desc   = "Defeat Princess Theradras after completing the Maraudon quest chain.",
    points = 50,
    icon   = "Interface\\Icons\\INV_Misc_Root_02",
    title  = {id="title_deep_diver", name="Deep Diver", prefix=false},
    steps  = {
      "Corruption of Earth and Seed",
      "Legends of Maraudon",
      "The Scepter of Celebras",
      "Shadowshard Fragments",
      "Vyletongue Corruption",
    },
  },

  -- Dreadsteed of Xoroth (Warlock Epic Mount)
  {
    id     = "quest_dreadsteed",
    name   = "Dreadsteed of Xoroth",
    desc   = "Complete the Warlock epic mount quest chain, or summon your Dreadsteed if the rite was finished before the addon ever knew your name.",
    points = 100,
    icon   = "Interface\\Icons\\Ability_Mount_Nightmarehorse",
    title  = {id="title_dreadlord", name="the Dreadlord", prefix=false},
    steps  = {
      "Seeking Stinky and Smelly",
      "Klinfran the Crazed",
      "Corruption",
      "The Completed Orb",
      "Imp Delivery",
      "Dreadsteed of Xoroth",
    },
  },

  -- Charger (Paladin Epic Mount)
  {
    id     = "quest_charger",
    name   = "Blessed Charger",
    desc   = "Complete the Paladin epic mount quest chain, or summon your Charger if the blessing was earned long before the addon was installed.",
    points = 100,
    icon   = "Interface\\Icons\\Spell_Holy_SealOfWrath",
    title  = {id="title_lightsworn", name="the Lightsworn", prefix=false},
    steps  = {
      "Emphasis on Effort",
      "The Work of Grimand Elmore",
      "Blessed Arcanite Barding",
      "The Divination Scryer",
      "Ancient Equine Spirit",
      "Manna-Enriched Horse Feed",
      "Grimand's Finest Work",
      "Charger",
    },
  },

  -- Quel'Serrar (Warrior / Paladin legendary blade)
  {
    id     = "quest_quelserrar",
    name   = "The Ancient Blade Reforged",
    desc   = "Reforge Quel'Serrar by completing its legendary quest chain.",
    points = 100,
    icon   = "Interface\\Icons\\INV_Sword_39",
    title  = {id="title_blade_of_lore", name="Blade of Lore", prefix=false},
    steps  = {
      "The Highborne's Token",
      "A Worthy Vessel",
      "The Emerald Dreamcatcher",
      "Foror's Compendium",
      "The Forging of Quel'Serrar",
    },
  },

  -- Classic repeated-title chains
  {
    id     = "quest_defias_chapters",
    name   = "The Defias Dossier",
    desc   = "Complete all chapters of The Defias Brotherhood.",
    points = 60,
    icon   = "Interface\\Icons\\INV_Letter_15",
    steps  = {
      {name = "The Defias Brotherhood", count = 7},
    },
  },
  {
    id     = "quest_peoples_militia_chapters",
    name   = "Sentinel Hill Veteran",
    desc   = "Complete all chapters of The People's Militia.",
    points = 40,
    icon   = "Interface\\Icons\\INV_Shield_09",
    steps  = {
      {name = "The People's Militia", count = 3},
    },
  },
  {
    id     = "quest_hidden_enemies_chapters",
    name   = "Hidden No More",
    desc   = "Complete all chapters of Hidden Enemies.",
    points = 50,
    icon   = "Interface\\Icons\\Ability_Spy",
    steps  = {
      {name = "Hidden Enemies", count = 5},
    },
  },
  {
    id     = "quest_stalvan_chapters",
    name   = "The Stalvan File",
    desc   = "Complete all chapters of The Legend of Stalvan.",
    points = 70,
    icon   = "Interface\\Icons\\INV_Misc_Book_09",
    steps  = {
      {name = "The Legend of Stalvan", count = 13},
    },
  },
  {
    id     = "quest_corrupter_chapters",
    name   = "Corruption Cut Short",
    desc   = "Complete all chapters of The Corrupter.",
    points = 45,
    icon   = "Interface\\Icons\\Spell_Shadow_Curse",
    steps  = {
      {name = "The Corrupter", count = 5},
    },
  },
  {
    id     = "quest_new_frontier_chapters",
    name   = "Frontier Scout",
    desc   = "Complete all chapters of The New Frontier.",
    points = 55,
    icon   = "Interface\\Icons\\INV_Misc_Map_01",
    steps  = {
      {name = "The New Frontier", count = 7},
    },
  },
  {
    id     = "quest_yeti_chapters",
    name   = "Yeti Wrangler",
    desc   = "Complete all chapters of Are We There, Yeti?.",
    points = 35,
    icon   = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla",
    steps  = {
      {name = "Are We There, Yeti?", count = 3},
    },
  },
  {
    id     = "quest_chicken_clucking_chapters",
    name   = "Mint Condition",
    desc   = "Complete both stages of Chicken Clucking for a Mint.",
    points = 25,
    icon   = "Interface\\Icons\\INV_Egg_06",
    steps  = {
      {name = "Chicken Clucking for a Mint", count = 2},
    },
  },
  {
    id     = "quest_wildlife_suffers_too_chapters",
    name   = "Winterspring Warden",
    desc   = "Complete both chapters of The Wildlife Suffers Too.",
    points = 35,
    icon   = "Interface\\Icons\\INV_Misc_Pelt_Bear_03",
    steps  = {
      {name = "The Wildlife Suffers Too", count = 2},
    },
  },

  -- Additional classic chains
  {
    id     = "quest_tirion_in_dreams",
    name   = "Fordring's Redemption",
    desc   = "Complete Tirion's late Plaguelands chain through In Dreams.",
    points = 120,
    icon   = "Interface\\Icons\\INV_Misc_Book_11",
    title  = {id="title_dreamward", name="the Dreamward", prefix=false},
    steps  = {
      "Demon Dogs",
      "Blood Tinged Skies",
      "Carrion Grubbage",
      "Redemption",
      "Of Forgotten Memories",
      "Of Lost Honor",
      {name = "Of Love and Family", count = 2},
      "In Dreams",
    },
  },
  {
    id     = "quest_scholomance_keyline",
    name   = "Keeper of Scholomance",
    desc   = "Complete the Scholomance key progression quests.",
    points = 90,
    icon   = "Interface\\Icons\\INV_Key_03",
    title  = {id="title_keywarden", name="the Keywarden", prefix=false},
    steps  = {
      "Doctor Theolen Krastinov, the Butcher",
      "Kirtonos the Herald",
      "The Human, Ras Frostwhisper",
      "The Key to Scholomance",
    },
  },
  {
    id     = "quest_atiesh_legacy",
    name   = "Atiesh Reborn",
    desc   = "Reclaim and purify Atiesh, Greatstaff of the Guardian.",
    points = 150,
    icon   = "Interface\\Icons\\INV_Staff_Medivh",
    title  = {id="title_guardians_heir", name="the Guardian's Heir", prefix=false},
    steps  = {
      "Frame of Atiesh",
      "Atiesh, the Befouled Greatstaff",
      "Atiesh, Greatstaff of the Guardian",
    },
  },
  {
    id     = "quest_aq_eternal_board",
    name   = "A Pawn No Longer",
    desc   = "Complete A Pawn on the Eternal Board.",
    points = 100,
    icon   = "Interface\\Icons\\INV_QirajIdol_Death",
    steps  = {
      "A Pawn on the Eternal Board",
    },
  },
  {
    id     = "quest_blueleaf_tubers",
    name   = "Blueleaf Forager",
    desc   = "Complete Blueleaf Tubers.",
    points = 35,
    icon   = "Interface\\Icons\\INV_Misc_Herb_08",
    steps  = {
      "Blueleaf Tubers",
    },
  },
  {
    id     = "quest_araj_scarab",
    name   = "Scarab of Andorhal",
    desc   = "Complete Araj's Scarab.",
    points = 55,
    icon   = "Interface\\Icons\\INV_Misc_Orb_03",
    steps  = {
      "Araj's Scarab",
    },
  },
  {
    id     = "quest_brood_of_onyxia",
    name   = "Brood Exposed",
    desc   = "Complete Identifying the Brood and The Brood of Onyxia.",
    points = 60,
    icon   = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    steps  = {
      "Identifying the Brood",
      "The Brood of Onyxia",
    },
  },
  {
    id     = "quest_sunken_temple_trials",
    name   = "Temple Delver",
    desc   = "Complete The Sunken Temple.",
    points = 55,
    icon   = "Interface\\Icons\\INV_Misc_Eye_01",
    steps  = {
      "The Sunken Temple",
    },
  },
  {
    id     = "quest_return_to_chromie",
    name   = "Chronicle's Return",
    desc   = "Complete Return to Chromie.",
    points = 50,
    icon   = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    steps  = {
      "Return to Chromie",
    },
  },

  -- Classic low-level one-offs
  {
    id     = "quest_hogger_bounty",
    name   = "Hogger's End",
    desc   = "Complete Wanted: Hogger.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Gnoll_01",
    steps  = {"Wanted: Hogger"},
  },
  {
    id     = "quest_maggot_eye_bounty",
    name   = "Eye for Maggot Eye",
    desc   = "Complete Wanted: Maggot Eye.",
    points = 20,
    icon   = "Interface\\Icons\\Ability_CriticalStrike",
    steps  = {"Wanted: Maggot Eye"},
  },
  {
    id     = "quest_princess_must_die",
    name   = "Boar Crown Broken",
    desc   = "Complete Princess Must Die!",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Boar_01",
    steps  = {"Princess Must Die!"},
  },
  {
    id     = "quest_disruption_ends",
    name   = "No More Disruption",
    desc   = "Complete The Disruption Ends.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Pick_02",
    steps  = {"The Disruption Ends"},
  },
  {
    id     = "quest_kolkar_leaders",
    name   = "Kolkar Decapitated",
    desc   = "Complete Kolkar Leaders.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Axe_06",
    steps  = {"Kolkar Leaders"},
  },
  {
    id     = "quest_echeyakee",
    name   = "White Mane Fell",
    desc   = "Complete Echeyakee.",
    points = 25,
    icon   = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
    steps  = {"Echeyakee"},
  },
  {
    id     = "quest_harpy_raiders",
    name   = "Featherbreaker",
    desc   = "Complete Harpy Raiders.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Feather_02",
    steps  = {"Harpy Raiders"},
  },
  {
    id     = "quest_raptor_horns",
    name   = "Horn Collector",
    desc   = "Complete Raptor Horns.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Bone_03",
    steps  = {"Raptor Horns"},
  },
  {
    id     = "quest_consumed_by_hatred",
    name   = "Hatred Spent",
    desc   = "Complete Consumed by Hatred.",
    points = 20,
    icon   = "Interface\\Icons\\Spell_Shadow_Curse",
    steps  = {"Consumed by Hatred"},
  },
  {
    id     = "quest_leaders_of_the_fang",
    name   = "Fangbreaker",
    desc   = "Complete Leaders of the Fang.",
    points = 25,
    icon   = "Interface\\Icons\\INV_Misc_MonsterFang_01",
    steps  = {"Leaders of the Fang"},
  },
  {
    id     = "quest_trouble_at_docks",
    name   = "Dockside Cleanup",
    desc   = "Complete Trouble at the Docks.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Crate_03",
    steps  = {"Trouble at the Docks"},
  },
  {
    id     = "quest_family_fishing_pole",
    name   = "Family Catch",
    desc   = "Complete The Family and the Fishing Pole.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Fishingpole_01",
    steps  = {"The Family and the Fishing Pole"},
  },
  {
    id     = "quest_stockade_riots",
    name   = "Riot Suppressor",
    desc   = "Complete The Stockade Riots.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Bag_11",
    steps  = {"The Stockade Riots"},
  },
  {
    id     = "quest_fenris_assault",
    name   = "Fenris Breaker",
    desc   = "Complete Assault on Fenris Isle.",
    points = 20,
    icon   = "Interface\\Icons\\Ability_Racial_BloodRage",
    steps  = {"Assault on Fenris Isle"},
  },
  {
    id     = "quest_arugal_must_die",
    name   = "Shadowfang's End",
    desc   = "Complete Arugal Must Die.",
    points = 25,
    icon   = "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    steps  = {"Arugal Must Die"},
  },
  {
    id     = "quest_lost_in_battle",
    name   = "Remember the Fallen",
    desc   = "Complete Lost in Battle.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Sword_04",
    steps  = {"Lost in Battle"},
  },
  {
    id     = "quest_baron_longshore_bounty",
    name   = "Longshore Cut Short",
    desc   = "Complete WANTED: Baron Longshore.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Human_01",
    steps  = {"WANTED: Baron Longshore"},
  },
  {
    id     = "quest_gathilzogg_bounty",
    name   = "Gath'Ilzogg's Fall",
    desc   = "Complete Wanted: Gath'Ilzogg.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Orc_01",
    steps  = {"Wanted: Gath'Ilzogg"},
  },
  {
    id     = "quest_fangore_bounty",
    name   = "Lieutenant No More",
    desc   = "Complete Wanted: Lieutenant Fangore.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Human_02",
    steps  = {"Wanted: Lieutenant Fangore"},
  },
  {
    id     = "quest_murkdeep_bounty",
    name   = "Murkdeep Hunted",
    desc   = "Complete WANTED: Murkdeep!",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Head_Murloc_01",
    steps  = {"WANTED: Murkdeep!"},
  },
  {
    id     = "quest_green_hills_stranglethorn",
    name   = "Pages of the Jungle",
    desc   = "Complete The Green Hills of Stranglethorn.",
    points = 30,
    icon   = "Interface\\Icons\\INV_Misc_Book_11",
    steps  = {"The Green Hills of Stranglethorn"},
  },
  {
    id     = "quest_test_of_righteousness",
    name   = "Judged Worthy",
    desc   = "Complete The Test of Righteousness.",
    points = 45,
    icon   = "Interface\\Icons\\Spell_Holy_SealOfValor",
    steps  = {"The Test of Righteousness"},
  },
  {
    id     = "quest_cyclonian",
    name   = "Stormbreaker",
    desc   = "Complete Cyclonian.",
    points = 50,
    icon   = "Interface\\Icons\\Spell_Nature_Cyclone",
    steps  = {"Cyclonian"},
  },
  {
    id     = "quest_saving_sharpbeak",
    name   = "Sharpbeak's Savior",
    desc   = "Complete Saving Sharpbeak.",
    points = 35,
    icon   = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
    steps  = {"Saving Sharpbeak"},
  },
  {
    id     = "quest_god_hakkar",
    name   = "Godsbane of the Temple",
    desc   = "Complete The God Hakkar.",
    points = 60,
    icon   = "Interface\\Icons\\Spell_Shadow_LifeDrain",
    steps  = {"The God Hakkar"},
  },
  {
    id     = "quest_seal_of_ascension",
    name   = "Sealbearer",
    desc   = "Complete Seal of Ascension.",
    points = 75,
    icon   = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    steps  = {"Seal of Ascension"},
  },
  {
    id     = "quest_naxx_attunement",
    name   = "Dreadward",
    desc   = "Complete The Dread Citadel - Naxxramas.",
    points = 90,
    icon   = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    steps  = {"The Dread Citadel - Naxxramas"},
  },
  {
    id     = "quest_order_must_be_restored",
    name   = "Restored Order",
    desc   = "Complete Order Must Be Restored.",
    points = 70,
    icon   = "Interface\\Icons\\Ability_Warrior_Challange",
    steps  = {"Order Must Be Restored"},
  },
  {
    id     = "quest_day_after",
    name   = "Hungover Hero",
    desc   = "Complete The Day After.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Drink_17",
    steps  = {"The Day After"},
  },
  {
    id     = "quest_fine_mess",
    name   = "Certified Mess",
    desc   = "Complete A Fine Mess.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Bomb_04",
    steps  = {"A Fine Mess"},
  },
  {
    id     = "quest_super_snapper_fx",
    name   = "Turtle Paparazzi",
    desc   = "Complete The Super Snapper FX.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Misc_Spyglass_01",
    steps  = {"The Super Snapper FX"},
  },
  {
    id     = "quest_love_potion",
    name   = "Brewed Affection",
    desc   = "Complete The Love Potion.",
    points = 20,
    icon   = "Interface\\Icons\\INV_Potion_51",
    steps  = {"The Love Potion"},
  },
  {
    id     = "quest_haze_of_evil",
    name   = "Hazy Victory",
    desc   = "Complete Haze of Evil.",
    points = 25,
    icon   = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
    steps  = {"Haze of Evil"},
  },
  {
    id     = "quest_saving_yenniku",
    name   = "Mind Over Mayhem",
    desc   = "Complete Saving Yenniku.",
    points = 25,
    icon   = "Interface\\Icons\\INV_Misc_Head_Troll_01",
    steps  = {"Saving Yenniku"},
  },

  -- Turtle quest chains
  {
    id     = "quest_turtle_kheyna_timeway",
    name   = "Gears of Time",
    desc   = "Complete Kheyna's long campaign through Black Morass timeways.",
    points = 140,
    icon   = "Interface\\Icons\\INV_Misc_PocketWatch_02",
    title  = {id="title_chronomechanic", name="the Chronomechanic", prefix=false},
    steps  = {
      "A Glittering Opportunity",
      "A Bloody Good Deed",
      "Sap Their Strength",
      "A Pounding Brain",
      "Zalazane's Apprentice",
      "Re-assembler!",
      "To Build a Pounder",
      "The Zeppelin Crash",
      "Delivery for Drazzit",
      "Secure the Cargo!",
      "A Letter From a Friend",
      "A Slaughter for Brains",
      "Return to Kheyna",
      "A Timely Situation",
      "An Infinite Hunt",
      "A Journey Into The Caverns",
      "The First Opening of The Dark Portal",
    },
  },
  {
    id     = "quest_turtle_si7_scarlet",
    name   = "Scarlet Masquerade",
    desc   = "Complete the SI:7 infiltration line.",
    points = 130,
    icon   = "Interface\\Icons\\INV_Misc_Cape_18",
    title  = {id="title_scarlet_shadow", name="the Scarlet Shadow", prefix=false},
    steps  = {
      "A Particular Letter",
      "The Elusive SI:7",
      "Young and Foolish",
      "Thandol Span",
      "Are You True to Your Nature?",
      "The Means of Persuading",
      "Seeking Justice or Vengeance?",
      "The Price Of Information",
      "Scarlet Aid",
      "Donning the Red Flag",
      "It's All in Their Brains",
      "Supplies We Need",
    },
  },
  {
    id     = "quest_turtle_dark_lady",
    name   = "Banshee's Gambit",
    desc   = "Complete the Forsaken anti-Scarlet intelligence chain.",
    points = 130,
    icon   = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    title  = {id="title_banshees_hand", name="the Banshee's Hand", prefix=false},
    steps  = {
      "A Dreadful Summon",
      "Grim News",
      "To Catch a Rat...",
      "Trusted Apothecary",
      "Consulting an Expert",
      "In Gunther's Favor",
      "Soul and Alchemy",
      "Dark Temper for a Dark Lady",
      "The Future Looks Grim",
      "A Different Shade of Red",
    },
  },
  {
    id     = "quest_turtle_alahthalas_legacy",
    name   = "Echoes of Alah'Thalas",
    desc   = "Complete the Alah'Thalas legacy line.",
    points = 80,
    icon   = "Interface\\Icons\\INV_Misc_Gem_Sapphire_02",
    steps  = {
      "Assisting the Children of the Sun",
      "To Alah'Thalas!",
      "A Crystal Clear Task",
      "Relics in Feralas",
      "Smashing Zul'Mashar",
      "Welcome to Alah'Thalas",
      "Tears of the Poppy",
      "Help With a Compassionate Matter",
      "Teslinah's Search I",
      "Teslinah's Search II",
      "Teslinah's Search III",
      "Teslinah's Search IV",
      "Teslinah's Search V",
    },
  },
  {
    id     = "quest_turtle_donation_drive",
    name   = "Two Banners, Ten Donations",
    desc   = "Complete all donation drives for Silvermoon Remnants and Revantusk Tribe.",
    points = 70,
    icon   = "Interface\\Icons\\INV_Misc_Coin_01",
    steps  = {
      "A Donation of Wool: Silvermoon Remnants",
      "A Donation of Silk: Silvermoon Remnants",
      "A Donation of Mageweave: Silvermoon Remnants",
      "A Donation of Runecloth: Silvermoon Remnants",
      "Additional Runecloth: Silvermoon Remnants",
      "A Donation of Wool: Revantusk Tribe",
      "A Donation of Silk: Revantusk Tribe",
      "A Donation of Mageweave: Revantusk Tribe",
      "A Donation of Runecloth: Revantusk Tribe",
      "Additional Runecloth: Revantusk Tribe",
    },
  },
  {
    id     = "quest_turtle_scale_requests",
    name   = "Scalebound Secrets",
    desc   = "Complete Aurelius's scale requests.",
    points = 55,
    icon   = "Interface\\Icons\\INV_Misc_MonsterScales_03",
    steps  = {
      "An Uncommon Request",
      "A Rare Request",
    },
  },
  {
    id     = "quest_turtle_lantern_rite",
    name   = "Lantern Rite",
    desc   = "Complete Illuminate the Moonlit Night.",
    points = 25,
    icon   = "Interface\\Icons\\INV_Misc_Lantern_01",
    steps  = {
      "Illuminate the Moonlit Night",
    },
  },
  {
    id     = "quest_turtle_beast_training",
    name   = "The Beast Within",
    desc   = "Complete Training the Beast.",
    points = 40,
    icon   = "Interface\\Icons\\Ability_Hunter_BeastTaming",
    steps  = {
      "Training the Beast",
    },
  },
  {
    id     = "quest_turtle_strategic_strike",
    name   = "Strategic Strike",
    desc   = "Complete Strategic Strike.",
    points = 80,
    icon   = "Interface\\Icons\\INV_Sword_48",
    steps  = {
      {name = "Strategic Strike", count = 1},
    },
  },
}

-- Map each normalized quest step to the chains that use it.
local STEP_TO_CHAINS = {}
local TRACKED_STEPS = {}

local function IndexQuestChains()
  STEP_TO_CHAINS = {}
  TRACKED_STEPS = {}
  for _, chain in ipairs(QUEST_CHAINS) do
    for _, step in ipairs(chain.steps or {}) do
      local stepName = GetStepData(step)
      local key = NormalizeQuestKey(stepName)
      if key then
        TRACKED_STEPS[key] = true
        if not STEP_TO_CHAINS[key] then STEP_TO_CHAINS[key] = {} end
        table.insert(STEP_TO_CHAINS[key], chain)
      end
    end
  end
end

IndexQuestChains()

-- ============================================================
-- Helpers
-- ============================================================

-- Check whether a chain is complete and award if so.
-- Pass silent=true when calling from a backlog/login scan.
local function CheckChain(me, chain, silent)
  if LeafVE_AchTest:HasAchievement(me, chain.id) then return end
  if not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.completedQuests then return end
  local completed = LeafVE_AchTest_DB.completedQuests[me]
  if not completed then return end

  for _, step in ipairs(chain.steps or {}) do
    local stepName, needed = GetStepData(step)
    if not stepName then return end
    if GetQuestCompletionCount(completed, stepName) < needed then return end
  end

  LeafVE_AchTest:AwardAchievement(chain.id, silent)
end

local function EnsureQuestCompletion(me, questName, silent)
  if not me or not questName or questName == "" then return end
  if not LeafVE_AchTest_DB then return end

  local key = NormalizeQuestKey(questName)
  if not key or not TRACKED_STEPS[key] then return end

  if not LeafVE_AchTest_DB.completedQuests then LeafVE_AchTest_DB.completedQuests = {} end
  if not LeafVE_AchTest_DB.completedQuests[me] then LeafVE_AchTest_DB.completedQuests[me] = {} end

  local completed = LeafVE_AchTest_DB.completedQuests[me]
  if ReadQuestCount(completed[key]) < 1 then
    completed[key] = 1
  end

  local legacyKey = LegacyQuestKey(questName)
  if legacyKey and legacyKey ~= key and ReadQuestCount(completed[legacyKey]) < 1 then
    completed[legacyKey] = 1
  end

  local chains = STEP_TO_CHAINS[key]
  if not chains then return end
  for _, chain in ipairs(chains) do
    CheckChain(me, chain, silent)
  end
end

if LeafVE_AchTest then
  LeafVE_AchTest.EnsureQuestCompletion = EnsureQuestCompletion
end

-- Record a quest completion and check impacted chains.
local lastQuestRecordKey = nil
local lastQuestRecordTime = 0
local QUEST_RECORD_DEDUPE_WINDOW = 0.75

local function RecordQuestCompletion(me, questName, silent)
  if not me or not questName or questName == "" then return end
  if not LeafVE_AchTest_DB then return end

  local key = NormalizeQuestKey(questName)
  if not key or not TRACKED_STEPS[key] then return end

  local now = GetTime and GetTime() or 0
  if now > 0 then
    local recordKey = string.lower(tostring(me)) .. "|" .. key
    if lastQuestRecordKey == recordKey and (now - lastQuestRecordTime) <= QUEST_RECORD_DEDUPE_WINDOW then
      return
    end
    lastQuestRecordKey = recordKey
    lastQuestRecordTime = now
  end

  if not LeafVE_AchTest_DB.completedQuests then LeafVE_AchTest_DB.completedQuests = {} end
  if not LeafVE_AchTest_DB.completedQuests[me] then LeafVE_AchTest_DB.completedQuests[me] = {} end

  local completed = LeafVE_AchTest_DB.completedQuests[me]
  local newCount = ReadQuestCount(completed[key]) + 1
  completed[key] = newCount

  -- Keep legacy lowercase key in sync so older code and old DB entries remain compatible.
  local legacyKey = LegacyQuestKey(questName)
  if legacyKey and legacyKey ~= key then
    local legacyCount = ReadQuestCount(completed[legacyKey])
    if newCount > legacyCount then
      completed[legacyKey] = newCount
    end
  end

  local chains = STEP_TO_CHAINS[key]
  if not chains then return end
  for _, chain in ipairs(chains) do
    CheckChain(me, chain, silent)
  end
end

if LeafVE_AchTest then
  LeafVE_AchTest.RecordQuestCompletion = RecordQuestCompletion
end

local ATTN_ZONE_BACKFILL = {
  ["Molten Core"] = "Attunement to the Core",
  ["Blackwing Lair"] = "Blackhand's Command",
}

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

local function CheckRaidAttunementBackfill(silent)
  local me = LeafVE_AchTest and LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  if not me then return end
  local zoneName = GetCurrentZoneName()
  local questName = ATTN_ZONE_BACKFILL[zoneName]
  if questName then
    EnsureQuestCompletion(me, questName, silent)
  end
end

-- ============================================================
-- Registration
-- ============================================================

local function RegisterQuestChainAchievements()
  LeafVE_AchTest.NormalizeQuestStepKey = NormalizeQuestKey
  for _, chain in ipairs(QUEST_CHAINS) do
    LeafVE_AchTest:AddAchievement(chain.id, {
      id          = chain.id,
      name        = chain.name,
      desc        = chain.desc,
      category    = "Quests",
      points      = chain.points or 50,
      icon        = chain.icon,
      _questSteps = chain.steps,
    })
    if chain.title and LeafVE_AchTest.AddTitle then
      LeafVE_AchTest:AddTitle({
        id          = chain.title.id,
        name        = chain.title.name,
        achievement = chain.id,
        prefix      = chain.title.prefix or false,
        category    = "Quests",
        icon        = chain.icon,
      })
    end
  end
end

-- ============================================================
-- Event handler
-- ============================================================

local questFrame = CreateFrame("Frame")
questFrame:RegisterEvent("ADDON_LOADED")
questFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
questFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
questFrame:RegisterEvent("ZONE_CHANGED")
questFrame:RegisterEvent("ZONE_CHANGED_INDOORS")

questFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageAchievements" then
    if LeafVE_AchTest then
      LeafVE_AchTest.NormalizeQuestStepKey = NormalizeQuestKey
      LeafVE_AchTest.EnsureQuestCompletion = EnsureQuestCompletion
      LeafVE_AchTest.RecordQuestCompletion = RecordQuestCompletion
    end
    if LeafVE_AchTest and LeafVE_AchTest.AddAchievement then
      RegisterQuestChainAchievements()
    end
    -- Backlog: re-check chains in case required steps were completed in a prior session.
    local me = LeafVE_AchTest and LeafVE_AchTest.ShortName and
               LeafVE_AchTest.ShortName(UnitName("player"))
    if me then
      for _, chain in ipairs(QUEST_CHAINS) do
        CheckChain(me, chain, true)
      end
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    CheckRaidAttunementBackfill(true)
  elseif event == "ZONE_CHANGED_NEW_AREA"
    or event == "ZONE_CHANGED"
    or event == "ZONE_CHANGED_INDOORS" then
    CheckRaidAttunementBackfill(false)
  end
end)
