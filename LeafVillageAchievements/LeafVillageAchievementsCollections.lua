--[[
LeafVillageAchievements integrated collections module.

This module is part of the main achievements addon. It provides the locked
2D mount and companion collection tabs, independent searches, acquisition
sources, spellbook detection, summoning buttons, and collection achievements.
There is no separate AshenBannerCollections addon dependency and no active
3D model renderer.
]]

LeafVE_AchTest = LeafVE_AchTest or {}
LeafVillageAchievements = LeafVE_AchTest
LeafVE_AchTest.Collections = LeafVE_AchTest.Collections or {}

-- Compatibility alias for old internal references. This is not a separate addon.
AshenBannerCollections = LeafVE_AchTest.Collections
local ABC = LeafVE_AchTest.Collections
ABC.version = "4.1.1-MOUNT-ICON-AUDIT"

-- Collection UI preferences now live inside the main addon's per-character DB.
LeafVE_AchTest_DB = LeafVE_AchTest_DB or {}
LeafVE_AchTest_DB.collectionSettings = LeafVE_AchTest_DB.collectionSettings or {}
AshenBannerCollectionsDB = LeafVE_AchTest_DB.collectionSettings
ABC.runtime = ABC.runtime or { mounts = {}, companions = {}, toys = {}, allSpells = {} }
ABC.installedHooks = false
ABC.pendingInstall = true
ABC.scanCount = 0
ABC.buildingCollectionView = false

local BOOK_SPELL = BOOKTYPE_SPELL or "spell"
local BOOK_PET = BOOKTYPE_PET or "pet"

local function Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFB45A2B[Ashen Achievements]|r "..tostring(msg))
  end
end

local function Trim(s)
  return string.gsub(s or "", "^%s*(.-)%s*$", "%1")
end

local function Lower(s)
  return string.lower(tostring(s or ""))
end

local function tcount(t)
  local n = 0
  if type(t) == "table" then
    for _ in pairs(t) do n = n + 1 end
  end
  return n
end

local function EnsureDB()
  if not AshenBannerCollectionsDB then AshenBannerCollectionsDB = {} end
  if type(AshenBannerCollectionsDB.models) ~= "table" then AshenBannerCollectionsDB.models = {} end
  if type(AshenBannerCollectionsDB.models.mounts) ~= "table" then AshenBannerCollectionsDB.models.mounts = {} end
  if type(AshenBannerCollectionsDB.models.companions) ~= "table" then AshenBannerCollectionsDB.models.companions = {} end
  if type(AshenBannerCollectionsDB.lastSeen) ~= "table" then AshenBannerCollectionsDB.lastSeen = {} end
  if type(AshenBannerCollectionsDB.modelView) ~= "table" then AshenBannerCollectionsDB.modelView = { mounts = {}, companions = {} } end
  if type(AshenBannerCollectionsDB.familyView) ~= "table" then AshenBannerCollectionsDB.familyView = { mounts = {}, companions = {} } end
  if AshenBannerCollectionsDB.rendererVersion ~= 5 then
    AshenBannerCollectionsDB.modelView = { mounts = {}, companions = {} }
    AshenBannerCollectionsDB.familyView = { mounts = {}, companions = {} }
    AshenBannerCollectionsDB.rendererVersion = 5
  end
  if type(AshenBannerCollectionsDB.mountFilter) ~= "string" then
    AshenBannerCollectionsDB.mountFilter = "All"
  end
  if type(AshenBannerCollectionsDB.companionFilter) ~= "string" then
    AshenBannerCollectionsDB.companionFilter = "All"
  end
  if type(AshenBannerCollectionsDB.toyFilter) ~= "string" then
    AshenBannerCollectionsDB.toyFilter = "All"
  end
  if type(AshenBannerCollectionsDB.portraitView) ~= "table" then
    AshenBannerCollectionsDB.portraitView = { mounts = {}, companions = {} }
  end
  if type(AshenBannerCollectionsDB.portraitFamilyView) ~= "table" then
    AshenBannerCollectionsDB.portraitFamilyView = { mounts = {}, companions = {} }
  end
  -- Preserve every mount's saved placement across renderer updates. Earlier
  -- proof builds cleared this table whenever the proof version changed, which
  -- made hand-calibration impossible. New fields are migrated in-place.
  if type(AshenBannerCollectionsDB.use3DProof) ~= "boolean" then
    AshenBannerCollectionsDB.use3DProof = true
  end
  if type(AshenBannerCollectionsDB.threeDView) ~= "table" then
    AshenBannerCollectionsDB.threeDView = {}
  end
  if AshenBannerCollectionsDB.threeDProofVersion ~= "1.2.0" then
    for _, profile in pairs(AshenBannerCollectionsDB.threeDView) do
      if type(profile) == "table" then
        if profile.frameX == nil then profile.frameX = 0 end
        if profile.frameY == nil then profile.frameY = 0 end
      end
    end
    AshenBannerCollectionsDB.threeDProofVersion = "1.2.0"
  end

  if not LeafVE_AchTest_DB then LeafVE_AchTest_DB = {} end
  if type(LeafVE_AchTest_DB.collections) ~= "table" then LeafVE_AchTest_DB.collections = {} end
  if type(LeafVE_AchTest_DB.collections.mounts) ~= "table" then LeafVE_AchTest_DB.collections.mounts = {} end
  if type(LeafVE_AchTest_DB.collections.companions) ~= "table" then LeafVE_AchTest_DB.collections.companions = {} end
  if type(LeafVE_AchTest_DB.collections.toys) ~= "table" then LeafVE_AchTest_DB.collections.toys = {} end

  -- Guild-wide ownership data synced in via COLSYNC (see LeafVillageAchievements.lua).
  -- Guarded here too since this file's EnsureDB may run before the other chunk's.
  if type(LeafVE_AchTest_DB.guildCollections) ~= "table" then LeafVE_AchTest_DB.guildCollections = {} end
  if type(LeafVE_AchTest_DB.guildCollections.mounts) ~= "table" then LeafVE_AchTest_DB.guildCollections.mounts = {} end
  if type(LeafVE_AchTest_DB.guildCollections.companions) ~= "table" then LeafVE_AchTest_DB.guildCollections.companions = {} end
  if type(LeafVE_AchTest_DB.guildCollections.toys) ~= "table" then LeafVE_AchTest_DB.guildCollections.toys = {} end
end

local function SafeCall(obj, method, a, b, c, d)
  if obj and obj[method] then
    pcall(function() obj[method](obj, a, b, c, d) end)
  end
end

local function ClearPoint(frame)
  if frame and frame.ClearAllPoints then frame:ClearAllPoints() end
end

-- Starter database. This is intentionally light: Turtle custom spells should be learned from spellbook tabs.
-- Add exact model IDs in-game with /abcoll model mount <Spell Name> <CreatureID>
-- or put them here as creatureID = 12345.
local ABC_MOUNT_CREATURE_IDS = {
  ["Ancient Frostsaber"] = 10322,
  ["Arctic Wolf"] = 359,
  ["Black Battlestrider"] = 14334,
  ["Black Nightsaber"] = 7322,
  ["Black Qiraji Battle Tank"] = 15666,
  ["Black Ram"] = 4780,
  ["Black Stallion"] = 308,
  ["Black War Kodo"] = 14333,
  ["Black War Ram"] = 14335,
  ["Black War Raptor"] = 14330,
  ["Black War Steed"] = 14332,
  ["Black War Tiger"] = 14336,
  ["Black War Wolf"] = 14329,
  ["Black Wolf"] = 356,
  ["Blue Mechanostrider"] = 7749,
  ["Blue Qiraji Battle Tank"] = 15713,
  ["Blue Ram"] = 4778,
  ["Blue Skeletal Horse"] = 11154,
  ["Brown Horse"] = 284,
  ["Brown Kodo"] = 11689,
  ["Brown Ram"] = 4779,
  ["Brown Skeletal Horse"] = 11155,
  ["Brown Wolf"] = 4272,
  ["Chestnut Mare"] = 4269,
  ["Chromatic Mount"] = 15135,
  ["Dire Wolf"] = 4271,
  ["Dreadsteed"] = 14505,
  ["Emerald Raptor"] = 6075,
  ["Felsteed"] = 304,
  ["Fluorescent Green Mechanostrider"] = 10178,
  ["Frost Ram"] = 4778,
  ["Frostwolf Howler"] = 14744,
  ["Golden Sabercat"] = 10338,
  ["Gray Kodo"] = 12149,
  ["Gray Ram"] = 4710,
  ["Gray Wolf"] = 4268,
  ["Great Brown Kodo"] = 14549,
  ["Great Gray Kodo"] = 14550,
  ["Great White Kodo"] = 14542,
  ["Green Kodo"] = 12151,
  ["Green Mechanostrider"] = 10178,
  ["Green Qiraji Battle Tank"] = 15715,
  ["Green Skeletal Warhorse"] = 11156,
  ["Icy Blue Mechanostrider Mod A"] = 11150,
  ["Ivory Raptor"] = 7706,
  ["Leopard"] = 7684,
  ["Mottled Red Raptor"] = 7704,
  ["Naxxramas Deathcharger"] = 11195,
  ["Nether Drake"] = 15135,
  ["Obsidian Raptor"] = 7703,
  ["Palamino"] = 306,
  ["Palomino"] = 306,
  ["Pinto"] = 307,
  ["Primal Leopard"] = 10336,
  ["Purple Mechanostrider"] = 11148,
  ["Purple Skeletal Warhorse"] = 14558,
  ["Red Mechanostrider"] = 7739,
  ["Red Qiraji Battle Tank"] = 15716,
  ["Red Skeletal Horse"] = 11153,
  ["Red Skeletal Warhorse"] = 14331,
  ["Red Wolf"] = 4270,
  ["Red and Blue Mechanostrider"] = 11149,
  ["Reindeer"] = 15524,
  ["Riding Kodo"] = 11689,
  ["Riding Turtle"] = 17266,
  ["Rivendare's Deathcharger"] = 11195,
  ["Skeletal Horse"] = 6486,
  ["Spotted Frostsaber"] = 7687,
  ["Spotted Panther"] = 7689,
  ["Steel Mechanostrider"] = 10180,
  ["Stormpike Battle Charger"] = 14745,
  ["Striped Frostsaber"] = 6074,
  ["Striped Nightsaber"] = 7690,
  ["Summon Brown Tallstrider"] = 7709,
  ["Summon Charger"] = 14565,
  ["Summon Gray Tallstrider"] = 7710,
  ["Summon Ivory Tallstrider"] = 6076,
  ["Summon Pink Tallstrider"] = 7711,
  ["Summon Purple Tallstrider"] = 7712,
  ["Summon Turquoise Tallstrider"] = 7713,
  ["Summon Warhorse"] = 9158,
  ["Swift Blue Raptor"] = 14545,
  ["Swift Brown Ram"] = 14546,
  ["Swift Brown Steed"] = 14561,
  ["Swift Brown Wolf"] = 14540,
  ["Swift Dawnsaber"] = 14557,
  ["Swift Frostsaber"] = 14556,
  ["Swift Gray Ram"] = 14548,
  ["Swift Gray Wolf"] = 14541,
  ["Swift Green Mechanostrider"] = 14553,
  ["Swift Mistsaber"] = 14555,
  ["Swift Olive Raptor"] = 14543,
  ["Swift Orange Raptor"] = 14544,
  ["Swift Palomino"] = 14559,
  ["Swift Razzashi Raptor"] = 15090,
  ["Swift Stormsaber"] = 14602,
  ["Swift Timber Wolf"] = 14539,
  ["Swift White Mechanostrider"] = 14552,
  ["Swift White Ram"] = 14547,
  ["Swift White Steed"] = 14560,
  ["Swift Yellow Mechanostrider"] = 14551,
  ["Swift Zulian Tiger"] = 15104,
  ["Tawny Sabercat"] = 10337,
  ["Teal Kodo"] = 12148,
  ["Tiger"] = 7686,
  ["Timber Wolf"] = 358,
  ["Turquoise Raptor"] = 7707,
  ["Unpainted Mechanostrider"] = 10180,
  ["Violet Raptor"] = 7708,
  ["White Mechanostrider Mod B"] = 10179,
  ["White Ram"] = 4777,
  ["White Stallion"] = 305,
  ["Winter Wolf"] = 359,
  ["Winterspring Frostsaber"] = 11021,
  ["Yellow Qiraji Battle Tank"] = 15714,
}

local ABC_MOUNT_DISPLAY_BY_CREATURE = {
  [284] = 2404,
  [304] = 2346,
  [305] = 2410,
  [306] = 2408,
  [307] = 2409,
  [308] = 2402,
  [356] = 207,
  [358] = 247,
  [359] = 1166,
  [4268] = 2320,
  [4269] = 2405,
  [4270] = 2326,
  [4271] = 2327,
  [4272] = 2328,
  [4710] = 2736,
  [4777] = 2786,
  [4778] = 2784,
  [4779] = 2785,
  [4780] = 2787,
  [6074] = 6080,
  [6075] = 4806,
  [6486] = 1951,
  [7322] = 9991,
  [7687] = 6444,
  [7689] = 11448,
  [7690] = 6448,
  [7703] = 6468,
  [7704] = 6469,
  [7706] = 6471,
  [7707] = 6472,
  [7708] = 6473,
  [7739] = 9473,
  [7749] = 6569,
  [10179] = 9474,
  [10180] = 9476,
  [10322] = 6080,
  [11021] = 10426,
  [11150] = 10666,
  [11153] = 10670,
  [11154] = 10671,
  [11155] = 10672,
  [11156] = 10720,
  [11195] = 10718,
  [11689] = 11641,
  [12148] = 12242,
  [12149] = 12244,
  [12151] = 12245,
  [14329] = 14334,
  [14330] = 14388,
  [14331] = 10719,
  [14332] = 14337,
  [14333] = 14348,
  [14334] = 14372,
  [14335] = 14577,
  [14336] = 14330,
  [14505] = 14554,
  [14539] = 14575,
  [14540] = 14573,
  [14541] = 14574,
  [14542] = 14349,
  [14543] = 14344,
  [14544] = 14342,
  [14545] = 14339,
  [14546] = 14347,
  [14547] = 14346,
  [14548] = 14576,
  [14549] = 14578,
  [14550] = 14579,
  [14551] = 14377,
  [14552] = 14376,
  [14553] = 14374,
  [14555] = 14332,
  [14556] = 14331,
  [14557] = 14329,
  [14558] = 10721,
  [14559] = 14582,
  [14560] = 14338,
  [14561] = 14583,
  [14602] = 14632,
  [14744] = 14776,
  [14745] = 14777,
  [15090] = 15289,
  [15104] = 15290,
  [15524] = 15902,
  [15666] = 15677,
  [15713] = 15678,
  [15714] = 15680,
  [15715] = 15679,
  [15716] = 15681,
  [17266] = 17158,
}

local ABC_MOUNT_MODEL_INFO = {
  [284] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [304] = { path = "Creature\\Nightmare\\Nightmare.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [305] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [306] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [307] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [308] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [356] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [358] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [359] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4268] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4269] = { path = "Creature\\RidingHorse\\RidingHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [4270] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4271] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4272] = { path = "Creature\\DireWolf\\RidingDireWolf.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4710] = { path = "Creature\\Ram\\RidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4777] = { path = "Creature\\Ram\\RidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4778] = { path = "Creature\\Ram\\RidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4779] = { path = "Creature\\Ram\\RidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [4780] = { path = "Creature\\Ram\\RidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [6074] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [6075] = { path = "Creature\\RidingRaptor\\RidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [6486] = { path = "Creature\\Horse\\Horse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [7322] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7687] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7689] = { path = "Creature\\Tiger\\Tiger.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7690] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7703] = { path = "Creature\\Raptor\\Raptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7704] = { path = "Creature\\RidingRaptor\\RidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7706] = { path = "Creature\\RidingRaptor\\RidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7707] = { path = "Creature\\RidingRaptor\\RidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7708] = { path = "Creature\\RidingRaptor\\RidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7739] = { path = "Creature\\MechaStrider\\MechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [7749] = { path = "Creature\\MechaStrider\\MechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [10179] = { path = "Creature\\MechaStrider\\MechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [10180] = { path = "Creature\\MechaStrider\\MechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [10322] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [11021] = { path = "Creature\\FrostSabre\\RidingFrostSabre.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [11150] = { path = "Creature\\MechaStrider\\MechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [11153] = { path = "Creature\\UndeadHorse\\RidingUndeadHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [11154] = { path = "Creature\\UndeadHorse\\RidingUndeadHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [11155] = { path = "Creature\\UndeadHorse\\RidingUndeadHorse.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [11156] = { path = "Creature\\MountedDeathKnight\\RidingUndeadWarHorse.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [11195] = { path = "Creature\\DeathKnightMount\\DeathKnightMount.m2", scale = 0.1969, x = 0, y = -0.18, z = -0.7 },
  [11689] = { path = "Creature\\Kodobeast\\RidingKodo.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [12148] = { path = "Creature\\Kodobeast\\RidingKodo.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [12149] = { path = "Creature\\Kodobeast\\RidingKodo.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [12151] = { path = "Creature\\Kodobeast\\RidingKodo.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14329] = { path = "Creature\\HordePvPMount\\HordePvPMount.m2", scale = 0.2058, x = 0, y = -0.18, z = -0.7 },
  [14330] = { path = "Creature\\ViciousWarRaptor\\ViciousWarRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14331] = { path = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14332] = { path = "Creature\\AlliancePVPMount\\AlliancePVPMount.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [14333] = { path = "Creature\\Kodobeast\\KodoBeastPvPT2.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14334] = { path = "Creature\\ViciousWarMechanoStrider\\ViciousWarMechanoStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14335] = { path = "Creature\\Ram\\PVPRidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14336] = { path = "Creature\\WarnightSabermount\\WarnightSabermount.m2", scale = 0.2017, x = 0, y = -0.18, z = -0.7 },
  [14505] = { path = "Creature\\Nightmare\\Gorgon101.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [14539] = { path = "Creature\\DireWolf\\PvPRidingDireWolf.m2", scale = 0.2058, x = 0, y = -0.18, z = -0.7 },
  [14540] = { path = "Creature\\DireWolf\\PvPRidingDireWolf.m2", scale = 0.2058, x = 0, y = -0.18, z = -0.7 },
  [14541] = { path = "Creature\\DireWolf\\PvPRidingDireWolf.m2", scale = 0.2058, x = 0, y = -0.18, z = -0.7 },
  [14542] = { path = "Creature\\Kodobeast\\KodoBeastPvPT2.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14543] = { path = "Creature\\RidingRaptor\\PvPRidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14544] = { path = "Creature\\RidingRaptor\\PvPRidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14545] = { path = "Creature\\RidingRaptor\\PvPRidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14546] = { path = "Creature\\Ram\\PVPRidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14547] = { path = "Creature\\Ram\\PVPRidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14548] = { path = "Creature\\Ram\\PVPRidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14549] = { path = "Creature\\Kodobeast\\KodoBeastPvPT2.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14550] = { path = "Creature\\Kodobeast\\KodoBeastPvPT2.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14551] = { path = "Creature\\MechaStrider\\PvPMechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14552] = { path = "Creature\\MechaStrider\\PvPMechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14553] = { path = "Creature\\MechaStrider\\PvPMechaStrider.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14555] = { path = "Creature\\FrostSabre\\PVPRidingFrostSabre.m2", scale = 0.288, x = 0, y = -0.18, z = -0.7 },
  [14556] = { path = "Creature\\FrostSabre\\PVPRidingFrostSabre.m2", scale = 0.288, x = 0, y = -0.18, z = -0.7 },
  [14557] = { path = "Creature\\FrostSabre\\PVPRidingFrostSabre.m2", scale = 0.288, x = 0, y = -0.18, z = -0.7 },
  [14558] = { path = "Creature\\MountedDeathKnight\\RidingUndeadWarHorse.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [14559] = { path = "Creature\\RidingHorse\\RidingHorsePvPT2.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [14560] = { path = "Creature\\RidingHorse\\RidingHorsePvPT2.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [14561] = { path = "Creature\\RidingHorse\\RidingHorsePvPT2.m2", scale = 0.144, x = 0, y = -0.18, z = -0.7 },
  [14602] = { path = "Creature\\FrostSabre\\PVPRidingFrostSabre.m2", scale = 0.288, x = 0, y = -0.18, z = -0.7 },
  [14744] = { path = "Creature\\KorkronEliteWolf\\KorkronEliteWolf.m2", scale = 0.2058, x = 0, y = -0.18, z = -0.7 },
  [14745] = { path = "Creature\\Ram\\PVPRidingRam.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [15090] = { path = "Creature\\RidingRaptor\\PvPRidingRaptor.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
  [15104] = { path = "Creature\\FrostSabre\\PVPRidingFrostSabre.m2", scale = 0.288, x = 0, y = -0.18, z = -0.7 },
  [15524] = { path = "Creature\\ReinDeer\\ReinDeerMount.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [15666] = { path = "Creature\\RidingSilithid\\RidingSilithid.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [15713] = { path = "Creature\\RidingSilithid\\RidingSilithid.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [15714] = { path = "Creature\\RidingSilithid\\RidingSilithid.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [15715] = { path = "Creature\\RidingSilithid\\RidingSilithid.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [15716] = { path = "Creature\\RidingSilithid\\RidingSilithid.m2", scale = 0.2, x = 0, y = -0.18, z = -0.7 },
  [17266] = { path = "Creature\\RidingTurtle\\RidingTurtle.m2", scale = 0.192, x = 0, y = -0.18, z = -0.7 },
}

ABC.defaultMountData = {
  ["Riding Turtle"] = { source = "Turtle WoW mount collection", speed = "Slow", creatureID = nil },
  ["Swift Brown Steed"] = { source = "Human racial mount", speed = "100%", creatureID = nil },
  ["Brown Horse"] = { source = "Human racial mount", speed = "60%", creatureID = nil },
  ["Black Stallion"] = { source = "Human racial mount", speed = "60%", creatureID = nil },
  ["Chestnut Mare"] = { source = "Human racial mount", speed = "60%", creatureID = nil },
  ["Swift Palomino"] = { source = "Human racial mount", speed = "100%", creatureID = nil },
  ["Swift White Steed"] = { source = "Human racial mount", speed = "100%", creatureID = nil },
  ["Gray Ram"] = { source = "Dwarf racial mount", speed = "60%", creatureID = nil },
  ["Brown Ram"] = { source = "Dwarf racial mount", speed = "60%", creatureID = nil },
  ["White Ram"] = { source = "Dwarf racial mount", speed = "60%", creatureID = nil },
  ["Swift Gray Ram"] = { source = "Dwarf racial mount", speed = "100%", creatureID = nil },
  ["Swift Brown Ram"] = { source = "Dwarf racial mount", speed = "100%", creatureID = nil },
  ["Swift White Ram"] = { source = "Dwarf racial mount", speed = "100%", creatureID = nil },
  ["Green Mechanostrider"] = { source = "Gnome racial mount", speed = "60%", creatureID = nil },
  ["Unpainted Mechanostrider"] = { source = "Gnome racial mount", speed = "60%", creatureID = nil },
  ["Blue Mechanostrider"] = { source = "Gnome racial mount", speed = "60%", creatureID = nil },
  ["Swift Green Mechanostrider"] = { source = "Gnome racial mount", speed = "100%", creatureID = nil },
  ["Swift White Mechanostrider"] = { source = "Gnome racial mount", speed = "100%", creatureID = nil },
  ["Swift Yellow Mechanostrider"] = { source = "Gnome racial mount", speed = "100%", creatureID = nil },
  ["Reins of the Winterspring Frostsaber"] = { source = "Winterspring", speed = "100%", creatureID = nil },
  ["Frostwolf Howler"] = { source = "Alterac Valley", speed = "100%", creatureID = nil },
  ["Stormpike Battle Charger"] = { source = "Alterac Valley", speed = "100%", creatureID = nil },
}

ABC.defaultCompanionData = {
  ["Ancona Chicken"] = { source = "Companion collection", creatureID = nil },
  ["Black Tabby"] = { source = "Companion collection", creatureID = nil },
  ["Bombay Cat"] = { source = "Companion collection", creatureID = nil },
  ["Cornish Rex Cat"] = { source = "Companion collection", creatureID = nil },
  ["Orange Tabby Cat"] = { source = "Companion collection", creatureID = nil },
  ["Silver Tabby Cat"] = { source = "Companion collection", creatureID = nil },
  ["White Kitten"] = { source = "Companion collection", creatureID = nil },
  ["Cockatiel"] = { source = "Companion collection", creatureID = nil },
  ["Senegal"] = { source = "Companion collection", creatureID = nil },
  ["Hawk Owl"] = { source = "Companion collection", creatureID = nil },
  ["Great Horned Owl"] = { source = "Companion collection", creatureID = nil },
  ["Prairie Dog"] = { source = "Companion collection", creatureID = nil },
  ["Tiny Black Whelpling"] = { source = "Companion collection", creatureID = nil },
  ["Tiny Crimson Whelpling"] = { source = "Companion collection", creatureID = nil },
  ["Tiny Emerald Whelpling"] = { source = "Companion collection", creatureID = nil },
  ["Dark Whelpling"] = { source = "Companion collection", creatureID = nil },
}

local function BuildMasterLists()
  ABC.masterMountList = {}
  for name, creatureID in pairs(ABC_MOUNT_CREATURE_IDS) do
    local base = ABC.defaultMountData[name] or {}
    local displayID = ABC_MOUNT_DISPLAY_BY_CREATURE[creatureID]
    local info = ABC_MOUNT_MODEL_INFO[creatureID]
    ABC.masterMountList[name] = {
      name = name,
      source = base.source or "Mount collection",
      speed = base.speed,
      creatureID = creatureID,
      displayID = displayID,
      model = info and info.path,
      modelScale = info and info.scale,
      x = info and info.x,
      y = info and info.y,
      z = info and info.z,
      icon = base.icon,
      -- ABC_OCTOWOW_MOUNTS already carries the real item ID for most
      -- entries -- wasn't being copied through to the row objects the
      -- icon-resolution code (ABC_GetMountItemTexture) actually reads.
      itemID = base.itemID,
    }
  end

  ABC.masterCompanionList = {}
  local companionMaster = LeafVE_Ach_CompanionsMaster or ABC.defaultCompanionData
  for name, info in pairs(companionMaster) do
    local base = ABC.defaultCompanionData[name] or {}
    ABC.masterCompanionList[name] = {
      name = name,
      source = (type(info) == "table" and info.source) or base.source or "Companion collection",
      obtainedFrom = (type(info) == "table" and info.obtainedFrom) or base.obtainedFrom,
      sourceConfidence = (type(info) == "table" and info.sourceConfidence) or base.sourceConfidence,
      category = (type(info) == "table" and (info.sourceCategory or info.category)) or base.category,
      sourceCategory = (type(info) == "table" and (info.sourceCategory or info.category)) or base.sourceCategory,
      points = (type(info) == "table" and info.points) or base.points,
      difficulty = (type(info) == "table" and info.difficulty) or base.difficulty,
      achievementId = (type(info) == "table" and info.achievementId) or base.achievementId,
      icon = (type(info) == "table" and info.icon) or base.icon,
      creatureID = base.creatureID,
      -- Populated from COMPANION_CATALOG's itemID (LeafVE_Ach_Companions.lua)
      -- via LeafVE_Ach_CompanionsMaster, same idea as mounts above.
      itemID = (type(info) == "table" and info.itemID) or base.itemID,
    }
  end

  ABC.masterToyList = {}
  for name, info in pairs(LeafVE_Ach_ToysMaster or {}) do
    ABC.masterToyList[name] = {
      name = name,
      source = info.source,
      obtainedFrom = info.obtainedFrom,
      sourceConfidence = info.sourceConfidence,
      category = info.category or info.sourceCategory,
      sourceCategory = info.sourceCategory,
      points = info.points,
      difficulty = info.difficulty,
      achievementId = info.achievementId,
      icon = info.icon,
      itemID = info.itemID,
      description = info.description,
    }
  end
end
BuildMasterLists()

local function MergeData(kind, spellName, icon, tabName, spellIndex, bookType)
  EnsureDB()
  if not spellName or spellName == "" then return end

  local key = (kind == "mount") and "mounts" or "companions"
  local defaults = (kind == "mount") and ABC.defaultMountData or ABC.defaultCompanionData
  local saved = LeafVE_AchTest_DB.collections[key]
  local override = AshenBannerCollectionsDB.models[key][spellName]
  local base = defaults[spellName] or {}

  if type(saved[spellName]) ~= "table" then saved[spellName] = {} end
  saved[spellName].name = spellName
  saved[spellName].icon = icon or saved[spellName].icon or base.icon
  saved[spellName].tabName = tabName or saved[spellName].tabName
  saved[spellName].seenAt = time and time() or saved[spellName].seenAt or 0
  saved[spellName].source = saved[spellName].source or base.source or (tabName and ("Spellbook: "..tabName) or "Spellbook collection")
  saved[spellName].speed = saved[spellName].speed or base.speed

  local creatureID = tonumber(override or base.creatureID or saved[spellName].creatureID or (kind == "mount" and ABC_MOUNT_CREATURE_IDS[spellName]))
  if creatureID and creatureID > 0 then saved[spellName].creatureID = creatureID end

  local displayID = tonumber(saved[spellName].displayID or (kind == "mount" and creatureID and ABC_MOUNT_DISPLAY_BY_CREATURE[creatureID]))
  if displayID and displayID > 0 then saved[spellName].displayID = displayID end

  local info = (kind == "mount" and creatureID and ABC_MOUNT_MODEL_INFO[creatureID])
  if info then
    saved[spellName].model = info.path
    saved[spellName].modelScale = info.scale
    saved[spellName].x = info.x
    saved[spellName].y = info.y
    saved[spellName].z = info.z
  end



  ABC.runtime[key][spellName] = {
    name = spellName,
    icon = icon or saved[spellName].icon,
    tabName = tabName,
    spellIndex = spellIndex,
    bookType = bookType or BOOK_SPELL,
    source = saved[spellName].source,
    speed = saved[spellName].speed,
    creatureID = creatureID,
    displayID = displayID,
    model = saved[spellName].model,
    modelScale = saved[spellName].modelScale,
    x = saved[spellName].x,
    y = saved[spellName].y,
    z = saved[spellName].z,
  }
end

local function IsKnownMount(spellName)
  return (ABC.defaultMountData[spellName] ~= nil) or (ABC.masterMountList and ABC.masterMountList[spellName] ~= nil)
end

local function IsKnownCompanion(spellName)
  return (ABC.defaultCompanionData[spellName] ~= nil) or (ABC.masterCompanionList and ABC.masterCompanionList[spellName] ~= nil)
end

local function ClassifySpell(spellName, tabName)
  local tab = Lower(tabName)
  local name = Lower(spellName)

  if string.find(tab, "mount") or string.find(tab, "riding") then return "mount" end
  if string.find(tab, "companion") or string.find(tab, "companions") or string.find(tab, "pet") or string.find(tab, "pets") or string.find(tab, "critter") or string.find(tab, "vanity") then return "companion" end

  if IsKnownMount(spellName) then return "mount" end
  if IsKnownCompanion(spellName) then return "companion" end

  -- Gentle fallback: catches many vanilla/Turtle mount names without turning normal spells into mounts.
  if string.find(name, "steed") or string.find(name, "stallion") or string.find(name, "mare") or string.find(name, "ram") or string.find(name, "mechanostrider") or string.find(name, "frostsaber") or string.find(name, "charger") or string.find(name, "howler") or string.find(name, "kodo") or string.find(name, "raptor") or string.find(name, "tiger") or string.find(name, "wolf") or string.find(name, "turtle") then
    return "mount"
  end

  return nil
end

local function ScanSpellByIndex(index, bookType, tabName)
  if not GetSpellName then return false end
  local spellName, spellRank = GetSpellName(index, bookType or BOOK_SPELL)
  if not spellName then return false end

  local icon
  if GetSpellTexture then icon = GetSpellTexture(index, bookType or BOOK_SPELL) end
  table.insert(ABC.runtime.allSpells, { name = spellName, rank = spellRank, icon = icon, index = index, bookType = bookType or BOOK_SPELL, tabName = tabName })

  local kind = ClassifySpell(spellName, tabName)
  if kind == "mount" then
    MergeData("mount", spellName, icon, tabName, index, bookType or BOOK_SPELL)
  elseif kind == "companion" then
    MergeData("companion", spellName, icon, tabName, index, bookType or BOOK_SPELL)
  end
  return true
end

function ABC:ScanSpellbook(verbose)
  EnsureDB()
  if ABC.PurgeRejectedMountData then ABC:PurgeRejectedMountData() end
  ABC.runtime.mounts = {}
  ABC.runtime.companions = {}
  ABC.runtime.toys = {}
  ABC.runtime.allSpells = {}
  ABC.scanCount = ABC.scanCount + 1

  local scannedTabs = false
  if GetNumSpellTabs and GetSpellTabInfo then
    local nTabs = GetNumSpellTabs() or 0
    for tabIndex = 1, nTabs do
      local tabName, tabTexture, offset, numSpells = GetSpellTabInfo(tabIndex)
      offset = tonumber(offset) or 0
      numSpells = tonumber(numSpells) or 0
      if numSpells > 0 then
        scannedTabs = true
        local firstIndex = offset + 1
        local lastIndex = offset + numSpells
        for i = firstIndex, lastIndex do
          ScanSpellByIndex(i, BOOK_SPELL, tabName)
        end
      end
    end
  end

  -- Fallback: scan the main spell book linearly. This is also useful if Turtle exposes the collection
  -- spells without giving them normal spell tabs.
  local i = 1
  while i <= 600 do
    local ok = ScanSpellByIndex(i, BOOK_SPELL, nil)
    if not ok then break end
    i = i + 1
  end

  -- Some clients expose companion-like pet spells through the pet book. It usually returns nil if no pet.
  local p = 1
  while p <= 200 do
    local ok = ScanSpellByIndex(p, BOOK_PET, "Pet")
    if not ok then break end
    p = p + 1
  end

  if verbose then
    Print("Scan complete: "..tostring(tcount(ABC.runtime.mounts)).." mounts, "..tostring(tcount(ABC.runtime.companions)).." companions detected.")
    Print("Use /abcoll dump to list every spellbook entry seen by the addon.")
  end

  -- Skip this when a BuildCollectionView call further up the stack is what
  -- triggered this scan (first-ever load, scanCount was 0) -- that caller
  -- is about to render the freshly-scanned data itself; refreshing again
  -- here would just build the whole view a second time on top of it.
  if not ABC.buildingCollectionView and LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView and (LeafVE_AchTest.UI.currentView == "mounts" or LeafVE_AchTest.UI.currentView == "companions") then
    LeafVE_AchTest.UI:Refresh()
  end
end

local function GetSavedCollection(kind)
  EnsureDB()
  if kind == "mount" then return LeafVE_AchTest_DB.collections.mounts end
  if kind == "toy" then return LeafVE_AchTest_DB.collections.toys end
  return LeafVE_AchTest_DB.collections.companions
end

local function GetRuntimeCollection(kind)
  if kind == "mount" then return ABC.runtime.mounts end
  if kind == "toy" then return ABC.runtime.toys end
  return ABC.runtime.companions
end

-- Mounts/companions have no earned-date of their own (same as titles) --
-- the linked achievement's timestamp is the only date available. Shared by
-- the recency sort below and the card's "Collected: <date>" display.
local function ABC_CollectedTimestamp(row)
  local me = LeafVE_AchTest and LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  local playerAchievements = (me and LeafVE_AchTest.GetPlayerAchievements and LeafVE_AchTest:GetPlayerAchievements(me)) or {}
  local achId = row and (row.achievementId or row.id)
  local rec = achId and playerAchievements[achId]
  return (rec and rec.timestamp) or 0
end

-- Most recently collected first, then alphabetically. Shared by
-- BuildSortedList and ABC_StableFilterList so the order survives both the
-- initial build and the per-category/search re-sort.
local function ABC_SortByRecencyThenName(list)
  table.sort(list, function(a, b)
    if a.collected and not b.collected then return true end
    if not a.collected and b.collected then return false end
    if a.collected and b.collected then
      local aTs = ABC_CollectedTimestamp(a)
      local bTs = ABC_CollectedTimestamp(b)
      if aTs ~= bTs then return aTs > bTs end
    end
    return Lower(a.name or "") < Lower(b.name or "")
  end)
  return list
end

local function BuildSortedList(kind)
  local key = (kind == "mount") and "mounts" or "companions"
  local saved = GetSavedCollection(kind)
  local runtime = GetRuntimeCollection(kind)
  local master = (kind == "mount") and ABC.masterMountList or ABC.masterCompanionList
  local outMap = {}

  for name, mdata in pairs(master or {}) do
    local row = {}
    for k, v in pairs(mdata) do row[k] = v end
    row.name = name
    row.collected = false
    if not row.points and LeafVE_AchTest then
      if kind == "mount" and LeafVE_AchTest.GetMountPointValue then row.points = LeafVE_AchTest:GetMountPointValue(row.name, row.source)
      elseif kind ~= "mount" and LeafVE_AchTest.GetCompanionPointValue then row.points = LeafVE_AchTest:GetCompanionPointValue(row.name) end
    end
    outMap[name] = row
  end

  for name, data in pairs(saved) do
    local r = runtime[name] or {}
    local row = outMap[name] or {}
    for k, v in pairs(data) do row[k] = v end
    for k, v in pairs(r) do row[k] = v end
    row.name = name
    row.collected = true
    if not row.points and LeafVE_AchTest then
      if kind == "mount" and LeafVE_AchTest.GetMountPointValue then row.points = LeafVE_AchTest:GetMountPointValue(row.name, row.source)
      elseif kind ~= "mount" and LeafVE_AchTest.GetCompanionPointValue then row.points = LeafVE_AchTest:GetCompanionPointValue(row.name) end
    end
    outMap[name] = row
  end

  local out = {}
  for _, row in pairs(outMap) do
    table.insert(out, row)
  end

  ABC_SortByRecencyThenName(out)

  return out
end

local ABC_MOUNT_FILTERS = {
  { label = "All", value = "All" },
  { label = "Collected", value = "Collected" },
  { label = "Missing", value = "Missing" },
  { label = "Racial", value = "Racial" },
  { label = "Alliance", value = "Alliance" },
  { label = "Horde", value = "Horde" },
  { label = "PvP", value = "PvP" },
  { label = "Qiraji", value = "Qiraji" },
  { label = "Turtle WoW", value = "Turtle WoW" },
}

local function MountMatchesFilter(row, filterValue)
  local filter = filterValue or "All"
  if filter == "All" then return true end
  if filter == "Collected" then return row and row.collected == true end
  if filter == "Missing" then return not (row and row.collected == true) end

  local name = Lower(row and row.name)
  local source = Lower(row and (row.source or row.tabName))
  local text = name.." "..source
  local alliance = string.find(text, "human", 1, true)
    or string.find(text, "dwarf", 1, true)
    or string.find(text, "gnome", 1, true)
    or string.find(text, "night elf", 1, true)
    or string.find(text, "alliance", 1, true)
  local horde = string.find(text, "orc", 1, true)
    or string.find(text, "tauren", 1, true)
    or string.find(text, "troll", 1, true)
    or string.find(text, "undead", 1, true)
    or string.find(text, "forsaken", 1, true)
    or string.find(text, "horde", 1, true)
  local pvp = string.find(text, "pvp", 1, true)
    or string.find(name, "black war", 1, true)
    or string.find(name, "battlestrider", 1, true)
  local qiraji = string.find(text, "qiraji", 1, true)
    or string.find(text, "silithid", 1, true)
  local turtle = string.find(text, "turtle wow", 1, true)
    or string.find(source, "turtle", 1, true)

  if filter == "Alliance" then return alliance and true or false end
  if filter == "Horde" then return horde and true or false end
  if filter == "Racial" then return (alliance or horde or string.find(source, "racial", 1, true)) and true or false end
  if filter == "PvP" then return pvp and true or false end
  if filter == "Qiraji" then return qiraji and true or false end
  if filter == "Turtle WoW" then return turtle and true or false end
  return true
end

local function FilterCollectionList(list, kind)
  if kind ~= "mount" then return list end
  EnsureDB()
  local out = {}
  local filter = AshenBannerCollectionsDB.mountFilter or "All"
  for i = 1, table.getn(list or {}) do
    if MountMatchesFilter(list[i], filter) then table.insert(out, list[i]) end
  end
  return out
end

function ABC:EnsureMountSidebar(ui)
  if not ui or not ui.frame then return nil end
  if ui.abcMountSidebarFrame then return ui.abcMountSidebarFrame end

  -- Sidebar is narrower than the 158px gap it sits in (window edge to the
  -- content area's own TOPLEFT at x=158, same as the achievements/titles
  -- sidebars) and centered within that gap -- 18px on both sides.
  local frame = CreateFrame("Frame", nil, ui.frame)
  frame:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", 18, -98)
  frame:SetPoint("BOTTOMLEFT", ui.frame, "BOTTOMLEFT", 18, 10)
  frame:SetWidth(122)
  frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  frame:SetBackdropColor(0, 0, 0, 0)
  frame:SetBackdropBorderColor(0.55, 0.42, 0.18, 1)

  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
  bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  if ui.companionSidebarFrame and ui.companionSidebarFrame.bg and ui.companionSidebarFrame.bg.GetTexture then
    bg:SetTexture(ui.companionSidebarFrame.bg:GetTexture())
  else
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
  end
  bg:SetVertexColor(1, 1, 1, 1)
  frame.bg = bg
  frame.buttons = {}

  for i = 1, table.getn(ABC_MOUNT_FILTERS) do
    local def = ABC_MOUNT_FILTERS[i]
    local btn = CreateFrame("Button", nil, frame)
    -- Same row layout as the achievements/titles sidebars (SIDEBAR_CATS in
    -- LeafVillageAchievements.lua): left-aligned label instead of centered,
    -- no per-row backdrop box.
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -(i - 1) * 27 - 4)
    btn:SetWidth(110)
    btn:SetHeight(24)
    btn.filterValue = def.value

    local hi = btn:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints(btn)
    hi:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hi:SetVertexColor(0.72, 0.28, 0.08, 0.65)
    hi:Hide()
    btn.highlight = hi

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    label:SetWidth(100)
    label:SetJustifyH("LEFT")
    label:SetText(def.label)
    label:SetTextColor(0.92, 0.78, 0.26)
    btn.label = label

    btn:SetScript("OnClick", function()
      EnsureDB()
      AshenBannerCollectionsDB.mountFilter = this.filterValue or "All"
      ABC.pages.mount = 1
      PlaySound("igMainMenuOptionCheckBoxOn")
      ABC:BuildCollectionView("mount")
    end)
    btn:SetScript("OnEnter", function()
      if this.highlight then this.highlight:Show() end
      if this.label then this.label:SetTextColor(1, 1, 1) end
    end)
    btn:SetScript("OnLeave", function()
      local selected = AshenBannerCollectionsDB and AshenBannerCollectionsDB.mountFilter or "All"
      if this.filterValue ~= selected then
        if this.highlight then this.highlight:Hide() end
        if this.label then this.label:SetTextColor(0.92, 0.78, 0.26) end
      end
    end)
    table.insert(frame.buttons, btn)
  end

  ui.abcMountSidebarFrame = frame
  return frame
end

function ABC:RefreshMountSidebar(ui)
  local frame = self:EnsureMountSidebar(ui)
  if not frame then return end
  EnsureDB()
  local selected = AshenBannerCollectionsDB.mountFilter or "All"
  for i = 1, table.getn(frame.buttons or {}) do
    local btn = frame.buttons[i]
    if btn.filterValue == selected then
      if btn.highlight then btn.highlight:Show() end
      if btn.label then btn.label:SetTextColor(1.0, 0.45, 0.18) end
    else
      if btn.highlight then btn.highlight:Hide() end
      if btn.label then btn.label:SetTextColor(0.92, 0.78, 0.26) end
    end
  end
end


local ABC_COMPANION_FILTERS = {
  {label="All",value="All"}, {label="Collected",value="Collected"}, {label="Missing",value="Missing"},
  {label="Vendor",value="Vendor"}, {label="Quest",value="Quest"}, {label="Drops",value="Drop"},
  {label="Events",value="Event"}, {label="Reputation",value="Reputation"},
  {label="Professions",value="Profession"}, {label="Turtle Shop",value="Turtle Shop"},
}

local function CompanionMatchesFilter(row,filterValue)
  local filter=filterValue or "All"
  if filter=="All" then return true end
  if filter=="Collected" then return row and row.collected==true end
  if filter=="Missing" then return not (row and row.collected==true) end
  local text=Lower(tostring(row and row.sourceCategory or "").." "..tostring(row and row.category or "").." "..tostring(row and row.source or "").." "..tostring(row and row.obtainedFrom or ""))
  if filter=="Vendor" then return string.find(text,"vendor",1,true) or string.find(text,"buy from",1,true) end
  if filter=="Quest" then return string.find(text,"quest",1,true) or string.find(text,"challenge",1,true) end
  if filter=="Drop" then return string.find(text,"drop",1,true) or string.find(text,"dungeon",1,true) or string.find(text,"raid",1,true) end
  if filter=="Event" then return string.find(text,"event",1,true) or string.find(text,"seasonal",1,true) or string.find(text,"promotion",1,true) or string.find(text,"darkmoon",1,true) end
  if filter=="Reputation" then return string.find(text,"reputation",1,true) or string.find(text,"pvp",1,true) end
  if filter=="Profession" then return string.find(text,"profession",1,true) or string.find(text,"engineering",1,true) or string.find(text,"craft",1,true) end
  if filter=="Turtle Shop" then return string.find(text,"turtle shop",1,true) or string.find(text,"token-shop",1,true) or string.find(text,"donation",1,true) end
  return true
end

function ABC:EnsureCompanionSidebar(ui)
  if not ui or not ui.frame then return nil end
  if ui.abcCompanionSidebarFrame then return ui.abcCompanionSidebarFrame end
  -- Sidebar is narrower than the 158px gap it sits in (window edge to the
  -- content area's own TOPLEFT at x=158, same as the achievements/titles
  -- sidebars) and centered within that gap -- 18px on both sides.
  local frame=CreateFrame("Frame",nil,ui.frame)
  frame:SetPoint("TOPLEFT",ui.frame,"TOPLEFT",18,-98)
  frame:SetPoint("BOTTOMLEFT",ui.frame,"BOTTOMLEFT",18,10)
  frame:SetWidth(122)
  frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
  frame:SetBackdropColor(0,0,0,0); frame:SetBackdropBorderColor(0.55,0.42,0.18,1)
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2); bg:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
  if ui.companionSidebarFrame and ui.companionSidebarFrame.bg and ui.companionSidebarFrame.bg.GetTexture then bg:SetTexture(ui.companionSidebarFrame.bg:GetTexture())
  else bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark") end
  bg:SetVertexColor(1,1,1,1); frame.bg=bg; frame.buttons={}
  -- Same row layout as the achievements/titles sidebars (SIDEBAR_CATS in
  -- LeafVillageAchievements.lua): left-aligned label instead of centered,
  -- no per-row backdrop box.
  for i=1,table.getn(ABC_COMPANION_FILTERS) do
    local def=ABC_COMPANION_FILTERS[i]
    local btn=CreateFrame("Button",nil,frame)
    btn:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-(i-1)*27-4); btn:SetWidth(110); btn:SetHeight(24)
    btn.filterValue=def.value
    local hi=btn:CreateTexture(nil,"BACKGROUND"); hi:SetAllPoints(btn); hi:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight"); hi:SetVertexColor(0.72,0.28,0.08,0.65); hi:Hide(); btn.highlight=hi
    local label=btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); label:SetPoint("LEFT",btn,"LEFT",8,0); label:SetWidth(100); label:SetJustifyH("LEFT"); label:SetText(def.label); label:SetTextColor(0.92,0.78,0.26); btn.label=label
    btn:SetScript("OnClick",function() EnsureDB(); AshenBannerCollectionsDB.companionFilter=this.filterValue or "All"; ABC.pages.companion=1; PlaySound("igMainMenuOptionCheckBoxOn"); ABC:BuildCollectionView("companion") end)
    btn:SetScript("OnEnter",function() if this.highlight then this.highlight:Show() end; if this.label then this.label:SetTextColor(1,1,1) end end)
    btn:SetScript("OnLeave",function() local selected=AshenBannerCollectionsDB and AshenBannerCollectionsDB.companionFilter or "All"; if this.filterValue~=selected then if this.highlight then this.highlight:Hide() end; if this.label then this.label:SetTextColor(0.92,0.78,0.26) end end end)
    table.insert(frame.buttons,btn)
  end
  ui.abcCompanionSidebarFrame=frame
  return frame
end

function ABC:RefreshCompanionSidebar(ui)
  local frame=self:EnsureCompanionSidebar(ui); if not frame then return end
  EnsureDB(); local selected=AshenBannerCollectionsDB.companionFilter or "All"
  for i=1,table.getn(frame.buttons or {}) do local btn=frame.buttons[i]
    if btn.filterValue==selected then if btn.highlight then btn.highlight:Show() end; if btn.label then btn.label:SetTextColor(1.0,0.45,0.18) end
    else if btn.highlight then btn.highlight:Hide() end; if btn.label then btn.label:SetTextColor(0.92,0.78,0.26) end end
  end
end

local ABC_TOY_FILTERS = {
  {label="All",value="All"}, {label="Collected",value="Collected"}, {label="Missing",value="Missing"},
  {label="Music",value="Music"}, {label="Novelty",value="Novelty"},
  {label="Utility",value="Utility"}, {label="Ambience",value="Ambience"},
}

local function ToyMatchesFilter(row,filterValue)
  local filter=filterValue or "All"
  if filter=="All" then return true end
  if filter=="Collected" then return row and row.collected==true end
  if filter=="Missing" then return not (row and row.collected==true) end
  local cat=row and (row.sourceCategory or row.category) or ""
  if cat==filter then return true end
  return false
end

function ABC:EnsureToySidebar(ui)
  if not ui or not ui.frame then return nil end
  if ui.abcToySidebarFrame then return ui.abcToySidebarFrame end
  -- Sidebar is narrower than the 158px gap it sits in (window edge to the
  -- content area's own TOPLEFT at x=158, same as the achievements/titles
  -- sidebars) and centered within that gap -- 18px on both sides.
  local frame=CreateFrame("Frame",nil,ui.frame)
  frame:SetPoint("TOPLEFT",ui.frame,"TOPLEFT",18,-98)
  frame:SetPoint("BOTTOMLEFT",ui.frame,"BOTTOMLEFT",18,10)
  frame:SetWidth(122)
  frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
  frame:SetBackdropColor(0,0,0,0); frame:SetBackdropBorderColor(0.55,0.42,0.18,1)
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2); bg:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
  if ui.companionSidebarFrame and ui.companionSidebarFrame.bg and ui.companionSidebarFrame.bg.GetTexture then bg:SetTexture(ui.companionSidebarFrame.bg:GetTexture())
  else bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark") end
  bg:SetVertexColor(1,1,1,1); frame.bg=bg; frame.buttons={}
  -- Same row layout as the achievements/titles sidebars (SIDEBAR_CATS in
  -- LeafVillageAchievements.lua): left-aligned label instead of centered,
  -- no per-row backdrop box.
  for i=1,table.getn(ABC_TOY_FILTERS) do
    local def=ABC_TOY_FILTERS[i]
    local btn=CreateFrame("Button",nil,frame)
    btn:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-(i-1)*27-4); btn:SetWidth(110); btn:SetHeight(24)
    btn.filterValue=def.value
    local hi=btn:CreateTexture(nil,"BACKGROUND"); hi:SetAllPoints(btn); hi:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight"); hi:SetVertexColor(0.72,0.28,0.08,0.65); hi:Hide(); btn.highlight=hi
    local label=btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); label:SetPoint("LEFT",btn,"LEFT",8,0); label:SetWidth(100); label:SetJustifyH("LEFT"); label:SetText(def.label); label:SetTextColor(0.92,0.78,0.26); btn.label=label
    btn:SetScript("OnClick",function() EnsureDB(); AshenBannerCollectionsDB.toyFilter=this.filterValue or "All"; ABC.pages.toy=1; PlaySound("igMainMenuOptionCheckBoxOn"); ABC:BuildCollectionView("toy") end)
    btn:SetScript("OnEnter",function() if this.highlight then this.highlight:Show() end; if this.label then this.label:SetTextColor(1,1,1) end end)
    btn:SetScript("OnLeave",function() local selected=AshenBannerCollectionsDB and AshenBannerCollectionsDB.toyFilter or "All"; if this.filterValue~=selected then if this.highlight then this.highlight:Hide() end; if this.label then this.label:SetTextColor(0.92,0.78,0.26) end end end)
    table.insert(frame.buttons,btn)
  end
  ui.abcToySidebarFrame=frame
  return frame
end

function ABC:RefreshToySidebar(ui)
  local frame=self:EnsureToySidebar(ui); if not frame then return end
  EnsureDB(); local selected=AshenBannerCollectionsDB.toyFilter or "All"
  for i=1,table.getn(frame.buttons or {}) do local btn=frame.buttons[i]
    if btn.filterValue==selected then if btn.highlight then btn.highlight:Show() end; if btn.label then btn.label:SetTextColor(1.0,0.45,0.18) end
    else if btn.highlight then btn.highlight:Hide() end; if btn.label then btn.label:SetTextColor(0.92,0.78,0.26) end end
  end
end

local function HideFrame(frame)
  if frame and frame.Hide then frame:Hide() end
end

local function ShowFrame(frame)
  if frame and frame.Show then frame:Show() end
end

local function HideButtonArray(arr)
  if type(arr) ~= "table" then return end
  for i = 1, table.getn(arr) do HideFrame(arr[i]) end
end

local function HideOriginalFilters(ui)
  HideFrame(ui.searchBox)
  HideFrame(ui.clearBtn)
  HideFrame(ui.searchLabel)
  HideFrame(ui.titleSearchBox)
  HideFrame(ui.titleSearchLabel)
  HideFrame(ui.titleClearBtn)
end

local function ClearScrollChild(ui)
  if not ui or not ui.scrollChild then return end
  local children = { ui.scrollChild:GetChildren() }
  for i = 1, table.getn(children) do
    children[i]:Hide()
  end
  local regions = { ui.scrollChild:GetRegions() }
  for i = 1, table.getn(regions) do
    regions[i]:Hide()
  end
end

local function SetScrollHeight(ui, height)
  if not ui or not ui.scrollChild then return end
  if height < 1 then height = 1 end
  ui.scrollChild:SetHeight(height)
  if ui.scrollFrame and ui.scrollbar then
    local frameHeight = ui.scrollFrame:GetHeight() or 420
    local maxScroll = height - frameHeight
    if maxScroll < 0 then maxScroll = 0 end
    ui.scrollbar:SetMinMaxValues(0, maxScroll)
    ui.scrollbar:SetValue(0)
  end
end

-- ---------------------------------------------------------------------------
-- Vanilla 1.12 model renderer (v2 rebuild)
--
-- Rules used here:
--   * Raw mount paths use a base Model direct child of the preview frame.
--   * Companions may use PlayerModel when a cached creature is available.
--   * No UIParent-rooted model canvases; the card remains the only viewport.
--   * Raw model yaw uses SetFacing; PlayerModel yaw uses SetRotation.
--   * Position, scale and rotation are saved per mount and can be copied to a
--     whole model family after one representative is calibrated.
-- ---------------------------------------------------------------------------

ABC.cardsPerPage = 6
ABC.pages = ABC.pages or { mount = 1, companion = 1, toy = 1 }
ABC.configMode = ABC.configMode or false
ABC.activeModels = ABC.activeModels or {}
ABC.activeCards = ABC.activeCards or {}

local ABC_MODEL_DEFAULTS = {
  -- Raw mount M2 files are rendered by the base Model widget.  The previous
  -- PlayerModel camera treated these numbers as unit-camera coordinates and
  -- projected pieces of the mesh outside the card.  These values are neutral
  -- Model-space starting points, normalized from the original per-mount scales.
  default   = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0500, rotation = 1.57, camera = 0 },
  horse     = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0360, rotation = 1.57, camera = 0 },
  skeletal  = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  wolf      = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  ram       = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  kodo      = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0400, rotation = 1.57, camera = 0 },
  raptor    = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  cat       = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0700, rotation = 1.57, camera = 0 },
  mech      = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  qiraji    = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0500, rotation = 1.57, camera = 0 },
  turtle    = { x = 0.00, y = 0.00, z = 0.00, scale = 0.0480, rotation = 1.57, camera = 0 },
  companion = { x = 0.00, y = 0.00, z = 0.00, scale = 0.1000, rotation = 0.61, camera = 0 },
}

local function CopyModelProfile(source)
  local out = {}
  for k, v in pairs(source or ABC_MODEL_DEFAULTS.default) do out[k] = v end
  return out
end

-- Companion equivalent of the mount family detection below -- lets an
-- uncollected companion show a thematically-appropriate icon (frog, cat,
-- bird, snake, etc.) instead of the single generic placeholder used for
-- every not-yet-owned companion regardless of what it actually is.
local function GetCompanionFamily(data)
  local value = Lower((data and data.name) or "")
  if string.find(value, "frog", 1, true) then return "frog" end
  if string.find(value, "snake", 1, true) then return "snake" end
  if string.find(value, "murloc", 1, true) or value == "gurky" or value == "murky" then return "murloc" end
  if string.find(value, "whelpling", 1, true) or string.find(value, "dragon", 1, true) or string.find(value, "phoenix", 1, true) or string.find(value, "dragonhawk", 1, true) then return "drake" end
  if string.find(value, "snapjaw", 1, true) or string.find(value, "crocolisk", 1, true) then return "crocolisk" end
  if string.find(value, "turtle", 1, true) then return "turtle" end
  if string.find(value, "tabby", 1, true) or string.find(value, "kitten", 1, true) or string.find(value, "siamese", 1, true) or string.find(value, "bombay", 1, true) or string.find(value, "cornish rex", 1, true) or string.find(value, "tiger cub", 1, true) or string.find(value, "bigglesworth", 1, true) then return "cat" end
  if string.find(value, "owl", 1, true) or string.find(value, "raven", 1, true) or string.find(value, "macaw", 1, true) or string.find(value, "cockatiel", 1, true) or string.find(value, "senegal", 1, true) or string.find(value, "wing", 1, true) or string.find(value, "hedwig", 1, true) or string.find(value, "chicken", 1, true) then return "bird" end
  if string.find(value, "worg", 1, true) or string.find(value, "ghostpup", 1, true) then return "wolf" end
  if string.find(value, "crab", 1, true) then return "crab" end
  if string.find(value, "pony", 1, true) then return "horse" end
  if string.find(value, "tonk", 1, true) or string.find(value, "mechanical", 1, true) or string.find(value, "repair bot", 1, true) or string.find(value, "auctioneer", 1, true) or string.find(value, "barber", 1, true) or string.find(value, "surgeon", 1, true) then return "mechanical" end
  if string.find(value, "elemental", 1, true) or string.find(value, "waveling", 1, true) then return "elemental" end
  if string.find(value, "spectral", 1, true) then return "ghost" end
  return "companion"
end

local function GetModelFamily(data, kind)
  if kind ~= "mount" then return GetCompanionFamily(data) end
  local value = Lower((data and data.name) or "").." "..Lower((data and data.model) or "")
  local explicit = Lower((data and data.family) or "")

  if string.find(value, "skeletal", 1, true) or string.find(value, "undeadhorse", 1, true) or string.find(value, "deathcharger", 1, true) or string.find(value, "invincible", 1, true) then return "skeletal" end
  if string.find(value, "wolf", 1, true) or string.find(value, "direwolf", 1, true) or string.find(value, "howler", 1, true) then return "wolf" end
  if string.find(value, "kodo", 1, true) then return "kodo" end
  if string.find(value, "raptor", 1, true) then return "raptor" end
  if string.find(value, "ram", 1, true) then return "ram" end
  if string.find(value, "frostsaber", 1, true) or string.find(value, "nightsaber", 1, true) or string.find(value, "dawnsaber", 1, true) or string.find(value, "mistsaber", 1, true) or string.find(value, "stormsaber", 1, true) or string.find(value, "tiger", 1, true) or string.find(value, "panther", 1, true) or string.find(value, "leopard", 1, true) or string.find(value, "sabercat", 1, true) or string.find(value, "cheetah", 1, true) or string.find(value, "lion", 1, true) or string.find(value, "furline", 1, true) or string.find(value, "rak'shiri", 1, true) then return "cat" end
  if string.find(value, "mechanostrider", 1, true) or string.find(value, "mechastrider", 1, true) or string.find(value, "battlestrider", 1, true) then return "mechanostrider" end
  if string.find(value, "qiraji", 1, true) or string.find(value, "silithid", 1, true) then return "qiraji" end
  if string.find(value, "turtle", 1, true) or string.find(value, "grumbleshell", 1, true) then return "turtle" end
  if string.find(value, "bear", 1, true) then return "bear" end
  if string.find(value, "boar", 1, true) then return "boar" end
  if string.find(value, "gryphon", 1, true) then return "gryphon" end
  if string.find(value, "hippogryph", 1, true) then return "hippogryph" end
  if string.find(value, "drake", 1, true) or string.find(value, "dragon", 1, true) then return "drake" end
  if string.find(value, "scorpid", 1, true) then return "scorpid" end
  if string.find(value, "crab", 1, true) or string.find(value, "crustacean", 1, true) then return "crab" end
  if string.find(value, "crocolisk", 1, true) then return "crocolisk" end
  if string.find(value, "talbuk", 1, true) then return "talbuk" end
  if string.find(value, "tallstrider", 1, true) or string.find(value, "ostrich", 1, true) or string.find(value, "chicken", 1, true) or string.find(value, "rooster", 1, true) or string.find(value, "raven lord", 1, true) then return "bird" end
  if string.find(value, "stag", 1, true) or string.find(value, "reindeer", 1, true) or string.find(value, "elk", 1, true) or string.find(value, "moose", 1, true) then return "elk" end
  if string.find(value, "zhevra", 1, true) or string.find(value, "zebra", 1, true) then return "zhevra" end
  if string.find(value, "giraffe", 1, true) then return "giraffe" end
  if string.find(value, "hyena", 1, true) then return "hyena" end
  if string.find(value, "camel", 1, true) then return "camel" end
  if string.find(value, "thunder lizard", 1, true) then return "thunderlizard" end
  if string.find(value, "rocket car", 1, true) or string.find(value, "shredder", 1, true) or string.find(value, "pounder", 1, true) or string.find(value, "steam", 1, true) or string.find(value, "trike", 1, true) or string.find(value, "mechano", 1, true) or string.find(value, "flying machine", 1, true) then return "mechanical" end
  if string.find(value, "cloud", 1, true) then return "cloud" end
  if string.find(value, "horse", 1, true) or string.find(value, "steed", 1, true) or string.find(value, "mare", 1, true) or string.find(value, "stallion", 1, true) or string.find(value, "palomino", 1, true) or string.find(value, "charger", 1, true) or string.find(value, "felsteed", 1, true) or string.find(value, "dreadsteed", 1, true) or string.find(value, "pony", 1, true) or string.find(value, "pinto", 1, true) or string.find(value, "marshmallow", 1, true) or string.find(value, "snowball", 1, true) or string.find(value, "twilight", 1, true) then return "horse" end

  if explicit == "mech" then return "mechanostrider" end
  if explicit ~= "" and explicit ~= "default" then return explicit end
  return "horse"
end

-- Raw Model paths are the only mount source that this stock 1.12 client can
-- render without the creature already being cached.  These fallbacks also give
-- database entries that lack an explicit path a stable family representative.
local ABC_FAMILY_MODEL_PATHS = {
  horse    = "Creature\\RidingHorse\\RidingHorse.m2",
  skeletal = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2",
  wolf     = "Creature\\DireWolf\\RidingDireWolf.m2",
  ram      = "Creature\\Ram\\RidingRam.m2",
  kodo     = "Creature\\Kodobeast\\RidingKodo.m2",
  raptor   = "Creature\\RidingRaptor\\RidingRaptor.m2",
  cat      = "Creature\\FrostSabre\\RidingFrostSabre.m2",
  mech     = "Creature\\MechaStrider\\MechaStrider.m2",
  qiraji   = "Creature\\RidingSilithid\\RidingSilithid.m2",
  turtle   = "Creature\\RidingTurtle\\RidingTurtle.m2",
  default  = "Creature\\RidingHorse\\RidingHorse.m2",
}

local function ResolveRawModelPath(data, kind)
  if data and data.model and data.model ~= "" then return data.model end
  if kind ~= "mount" then return data and data.model end
  return ABC_FAMILY_MODEL_PATHS[GetModelFamily(data, kind)] or ABC_FAMILY_MODEL_PATHS.default
end

local function ModelViewBucket(kind)
  EnsureDB()
  if type(AshenBannerCollectionsDB.modelView) ~= "table" then AshenBannerCollectionsDB.modelView = {} end
  local key = (kind == "mount") and "mounts" or "companions"
  if type(AshenBannerCollectionsDB.modelView[key]) ~= "table" then AshenBannerCollectionsDB.modelView[key] = {} end
  if type(AshenBannerCollectionsDB.familyView) ~= "table" then AshenBannerCollectionsDB.familyView = {} end
  if type(AshenBannerCollectionsDB.familyView[key]) ~= "table" then AshenBannerCollectionsDB.familyView[key] = {} end
  return AshenBannerCollectionsDB.modelView[key], AshenBannerCollectionsDB.familyView[key]
end

local function GetModelProfile(data, kind)
  local perModel, perFamily = ModelViewBucket(kind)
  local name = tostring((data and data.name) or "Unknown")
  local family = GetModelFamily(data, kind)
  local saved = perModel[name]
  if type(saved) == "table" then return CopyModelProfile(saved), family end
  local familySaved = perFamily[family]
  if type(familySaved) == "table" then return CopyModelProfile(familySaved), family end
  return CopyModelProfile(ABC_MODEL_DEFAULTS[family] or ABC_MODEL_DEFAULTS.default), family
end

local function SaveModelProfile(data, kind, profile)
  if not data or not profile then return end
  local perModel = ModelViewBucket(kind)
  perModel[tostring(data.name or "Unknown")] = CopyModelProfile(profile)
end

local function SaveFamilyProfile(data, kind, profile)
  if not data or not profile then return end
  local _, perFamily = ModelViewBucket(kind)
  local family = GetModelFamily(data, kind)
  perFamily[family] = CopyModelProfile(profile)
end

local function ResetModelProfile(data, kind)
  if not data then return end
  local perModel = ModelViewBucket(kind)
  perModel[tostring(data.name or "Unknown")] = nil
end

local function Clamp(value, low, high)
  value = tonumber(value) or low
  if value < low then return low end
  if value > high then return high end
  return value
end

local function StopModel(model, clearIt)
  if not model then return end
  model:SetScript("OnUpdate", nil)
  model._abcData = nil
  model._abcProfile = nil
  model._abcLoader = nil
  if clearIt then
    if model.ClearModel then
      pcall(function() model:ClearModel() end)
    elseif model.SetModel then
      pcall(function() model:SetModel("") end)
    end
  end
  model:Hide()
end

local function ReleaseActiveModels()
  for i = 1, table.getn(ABC.activeModels or {}) do StopModel(ABC.activeModels[i], true) end
  ABC.activeModels = {}
  ABC.activeCards = {}
end

local function ApplyVanillaTransforms(model)
  if not model or not model._abcProfile then return end
  local p = model._abcProfile

  -- The base Model widget owns raw M2 geometry.  It uses SetFacing and its own
  -- camera; PlayerModel-only RefreshCamera/SetRotation calls are intentionally
  -- avoided for mount paths.
  if model._abcWidgetType == "Model" then
    if model.SetCamera then pcall(function() model:SetCamera(tonumber(p.camera) or 0) end) end
    if model.SetModelScale then pcall(function() model:SetModelScale(Clamp(p.scale, 0.005, 0.250)) end) end
    if model.SetPosition then
      pcall(function()
        model:SetPosition(
          Clamp(p.x, -2.0, 2.0),
          Clamp(p.y, -2.0, 2.0),
          Clamp(p.z, -2.0, 2.0)
        )
      end)
    end
    if model.SetFacing then pcall(function() model:SetFacing(tonumber(p.rotation) or 1.57) end) end
  else
    if model.SetCamera then pcall(function() model:SetCamera(tonumber(p.camera) or 0) end) end
    if model.RefreshCamera then pcall(function() model:RefreshCamera() end) end
    if model.SetModelScale then pcall(function() model:SetModelScale(Clamp(p.scale, 0.005, 1.0)) end) end
    if model.SetPosition then pcall(function() model:SetPosition(tonumber(p.x) or 0, tonumber(p.y) or 0, tonumber(p.z) or 0) end) end
    if model.SetRotation then pcall(function() model:SetRotation(tonumber(p.rotation) or 0.61) end)
    elseif model.SetFacing then pcall(function() model:SetFacing(tonumber(p.rotation) or 0.61) end) end
  end

  if model.SetSequence then pcall(function() model:SetSequence(0) end) end
  if model._abcReadout then
    model._abcReadout:SetText(string.format("X %.3f  Y %.3f  Z %.3f\nScale %.4f  Rot %.3f  Cam %d", p.x or 0, p.y or 0, p.z or 0, p.scale or 0.05, p.rotation or 1.57, tonumber(p.camera) or 0))
  end
end

local function TryLoader(model, method, value, loaderKind)
  if not model or value == nil or type(model[method]) ~= "function" then return false end
  local ok = pcall(function() model[method](model, value) end)
  if ok then
    model._abcLoader = method..":"..tostring(value)
    model._abcLoaderKind = loaderKind or method
    return true
  end
  return false
end

local function LoadModel(model, data, kind)
  if not model or not data then return false end
  StopModel(model, true)
  model:Show()

  local loaded = false
  if model._abcWidgetType == "Model" then
    -- Stock Vanilla 1.12 cannot reliably skin an arbitrary uncached creature.
    -- Render the known M2 in the widget designed for raw meshes instead of
    -- forcing it through PlayerModel's unit camera.
    local modelPath = ResolveRawModelPath(data, kind)
    if modelPath and modelPath ~= "" then loaded = TryLoader(model, "SetModel", modelPath, "path") end
  else
    local creatureID = tonumber(data.creatureID)
    local displayID = tonumber(data.displayID)
    if creatureID and creatureID > 0 then loaded = TryLoader(model, "SetCreature", creatureID, "creature") end
    if not loaded and displayID and displayID > 0 then loaded = TryLoader(model, "SetDisplayInfo", displayID, "display") end
    if not loaded and data.model and data.model ~= "" then loaded = TryLoader(model, "SetModel", data.model, "path") end
  end

  if not loaded then model:Hide(); return false end

  local profile, family = GetModelProfile(data, kind)
  model._abcData = data
  model._abcKind = kind
  model._abcFamily = family
  model._abcProfile = profile
  ApplyVanillaTransforms(model)

  -- A raw Model path is synchronous in this client.  Reapplying transforms every
  -- frame was fighting the model camera and contributed to detached fragments.
  -- PlayerModel fallbacks get only a few delayed refreshes.
  if model._abcWidgetType ~= "Model" then
    model._abcStabilize = 0
    model._abcPasses = 0
    model:SetScript("OnUpdate", function()
      this._abcStabilize = (this._abcStabilize or 0) + (arg1 or 0)
      if this._abcStabilize >= 0.15 then
        this._abcStabilize = 0
        ApplyVanillaTransforms(this)
        this._abcPasses = (this._abcPasses or 0) + 1
        if this._abcPasses >= 4 then this:SetScript("OnUpdate", nil) end
      end
    end)
  end
  return true
end

local function CardBackdrop(frame, locked)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  if locked then
    frame:SetBackdropColor(0.06, 0.05, 0.04, 0.82)
    frame:SetBackdropBorderColor(0.25, 0.22, 0.18, 0.90)
  else
    frame:SetBackdropColor(0.10, 0.075, 0.045, 0.92)
    frame:SetBackdropBorderColor(0.62, 0.42, 0.16, 1.0)
  end
end

local function AdjustAndSave(model, fn)
  if not model or not model._abcProfile then return end
  fn(model._abcProfile)
  SaveModelProfile(model._abcData, model._abcKind, model._abcProfile)
  ApplyVanillaTransforms(model)
end

local function CreateFineButton(parent, text, point, relative, relativePoint, x, y, width, callback)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(width or 38)
  b:SetHeight(18)
  b:SetPoint(point, relative, relativePoint, x, y)
  b:SetText(text)
  b:SetScript("OnClick", callback)
  return b
end


local CreateModelCard

-- ---------------------------------------------------------------------------
-- Reliable portrait renderer
--
-- The stock Turtle/Vanilla client exposes SetModel but not arbitrary creature
-- or display loading. Raw M2 geometry therefore has no dependable skin. Mount
-- cards use 2D textures instead: an optional transparent mount portrait, the
-- exact learned-spell icon, or a family-specific mount icon for missing mounts.
-- ---------------------------------------------------------------------------

AshenBannerCollectionPortraits = AshenBannerCollectionPortraits or {}

local ABC_FAMILY_PORTRAIT_TEXTURES = {
  default        = "Interface\\Icons\\Ability_Mount_RidingHorse",
  horse          = "Interface\\Icons\\Ability_Mount_RidingHorse",
  skeletal       = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  wolf           = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  ram            = "Interface\\Icons\\Ability_Mount_MountainRam",
  kodo           = "Interface\\Icons\\Ability_Mount_Kodo_03",
  raptor         = "Interface\\Icons\\Ability_Mount_Raptor",
  cat            = "Interface\\Icons\\Ability_Mount_BlackPanther",
  mech           = "Interface\\Icons\\Ability_Mount_MechaStrider",
  mechanostrider = "Interface\\Icons\\Ability_Mount_MechaStrider",
  mechanical     = "Interface\\Icons\\Ability_Mount_MechaStrider",
  qiraji         = "Interface\\Icons\\INV_Misc_QirajiCrystal_04",
  turtle         = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
  bear           = "Interface\\Icons\\Ability_Mount_PolarBear_White",
  boar           = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
  gryphon        = "Interface\\Icons\\Ability_Mount_Gryphon_01",
  hippogryph     = "Interface\\Icons\\Ability_Mount_Gryphon_01",
  drake          = "Interface\\Icons\\Ability_Mount_Drake_Red",
  scorpid        = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid",
  crab           = "Interface\\Icons\\Ability_Hunter_Pet_Crab",
  crocolisk      = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk",
  talbuk         = "Interface\\Icons\\Ability_Hunter_Pet_Stag",
  bird           = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
  elk            = "Interface\\Icons\\Ability_Hunter_Pet_Stag",
  zhevra         = "Interface\\Icons\\Ability_Mount_RidingHorse",
  giraffe        = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
  hyena          = "Interface\\Icons\\Ability_Hunter_Pet_Hyena",
  camel          = "Interface\\Icons\\Ability_Mount_RidingHorse",
  thunderlizard  = "Interface\\Icons\\Spell_Nature_Lightning",
  cloud          = "Interface\\Icons\\Spell_Nature_Cyclone",
  companion      = "Interface\\Icons\\INV_Misc_QuestionMark",
  -- Companion-specific families (mounts don't need these).
  frog           = "Interface\\Icons\\Spell_Nature_Polymorph",
  snake          = "Interface\\Icons\\INV_Misc_MonsterScales_03",
  murloc         = "Interface\\Icons\\INV_Misc_Head_Murloc_01",
  elemental      = "Interface\\Icons\\Spell_Fire_Elemental_Totem",
  ghost          = "Interface\\Icons\\Spell_Shadow_AnimateDead",
}

local ABC_PORTRAIT_DEFAULTS = {
  default   = { x = 0, y = 0, scale = 1.00 },
  horse     = { x = 0, y = 0, scale = 1.00 },
  skeletal  = { x = 0, y = 0, scale = 1.00 },
  wolf      = { x = 0, y = 0, scale = 1.00 },
  ram       = { x = 0, y = 0, scale = 1.00 },
  kodo      = { x = 0, y = 0, scale = 1.00 },
  raptor    = { x = 0, y = 0, scale = 1.00 },
  cat       = { x = 0, y = 0, scale = 1.00 },
  mech      = { x = 0, y = 0, scale = 1.00 },
  qiraji    = { x = 0, y = 0, scale = 1.00 },
  turtle    = { x = 0, y = 0, scale = 1.00 },
  companion = { x = 0, y = 0, scale = 1.00 },
}

local function CopyPortraitProfile(source)
  local s = source or ABC_PORTRAIT_DEFAULTS.default
  return { x = tonumber(s.x) or 0, y = tonumber(s.y) or 0, scale = tonumber(s.scale) or 1 }
end

local function PortraitBuckets(kind)
  EnsureDB()
  local key = (kind == "mount") and "mounts" or "companions"
  if type(AshenBannerCollectionsDB.portraitView[key]) ~= "table" then AshenBannerCollectionsDB.portraitView[key] = {} end
  if type(AshenBannerCollectionsDB.portraitFamilyView[key]) ~= "table" then AshenBannerCollectionsDB.portraitFamilyView[key] = {} end
  return AshenBannerCollectionsDB.portraitView[key], AshenBannerCollectionsDB.portraitFamilyView[key]
end

local function GetPortraitProfile(data, kind)
  local perMount, perFamily = PortraitBuckets(kind)
  local name = tostring((data and data.name) or "Unknown")
  local family = GetModelFamily(data, kind)
  if type(perMount[name]) == "table" then return CopyPortraitProfile(perMount[name]), family end
  if type(perFamily[family]) == "table" then return CopyPortraitProfile(perFamily[family]), family end
  return CopyPortraitProfile(ABC_PORTRAIT_DEFAULTS[family] or ABC_PORTRAIT_DEFAULTS.default), family
end

local function SavePortraitProfile(data, kind, profile)
  if not data or not profile then return end
  local perMount = PortraitBuckets(kind)
  perMount[tostring(data.name or "Unknown")] = CopyPortraitProfile(profile)
end

local function SavePortraitFamilyProfile(data, kind, profile)
  if not data or not profile then return end
  local _, perFamily = PortraitBuckets(kind)
  perFamily[GetModelFamily(data, kind)] = CopyPortraitProfile(profile)
end

local function ResetPortraitProfile(data, kind)
  if not data then return end
  local perMount = PortraitBuckets(kind)
  perMount[tostring(data.name or "Unknown")] = nil
end

local function SafePortraitKey(name)
  local s = tostring(name or "")
  s = string.gsub(s, "[^%w]", "")
  return s
end

local ABC_MOUNT_ITEM_ICON_CACHE = {}
local ABC_MOUNT_ICON_QUERY_TIP
local ABC_MOUNT_ICON_REFRESH

-- Icons for the mount/companion teaching items, keyed by item ID, sourced
-- directly from the server's own item database (octowow.st/db). Most of
-- these are custom OctoWoW/Turtle-WoW items that exist only server-side --
-- the client's local item cache has no entry for them, so GetItemIcon
-- (which only reads local data) and GetItemInfo (which needs the client
-- to have already seen/cached the item some other way) both silently fail
-- for the majority of them. This table sidesteps that entirely: it's not
-- dependent on client/server cache state at all.
local ABC_DB_ITEM_ICONS = {
  [41] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [161] = "Interface\\Icons\\INV_Misc_Birdbeck_02",
  [950] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [1041] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [1132] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [1134] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  [2411] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [2413] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [2414] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [5655] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [5656] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [5663] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [5665] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  [5668] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [5864] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [5872] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [5873] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [8485] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8486] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8487] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8488] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8489] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8490] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8491] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [8492] = "Interface\\Icons\\Spell_Nature_ForceOfNature",
  [8494] = "Interface\\Icons\\Spell_Nature_ForceOfNature",
  [8495] = "Interface\\Icons\\Spell_Nature_ForceOfNature",
  [8496] = "Interface\\Icons\\Spell_Nature_ForceOfNature",
  [8497] = "Interface\\Icons\\INV_Crate_02",
  [8498] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  [8499] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  [8500] = "Interface\\Icons\\Ability_EyeOfTheOwl",
  [8501] = "Interface\\Icons\\Ability_EyeOfTheOwl",
  [8563] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [8588] = "Interface\\Icons\\Ability_Mount_Raptor",
  [8589] = "Interface\\Icons\\Ability_Mount_Raptor",
  [8591] = "Interface\\Icons\\Ability_Mount_Raptor",
  [8592] = "Interface\\Icons\\Ability_Mount_Raptor",
  [8595] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [8629] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [8630] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [8631] = "Interface\\Icons\\Ability_Mount_WhiteTiger",
  [8632] = "Interface\\Icons\\Ability_Mount_WhiteTiger",
  [8635] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [10360] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [10361] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [10392] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [10393] = "Interface\\Icons\\Spell_Shadow_CarrionSwarm",
  [10394] = "Interface\\Icons\\Ability_Hunter_BeastCall",
  [10398] = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
  [10822] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  [11023] = "Interface\\Icons\\INV_Crate_02",
  [11026] = "Interface\\Icons\\INV_Crate_02",
  [11027] = "Interface\\Icons\\INV_Crate_02",
  [11110] = "Interface\\Icons\\INV_Egg_02",
  [11474] = "Interface\\Icons\\INV_Egg_02",
  [11903] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [12264] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [12302] = "Interface\\Icons\\Ability_Mount_WhiteTiger",
  [12303] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [12325] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [12326] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [12327] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [12351] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [12353] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [12354] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [12529] = "Interface\\Icons\\INV_Box_Birdcage_01",
  [13086] = "Interface\\Icons\\Ability_Mount_PinkTiger",
  [13321] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13322] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13323] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13324] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13325] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13326] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13327] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [13328] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [13329] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [13331] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [13332] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [13333] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [13334] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [13335] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [13582] = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
  [13583] = "Interface\\Icons\\INV_Belt_05",
  [13584] = "Interface\\Icons\\INV_DiabloStone",
  [15277] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [15290] = "Interface\\Icons\\Ability_Mount_Kodo_03",
  [15292] = "Interface\\Icons\\Ability_Mount_Kodo_02",
  [15293] = "Interface\\Icons\\Ability_Mount_Kodo_02",
  [16339] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [18241] = "Interface\\Icons\\Ability_Mount_NightmareHorse",
  [18242] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [18243] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [18244] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [18245] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [18246] = "Interface\\Icons\\Ability_Mount_Raptor",
  [18247] = "Interface\\Icons\\Ability_Mount_Kodo_03",
  [18248] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [18766] = "Interface\\Icons\\Ability_Mount_WhiteTiger",
  [18767] = "Interface\\Icons\\Ability_Mount_WhiteTiger",
  [18768] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [18772] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [18773] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [18774] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [18776] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [18777] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [18778] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [18785] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [18786] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [18787] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [18788] = "Interface\\Icons\\Ability_Mount_Raptor",
  [18789] = "Interface\\Icons\\Ability_Mount_Raptor",
  [18790] = "Interface\\Icons\\Ability_Mount_Raptor",
  [18791] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [18793] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [18794] = "Interface\\Icons\\Ability_Mount_Kodo_03",
  [18795] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [18796] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [18797] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  [18798] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  [18902] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [18963] = "Interface\\Icons\\INV_Egg_03",
  [18964] = "Interface\\Icons\\INV_Egg_02",
  [18965] = "Interface\\Icons\\INV_Egg_03",
  [18966] = "Interface\\Icons\\INV_Egg_03",
  [18967] = "Interface\\Icons\\INV_Egg_02",
  [19029] = "Interface\\Icons\\INV_Misc_Horn_01",
  [19030] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [19054] = "Interface\\Icons\\INV_Misc_Orb_05",
  [19055] = "Interface\\Icons\\INV_Misc_Orb_01",
  [19450] = "Interface\\Icons\\INV_Egg_04",
  [19872] = "Interface\\Icons\\Ability_Mount_Raptor",
  [19902] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [20371] = "Interface\\Icons\\INV_Egg_03",
  [21044] = "Interface\\Icons\\INV_Misc_Branch_01",
  [21168] = "Interface\\Icons\\INV_Drink_19",
  [21176] = "Interface\\Icons\\INV_Misc_QirajiCrystal_05",
  [21218] = "Interface\\Icons\\INV_Misc_QirajiCrystal_04",
  [21301] = "Interface\\Icons\\INV_Holiday_Christmas_Present_03",
  [21305] = "Interface\\Icons\\INV_Holiday_Christmas_Present_01",
  [21308] = "Interface\\Icons\\INV_Misc_Bell_01",
  [21309] = "Interface\\Icons\\INV_Misc_Bag_17",
  [21321] = "Interface\\Icons\\INV_Misc_QirajiCrystal_02",
  [21323] = "Interface\\Icons\\INV_Misc_QirajiCrystal_03",
  [21324] = "Interface\\Icons\\INV_Misc_QirajiCrystal_01",
  [22114] = "Interface\\Icons\\INV_Egg_03",
  [22235] = "Interface\\Icons\\INV_Ammo_Arrow_02",
  [22780] = "Interface\\Icons\\INV_Egg_03",
  [22781] = "Interface\\Icons\\INV_Belt_09",
  [23002] = "Interface\\Icons\\INV_Crate_03",
  [23007] = "Interface\\Icons\\INV_Belt_25",
  [23015] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [23193] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [23712] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [23713] = "Interface\\Icons\\INV_Egg_02",
  [23720] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
  [23800] = "Interface\\Icons\\Ability_Mount_Raptor",
  [30000] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [30003] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30005] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30008] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30009] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30010] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30011] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30012] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30013] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30014] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30015] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30016] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30017] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  [30018] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30019] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30020] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30021] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30022] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30024] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30025] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30026] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [30040] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
  [31829] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [36500] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [36501] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [36502] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [36503] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [36504] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [36505] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36506] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36507] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36508] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36509] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36510] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36511] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36512] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36513] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36514] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36515] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [36516] = "Interface\\Icons\\INV_Misc_Food_02",
  [37000] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37002] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37005] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37006] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37009] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37010] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37011] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37024] = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
  [37050] = "Interface\\Icons\\INV_Misc_Fish_33",
  [37051] = "Interface\\Icons\\INV_Misc_Food_40",
  [37052] = "Interface\\Icons\\Ability_Hunter_BeastCall",
  [37053] = "Interface\\Icons\\INV_Gauntlets_02",
  [37054] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
  [37055] = "Interface\\Icons\\Spell_Nature_NaturesWrath",
  [37056] = "Interface\\Icons\\INV_Mushroom_11",
  [37057] = "Interface\\Icons\\INV_Feather_13",
  [37058] = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
  [37059] = "Interface\\Icons\\INV_Weapon_ShortBlade_09",
  [37060] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [37061] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [37062] = "Interface\\Icons\\INV_Misc_MonsterScales_01",
  [37063] = "Interface\\Icons\\INV_Misc_MonsterScales_03",
  [37064] = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01",
  [37065] = "Interface\\Icons\\INV_Feather_14",
  [37066] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_05",
  [37067] = "Interface\\Icons\\INV_Misc_Food_23",
  [37068] = "Interface\\Icons\\INV_Feather_12",
  [37069] = "Interface\\Icons\\INV_Misc_Slime_01",
  [37070] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [37071] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [37072] = "Interface\\Icons\\INV_Misc_Orb_02",
  [50005] = "Interface\\Icons\\INV_Misc_EngGizmos_swissArmy",
  [50007] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [50009] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [50013] = "Interface\\Icons\\INV_Misc_Bone_07",
  [50014] = "Interface\\Icons\\INV_Misc_Branch_01",
  [50019] = "Interface\\Icons\\INV_Egg_03",
  [50058] = "Interface\\Icons\\INV_Misc_Food_02",
  [50066] = "Interface\\Icons\\Ability_Mount_MechaStrider",
  [50067] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [50068] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [50069] = "Interface\\Icons\\Spell_Nature_GuardianWard",
  [50070] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  [50071] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50072] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50073] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50074] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50075] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50076] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [50077] = "Interface\\Icons\\INV_Egg_02",
  [50078] = "Interface\\Icons\\INV_Crate_02",
  [50079] = "Interface\\Icons\\INV_Crate_02",
  [50080] = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
  [50081] = "Interface\\Icons\\INV_Crate_02",
  [50082] = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
  [50083] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  [50084] = "Interface\\Icons\\INV_Enchant_DustSoul",
  [50085] = "Interface\\Icons\\INV_Jewelry_FrostwolfTrinket_01",
  [50200] = "Interface\\Icons\\INV_Ammo_Bullet_01",
  [50202] = "Interface\\Icons\\INV_Egg_03",
  [50399] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [50400] = "Interface\\Icons\\INV_Jewelry_Talisman_02",
  [50401] = "Interface\\Icons\\Ability_Mount_Raptor",
  [50402] = "Interface\\Icons\\Ability_Mount_Raptor",
  [50403] = "Interface\\Icons\\Ability_Mount_Raptor",
  [50404] = "Interface\\Icons\\Ability_Mount_Raptor",
  [50406] = "Interface\\Icons\\INV_Misc_Root_02",
  [50407] = "Interface\\Icons\\Ability_Mount_NightmareHorse",
  [50426] = "Interface\\Icons\\INV_Jewelry_Talisman_02",
  [50535] = "Interface\\Icons\\INV_Misc_Foot_Centaur",
  [50536] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [50600] = "Interface\\Icons\\INV_Misc_Comb_01",
  [50601] = "Interface\\Icons\\INV_Weapon_ShortBlade_21",
  [50602] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [51002] = "Interface\\Icons\\INV_Gizmo_02",
  [51003] = "Interface\\Icons\\INV_Gizmo_02",
  [51007] = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
  [51220] = "Interface\\Icons\\Spell_Nature_Polymorph",
  [51221] = "Interface\\Icons\\Spell_Nature_Polymorph",
  [51249] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
  [51251] = "Interface\\Icons\\Ability_EyeOfTheOwl",
  [51252] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  [51259] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [51260] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [51421] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [51433] = "Interface\\Icons\\INV_Misc_Foot_Centaur",
  [51700] = "Interface\\Icons\\INV_Egg_02",
  [51739] = "Interface\\Icons\\INV_Fabric_Wool_02",
  [51858] = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_03",
  [51889] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [51891] = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
  [51930] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [54000] = "Interface\\Icons\\INV_Crate_02",
  [54001] = "Interface\\Icons\\INV_Crate_02",
  [54002] = "Interface\\Icons\\INV_Crate_02",
  [54003] = "Interface\\Icons\\INV_Crate_02",
  [54004] = "Interface\\Icons\\INV_Crate_02",
  [54005] = "Interface\\Icons\\INV_Crate_02",
  [54006] = "Interface\\Icons\\INV_Crate_02",
  [54007] = "Interface\\Icons\\INV_Crate_02",
  [54008] = "Interface\\Icons\\INV_Crate_02",
  [55027] = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
  [55071] = "Interface\\Icons\\INV_Weapon_ShortBlade_16",
  [67000] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [69000] = "Interface\\Icons\\INV_Weapon_ShortBlade_16",
  [69001] = "Interface\\Icons\\INV_Weapon_ShortBlade_16",
  [69002] = "Interface\\Icons\\INV_Misc_Spyglass_03",
  [69003] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [69004] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [69006] = "Interface\\Icons\\INV_Feather_13",
  [69170] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [69171] = "Interface\\Icons\\Spell_Magic_PolymorphPig",
  [69172] = "Interface\\Icons\\Spell_Magic_PolymorphPig",
  [69173] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [70016] = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
  [80000] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [80001] = "Interface\\Icons\\INV_Misc_Herb_14",
  [80003] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [80004] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [80006] = "Interface\\Icons\\Spell_Arcane_Blink",
  [80007] = "Interface\\Icons\\INV_Staff_08",
  [80010] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [80410] = "Interface\\Icons\\Ability_Hunter_BeastCall",
  [80425] = "Interface\\Icons\\INV_Misc_Root_02",
  [80430] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [80431] = "Interface\\Icons\\Spell_Magic_PolymorphChicken",
  [80433] = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
  [80438] = "Interface\\Icons\\Ability_Druid_DemoralizingRoar",
  [80443] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [80446] = "Interface\\Icons\\Ability_Mount_BlackPanther",
  [80447] = "Interface\\Icons\\Ability_Mount_BlackDireWolf",
  [80449] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [80455] = "Interface\\Icons\\Ability_Mount_Kodo_03",
  [80457] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [80458] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [80459] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [80460] = "Interface\\Icons\\INV_Misc_MissileSmall_Red",
  [80461] = "Interface\\Icons\\INV_Misc_MissileSmall_Green",
  [80462] = "Interface\\Icons\\INV_Misc_MissileSmall_Blue",
  [80692] = "Interface\\Icons\\Ability_Mount_NightmareHorse",
  [80878] = "Interface\\Icons\\INV_Feather_14",
  [81091] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81100] = "Interface\\Icons\\INV_Feather_13",
  [81102] = "Interface\\Icons\\Ability_Druid_ChallangingRoar",
  [81120] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81121] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81150] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81151] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [81152] = "Interface\\Icons\\INV_Box_PetCarrier_01",
  [81153] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [81154] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [81155] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [81156] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81158] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [81159] = "Interface\\Icons\\INV_Drink_19",
  [81182] = "Interface\\Icons\\Ability_Mount_Raptor",
  [81183] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81185] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81186] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81190] = "Interface\\Icons\\INV_Misc_Key_06",
  [81191] = "Interface\\Icons\\INV_Misc_Key_05",
  [81192] = "Interface\\Icons\\INV_Misc_Gear_01",
  [81193] = "Interface\\Icons\\INV_Misc_Gear_01",
  [81194] = "Interface\\Icons\\INV_Misc_Gear_01",
  [81195] = "Interface\\Icons\\INV_Misc_Gear_01",
  [81198] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [81207] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81224] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [81225] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [81226] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [81227] = "Interface\\Icons\\Ability_Mount_JungleTiger",
  [81231] = "Interface\\Icons\\Ability_Mount_PinkTiger",
  [81232] = "Interface\\Icons\\Ability_Mount_PinkTiger",
  [81233] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [81234] = "Interface\\Icons\\Ability_Mount_MountainRam",
  [81235] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [81236] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [81237] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [81238] = "Interface\\Icons\\INV_Misc_Key_12",
  [81239] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81240] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81241] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81242] = "Interface\\Icons\\INV_Misc_QuestionMark",
  [81243] = "Interface\\Icons\\INV_Misc_Birdbeck_01",
  [81244] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [81245] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [81246] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [81247] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [81248] = "Interface\\Icons\\INV_Drink_19",
  [81254] = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
  [81258] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [81283] = "Interface\\Icons\\INV_Misc_Ribbon_01",
  [83150] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
  [83151] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [83152] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [83153] = "Interface\\Icons\\Ability_Mount_Raptor",
  [83154] = "Interface\\Icons\\Ability_Mount_Raptor",
  [83155] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [83156] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [83157] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [83158] = "Interface\\Icons\\INV_Jewelry_Talisman_02",
  [83159] = "Interface\\Icons\\Ability_Mount_Kodo_01",
  [83300] = "Interface\\Icons\\INV_Misc_Urn_01",
  [83301] = "Interface\\Icons\\Spell_Fire_LavaSpawn",
  [83302] = "Interface\\Icons\\INV_Misc_Rune_04",
  [83475] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [83476] = "Interface\\Icons\\Ability_Mount_PinkTiger",
  [83477] = "Interface\\Icons\\INV_Misc_Foot_Centaur",
  [83520] = "Interface\\Icons\\Ability_Mount_RidingHorse",
  [84038] = "Interface\\Icons\\INV_Misc_Bone_04",
  [92016] = "Interface\\Icons\\INV_Crate_02",
  [92017] = "Interface\\Icons\\INV_Misc_Foot_Centaur",
  [92018] = "Interface\\Icons\\INV_Misc_Foot_Centaur",
  [92020] = "Interface\\Icons\\INV_Misc_Birdbeck_02",
  [92050] = "Interface\\Icons\\INV_Jewelry_Talisman_08",
  [92051] = "Interface\\Icons\\Ability_Mount_Undeadhorse",
  [92052] = "Interface\\Icons\\INV_Misc_Head_Tiger_01",
  [98800] = "Interface\\Icons\\inv_misc_octopuss",
  [98801] = "Interface\\Icons\\inv_misc_octopuss_purple",
}

local function ABC_GetMountItemTexture(data)
  if not data or not data.itemID then return nil end
  local itemID = tonumber(data.itemID)
  if not itemID or itemID <= 0 then return nil end
  if ABC_MOUNT_ITEM_ICON_CACHE[itemID] then return ABC_MOUNT_ITEM_ICON_CACHE[itemID] end
  if ABC_DB_ITEM_ICONS[itemID] then
    ABC_MOUNT_ITEM_ICON_CACHE[itemID] = ABC_DB_ITEM_ICONS[itemID]
    return ABC_DB_ITEM_ICONS[itemID]
  end
  -- ClassicAPI's GetItemIcon reads straight from the item's own DBC data --
  -- no server round-trip/caching needed like GetItemInfo, so it works
  -- instantly even for an item the client has never seen before. Falls
  -- through to the GetItemInfo/tooltip-scan path below if it's not
  -- available (e.g. ClassicAPI isn't loaded) or doesn't know the item.
  if GetItemIcon then
    local ok, texture = pcall(GetItemIcon, itemID)
    if ok and texture and texture ~= "" then
      ABC_MOUNT_ITEM_ICON_CACHE[itemID] = texture
      return texture
    end
  end
  if GetItemInfo then
    local itemName, itemLink, quality, itemLevel, requiredLevel, itemType, itemSubType, stackCount, equipSlot, texture = GetItemInfo(itemID)
    if texture and texture ~= "" then
      ABC_MOUNT_ITEM_ICON_CACHE[itemID] = texture
      return texture
    end
  end
  if not ABC_MOUNT_ICON_QUERY_TIP and CreateFrame then
    ABC_MOUNT_ICON_QUERY_TIP = CreateFrame("GameTooltip", "ABC_MountIconQueryTip", UIParent, "GameTooltipTemplate")
    ABC_MOUNT_ICON_QUERY_TIP:SetOwner(UIParent, "ANCHOR_NONE")
  end
  if ABC_MOUNT_ICON_QUERY_TIP and ABC_MOUNT_ICON_QUERY_TIP.SetHyperlink then
    pcall(function()
      ABC_MOUNT_ICON_QUERY_TIP:ClearLines()
      ABC_MOUNT_ICON_QUERY_TIP:SetHyperlink("item:"..tostring(itemID)..":0:0:0")
    end)
    -- Vanilla/Turtle clients may not expose GET_ITEM_INFO_RECEIVED. Poll a few
    -- times after asking the tooltip to cache the item so missing mounts can
    -- replace the family fallback with their exact mount-item texture.
    if ABC_MOUNT_ICON_REFRESH then
      if not ABC_MOUNT_ICON_REFRESH.pending then ABC_MOUNT_ICON_REFRESH.attempts = 0 end
      ABC_MOUNT_ICON_REFRESH.pending = true
      ABC_MOUNT_ICON_REFRESH.elapsed = 0
      ABC_MOUNT_ICON_REFRESH:Show()
    end
  end
  return nil
end

-- Exposed so the achievement row/toast/summary code in LeafVillageAchievements.lua
-- (a separate file, loaded before this one, so it can't see this local
-- directly) can resolve a real item icon for not-yet-collected mount/
-- companion/toy achievements, instead of showing their generic catalog
-- placeholder icon whenever a real one is available.
function ABC.GetItemIconForAchievement(itemID)
  if not itemID then return nil end
  return ABC_GetMountItemTexture({ itemID = itemID })
end

local function ABC_ResolveCollectionIcon(data, kind)
  if kind == "toy" then
    if data and data.collected and data.icon and data.icon ~= "" then return data.icon, "spell icon" end
    -- Toys have no creature model to guess a family from -- just the
    -- item icon (via itemID), falling back to a flat placeholder.
    local itemTexture = ABC_GetMountItemTexture(data)
    if itemTexture and itemTexture ~= "" then return itemTexture, "toy item icon" end
    return "Interface\\Icons\\INV_Misc_QuestionMark", "toy fallback icon"
  end
  if kind ~= "mount" then
    if data and data.collected and data.icon and data.icon ~= "" then return data.icon, "spell icon" end
    -- Despite the name, ABC_GetMountItemTexture only depends on data.itemID
    -- (via GetItemIcon/GetItemInfo) -- reusable here for the item that
    -- teaches a not-yet-collected companion, same idea as mounts below.
    local itemTexture = ABC_GetMountItemTexture(data)
    if itemTexture and itemTexture ~= "" then return itemTexture, "companion item icon" end
    local family = GetCompanionFamily(data)
    return ABC_FAMILY_PORTRAIT_TEXTURES[family] or ABC_FAMILY_PORTRAIT_TEXTURES.companion, "companion family icon"
  end
  if data and data.collected and data.icon and data.icon ~= "" then return data.icon, "spell icon" end
  local itemTexture = ABC_GetMountItemTexture(data)
  if itemTexture and itemTexture ~= "" then return itemTexture, "mount item icon" end
  local family = GetModelFamily(data, kind)
  return ABC_FAMILY_PORTRAIT_TEXTURES[family] or ABC_FAMILY_PORTRAIT_TEXTURES.default or "Interface\\Icons\\INV_Misc_QuestionMark", "family icon"
end

local function ResolvePortraitTexture(data, kind)
  local name = tostring((data and data.name) or "")
  local custom = AshenBannerCollectionPortraits[name]
  if custom and custom ~= "" then return custom, true, "custom" end
  local texture, sourceType = ABC_ResolveCollectionIcon(data, kind)
  return texture, false, sourceType
end

local function ApplyPortraitTransform(portrait)
  if not portrait or not portrait._abcProfile or not portrait._abcBg then return end
  local p = portrait._abcProfile
  local custom = portrait._abcCustomPortrait
  local baseW = custom and 188 or 94
  local baseH = custom and 94 or 94
  local scale = Clamp(tonumber(p.scale) or 1, 0.35, 2.50)
  portrait:ClearAllPoints()
  portrait:SetWidth(baseW * scale)
  portrait:SetHeight(baseH * scale)
  portrait:SetPoint("CENTER", portrait._abcBg, "CENTER", tonumber(p.x) or 0, tonumber(p.y) or 0)
  if portrait._abcReadout then
    portrait._abcReadout:SetText(string.format("X %.0f  Y %.0f  Scale %.2f", tonumber(p.x) or 0, tonumber(p.y) or 0, scale))
  end
end

local function AdjustPortraitAndSave(portrait, callback)
  if not portrait or not portrait._abcProfile then return end
  callback(portrait._abcProfile)
  SavePortraitProfile(portrait._abcData, portrait._abcKind, portrait._abcProfile)
  ApplyPortraitTransform(portrait)
end

local function Copy3DProofProfile(def)
  return {
    -- frameX/frameY are screen-space pixel offsets from the preview box. They
    -- are the primary placement controls because they make the visible model
    -- follow the mouse exactly, even when the raw model origin is unusual.
    frameX = tonumber(def and def.frameX) or 0,
    frameY = tonumber(def and def.frameY) or 0,
    camera = tonumber(def and def.camera) or 1,
    x = tonumber(def and def.x) or 0,
    y = tonumber(def and def.y) or 0,
    z = tonumber(def and def.z) or 0,
    scale = tonumber(def and def.scale) or 0.08,
    rotation = tonumber(def and def.rotation) or 0.82,
  }
end

local function Get3DProofProfile(data, def)
  EnsureDB()
  local key = tostring(data and data.name or "")
  local p = AshenBannerCollectionsDB.threeDView[key]
  if type(p) ~= "table" then
    p = Copy3DProofProfile(def)
    AshenBannerCollectionsDB.threeDView[key] = p
  end
  if p.frameX == nil then p.frameX = tonumber(def and def.frameX) or 0 end
  if p.frameY == nil then p.frameY = tonumber(def and def.frameY) or 0 end
  if p.camera == nil then p.camera = tonumber(def and def.camera) or 1 end
  if p.x == nil then p.x = tonumber(def and def.x) or 0 end
  if p.y == nil then p.y = tonumber(def and def.y) or 0 end
  if p.z == nil then p.z = tonumber(def and def.z) or 0 end
  if p.scale == nil then p.scale = tonumber(def and def.scale) or 0.08 end
  if p.rotation == nil then p.rotation = tonumber(def and def.rotation) or 0.82 end
  return p
end

local function Save3DProofProfile(model)
  if not model or not model._abcData or not model._abc3DProfile then return end
  EnsureDB()
  AshenBannerCollectionsDB.threeDView[tostring(model._abcData.name or "")] = model._abc3DProfile
end

local function Reset3DProofProfile(model)
  if not model or not model._abcData or not model._abc3DDef then return end
  EnsureDB()
  local p = Copy3DProofProfile(model._abc3DDef)
  AshenBannerCollectionsDB.threeDView[tostring(model._abcData.name or "")] = p
  model._abc3DProfile = p
end

local function Apply3DProofTransform(model)
  if not model or not model._abc3DDef then return end
  local d = model._abc3DProfile or model._abc3DDef

  -- Move the viewport itself in screen space. Raw Vanilla model origins vary
  -- wildly; this guarantees that dragging right/up moves the visible geometry
  -- right/up instead of guessing which model-space axis controls the screen.
  if model._abc3DAnchor then
    model:ClearAllPoints()
    model:SetPoint("CENTER", model._abc3DAnchor, "CENTER", tonumber(d.frameX) or 0, tonumber(d.frameY) or 0)
  end

  if model.SetCamera and d.camera ~= nil then pcall(function() model:SetCamera(d.camera) end) end
  if model.SetPosition then pcall(function() model:SetPosition(d.x or 0, d.y or 0, d.z or 0) end) end
  if model.SetModelScale then pcall(function() model:SetModelScale(Clamp(d.scale or 0.08, 0.001, 2.00)) end) end
  if model.SetRotation then
    pcall(function() model:SetRotation(d.rotation or 0.82) end)
  elseif model.SetFacing then
    pcall(function() model:SetFacing(d.rotation or 0.82) end)
  end
  if model._abcReadout then
    model._abcReadout:SetText(string.format(
      "Screen X %.0f  Y %.0f | Model X %.2f  Y %.2f  Z %.2f\nScale %.4f  Rot %.2f  Cam %d",
      d.frameX or 0, d.frameY or 0, d.x or 0, d.y or 0, d.z or 0,
      d.scale or 0.08, d.rotation or 0.82, tonumber(d.camera) or 1))
  end
end

local function Create3DProofOverlay(card, portraitBg, portrait, data, kind)
  EnsureDB()
  if kind ~= "mount" or AshenBannerCollectionsDB.use3DProof ~= true then return nil end
  local defs = AshenBannerCollections3D and AshenBannerCollections3D.models
  local def = defs and defs[tostring(data and data.name or "")]
  if not def or not def.path or def.path == "" then return nil end

  local model = CreateFrame("PlayerModel", nil, portraitBg)
  model:SetWidth(portraitBg:GetWidth() - 4)
  model:SetHeight(portraitBg:GetHeight() - 4)
  model._abc3DAnchor = portraitBg
  model:SetPoint("CENTER", portraitBg, "CENTER", 0, 0)
  model:SetFrameLevel(portraitBg:GetFrameLevel() + 3)
  model._abc3DDef = def
  model._abc3DProfile = Get3DProofProfile(data, def)
  model._abcData = data
  model:SetModel(def.path)
  Apply3DProofTransform(model)
  model:Show()
  model._abc3DElapsed = 0
  model._abc3DPasses = 0
  model:SetScript("OnUpdate", function()
    this._abc3DElapsed = (this._abc3DElapsed or 0) + (arg1 or 0)
    if this._abc3DElapsed >= 0.12 then
      this._abc3DElapsed = 0
      Apply3DProofTransform(this)
      this._abc3DPasses = (this._abc3DPasses or 0) + 1
      if this._abc3DPasses >= 6 then this:SetScript("OnUpdate", nil) end
    end
  end)

  -- Keep the portrait visible behind the model. It becomes an automatic
  -- fallback whenever a custom model is missing or positioned off-screen.
  card.proof3DModel = model
  card.proof3DPath = def.path
  return model
end

local function CreatePortraitCard(parent, index, data, kind)
  local cols = 3
  local cardW = 218
  local cardH = 198
  local gapX = 14
  local gapY = 14
  local col = math.mod(index - 1, cols)
  local row = math.floor((index - 1) / cols)
  local locked = not data.collected

  local card = CreateFrame("Button", nil, parent)
  card:SetWidth(cardW)
  card:SetHeight(cardH)
  card:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 + col * (cardW + gapX), -8 - row * (cardH + gapY))
  CardBackdrop(card, locked)
  card.data = data
  card.kind = kind
  card.isPortraitCard = true

  local icon = card:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(32); icon:SetHeight(32)
  icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
  icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

  local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
  name:SetWidth(cardW - 56); name:SetJustifyH("LEFT")
  name:SetText(data.name or "Unknown")
  if locked then name:SetTextColor(0.55, 0.55, 0.55) else name:SetTextColor(1.0, 0.82, 0.36) end

  local sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
  sub:SetWidth(cardW - 56); sub:SetJustifyH("LEFT")
  local subText = locked and "Not collected" or "Collected"
  if not locked and kind == "mount" and data.speed then subText = subText.." - "..data.speed end
  sub:SetText(subText); sub:SetTextColor(0.75, 0.75, 0.75)

  local portraitBg = CreateFrame("Frame", nil, card)
  portraitBg:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -48)
  portraitBg:SetWidth(cardW - 16); portraitBg:SetHeight(105)
  portraitBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  portraitBg:SetBackdropColor(0.02, 0.02, 0.02, 0.94)
  portraitBg:SetBackdropBorderColor(locked and 0.24 or 0.50, locked and 0.24 or 0.30, locked and 0.24 or 0.10, 1)
  card.modelBg = portraitBg

  local glow = portraitBg:CreateTexture(nil, "BACKGROUND")
  glow:SetPoint("TOPLEFT", portraitBg, "TOPLEFT", 3, -3)
  glow:SetPoint("BOTTOMRIGHT", portraitBg, "BOTTOMRIGHT", -3, 3)
  glow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  if locked then glow:SetVertexColor(0.08, 0.08, 0.08, 0.65) else glow:SetVertexColor(0.18, 0.10, 0.03, 0.50) end

  local portrait = portraitBg:CreateTexture(nil, "ARTWORK")
  local texturePath, isCustom, sourceType = ResolvePortraitTexture(data, kind)
  portrait:SetTexture(texturePath)
  portrait._abcBg = portraitBg
  portrait._abcData = data
  portrait._abcKind = kind
  portrait._abcCustomPortrait = isCustom
  portrait._abcSourceType = sourceType
  local profile, family = GetPortraitProfile(data, kind)
  portrait._abcProfile = profile
  portrait._abcFamily = family
  if isCustom then
    portrait:SetTexCoord(0, 1, 0, 1)
  else
    portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  if locked then portrait:SetVertexColor(0.38, 0.38, 0.38, 0.72) else portrait:SetVertexColor(1, 1, 1, 1) end
  card.portrait = portrait

  local overlay = CreateFrame("Button", nil, portraitBg)
  overlay:SetAllPoints(portraitBg)
  overlay:SetFrameLevel(portraitBg:GetFrameLevel() + 5)
  overlay:EnableMouse(true)
  if overlay.EnableMouseWheel then overlay:EnableMouseWheel(true) end
  if overlay.RegisterForDrag then overlay:RegisterForDrag("LeftButton") end
  if overlay.RegisterForClicks then overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
  overlay.portrait = portrait
  overlay.data = data
  overlay.kind = kind
  overlay.card = card

  local readout = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  readout:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 4)
  readout:SetWidth(cardW - 24); readout:SetJustifyH("CENTER")
  readout:SetTextColor(1.0, 0.72, 0.20); readout:Hide()
  portrait._abcReadout = readout

  local lockedText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lockedText:SetPoint("CENTER", overlay, "CENTER", 0, 0)
  lockedText:SetWidth(cardW - 28); lockedText:SetJustifyH("CENTER")
  lockedText:SetText(locked and "Not collected" or "")
  lockedText:SetTextColor(0.88, 0.88, 0.88)
  card.lockedOverlay = lockedText

  local configHint = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  configHint:SetPoint("TOP", overlay, "TOP", 0, -5)
  configHint:SetWidth(cardW - 28); configHint:SetJustifyH("CENTER")
  configHint:SetText("|cFFFF7A32DRAG HERE TO MOVE 3D MODEL|r")
  configHint:Hide()
  card.configHint = configHint

  ApplyPortraitTransform(portrait)
  local proof3D = Create3DProofOverlay(card, portraitBg, portrait, data, kind)
  if proof3D then proof3D._abcReadout = readout; Apply3DProofTransform(proof3D) end

  local function BeginPlacementDrag()
    if not ABC.configMode or this._abcDragging then return end
    if arg1 and arg1 ~= "LeftButton" then return end
    this._abcDragging = true
    local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local cx, cy = GetCursorPosition()
    this._abcScale = uiScale
    this._abcStartCursorX = (cx or 0) / uiScale
    this._abcStartCursorY = (cy or 0) / uiScale
    local model = this.card and this.card.proof3DModel
    if model and model._abc3DProfile then
      this._abcEditing3D = true
      this._abcStartFrameX = model._abc3DProfile.frameX or 0
      this._abcStartFrameY = model._abc3DProfile.frameY or 0
      this:SetScript("OnUpdate", function()
        local s = this._abcScale or 1
        local x, y = GetCursorPosition(); x = (x or 0) / s; y = (y or 0) / s
        local m = this.card and this.card.proof3DModel
        local p = m and m._abc3DProfile
        if not p then return end
        -- One cursor pixel equals one screen-space model pixel.
        p.frameX = Clamp((this._abcStartFrameX or 0) + x - (this._abcStartCursorX or 0), -1200, 1200)
        p.frameY = Clamp((this._abcStartFrameY or 0) + y - (this._abcStartCursorY or 0), -900, 900)
        Apply3DProofTransform(m)
      end)
    elseif this.portrait then
      this._abcEditing3D = false
      this._abcStartX = this.portrait._abcProfile.x or 0
      this._abcStartY = this.portrait._abcProfile.y or 0
      this:SetScript("OnUpdate", function()
        local s = this._abcScale or 1
        local x, y = GetCursorPosition(); x = (x or 0) / s; y = (y or 0) / s
        local p = this.portrait and this.portrait._abcProfile
        if not p then return end
        p.x = (this._abcStartX or 0) + x - (this._abcStartCursorX or 0)
        p.y = (this._abcStartY or 0) + y - (this._abcStartCursorY or 0)
        ApplyPortraitTransform(this.portrait)
      end)
    end
  end

  local function EndPlacementDrag()
    if not this._abcDragging then return end
    this:SetScript("OnUpdate", nil)
    local model = this.card and this.card.proof3DModel
    if this._abcEditing3D and model then Save3DProofProfile(model)
    elseif this.portrait then SavePortraitProfile(this.data, this.kind, this.portrait._abcProfile) end
    this._abcEditing3D = nil
    this._abcDragging = nil
  end

  -- MouseDown/MouseUp is the reliable path on the 1.12 client. Drag scripts
  -- remain registered as a fallback for clients that emit them instead.
  overlay:SetScript("OnMouseDown", BeginPlacementDrag)
  overlay:SetScript("OnMouseUp", EndPlacementDrag)
  overlay:SetScript("OnDragStart", BeginPlacementDrag)
  overlay:SetScript("OnDragStop", EndPlacementDrag)
  overlay:SetScript("OnMouseWheel", function()
    if not ABC.configMode then return end
    local delta = tonumber(arg1) or 0
    local model = this.card and this.card.proof3DModel
    if model and model._abc3DProfile then
      local p = model._abc3DProfile
      if IsControlKeyDown and IsControlKeyDown() then
        p.rotation = (p.rotation or 0.82) + delta * 0.08
      elseif IsShiftKeyDown and IsShiftKeyDown() then
        p.z = Clamp((p.z or 0) + delta * 0.04, -12, 12)
      elseif IsAltKeyDown and IsAltKeyDown() then
        p.y = Clamp((p.y or 0) + delta * 0.04, -12, 12)
      else
        if delta > 0 then p.scale = (p.scale or 0.08) * 1.10 else p.scale = (p.scale or 0.08) / 1.10 end
        p.scale = Clamp(p.scale, 0.001, 2.00)
      end
      Save3DProofProfile(model)
      Apply3DProofTransform(model)
    elseif this.portrait then
      AdjustPortraitAndSave(this.portrait, function(p)
        if IsShiftKeyDown and IsShiftKeyDown() then p.y = Clamp((p.y or 0) + delta * 2, -100, 100)
        elseif IsAltKeyDown and IsAltKeyDown() then p.x = Clamp((p.x or 0) + delta * 2, -160, 160)
        else
          if delta > 0 then p.scale = (p.scale or 1) * 1.08 else p.scale = (p.scale or 1) / 1.08 end
          p.scale = Clamp(p.scale, 0.35, 2.50)
        end
      end)
    end
  end)
  overlay:SetScript("OnClick", function()
    if not ABC.configMode then return end
    if arg1 == "RightButton" then
      local model = this.card and this.card.proof3DModel
      if model then
        Reset3DProofProfile(model)
        Apply3DProofTransform(model)
        Print("Reset 3D view for "..tostring(this.data.name or "mount")..".")
      elseif this.portrait then
        ResetPortraitProfile(this.data, this.kind)
        local p, family = GetPortraitProfile(this.data, this.kind)
        this.portrait._abcProfile = p; this.portrait._abcFamily = family
        ApplyPortraitTransform(this.portrait)
        Print("Reset portrait for "..tostring(this.data.name or "mount")..".")
      end
    end
  end)
  overlay:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(tostring(this.data.name or "Unknown"), 1, 0.82, 0.36)
    GameTooltip:AddLine("Portrait source: "..tostring(this.portrait._abcSourceType or "unknown"), 0.55, 0.80, 1.0)
    if this.card and this.card.proof3DModel then
      GameTooltip:AddLine("3D POC: "..tostring(this.card.proof3DPath or "custom model"), 0.45, 1.0, 0.55, true)
    end
    if ABC.configMode then
      if this.card and this.card.proof3DModel then
        GameTooltip:AddLine("3D CONFIG", 1.0, 0.45, 0.20)
        GameTooltip:AddLine("Drag inside the preview: move model on screen", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Wheel: scale", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Shift / Alt / Ctrl + wheel: Z / Y / rotation", 0.80, 0.80, 0.80)
      else
        GameTooltip:AddLine("PORTRAIT CONFIG", 1.0, 0.45, 0.20)
        GameTooltip:AddLine("Drag: move portrait", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Wheel: scale", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Shift / Alt + wheel: Y / X nudge", 0.80, 0.80, 0.80)
      end
      GameTooltip:AddLine("Right-click: reset", 0.80, 0.80, 0.80)
    end
    GameTooltip:Show()
  end)
  overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local source = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  source:SetPoint("TOPLEFT", portraitBg, "BOTTOMLEFT", 2, -5)
  source:SetWidth(cardW - 20); source:SetJustifyH("LEFT")
  source:SetText(data.source or data.tabName or "Spellbook collection")

  if not locked then
    local summon = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    summon:SetWidth(76); summon:SetHeight(22)
    summon:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
    summon:SetText(kind == "mount" and "Mount" or "Summon")
    summon:SetScript("OnClick", function()
      local d = this:GetParent().data
      if d and d.spellIndex then CastSpell(d.spellIndex, d.bookType or BOOK_SPELL)
      else Print("Spellbook index not available. Run /abcoll scan, then reopen the tab.") end
    end)
  end

  card:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(data.name or "Unknown", 1, 0.82, 0.36)
    GameTooltip:AddLine("Mount Collection", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Reliable portrait renderer", 0.55, 0.80, 1.0)
    GameTooltip:Show()
  end)
  card:SetScript("OnLeave", function() GameTooltip:Hide() end)

  table.insert(ABC.activeCards, card)
  return card
end

local function CreateCard(parent, index, data, kind)
  if kind == "mount" then return CreatePortraitCard(parent, index, data, kind) end
  return CreateModelCard(parent, index, data, kind)
end

CreateModelCard = function(parent, index, data, kind)
  local cols = 3
  local cardW = 218
  local cardH = 198
  local gapX = 14
  local gapY = 14
  local col = math.mod(index - 1, cols)
  local row = math.floor((index - 1) / cols)
  local locked = not data.collected

  local card = CreateFrame("Button", nil, parent)
  card:SetWidth(cardW)
  card:SetHeight(cardH)
  card:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 + col * (cardW + gapX), -8 - row * (cardH + gapY))
  CardBackdrop(card, locked)
  card.data = data
  card.kind = kind

  local icon = card:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(32)
  icon:SetHeight(32)
  icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
  icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

  local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
  name:SetWidth(cardW - 56)
  name:SetJustifyH("LEFT")
  name:SetText(data.name or "Unknown")
  if locked then name:SetTextColor(0.55, 0.55, 0.55) else name:SetTextColor(1.0, 0.82, 0.36) end

  local sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
  sub:SetWidth(cardW - 56)
  sub:SetJustifyH("LEFT")
  local subText = locked and "Not collected" or "Collected"
  if not locked and kind == "mount" and data.speed then subText = subText.." - "..data.speed end
  sub:SetText(subText)
  sub:SetTextColor(0.75, 0.75, 0.75)

  local modelBg = CreateFrame("Frame", nil, card)
  modelBg:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -48)
  modelBg:SetWidth(cardW - 16)
  modelBg:SetHeight(105)
  modelBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  modelBg:SetBackdropColor(0.02, 0.02, 0.02, 0.94)
  modelBg:SetBackdropBorderColor(locked and 0.24 or 0.50, locked and 0.24 or 0.30, locked and 0.24 or 0.10, 1)
  card.modelBg = modelBg

  -- LOCKED LAYOUT: only the renderer type changes here.  Raw mount M2 files
  -- belong in the base Model widget.  PlayerModel is retained for companions
  -- that can be resolved through a cached creature/unit model.
  local widgetType = (kind == "mount") and "Model" or "PlayerModel"
  local model = CreateFrame(widgetType, nil, modelBg)
  model._abcWidgetType = widgetType
  model:SetPoint("TOPLEFT", modelBg, "TOPLEFT", 3, -3)
  model:SetPoint("BOTTOMRIGHT", modelBg, "BOTTOMRIGHT", -3, 3)
  if model.SetFrameLevel then model:SetFrameLevel(modelBg:GetFrameLevel() + 2) end
  if model.SetAlpha then model:SetAlpha(locked and 0.58 or 1.0) end
  card.model = model
  table.insert(ABC.activeModels, model)

  local overlay = CreateFrame("Button", nil, modelBg)
  overlay:SetAllPoints(modelBg)
  if overlay.SetFrameLevel then overlay:SetFrameLevel(modelBg:GetFrameLevel() + 5) end
  overlay:EnableMouse(true)
  if overlay.EnableMouseWheel then overlay:EnableMouseWheel(true) end
  if overlay.RegisterForDrag then overlay:RegisterForDrag("LeftButton") end
  if overlay.RegisterForClicks then overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
  card.modelOverlay = overlay

  local readout = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  readout:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 4)
  readout:SetWidth(cardW - 24)
  readout:SetJustifyH("CENTER")
  readout:SetTextColor(1.0, 0.72, 0.20)
  readout:Hide()
  model._abcReadout = readout

  local lockedText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  lockedText:SetPoint("CENTER", overlay, "CENTER", 0, 0)
  lockedText:SetWidth(cardW - 28)
  lockedText:SetJustifyH("CENTER")
  lockedText:SetText(locked and "Not collected" or "")
  lockedText:SetTextColor(0.85, 0.85, 0.85)
  card.lockedOverlay = lockedText

  local hasModel = LoadModel(model, data, kind)
  if not hasModel then
    local missing = overlay:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    missing:SetPoint("CENTER", overlay, "CENTER", 0, 0)
    missing:SetWidth(cardW - 28)
    missing:SetJustifyH("CENTER")
    missing:SetText("Model not available")
    model:Hide()
    card.missingModelText = missing
  end

  overlay.model = model
  overlay.data = data
  overlay.kind = kind

  overlay:SetScript("OnDragStart", function()
    if not ABC.configMode or not this.model or not this.model._abcProfile then return end
    local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local cx, cy = GetCursorPosition()
    this._abcScale = scale
    this._abcStartCursorX = (cx or 0) / scale
    this._abcStartCursorY = (cy or 0) / scale
    this._abcStartX = this.model._abcProfile.x or 0
    this._abcStartZ = this.model._abcProfile.z or 0
    this._abcStartRotation = this.model._abcProfile.rotation or 0.61
    this._abcRotateDrag = IsControlKeyDown and IsControlKeyDown()
    this:SetScript("OnUpdate", function()
      local s = this._abcScale or 1
      local x, y = GetCursorPosition()
      x = (x or 0) / s
      y = (y or 0) / s
      local dx = x - (this._abcStartCursorX or 0)
      local dy = y - (this._abcStartCursorY or 0)
      local p = this.model and this.model._abcProfile
      if not p then return end
      if this._abcRotateDrag then
        p.rotation = (this._abcStartRotation or 0.61) + dx * 0.012
      else
        -- Model coordinates are not UI pixels. Deliberately small conversion
        -- prevents crossing the model frustum after a short drag.
        p.x = (this._abcStartX or 0) + dx * 0.0025
        p.z = (this._abcStartZ or 0) + dy * 0.0025
      end
      ApplyVanillaTransforms(this.model)
    end)
  end)

  overlay:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    if this.model and this.model._abcProfile then SaveModelProfile(this.data, this.kind, this.model._abcProfile) end
  end)

  overlay:SetScript("OnMouseWheel", function()
    if not ABC.configMode or not this.model or not this.model._abcProfile then return end
    local delta = tonumber(arg1) or 0
    AdjustAndSave(this.model, function(p)
      if IsShiftKeyDown and IsShiftKeyDown() and IsControlKeyDown and IsControlKeyDown() then
        p.camera = (tonumber(p.camera) or 1) == 1 and 0 or 1
      elseif IsAltKeyDown and IsAltKeyDown() and IsControlKeyDown and IsControlKeyDown() then
        p.y = Clamp((p.y or 0) + delta * 0.02, -4, 4)
      elseif IsShiftKeyDown and IsShiftKeyDown() then
        p.z = Clamp((p.z or 0) + delta * 0.02, -4, 4)
      elseif IsAltKeyDown and IsAltKeyDown() then
        p.x = Clamp((p.x or 0) + delta * 0.02, -4, 4)
      elseif IsControlKeyDown and IsControlKeyDown() then
        p.rotation = (p.rotation or 0.61) + delta * 0.10
      else
        if delta > 0 then p.scale = (p.scale or 0.05) * 1.08 else p.scale = (p.scale or 0.05) / 1.08 end
        p.scale = Clamp(p.scale, 0.001, 1.0)
      end
    end)
  end)

  overlay:SetScript("OnClick", function()
    if not ABC.configMode or not this.model then return end
    if arg1 == "RightButton" then
      ResetModelProfile(this.data, this.kind)
      local p, family = GetModelProfile(this.data, this.kind)
      this.model._abcProfile = p
      this.model._abcFamily = family
      SaveModelProfile(this.data, this.kind, p)
      ApplyVanillaTransforms(this.model)
      Print("Reset view for "..tostring(this.data.name or "model")..".")
    end
  end)

  overlay:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(tostring(this.data.name or "Unknown"), 1, 0.82, 0.36)
    if ABC.configMode then
      GameTooltip:AddLine("VANILLA MODEL CONFIG", 1.0, 0.45, 0.20)
      GameTooltip:AddLine("Drag: horizontal / vertical model position", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("Ctrl + drag: native 1.12 model rotation", 0.85, 0.85, 0.85)
      GameTooltip:AddLine("Wheel: model scale", 0.80, 0.80, 0.80)
      GameTooltip:AddLine("Alt / Shift + wheel: X / Z nudge", 0.80, 0.80, 0.80)
      GameTooltip:AddLine("Shift + Ctrl + wheel: switch camera 0 / 1", 0.80, 0.80, 0.80)
      GameTooltip:AddLine("Alt + Ctrl + wheel: depth Y", 0.80, 0.80, 0.80)
      GameTooltip:AddLine("Right-click: reset this mount", 0.80, 0.80, 0.80)
    end
    if this.model._abcLoader then GameTooltip:AddLine("Loader: "..tostring(this.model._abcLoader), 0.50, 0.75, 1.0) end
    GameTooltip:AddLine("Family: "..tostring(this.model._abcFamily or "default"), 0.65, 0.65, 0.65)
    GameTooltip:Show()
  end)
  overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- Fine controls are shown only in config mode. They use the same model-space
  -- values as drag/wheel and make exact repeatable adjustments possible.
  local xMinus = CreateFineButton(overlay, "X-", "TOPLEFT", overlay, "TOPLEFT", 2, -2, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.x = (p.x or 0) - 0.02 end) end)
  local xPlus  = CreateFineButton(overlay, "X+", "LEFT", xMinus, "RIGHT", 1, 0, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.x = (p.x or 0) + 0.02 end) end)
  local zMinus = CreateFineButton(overlay, "Z-", "LEFT", xPlus, "RIGHT", 1, 0, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.z = (p.z or 0) - 0.02 end) end)
  local zPlus  = CreateFineButton(overlay, "Z+", "LEFT", zMinus, "RIGHT", 1, 0, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.z = (p.z or 0) + 0.02 end) end)
  local yMinus = CreateFineButton(overlay, "Y-", "LEFT", zPlus, "RIGHT", 1, 0, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.y = (p.y or 0) - 0.02 end) end)
  local yPlus  = CreateFineButton(overlay, "Y+", "LEFT", yMinus, "RIGHT", 1, 0, 30, function() AdjustAndSave(this:GetParent().model, function(p) p.y = (p.y or 0) + 0.02 end) end)
  local scaleMinus = CreateFineButton(overlay, "S-", "TOPLEFT", overlay, "TOPLEFT", 18, -22, 38, function() AdjustAndSave(this:GetParent().model, function(p) p.scale = Clamp((p.scale or 0.05) / 1.08, 0.001, 1.0) end) end)
  local scalePlus  = CreateFineButton(overlay, "S+", "LEFT", scaleMinus, "RIGHT", 2, 0, 38, function() AdjustAndSave(this:GetParent().model, function(p) p.scale = Clamp((p.scale or 0.05) * 1.08, 0.001, 1.0) end) end)
  local rotMinus = CreateFineButton(overlay, "R-", "LEFT", scalePlus, "RIGHT", 2, 0, 38, function() AdjustAndSave(this:GetParent().model, function(p) p.rotation = (p.rotation or 0.61) - 0.10 end) end)
  local rotPlus  = CreateFineButton(overlay, "R+", "LEFT", rotMinus, "RIGHT", 2, 0, 38, function() AdjustAndSave(this:GetParent().model, function(p) p.rotation = (p.rotation or 0.61) + 0.10 end) end)
  card.configButtons = { xMinus, xPlus, zMinus, zPlus, yMinus, yPlus, scaleMinus, scalePlus, rotMinus, rotPlus }
  for i = 1, table.getn(card.configButtons) do card.configButtons[i]:Hide() end

  local source = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  source:SetPoint("TOPLEFT", modelBg, "BOTTOMLEFT", 2, -5)
  source:SetWidth(cardW - 20)
  source:SetJustifyH("LEFT")
  source:SetText(data.source or data.tabName or "Spellbook collection")

  if not locked then
    local summon = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    summon:SetWidth(76)
    summon:SetHeight(22)
    summon:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
    summon:SetText(kind == "mount" and "Mount" or "Summon")
    summon:SetScript("OnClick", function()
      local d = this:GetParent().data
      if d and d.spellIndex then CastSpell(d.spellIndex, d.bookType or BOOK_SPELL)
      else Print("Spellbook index not available. Run /abcoll scan, then reopen the tab.") end
    end)
  end

  card:SetScript("OnHide", function() if this.model then StopModel(this.model, true) end end)
  card:SetScript("OnShow", function()
    if this.model and this.data then
      if LoadModel(this.model, this.data, this.kind) then this.model:Show() end
    end
  end)

  card:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(data.name or "Unknown", 1, 0.82, 0.36)
    GameTooltip:AddLine(kind == "mount" and "Mount Collection" or "Companion Collection", 0.7, 0.7, 0.7)
    if data.creatureID then GameTooltip:AddLine("Creature ID: "..tostring(data.creatureID), 0.55, 1.0, 0.55) end
    if data.displayID then GameTooltip:AddLine("Display ID: "..tostring(data.displayID), 0.55, 0.75, 1.0) end
    GameTooltip:Show()
  end)
  card:SetScript("OnLeave", function() GameTooltip:Hide() end)

  table.insert(ABC.activeCards, card)
  return card
end

function ABC:RefreshConfigVisuals()
  for i = 1, table.getn(self.activeCards or {}) do
    local card = self.activeCards[i]
    if card.isPortraitCard and card.portrait then
      local show = self.configMode
      if card.portrait._abcReadout then
        if show then
          card.portrait._abcReadout:Show()
          if card.proof3DModel then Apply3DProofTransform(card.proof3DModel) else ApplyPortraitTransform(card.portrait) end
        else card.portrait._abcReadout:Hide() end
      end
      if card.configHint then
        if show and card.proof3DModel then card.configHint:Show() else card.configHint:Hide() end
      end
      if card.modelBg then
        if show then card.modelBg:SetBackdropBorderColor(1.0, 0.35, 0.05, 1.0)
        else card.modelBg:SetBackdropBorderColor((not card.data.collected) and 0.24 or 0.50, (not card.data.collected) and 0.24 or 0.30, (not card.data.collected) and 0.24 or 0.10, 1.0) end
      end
    else
      local show = self.configMode and card.model and card.model._abcProfile
      if card.model and card.model._abcReadout then
        if show then card.model._abcReadout:Show(); ApplyVanillaTransforms(card.model)
        else card.model._abcReadout:Hide() end
      end
      for j = 1, table.getn(card.configButtons or {}) do
        if show then card.configButtons[j]:Show() else card.configButtons[j]:Hide() end
      end
      if card.modelBg then
        if show then card.modelBg:SetBackdropBorderColor(1.0, 0.35, 0.05, 1.0)
        else card.modelBg:SetBackdropBorderColor((not card.data.collected) and 0.24 or 0.50, (not card.data.collected) and 0.24 or 0.30, (not card.data.collected) and 0.24 or 0.10, 1.0) end
      end
    end
  end
end

function ABC:SetConfigMode(enabled, kind)
  self.configMode = enabled and true or false
  if kind then self:BuildCollectionView(kind) else self:RefreshConfigVisuals() end
end

function ABC:ApplyCurrentPageToFamilies(kind)
  local changed = 0
  for i = 1, table.getn(self.activeCards or {}) do
    local card = self.activeCards[i]
    if kind == "mount" and card and card.portrait and card.portrait._abcProfile then
      SavePortraitFamilyProfile(card.data, kind, card.portrait._abcProfile)
      changed = changed + 1
    elseif card and card.model and card.model._abcData and card.model._abcProfile and card.model._abcKind == kind then
      SaveFamilyProfile(card.model._abcData, kind, card.model._abcProfile)
      changed = changed + 1
    end
  end
  Print("Saved "..tostring(changed).." visible "..((kind == "mount") and "portrait" or "model").." views as family defaults.")
end


local function BuildEmptyState(parent, kind)
  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -22)
  title:SetText(kind == "mount" and "No mounts detected yet" or "No companions detected yet")
  title:SetTextColor(1.0, 0.82, 0.36)

  local body = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  body:SetWidth(650)
  body:SetJustifyH("LEFT")
  body:SetText("Run |cFFFFFFFF/abcoll scan|r after logging in. If Turtle stores these in a custom spellbook frame that does not expose normal spellbook entries, run |cFFFFFFFF/abcoll dump|r and send the output so we can hook the exact Turtle collection API.")
end

local function CreateCardFailure(parent, index, data, err)
  local cols = 3
  local cardW = 218
  local cardH = 198
  local gapX = 14
  local gapY = 14
  local col = math.mod(index - 1, cols)
  local row = math.floor((index - 1) / cols)

  local card = CreateFrame("Frame", nil, parent)
  card:SetWidth(cardW)
  card:SetHeight(cardH)
  card:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 + col * (cardW + gapX), -8 - row * (cardH + gapY))
  CardBackdrop(card, true)

  local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
  title:SetWidth(cardW - 20)
  title:SetJustifyH("LEFT")
  title:SetText(tostring((data and data.name) or "Unknown mount"))
  title:SetTextColor(1.0, 0.45, 0.25)

  local body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  body:SetWidth(cardW - 20)
  body:SetJustifyH("LEFT")
  body:SetText("Card renderer error. The rest of the page remains usable.\n\n"..tostring(err or "Unknown error"))
  body:SetTextColor(0.85, 0.75, 0.70)

  return card
end

function ABC:BuildCollectionView(kind)
  if not LeafVE_AchTest or not LeafVE_AchTest.UI then return end
  local ui = LeafVE_AchTest.UI
  if not ui.frame or not ui.scrollChild then return end

  if ui.summaryFrame then ui.summaryFrame:Hide() end
  if ui.titleSummaryFrame then ui.titleSummaryFrame:Hide() end
  ReleaseActiveModels()
  HideOriginalFilters(ui)
  ClearScrollChild(ui)
  ShowFrame(ui.scrollFrame)
  ShowFrame(ui.scrollbar)
  ShowFrame(ui.contentArt)
  HideFrame(ui.sidebarFrame)
  HideFrame(ui.titleSidebarFrame)
  HideFrame(ui.adminFrame)
  if kind == "mount" then
    HideFrame(ui.companionSidebarFrame)
    HideFrame(ui.abcCompanionSidebarFrame)
    ShowFrame(self:EnsureMountSidebar(ui))
    self:RefreshMountSidebar(ui)
  else
    HideFrame(ui.companionSidebarFrame)
    HideFrame(ui.abcMountSidebarFrame)
    ShowFrame(self:EnsureCompanionSidebar(ui))
    self:RefreshCompanionSidebar(ui)
  end

  if ABC.scanCount == 0 then ABC:ScanSpellbook(false) end
  local fullList = BuildSortedList(kind)
  local list = FilterCollectionList(fullList, kind)
  if table.getn(list) == 0 then
    if kind == "mount" and table.getn(fullList) > 0 then
      local empty = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      empty:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 18, -22)
      empty:SetText("No mounts match "..tostring(AshenBannerCollectionsDB.mountFilter or "this category"))
      empty:SetTextColor(1.0, 0.82, 0.36)
    else
      BuildEmptyState(ui.scrollChild, kind)
    end
    SetScrollHeight(ui, 420)
    return
  end

  local header = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 10, -4)
  header:SetText(kind == "mount" and "Mount Collection" or "Companion Collection")
  header:SetTextColor(1.0, 0.82, 0.36)

  local collected = 0
  for _, row in ipairs(fullList) do if row.collected then collected = collected + 1 end end
  local summary = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
  local shownSuffix = ""
  if kind == "mount" and table.getn(list) ~= table.getn(fullList) then
    shownSuffix = "  -  "..tostring(table.getn(list)).." shown"
  end
  summary:SetText(tostring(collected).." / "..tostring(table.getn(fullList)).." collected"..shownSuffix)
  summary:SetTextColor(0.78, 0.78, 0.78)

  local perPage = self.cardsPerPage or 6
  local totalPages = math.ceil(table.getn(list) / perPage)
  if totalPages < 1 then totalPages = 1 end
  local page = tonumber(self.pages[kind]) or 1
  if page < 1 then page = 1 end
  if page > totalPages then page = totalPages end
  self.pages[kind] = page

  local refresh = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  refresh:SetWidth(62); refresh:SetHeight(22)
  refresh:SetPoint("TOPRIGHT", ui.scrollChild, "TOPRIGHT", -10, -1)
  refresh:SetText("Rescan")
  refresh:SetScript("OnClick", function() ABC:ScanSpellbook(true) end)

  local nextBtn = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  nextBtn:SetWidth(48); nextBtn:SetHeight(22)
  nextBtn:SetPoint("RIGHT", refresh, "LEFT", -4, 0)
  nextBtn:SetText("Next")
  nextBtn:SetScript("OnClick", function()
    ABC.pages[kind] = math.min((tonumber(ABC.pages[kind]) or 1) + 1, totalPages)
    ABC:BuildCollectionView(kind)
  end)
  if page >= totalPages then nextBtn:Disable() end
  if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(nextBtn) end

  local pageText = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageText:SetWidth(70); pageText:SetJustifyH("CENTER")
  pageText:SetPoint("RIGHT", nextBtn, "LEFT", -2, 0)
  pageText:SetText("Page "..tostring(page).." / "..tostring(totalPages))
  pageText:SetTextColor(0.85, 0.78, 0.62)

  local prevBtn = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  prevBtn:SetWidth(48); prevBtn:SetHeight(22)
  prevBtn:SetPoint("RIGHT", pageText, "LEFT", -2, 0)
  prevBtn:SetText("Prev")
  prevBtn:SetScript("OnClick", function()
    ABC.pages[kind] = math.max((tonumber(ABC.pages[kind]) or 1) - 1, 1)
    ABC:BuildCollectionView(kind)
  end)
  if page <= 1 then prevBtn:Disable() end
  if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(prevBtn) end

  local configBtn = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  configBtn:SetWidth(72); configBtn:SetHeight(22)
  configBtn:SetPoint("RIGHT", prevBtn, "LEFT", -5, 0)
  configBtn:SetText(self.configMode and "Done" or "Configure")
  configBtn:SetScript("OnClick", function()
    ABC:SetConfigMode(not ABC.configMode, kind)
    if ABC.configMode then
      Print("3D placement enabled. Drag inside a preview box to move its model on screen; wheel scales; Ctrl+wheel rotates; Shift/Alt+wheel adjusts model Z/Y; Dump copies exact values.")
    else
      Print("Collection model placements saved.")
    end
  end)

  local dumpBtn = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  dumpBtn:SetWidth(68); dumpBtn:SetHeight(22)
  dumpBtn:SetPoint("RIGHT", configBtn, "LEFT", -4, 0)
  dumpBtn:SetText("Dump")
  dumpBtn:SetScript("OnClick", function() ABC:ShowModelViewDump(kind, true) end)

  local familyBtn = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  familyBtn:SetWidth(78); familyBtn:SetHeight(22)
  familyBtn:SetPoint("RIGHT", dumpBtn, "LEFT", -4, 0)
  familyBtn:SetText("Save Family")
  familyBtn:SetScript("OnClick", function()
    ABC:ApplyCurrentPageToFamilies(kind)
    ABC:BuildCollectionView(kind)
  end)
  if not self.configMode then familyBtn:Hide() end

  local firstCardY = self.configMode and 64 or 42
  if self.configMode then
    local help = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    help:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -5)
    help:SetWidth(680); help:SetJustifyH("LEFT")
    help:SetText("|cFFFF7A323D PLACEMENT:|r drag inside a model preview to move it directly; wheel scales; Ctrl+wheel rotates; Shift/Alt+wheel adjusts Z/Y; Dump copies exact per-mount values.")
    help:SetTextColor(0.92, 0.78, 0.62)
  end

  local shim = CreateFrame("Frame", nil, ui.scrollChild)
  shim:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 0, -firstCardY)
  shim:SetWidth(690); shim:SetHeight(1)

  local firstIndex = (page - 1) * perPage + 1
  local lastIndex = math.min(firstIndex + perPage - 1, table.getn(list))
  local localIndex = 1
  for i = firstIndex, lastIndex do
    local rowData = list[i]
    local ok, result = pcall(CreateCard, shim, localIndex, rowData, kind)
    if not ok then
      Print("Card renderer error for "..tostring((rowData and rowData.name) or "Unknown")..": "..tostring(result))
      CreateCardFailure(shim, localIndex, rowData, result)
    end
    localIndex = localIndex + 1
  end

  self:RefreshConfigVisuals()
  local shown = lastIndex - firstIndex + 1
  local rows = math.ceil(shown / 3)
  SetScrollHeight(ui, firstCardY + rows * 212 + 20)
end


function ABC:UpdateTabVisuals()
  if not LeafVE_AchTest or not LeafVE_AchTest.UI then return end
  local ui = LeafVE_AchTest.UI
  local current = ui.currentView
  local function set(btn, active)
    if not btn then return end
    if active then btn:Disable() else btn:Enable() end
  end
  set(ui.companionTab, current == "companions")
  set(ui.mountTab or ui.mountsTab, current == "mounts")
  set(ui.toyTab, current == "toys")
  set(ui.achTab, current == "achievements")
  set(ui.titlesTab, current == "titles")
  set(ui.adminTab, current == "admin")
  set(ui.guildCollectionTab, current == "guildcollection")
end

function ABC:InstallTabs()
  if not LeafVE_AchTest or not LeafVE_AchTest.UI or not LeafVE_AchTest.UI.frame then return false end
  local ui = LeafVE_AchTest.UI
  local f = ui.frame

  -- The base UI historically called this button mountsTab while the old
  -- external collections addon called it mountTab. Alias the existing button
  -- before checking for one so the fused addon never creates a duplicate.
  if ui.mountsTab and not ui.mountTab then ui.mountTab = ui.mountsTab end
  if ui.mountTab and not ui.mountsTab then ui.mountsTab = ui.mountTab end

  if ui.companionTab then
    ui.companionTab:SetScript("OnClick", function()
      HideFrame(LeafVE_AchTest.UI.abcMountSidebarFrame)
      LeafVE_AchTest.UI.currentView = "companions"
      ABC:ScanSpellbook(false)
      LeafVE_AchTest.UI:Refresh()
    end)
  end

  if not ui.mountTab and not ui.mountsTab then
    local mountTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mountTab:SetPoint("LEFT", ui.companionTab, "RIGHT", 5, 0)
    mountTab:SetWidth(70)
    mountTab:SetHeight(ui.companionTab and ui.companionTab:GetHeight() or 28)
    mountTab:SetText("Mounts")
    mountTab:SetScript("OnClick", function()
      LeafVE_AchTest.UI.currentView = "mounts"
      ABC:ScanSpellbook(false)
      LeafVE_AchTest.UI:Refresh()
    end)
    ui.mountTab = mountTab
    ui.mountsTab = mountTab

    if ui.titlesTab then
      ui.titlesTab:ClearAllPoints()
      ui.titlesTab:SetPoint("LEFT", mountTab, "RIGHT", 5, 0)
    end
  end

  -- "Who has this mount" -- guild-wide ownership lookup, anchored after
  -- Toys and pushing Admin over to make room, same re-anchor idiom used
  -- for titlesTab above when Mounts gets inserted late. Restricted to a
  -- single character while this tab is still being built out -- everyone
  -- else never gets the button (and thus never the "guildcollection" view)
  -- at all.
  if not ui.guildCollectionTab and ui.toyTab and UnitName("player") == "Kamehameheal" then
    local guildCollectionTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    guildCollectionTab:SetPoint("LEFT", ui.toyTab, "RIGHT", 5, 0)
    guildCollectionTab:SetWidth(60)
    guildCollectionTab:SetHeight(ui.toyTab:GetHeight() or 26)
    guildCollectionTab:SetText("Guild")
    guildCollectionTab:SetScript("OnClick", function()
      LeafVE_AchTest.UI.currentView = "guildcollection"
      LeafVE_AchTest.UI:Refresh()
    end)
    ui.guildCollectionTab = guildCollectionTab
    -- Every other tab (achTab/companionTab/mountsTab/toyTab/titlesTab/
    -- adminTab) gets this in UI:Build() (LeafVillageAchievements.lua
    -- ~7088-7093) right after creation -- this one is built later, from
    -- here in InstallTabs, and was never skinned, which is why it was
    -- still showing plain Blizzard grey/blue instead of the ashen texture
    -- + gold text every other tab button has.
    if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(guildCollectionTab) end

    if ui.adminTab then
      ui.adminTab:ClearAllPoints()
      ui.adminTab:SetPoint("LEFT", guildCollectionTab, "RIGHT", 20, 0)
    end
  end

  ABC:UpdateTabVisuals()
  return true
end

function ABC:InstallHooks()
  if ABC.installedHooks then return end
  if not LeafVE_AchTest or not LeafVE_AchTest.UI then return end
  local ui = LeafVE_AchTest.UI
  if not ui.Build or not ui.Refresh then return end

  local oldBuild = ui.Build
  ui.Build = function(self)
    oldBuild(self)
    ABC:InstallTabs()
  end

  local oldRefresh = ui.Refresh
  ui.Refresh = function(self)
    ABC:InstallTabs()

    -- Search ownership is strict: collection searches only exist on their own
    -- collection tab. Hide both before choosing the active view so a stale
    -- frame can never overlap Achievements, Titles, or Admin.
    if self.abcStableMountSearch then self.abcStableMountSearch:Hide() end
    if self.abcStableCompanionSearch then self.abcStableCompanionSearch:Hide() end
    if self.abcStableToySearch then self.abcStableToySearch:Hide() end
    if self.abcStableGuildSearch then self.abcStableGuildSearch:Hide() end

    -- The mounts/companions/toys branches below return before oldRefresh ever
    -- runs, so the base UI:Refresh's own summaryFrame/titleSummaryFrame
    -- :Hide() calls (added for the two Summary tabs) never get a chance
    -- to fire on those two views -- their recent-item icons/mosaics
    -- stayed visible on top of the collection grid. Hidden here
    -- unconditionally instead, before either early return.
    if self.summaryFrame then self.summaryFrame:Hide() end
    if self.titleSummaryFrame then self.titleSummaryFrame:Hide() end

    if self.currentView == "mounts" then
      ABC:BuildCollectionView("mount")
      ABC:UpdateTabVisuals()
      return
    elseif self.currentView == "companions" then
      ABC:BuildCollectionView("companion")
      ABC:UpdateTabVisuals()
      return
    elseif self.currentView == "toys" then
      ABC:BuildCollectionView("toy")
      ABC:UpdateTabVisuals()
      return
    elseif self.currentView == "guildcollection" then
      ABC:BuildGuildCollectionView()
      ABC:UpdateTabVisuals()
      return
    end

    HideFrame(self.abcMountSidebarFrame)
    HideFrame(self.abcCompanionSidebarFrame)
    HideFrame(self.abcToySidebarFrame)
    HideFrame(self.guildCollectionSidebarFrame)
    if self.scrollChild then ClearScrollChild(self) end
    local result = oldRefresh(self)

    -- Defensively enforce the base addon's independent searches as well.
    -- Achievements gets only the achievement search, Titles gets only the
    -- title search, and Admin/other views get neither.
    if self.currentView == "achievements" and self.selectedCategory ~= "Summary" then
      ShowFrame(self.searchLabel); ShowFrame(self.searchBox); ShowFrame(self.clearBtn)
      HideFrame(self.titleSearchLabel); HideFrame(self.titleSearchBox); HideFrame(self.titleClearBtn)
    elseif self.currentView == "titles" and self.titleCategoryFilter ~= "Summary" then
      HideFrame(self.searchLabel); HideFrame(self.searchBox); HideFrame(self.clearBtn)
      ShowFrame(self.titleSearchLabel); ShowFrame(self.titleSearchBox); ShowFrame(self.titleClearBtn)
    else
      HideFrame(self.searchLabel); HideFrame(self.searchBox); HideFrame(self.clearBtn)
      HideFrame(self.titleSearchLabel); HideFrame(self.titleSearchBox); HideFrame(self.titleClearBtn)
    end

    ABC:UpdateTabVisuals()
    return result
  end

  ABC.installedHooks = true
  ABC.pendingInstall = false
  Print("Integrated mount and companion collections loaded.")
end

local function EscapeDumpString(value)
  local s = tostring(value or "")
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, '"', '\\"')
  return s
end

function ABC:BuildModelViewDump(kind, pageOnly)
  EnsureDB()
  local kinds = {}
  if kind == "mount" or kind == "companion" then table.insert(kinds, kind)
  else table.insert(kinds, "mount"); table.insert(kinds, "companion") end

  local lines = {}
  table.insert(lines, "-- LeafVillageAchievements integrated collections v"..tostring(self.version).." view dump")
  table.insert(lines, "ABC_COLLECTION_VIEW_DUMP = {")
  for k = 1, table.getn(kinds) do
    local currentKind = kinds[k]
    local list = FilterCollectionList(BuildSortedList(currentKind), currentKind)
    local firstIndex, lastIndex = 1, table.getn(list)
    if pageOnly then
      local page = tonumber(self.pages[currentKind]) or 1
      local perPage = self.cardsPerPage or 6
      firstIndex = (page - 1) * perPage + 1
      lastIndex = math.min(firstIndex + perPage - 1, table.getn(list))
    end
    table.insert(lines, "  "..((currentKind == "mount") and "mounts" or "companions").." = {")
    for i = firstIndex, lastIndex do
      local data = list[i]
      if data then
        if currentKind == "mount" then
          local def = AshenBannerCollections3D and AshenBannerCollections3D.models and AshenBannerCollections3D.models[data.name]
          if def then
            local p3 = Get3DProofProfile(data, def)
            table.insert(lines, string.format(
              '    ["%s"] = { renderer = "3D", frameX = %.1f, frameY = %.1f, x = %.3f, y = %.3f, z = %.3f, scale = %.4f, rotation = %.3f, camera = %d, path = "%s" },',
              EscapeDumpString(data.name), p3.frameX or 0, p3.frameY or 0, p3.x or 0, p3.y or 0, p3.z or 0,
              p3.scale or 0.08, p3.rotation or 0.82, tonumber(p3.camera) or 1, EscapeDumpString(def.path)))
          else
            local p, family = GetPortraitProfile(data, currentKind)
            local texturePath, isCustom, sourceType = ResolvePortraitTexture(data, currentKind)
            table.insert(lines, string.format(
              '    ["%s"] = { family = "%s", x = %.1f, y = %.1f, scale = %.3f, source = "%s", texture = "%s", custom = %s },',
              EscapeDumpString(data.name), EscapeDumpString(family), p.x or 0, p.y or 0, p.scale or 1,
              EscapeDumpString(sourceType), EscapeDumpString(texturePath), tostring(isCustom and true or false)))
          end
        else
          local p, family = GetModelProfile(data, currentKind)
          table.insert(lines, string.format(
            '    ["%s"] = { family = "%s", x = %.4f, y = %.4f, z = %.4f, scale = %.5f, rotation = %.4f, camera = %d },',
            EscapeDumpString(data.name), EscapeDumpString(family), p.x or 0, p.y or 0, p.z or 0, p.scale or 0.05, p.rotation or 0.61, tonumber(p.camera) or 1))
        end
      end
    end
    table.insert(lines, "  },")
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n")
end

function ABC:ShowModelViewDump(kind, pageOnly)
  local text = self:BuildModelViewDump(kind, pageOnly)
  EnsureDB()
  AshenBannerCollectionsDB.lastModelDump = text
  if not self.modelDumpFrame then
    local f = CreateFrame("Frame", "ABCModelViewDumpFrame", UIParent)
    f:SetWidth(700); f:SetHeight(440)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("TOOLTIP")
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -18)
    title:SetText("Collection Portrait View Dump")
    title:SetTextColor(1.0, 0.82, 0.36)
    local help = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    help:SetText("Ctrl+A, Ctrl+C, then send the complete block back to me.")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    local box = CreateFrame("EditBox", nil, f)
    box:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -68)
    box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -22, 22)
    box:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    box:SetMultiLine(true); box:SetAutoFocus(true); box:SetMaxLetters(200000)
    box:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    box:SetBackdropColor(0.02, 0.02, 0.02, 0.96)
    box:SetScript("OnEscapePressed", function() this:GetParent():Hide() end)
    f.editBox = box
    self.modelDumpFrame = f
  end
  self.modelDumpFrame.editBox:SetText(text)
  self.modelDumpFrame:Show()
  self.modelDumpFrame.editBox:SetFocus()
  if self.modelDumpFrame.editBox.HighlightText then self.modelDumpFrame.editBox:HighlightText() end
end


function ABC:PrintDump()
  if ABC.scanCount == 0 then ABC:ScanSpellbook(false) end
  Print("Spellbook dump: "..tostring(table.getn(ABC.runtime.allSpells)).." entries seen.")
  for i = 1, table.getn(ABC.runtime.allSpells) do
    local s = ABC.runtime.allSpells[i]
    Print(tostring(s.index).." ["..tostring(s.bookType).."] "..tostring(s.tabName or "?").." -> "..tostring(s.name))
  end
end

function ABC:PrintMissingModels()
  EnsureDB()
  local missing = 0
  local mounts = BuildSortedList("mount")
  for i = 1, table.getn(mounts) do
    if not mounts[i].creatureID then
      missing = missing + 1
      Print("Missing mount model: /abcoll model mount "..mounts[i].name.." 12345")
    end
  end
  local companions = BuildSortedList("companion")
  for i = 1, table.getn(companions) do
    if not companions[i].creatureID then
      missing = missing + 1
      Print("Missing companion model: /abcoll model companion "..companions[i].name.." 12345")
    end
  end
  if missing == 0 then Print("No missing models in detected collections.") end
end

function ABC:SetModelFromSlash(msg)
  EnsureDB()
  local _, _, kind, rest = string.find(msg or "", "^model%s+(%S+)%s+(.+)$")
  kind = Lower(kind)
  rest = Trim(rest)
  if not kind or rest == "" then
    Print("Usage: /abcoll model mount Spell Name 12345")
    Print("Usage: /abcoll model companion Spell Name 12345")
    return
  end
  local _, _, spellName, idText = string.find(rest, "^(.-)%s+(%d+)%s*$")
  spellName = Trim(spellName)
  local creatureID = tonumber(idText)
  if spellName == "" or not creatureID then
    Print("Usage: /abcoll model mount Spell Name 12345")
    return
  end

  local key
  if kind == "mount" or kind == "mounts" then key = "mounts"
  elseif kind == "companion" or kind == "companions" or kind == "pet" or kind == "pets" then key = "companions"
  else
    Print("Kind must be mount or companion.")
    return
  end

  AshenBannerCollectionsDB.models[key][spellName] = creatureID

  local collection = (key == "mounts") and LeafVE_AchTest_DB.collections.mounts or LeafVE_AchTest_DB.collections.companions
  if type(collection[spellName]) == "table" then collection[spellName].creatureID = creatureID end

  Print("Saved model for "..spellName.." = creatureID "..tostring(creatureID)..".")
  ABC:ScanSpellbook(false)
  if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then LeafVE_AchTest.UI:Refresh() end
end



-- ---------------------------------------------------------------------------
-- MODEL LAB (temporary diagnostic window)
--
-- This deliberately does not use the collection-card renderer.  It creates
-- independent test cells so Turtle WoW can prove which widget/loader/camera
-- combination actually produces a visible, textured mount.
-- ---------------------------------------------------------------------------

local ABC_MODEL_LAB_MOUNTS = {
  stallion = {
    key = "stallion",
    name = "White Stallion",
    creatureID = 305,
    displayID = 2410,
    path = "Creature\\RidingHorse\\RidingHorse.m2",
    legacyScale = 0.144,
  },
  turtle = {
    key = "turtle",
    name = "Riding Turtle",
    creatureID = 17266,
    displayID = 17158,
    path = "Creature\\RidingTurtle\\RidingTurtle.m2",
    legacyScale = 0.192,
  },
}

local ABC_MODEL_LAB_TESTS = {
  { id="A", label="PlayerModel: Display ID", widget="PlayerModel", loader="display", camera=0, preset="db" },
  { id="B", label="PlayerModel: Display ID", widget="PlayerModel", loader="display", camera=1, preset="db" },
  { id="C", label="PlayerModel: Creature ID", widget="PlayerModel", loader="creature", camera=0, preset="db" },
  { id="D", label="PlayerModel: Creature ID", widget="PlayerModel", loader="creature", camera=1, preset="db" },
  { id="E", label="PlayerModel: Raw path", widget="PlayerModel", loader="path", camera=0, preset="neutral" },
  { id="F", label="PlayerModel: Raw path", widget="PlayerModel", loader="path", camera=1, preset="legacy" },
  { id="G", label="Model: Raw path", widget="Model", loader="path", camera=0, preset="neutral" },
  { id="H", label="Model: Raw path", widget="Model", loader="path", camera=1, preset="legacy" },
}

local function ModelLabMethodExists(obj, method)
  return obj and type(obj[method]) == "function"
end

local function ModelLabBool(v)
  if v then return "YES" end
  return "NO"
end

local function ModelLabCall(obj, method, value)
  if not ModelLabMethodExists(obj, method) then return false, "API missing" end
  local ok, err = pcall(function() obj[method](obj, value) end)
  if ok then return true, "call OK" end
  return false, tostring(err or "call failed")
end

local function ModelLabClear(model)
  if not model then return end
  model:SetScript("OnUpdate", nil)
  if model.ClearModel then
    pcall(function() model:ClearModel() end)
  elseif model.SetModel then
    pcall(function() model:SetModel("") end)
  end
end

local function ModelLabApplyTransforms(model, test, mount, state)
  if not model or not state then return end
  local camera = tonumber(state.camera) or tonumber(test.camera) or 0
  local scale = tonumber(state.scale) or 1
  local x = tonumber(state.x) or 0
  local y = tonumber(state.y) or 0
  local z = tonumber(state.z) or 0
  local rot = tonumber(state.rotation) or 0.70

  if model.SetCamera then pcall(function() model:SetCamera(camera) end) end
  if model.RefreshCamera then pcall(function() model:RefreshCamera() end) end
  if model.SetModelScale then pcall(function() model:SetModelScale(scale) end) end
  if model.SetPosition then pcall(function() model:SetPosition(x, y, z) end) end
  if model.SetRotation then
    pcall(function() model:SetRotation(rot) end)
  elseif model.SetFacing then
    pcall(function() model:SetFacing(rot) end)
  end
  if model.SetSequence then pcall(function() model:SetSequence(0) end) end

  if model._abcLabReadout then
    model._abcLabReadout:SetText(string.format("Cam %d  X %.2f  Y %.2f  Z %.2f\nScale %.3f  Rot %.2f", camera, x, y, z, scale, rot))
  end
end

local function ModelLabDefaultState(test, mount)
  local state = {
    camera = tonumber(test.camera) or 0,
    x = 0,
    y = 0,
    z = 0,
    scale = 1.0,
    rotation = 0.70,
  }

  if test.preset == "neutral" then
    state.scale = 0.050
  elseif test.preset == "legacy" then
    state.scale = tonumber(mount.legacyScale) or 0.150
    state.y = -0.18
    state.z = -0.70
  end
  return state
end

local function ModelLabLoadCell(cell, mount)
  if not cell or not cell.model or not cell.test or not mount then return end
  local model = cell.model
  local test = cell.test
  ModelLabClear(model)
  model:Show()

  cell.mount = mount
  cell.state = ModelLabDefaultState(test, mount)
  model._abcLabState = cell.state
  model._abcLabMount = mount
  model._abcLabTest = test

  local ok, detail
  if test.loader == "display" then
    ok, detail = ModelLabCall(model, "SetDisplayInfo", mount.displayID)
  elseif test.loader == "creature" then
    ok, detail = ModelLabCall(model, "SetCreature", mount.creatureID)
  else
    ok, detail = ModelLabCall(model, "SetModel", mount.path)
  end

  cell.callSucceeded = ok
  if ok then
    cell.status:SetText("|cFF66FF66"..detail.."|r")
    cell:SetBackdropBorderColor(0.25, 0.75, 0.30, 1)
  else
    cell.status:SetText("|cFFFF6666"..detail.."|r")
    cell:SetBackdropBorderColor(0.75, 0.20, 0.20, 1)
  end

  ModelLabApplyTransforms(model, test, mount, cell.state)

  if ok then
    model._abcLabElapsed = 0
    model._abcLabPasses = 0
    model:SetScript("OnUpdate", function()
      this._abcLabElapsed = (this._abcLabElapsed or 0) + (arg1 or 0)
      if this._abcLabElapsed >= 0.20 then
        this._abcLabElapsed = 0
        ModelLabApplyTransforms(this, this._abcLabTest, this._abcLabMount, this._abcLabState)
        this._abcLabPasses = (this._abcLabPasses or 0) + 1
        if this._abcLabPasses >= 5 then this:SetScript("OnUpdate", nil) end
      end
    end)
  end
end

local function ModelLabCreateCell(parent, index, test)
  local cols = 4
  local cellW = 214
  local cellH = 224
  local gapX = 8
  local gapY = 10
  local col = math.mod(index - 1, cols)
  local row = math.floor((index - 1) / cols)

  local cell = CreateFrame("Frame", nil, parent)
  cell:SetWidth(cellW)
  cell:SetHeight(cellH)
  cell:SetPoint("TOPLEFT", parent, "TOPLEFT", col * (cellW + gapX), -row * (cellH + gapY))
  cell:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = {left=3, right=3, top=3, bottom=3}
  })
  cell:SetBackdropColor(0.025, 0.025, 0.025, 0.97)
  cell:SetBackdropBorderColor(0.38, 0.30, 0.20, 1)
  cell.test = test

  local title = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  title:SetPoint("TOPLEFT", cell, "TOPLEFT", 8, -7)
  title:SetWidth(cellW - 16)
  title:SetJustifyH("LEFT")
  title:SetText("|cFFFFD36A"..test.id.."|r  "..test.label)

  local sub = cell:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  sub:SetWidth(cellW - 16)
  sub:SetJustifyH("LEFT")
  sub:SetText("Camera "..tostring(test.camera).."  /  "..tostring(test.preset))

  local modelBg = CreateFrame("Frame", nil, cell)
  modelBg:SetPoint("TOPLEFT", cell, "TOPLEFT", 7, -42)
  modelBg:SetWidth(cellW - 14)
  modelBg:SetHeight(139)
  modelBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=2, right=2, top=2, bottom=2}
  })
  modelBg:SetBackdropColor(0, 0, 0, 1)
  modelBg:SetBackdropBorderColor(0.20, 0.20, 0.20, 1)

  local model = CreateFrame(test.widget, nil, modelBg)
  model:SetPoint("TOPLEFT", modelBg, "TOPLEFT", 3, -3)
  model:SetPoint("BOTTOMRIGHT", modelBg, "BOTTOMRIGHT", -3, 3)
  if model.SetFrameLevel then model:SetFrameLevel(modelBg:GetFrameLevel() + 2) end
  cell.model = model

  local readout = modelBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  readout:SetPoint("BOTTOM", modelBg, "BOTTOM", 0, 3)
  readout:SetWidth(cellW - 20)
  readout:SetJustifyH("CENTER")
  readout:SetTextColor(1.0, 0.72, 0.20)
  model._abcLabReadout = readout

  local overlay = CreateFrame("Button", nil, modelBg)
  overlay:SetAllPoints(modelBg)
  overlay:EnableMouse(true)
  if overlay.EnableMouseWheel then overlay:EnableMouseWheel(true) end
  if overlay.RegisterForClicks then overlay:RegisterForClicks("RightButtonUp") end
  overlay.cell = cell

  overlay:SetScript("OnMouseWheel", function()
    local c = this.cell
    if not c or not c.state or not c.model then return end
    local delta = tonumber(arg1) or 0
    if IsShiftKeyDown and IsShiftKeyDown() then
      c.state.z = (c.state.z or 0) + delta * 0.05
    elseif IsAltKeyDown and IsAltKeyDown() then
      c.state.y = (c.state.y or 0) + delta * 0.05
    elseif IsControlKeyDown and IsControlKeyDown() then
      c.state.rotation = (c.state.rotation or 0.70) + delta * 0.12
    else
      if delta > 0 then c.state.scale = (c.state.scale or 1) * 1.15 else c.state.scale = (c.state.scale or 1) / 1.15 end
    end
    ModelLabApplyTransforms(c.model, c.test, c.mount, c.state)
  end)

  overlay:SetScript("OnClick", function()
    if arg1 == "RightButton" and this.cell and this.cell.mount then
      ModelLabLoadCell(this.cell, this.cell.mount)
    end
  end)

  overlay:SetScript("OnEnter", function()
    local c = this.cell
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(c and c.test and c.test.label or "Model Lab", 1, 0.82, 0.36)
    GameTooltip:AddLine("Wheel: scale", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Shift + wheel: vertical Z", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Alt + wheel: depth Y", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Ctrl + wheel: rotate", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("Right-click: reset this test", 0.85, 0.85, 0.85)
    GameTooltip:Show()
  end)
  overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local status = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", modelBg, "BOTTOMLEFT", 2, -5)
  status:SetWidth(cellW - 18)
  status:SetJustifyH("LEFT")
  status:SetText("Not run")
  cell.status = status

  return cell
end

local function ModelLabAPISummary()
  local pm = CreateFrame("PlayerModel", nil, UIParent)
  local bm = CreateFrame("Model", nil, UIParent)
  pm:SetWidth(1); pm:SetHeight(1); pm:Hide()
  bm:SetWidth(1); bm:SetHeight(1); bm:Hide()

  local line1 = "PlayerModel: Display="..ModelLabBool(ModelLabMethodExists(pm, "SetDisplayInfo"))
    .." Creature="..ModelLabBool(ModelLabMethodExists(pm, "SetCreature"))
    .." Model="..ModelLabBool(ModelLabMethodExists(pm, "SetModel"))
    .." Camera="..ModelLabBool(ModelLabMethodExists(pm, "SetCamera"))
    .." Refresh="..ModelLabBool(ModelLabMethodExists(pm, "RefreshCamera"))
  local line2 = "PlayerModel transforms: Scale="..ModelLabBool(ModelLabMethodExists(pm, "SetModelScale"))
    .." Position="..ModelLabBool(ModelLabMethodExists(pm, "SetPosition"))
    .." Rotation="..ModelLabBool(ModelLabMethodExists(pm, "SetRotation"))
    .." Facing="..ModelLabBool(ModelLabMethodExists(pm, "SetFacing"))
  local line3 = "Model: Model="..ModelLabBool(ModelLabMethodExists(bm, "SetModel"))
    .." Camera="..ModelLabBool(ModelLabMethodExists(bm, "SetCamera"))
    .." Scale="..ModelLabBool(ModelLabMethodExists(bm, "SetModelScale"))
    .." Position="..ModelLabBool(ModelLabMethodExists(bm, "SetPosition"))
    .." Rotation="..ModelLabBool(ModelLabMethodExists(bm, "SetRotation"))
    .." Facing="..ModelLabBool(ModelLabMethodExists(bm, "SetFacing"))
  return line1, line2, line3
end

function ABC:RefreshModelLab(mountKey)
  local f = self.modelLabFrame
  if not f then return end
  mountKey = mountKey or f.mountKey or "stallion"
  local mount = ABC_MODEL_LAB_MOUNTS[mountKey] or ABC_MODEL_LAB_MOUNTS.stallion
  f.mountKey = mount.key
  f.mountTitle:SetText("Testing: |cFFFFD36A"..mount.name.."|r  Creature "..tostring(mount.creatureID).."  Display "..tostring(mount.displayID))

  for i = 1, table.getn(f.cells or {}) do
    ModelLabLoadCell(f.cells[i], mount)
  end
end

function ABC:ShowModelLab(mountKey)
  if not self.modelLabFrame then
    local f = CreateFrame("Frame", "ABCModelLabFrame", UIParent)
    f:SetWidth(914)
    f:SetHeight(615)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = {left=11, right=12, top=12, bottom=11}
    })
    f:SetBackdropColor(0.02, 0.02, 0.02, 0.99)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -16)
    title:SetText("Ashen Collections Model Lab")
    title:SetTextColor(1.0, 0.82, 0.36)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

    local stallionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    stallionBtn:SetWidth(112); stallionBtn:SetHeight(22)
    stallionBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    stallionBtn:SetText("White Stallion")
    stallionBtn:SetScript("OnClick", function() ABC:RefreshModelLab("stallion") end)

    local turtleBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    turtleBtn:SetWidth(112); turtleBtn:SetHeight(22)
    turtleBtn:SetPoint("LEFT", stallionBtn, "RIGHT", 5, 0)
    turtleBtn:SetText("Riding Turtle")
    turtleBtn:SetScript("OnClick", function() ABC:RefreshModelLab("turtle") end)

    local rerunBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    rerunBtn:SetWidth(74); rerunBtn:SetHeight(22)
    rerunBtn:SetPoint("LEFT", turtleBtn, "RIGHT", 5, 0)
    rerunBtn:SetText("Re-run")
    rerunBtn:SetScript("OnClick", function() ABC:RefreshModelLab(ABC.modelLabFrame.mountKey) end)

    local mountTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mountTitle:SetPoint("LEFT", rerunBtn, "RIGHT", 12, 0)
    mountTitle:SetWidth(490)
    mountTitle:SetJustifyH("LEFT")
    f.mountTitle = mountTitle

    local api1, api2, api3 = ModelLabAPISummary()
    local api = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    api:SetPoint("TOPLEFT", stallionBtn, "BOTTOMLEFT", 0, -7)
    api:SetWidth(870)
    api:SetJustifyH("LEFT")
    api:SetText(api1.."\n"..api2.."\n"..api3)
    api:SetTextColor(0.72, 0.78, 0.86)

    local instructions = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", api, "BOTTOMLEFT", 0, -5)
    instructions:SetWidth(870)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Green means the Lua call succeeded, not that the model is visible. Compare the eight boxes. Wheel scales; Shift/Alt/Ctrl + wheel adjust Z/Y/rotation.")
    instructions:SetTextColor(0.93, 0.77, 0.52)

    local grid = CreateFrame("Frame", nil, f)
    grid:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -8)
    grid:SetWidth(880)
    grid:SetHeight(460)
    f.grid = grid
    f.cells = {}
    for i = 1, table.getn(ABC_MODEL_LAB_TESTS) do
      f.cells[i] = ModelLabCreateCell(grid, i, ABC_MODEL_LAB_TESTS[i])
    end

    f:SetScript("OnHide", function()
      for i = 1, table.getn(this.cells or {}) do
        if this.cells[i] and this.cells[i].model then ModelLabClear(this.cells[i].model) end
      end
    end)

    self.modelLabFrame = f
  end

  self.modelLabFrame:Show()
  self:RefreshModelLab(mountKey or self.modelLabFrame.mountKey or "stallion")
  Print("Model Lab opened. Start with White Stallion, then click Riding Turtle and take a second screenshot.")
end

function ABC:Help()
  Print("Commands:")
  Print("/abcoll scan - rescan Turtle spellbook collection tabs")
  Print("/abcoll config - toggle native 1.12 model calibration")
  Print("/abcoll dumpviewspage - copy exact X/Y/Z/scale/rotation for the page")
  Print("Card errors are isolated and printed without stopping the remaining grid.")
  Print("/abcoll dumpviews - dump the current collection")
  Print("/abcoll savefamilies - use visible portrait placement as family defaults")
  Print("/abcoll resetviews - reset all model calibration")
  Print("/abcoll modelapi - report the model APIs exposed by this client")
  Print("/abcoll modellab - open the White Stallion / Riding Turtle diagnostic lab")
  Print("/abcoll 3d on|off - enable the optional Black Stallion / Riding Turtle textured proof")
  Print("/abcoll 3d status - show expected custom MPQ model paths")
  Print("/abcoll model mount Spell Name 12345 - map a creature ID")
end

SLASH_ASHENBANNERCOLLECTIONS1 = "/abcoll"
SLASH_ASHENBANNERCOLLECTIONS2 = "/ashencoll"
SlashCmdList["ASHENBANNERCOLLECTIONS"] = function(msg)
  msg = Trim(msg or "")
  local lmsg = Lower(msg)
  local currentKind = "mount"
  if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView == "companions" then currentKind = "companion" end
  if msg == "" or lmsg == "help" then ABC:Help()
  elseif lmsg == "scan" then ABC:ScanSpellbook(true)
  elseif lmsg == "dump" then ABC:ScanSpellbook(false); ABC:PrintDump()
  elseif lmsg == "dumpviewspage" then ABC:ShowModelViewDump(currentKind, true)
  elseif lmsg == "dumpviews" then ABC:ShowModelViewDump(currentKind, false)
  elseif lmsg == "dumpviews all" then ABC:ShowModelViewDump(nil, false)
  elseif lmsg == "savefamilies" then ABC:ApplyCurrentPageToFamilies(currentKind); ABC:BuildCollectionView(currentKind)
  elseif lmsg == "config" or lmsg == "config on" or lmsg == "config off" then
    local enabled = not ABC.configMode
    if lmsg == "config on" then enabled = true elseif lmsg == "config off" then enabled = false end
    ABC:SetConfigMode(enabled, currentKind)
  elseif lmsg == "resetviews" then
    EnsureDB()
    AshenBannerCollectionsDB.modelView = { mounts = {}, companions = {} }
    AshenBannerCollectionsDB.familyView = { mounts = {}, companions = {} }
    Print("Reset all model calibration.")
    ABC:BuildCollectionView(currentKind)
  elseif lmsg == "modellab" or lmsg == "lab" then ABC:ShowModelLab("stallion")
  elseif lmsg == "modellab turtle" or lmsg == "lab turtle" then ABC:ShowModelLab("turtle")
  elseif lmsg == "modellab stallion" or lmsg == "lab stallion" then ABC:ShowModelLab("stallion")
  elseif lmsg == "modelapi" then
    local probe = CreateFrame("PlayerModel", nil, UIParent)
    probe:SetWidth(1); probe:SetHeight(1)
    Print("PlayerModel APIs: SetDisplayInfo="..tostring(type(probe.SetDisplayInfo)=="function")
      ..", SetCreature="..tostring(type(probe.SetCreature)=="function")
      ..", SetModel="..tostring(type(probe.SetModel)=="function")
      ..", SetPosition="..tostring(type(probe.SetPosition)=="function")
      ..", SetModelScale="..tostring(type(probe.SetModelScale)=="function")
      ..", SetRotation="..tostring(type(probe.SetRotation)=="function")
      ..", SetFacing="..tostring(type(probe.SetFacing)=="function")
      ..", SetCamera="..tostring(type(probe.SetCamera)=="function"))
    probe:Hide()
  elseif lmsg == "3d" or lmsg == "3d on" or lmsg == "3d off" then
    EnsureDB()
    local enabled = not AshenBannerCollectionsDB.use3DProof
    if lmsg == "3d on" then enabled = true elseif lmsg == "3d off" then enabled = false end
    AshenBannerCollectionsDB.use3DProof = enabled
    Print("Optional 3D proof "..(enabled and "enabled" or "disabled")..". Only Black Stallion and Riding Turtle are affected.")
    ABC:BuildCollectionView("mount")
  elseif lmsg == "3d status" then
    EnsureDB()
    Print("3D proof enabled: "..tostring(AshenBannerCollectionsDB.use3DProof == true))
    local defs = AshenBannerCollections3D and AshenBannerCollections3D.models or {}
    for name, def in pairs(defs) do Print(tostring(name).." -> "..tostring(def.path or "missing path")) end
  elseif lmsg == "missing" or lmsg == "models" then ABC:ScanSpellbook(false); ABC:PrintMissingModels()
  elseif string.find(lmsg, "^model%s+") then ABC:SetModelFromSlash(msg)
  elseif lmsg == "open" then if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.Build then LeafVE_AchTest.UI:Build() end
  else ABC:Help() end
end

local evt = CreateFrame("Frame")
evt:RegisterEvent("PLAYER_LOGIN")
evt:RegisterEvent("PLAYER_ENTERING_WORLD")
evt:RegisterEvent("SPELLS_CHANGED")
evt:RegisterEvent("LEARNED_SPELL_IN_TAB")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "ADDON_LOADED" then
    ABC:InstallHooks()
    ABC:ScanSpellbook(false)
  elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
    ABC:ScanSpellbook(false)
  end
end)

-- Retry hook install briefly in case the base addon initializes its UI table late.
local retry = CreateFrame("Frame")
retry.elapsed = 0
retry:SetScript("OnUpdate", function()
  if ABC.installedHooks then this:Hide() return end
  this.elapsed = (this.elapsed or 0) + (arg1 or 0)
  if this.elapsed > 1.0 then
    this.elapsed = 0
    ABC:InstallHooks()
  end
end)


-- v3.6.0 OctoWoW source-of-truth mount catalog generated from OctoWoW_mounts_15_4_COUNT_236.csv
-- IMPORTANT: This roster uses the uploaded OctoWoW list (225 valid mounts after removing 11 confirmed equipment anomalies) as the authoritative source for the journal.
local ABC_OCTOWOW_MOUNTS = {
  ["Admiral Grumbleshell"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30040, itemLevel = 60, requiredLevel = 60, description = "Retired from piracy. Still refuses to follow orders, but he'll take you places." },
  ["Ancient Arctic Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 12351, itemLevel = 40, requiredLevel = 1, description = "Ancient furbolg legends claim that wolves born with a white coat are blessed by Azeroth's two moons." },
  ["Ancient Black Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 13328, itemLevel = 60, requiredLevel = nil, description = "I've not seen this breed in ages, but when they're ram tough they stick around. - Veron Amberstill." },
  ["Ancient Black Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 1041, itemLevel = 40, requiredLevel = nil, description = "Once thought to be nearly extinct, this wolf can still occasionally be seen in the company of a few Horde veterans." },
  ["Ancient Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 12302, itemLevel = 60, requiredLevel = nil, description = "The lack of spots or stripes marks this beast as a descendant of the most ancient frostsaber line." },
  ["Ancient Green Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 15292, itemLevel = 60, requiredLevel = nil, description = "An alpha member of the herd, this kodo is a prime example of the mighty creatures which thunder through Desolace." },
  ["Ancient Nightsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 8635, itemLevel = 60, requiredLevel = nil, description = "The lack of spots or stripes marks this beast as a descendant of the most ancient frostsaber line." },
  ["Ancient Red Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 5663, itemLevel = 40, requiredLevel = nil, description = "Almost none remain in the whole of Azeroth; only the most experienced will have seen one." },
  ["Ancient Teal Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 15293, itemLevel = 60, requiredLevel = nil, description = "The kodo is the backbone of our people. Wherever the Horde goes - in trade, settlement, or war - there you will find the mighty kodo." },
  ["Armored Black Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81154, itemLevel = 20, requiredLevel = nil, description = "This ursine mount's swiftness is enhanced by its heavy armor." },
  ["Armored Black Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 80449, itemLevel = 20, requiredLevel = nil, description = "Armored to withstand collisions in battle." },
  ["Armored Blue Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 18788, itemLevel = 60, requiredLevel = 60, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Brewfest Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 80443, itemLevel = 20, requiredLevel = nil, description = "Dwarves attribute this breed's even temperament to rigorous training, but other races argue that a daily diet of strong ale has something to do with it." },
  ["Armored Brown Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81226, itemLevel = 60, requiredLevel = 60, description = "The Amani trolls decorate these ferocious mounts in magic amulets and ceremonial masks as a way to venerate the bear god Nalorakk." },
  ["Armored Brown Boar"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 69172, itemLevel = 20, requiredLevel = nil, description = "Only the mightiest boars earn the honor of being adorned with armor." },
  ["Armored Brown Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 18794, itemLevel = 60, requiredLevel = 60, description = "An alpha member of the herd, this kodo is a prime example of the mighty creatures which thunder through the Northern Barrens." },
  ["Armored Brown Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 18786, itemLevel = 60, requiredLevel = 60, description = "The Barak Tor'ol ram's thick bony skull and massive horns make it the ideal mount for charging through groups of armored enemies." },
  ["Armored Brown Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 18777, itemLevel = 60, requiredLevel = 60, description = "A veteran of some of the toughest battles fought by the Argent Crusade." },
  ["Armored Brown Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 18796, itemLevel = 60, requiredLevel = 60, description = "The wolves of the Horde are befriended, not domesticated." },
  ["Armored Crimson Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 81245, itemLevel = 60, requiredLevel = 60, description = "Some horses merely adopt the dark. This horse was born in it." },
  ["Armored Darkspear Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 81182, itemLevel = 60, requiredLevel = 60, description = "Speed, cunning, and ferocity are the things trolls and raptors admire about each other." },
  ["Armored Dawnsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "cat", itemID = 18768, itemLevel = 60, requiredLevel = nil, description = "Night elves once believed that seeing this light colored saber breed in the wild was an ill omen." },
  ["Armored Ebon Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 81244, itemLevel = 60, requiredLevel = 60, description = "Some horses merely adopt the dark. This horse was born in it." },
  ["Armored Emerald Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 81246, itemLevel = 60, requiredLevel = 60, description = "Some horses merely adopt the dark. This horse was born in it." },
  ["Armored Frostmane Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81158, itemLevel = 20, requiredLevel = nil, description = "This ursine mount's swiftness is enhanced by its heavy armor." },
  ["Armored Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 18766, itemLevel = 60, requiredLevel = 60, description = "Night elves raise frostsaber cubs from infancy, forging lifelong bonds of trust between rider and beast." },
  ["Armored Gray Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 18795, itemLevel = 60, requiredLevel = 60, description = "An alpha member of the herd, this kodo is a prime example of the mighty creatures which thunder through the Northern Barrens." },
  ["Armored Gray Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 18787, itemLevel = 60, requiredLevel = 60, description = "The Barak Tor'ol ram's thick bony skull and massive horns make it the ideal mount for charging through groups of armored enemies." },
  ["Armored Gray Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 18798, itemLevel = 60, requiredLevel = 60, description = "The wolves of the Horde are befriended, not domesticated." },
  ["Armored Green Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 13334, itemLevel = 60, requiredLevel = 60, description = "When fallen heroes are raised into undeath, so too are their horses." },
  ["Armored Green Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 18772, itemLevel = 60, requiredLevel = 60, description = "We have made a lot of improvements, but they are still based on the Mekkatorque designs." },
  ["Armored Grey Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 81236, itemLevel = 40, requiredLevel = nil, description = "A veteran of some of the toughest battles fought by the Alliance." },
  ["Armored Ice Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 83154, itemLevel = 20, requiredLevel = nil, description = "It is a fearsome sight, covered in thick plates of icy armor. Those who ride it are said to be as tough as the raptor itself." },
  ["Armored Ironforge Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "ram", itemID = 81233, itemLevel = 60, requiredLevel = 60, description = "Wildhammer Fact Checker claims that this specific breed was the first type of ram domesticated by the dwarves when they settled in Dun Morogh." },
  ["Armored Ivory Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 81247, itemLevel = 60, requiredLevel = 60, description = "Some horses merely adopt the dark. This horse was born in it." },
  ["Armored Ivory Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 50401, itemLevel = 60, requiredLevel = nil, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Mistsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 18767, itemLevel = 60, requiredLevel = 60, description = "Some historians claim that this breed's misty grey coat is the result of ancient Highborne experiments conducted on nightsabers." },
  ["Armored Nightsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 80446, itemLevel = 60, requiredLevel = 60, description = "When a night elf's mount perishes, it is custom for the rider to keep one of the saber's great fangs as a token of remembrance." },
  ["Armored Obsidian Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 50404, itemLevel = 60, requiredLevel = nil, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Olive Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 18789, itemLevel = 60, requiredLevel = 60, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Orange Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 18790, itemLevel = 60, requiredLevel = 60, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Orgrimmar Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 81241, itemLevel = 60, requiredLevel = 60, description = "The wolves of the Horde are befriended, not domesticated." },
  ["Armored Purple Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81153, itemLevel = 20, requiredLevel = nil, description = "This ursine mount's swiftness is enhanced by its heavy armor." },
  ["Armored Purple Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 18791, itemLevel = 60, requiredLevel = 60, description = "When fallen heroes are raised into undeath, so too are their horses." },
  ["Armored Razzashi Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 19872, itemLevel = 60, requiredLevel = 60, description = "The only known Razzashi Raptors were said to have been in the custody of Bloodlord Mandokir in Zul'Gurub. This species of raptor has not been seen in many years." },
  ["Armored Red Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81155, itemLevel = 20, requiredLevel = nil, description = "This ursine mount's swiftness is enhanced by its heavy armor." },
  ["Armored Red Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 18248, itemLevel = 40, requiredLevel = 40, description = "When fallen heroes are raised into undeath, so too are their horses." },
  ["Armored Red Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 50403, itemLevel = 60, requiredLevel = nil, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored Stormsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "cat", itemID = 18902, itemLevel = 60, requiredLevel = 60, description = "Rumor has it that this breed was named after the renowned archdruid Malfurion Stormrage." },
  ["Armored Stormwind Warhorse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "horse", itemID = 81225, itemLevel = 60, requiredLevel = 60, description = "Trained to withstand brutal hand-to-hand combat in the fiercest battlefields." },
  ["Armored Swift Palomino"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 18776, itemLevel = 60, requiredLevel = 60, description = "Prized by horse breeders for their discipline and steadfastness." },
  ["Armored Thalassian Unicorn"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "horse", itemID = 80457, itemLevel = 60, requiredLevel = 60, description = "A mythical creature, protected by enchanted armor, embodying grace and power." },
  ["Armored Thunder Bluff Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 81198, itemLevel = 40, requiredLevel = 60, description = "An alpha member of the herd, this kodo is a prime example of the mighty creatures which thunder through Mulgore." },
  ["Armored Timber Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 18797, itemLevel = 60, requiredLevel = 60, description = "The wolves of the Horde are befriended, not domesticated." },
  ["Armored Violet Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 50402, itemLevel = 60, requiredLevel = nil, description = "Longtime allies of the trolls, these jungle hunters form a special bond with their masters. They become steed, guardian, and friend." },
  ["Armored White Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 18793, itemLevel = 60, requiredLevel = 60, description = "An alpha member of the herd, this kodo is a prime example of the mighty creatures which thunder through the Northern Barrens." },
  ["Armored White Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 18773, itemLevel = 60, requiredLevel = 60, description = "We have made a lot of improvements, but they are still based on the Mekkatorque designs." },
  ["Armored White Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 18785, itemLevel = 60, requiredLevel = 60, description = "The Barak Tor'ol ram's thick bony skull and massive horns make it the ideal mount for charging through groups of armored enemies." },
  ["Armored White Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 18778, itemLevel = 60, requiredLevel = 60, description = "A veteran of some of the toughest battles fought by the Argent Crusade." },
  ["Armored Wildhammer Gryphon"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "default", itemID = 81186, itemLevel = 60, requiredLevel = 60, description = "This noble gryphon is as staunch a battle companion as any a member of the Alliance could ask for." },
  ["Armored Yellow Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 18774, itemLevel = 60, requiredLevel = 60, description = "We have made a lot of improvements, but they are still based on the Mekkatorque designs." },
  ["Azure Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 81232, itemLevel = 40, requiredLevel = nil, description = "The lack of spots or stripes marks this beast as a descendant of the most ancient frostsaber line." },
  ["Azure Spectral Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 80430, itemLevel = 20, requiredLevel = nil, description = "Historians claim that these incorporeal beasts were created when Draenor exploded, unleashing energies that warped the world's flora and fauna." },
  ["Azure Thunder Lizard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30013, itemLevel = 60, requiredLevel = nil, description = "Lightning doesn't strike twice, but he does." },
  ["Beige Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30019, itemLevel = 60, requiredLevel = 60, description = "Desert-approved and sand-colored." },
  ["Big Blizzard Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81091, itemLevel = 20, requiredLevel = nil, description = "Just remember to have your special little passenger straped in tightly before running off at top speed on an adventure." },
  ["Big Turtle WoW Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingTurtle\\RidingTurtle.m2", modelScale = 0.083, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "turtle", itemID = 83150, itemLevel = 20, requiredLevel = nil, description = "The Murloc rider on its back is a skilled warrior! He is a proud member of the Turtle WoW community, and he is always ready to defend his server against any threat." },
  ["Black Battlestrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "mech", itemID = 18243, itemLevel = 40, requiredLevel = 40, description = "A formidable mount, instilling fear in the hearts of enemies." },
  ["Black Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80433, itemLevel = 60, requiredLevel = 60, description = "He's big, he's ready for battle, and he's a bear. What more could you want in a mount?" },
  ["Black Boar"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 69173, itemLevel = 20, requiredLevel = nil, description = "Summon the Black Boar, a fierce companion with a taste for adventure!" },
  ["Black Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 23193, itemLevel = 60, requiredLevel = nil, description = "When fallen heroes are raised into undeath, so too are their horses." },
  ["Black Qiraji Resonating Crystal"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingSilithid\\RidingSilithid.m2", modelScale = 0.2, x = 0, y = -0.18, z = -0.7, category = "Qiraji", family = "qiraji", itemID = 21176, itemLevel = 60, requiredLevel = 60, description = "Although many varieties of Qiraji Battle Tank can still be found in the ruins of Ahn'Qiraj today, the darkest of the species were only seen on the day the Scarab gong was rung." },
  ["Black Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30020, itemLevel = 60, requiredLevel = nil, description = "Dark and mysterious." },
  ["Black Scrapforged Mechaspider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "mech", itemID = 81192, itemLevel = 60, requiredLevel = 60, description = "Smoky, sparky, and loud." },
  ["Black Spectral Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 83151, itemLevel = 20, requiredLevel = nil, description = "This fierce tiger is shrouded in dark energy, making it a fearsome sight on the battlefield. Those who ride it are said to embody the power of the shadows." },
  ["Black Stallion"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 2411, itemLevel = 40, requiredLevel = 40, description = "Rumored to be favored by SI:7 for night missions due to its dark coat." },
  ["Black Thunder Lizard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30012, itemLevel = 60, requiredLevel = nil, description = "Lightning doesn't strike twice, but he does." },
  ["Black Tournament Charger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 30000, itemLevel = 60, requiredLevel = 60, description = "Champion of the Northwind Joust." },
  ["Black War Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "kodo", itemID = 18247, itemLevel = 40, requiredLevel = 40, description = "Bred for their aggressive, unpredictable demeanor by the Kor'kron stablemasters, the Black War Kodos' trumpeting call signifies that blood will soon be shed." },
  ["Black War Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "ram", itemID = 18244, itemLevel = 40, requiredLevel = 40, description = "A sturdy and resilient mount, bred for battle in the mountains." },
  ["Black War Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "raptor", itemID = 18246, itemLevel = 40, requiredLevel = 40, description = "Bred from the same vicious line of raptors which sired Ohgan and brought victory to the Gurubashi Empire." },
  ["Black War Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "horse", itemID = 18241, itemLevel = 40, requiredLevel = 40, description = "Trained to withstand brutal hand-to-hand combat in the fiercest battlefields." },
  ["Black War Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "cat", itemID = 18242, itemLevel = 40, requiredLevel = 40, description = "" },
  ["Black War Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "wolf", itemID = 18245, itemLevel = 40, requiredLevel = 40, description = "Prized by Orgrimmar guards for their keen sense of smell." },
  ["Black Zulian Panther"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 12303, itemLevel = 60, requiredLevel = nil, description = "The jungle trolls have long coveted panther fangs, using them for rituals or as ingredients in mojos." },
  ["Blackstone Dragon Guard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81156, itemLevel = 20, requiredLevel = nil, description = "Dragonhawks are among the deadliest known predators. They are able to spot prey from great distances, rush in, and rend with both talon and beak." },
  ["Blue Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 8595, itemLevel = 40, requiredLevel = 40, description = "The terradynamic exo-plotters are conjoined by hydraulic imaging to the equilibrium enhancers..." },
  ["Blue Qiraji Resonating Crystal"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingSilithid\\RidingSilithid.m2", modelScale = 0.2, x = 0, y = -0.18, z = -0.7, category = "Qiraji", family = "qiraji", itemID = 21218, itemLevel = 60, requiredLevel = 60, description = "" },
  ["Blue Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30021, itemLevel = 60, requiredLevel = 60, description = "A scorpid with a bright blue carapace, swift across open terrain." },
  ["Blue Rocket Car"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80462, itemLevel = 40, requiredLevel = 40, description = "Airbags not included." },
  ["Blue Scrapforged Mechaspider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "mech", itemID = 81193, itemLevel = 60, requiredLevel = 60, description = "The check engine light is always on, it's when it goes off that you should be worried." },
  ["Blue Skeletal Horse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "skeletal", itemID = 13332, itemLevel = 40, requiredLevel = 40, description = "The Forsaken believe that without a purpose, even beasts of burden suffer in undeath." },
  ["Brewfest Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 80455, itemLevel = 20, requiredLevel = nil, description = "Afestive mount, celebrating the joyous spirit of Brewfest." },
  ["Brewfest Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 81234, itemLevel = 40, requiredLevel = 1, description = "Brewers retired this mount from active advertising service after complaints that the beasts were \"too temperamental\" to control in major cities." },
  ["Bronze Drake"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 51252, itemLevel = 60, requiredLevel = 60, description = "Lost time is never found again." },
  ["Brown Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80438, itemLevel = 60, requiredLevel = 60, description = "He's big, he's ready for battle, and he's a bear. What more could you want in a mount?" },
  ["Brown Horse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 5656, itemLevel = 40, requiredLevel = 40, description = "A favorite among Stormwind's guards thanks to its patience and stamina." },
  ["Brown Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 15290, itemLevel = 40, requiredLevel = 40, description = "The kodo is the backbone of our people. Wherever the Horde goes - in trade, settlement, or war - there you will find the mighty kodo." },
  ["Brown Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 5872, itemLevel = 40, requiredLevel = 40, description = "Male rams will often smash their thick skulls against each other for hours to impress a female. In that way, they're very similar to dwarves." },
  ["Brown Skeletal Horse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "skeletal", itemID = 13333, itemLevel = 40, requiredLevel = 40, description = "The Forsaken believe that without a purpose, even beasts of burden suffer in undeath." },
  ["Brown Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50072, itemLevel = nil, requiredLevel = nil, description = "" },
  ["Brown Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 5668, itemLevel = 40, requiredLevel = 40, description = "Can howl loudly enough to be heard for miles." },
  ["Brown Zhevra"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 83158, itemLevel = 20, requiredLevel = nil, description = "The Brown Zhevra is a swift and sure-footed mount, able to navigate even the roughest terrain with ease. Its striped coat and graceful movements make it a popular choice among adventurers." },
  ["Celestial Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 92050, itemLevel = 20, requiredLevel = nil, description = "Saddle up the stars on this supernatural flying mount." },
  ["Cenarion Hippogryph"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81121, itemLevel = 20, requiredLevel = nil, description = "Members of the Cenarion Circle have shared a long and prosperous partnership with their hippogryph allies. When conflict is unavoidable, the Cenarion War Hippogryph is called into service." },
  ["Chestnut Mare"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 5655, itemLevel = 40, requiredLevel = 40, description = "Sturdy and steady." },
  ["Chieftain's Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 81237, itemLevel = 40, requiredLevel = 60, description = "This Kodo with a Ceremonial Attire is usually reserved for Clan Chieftains, but after the Tauren joined the Horde, they have been made available to Champions of Thunderbluff." },
  ["Cloudwing Hippogryph"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81242, itemLevel = 40, requiredLevel = nil, description = "Ancient mounts of the Highborne, now left to run wild, they can rarely be found due to their latent magical powers." },
  ["Commander's Steed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 16339, itemLevel = 60, requiredLevel = 60, description = "" },
  ["Crimson Spectral Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 92052, itemLevel = 20, requiredLevel = nil, description = "Historians claim that these incorporeal beasts were created when Draenor exploded, unleashing energies that warped the world's flora and fauna." },
  ["Dalaran Rain Cloud"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81240, itemLevel = 40, requiredLevel = 1, description = "Now the sun is in the sky, and for no reason why, the sad cloud is crying itself away." },
  ["Dalaran Warhorse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "horse", itemID = 81224, itemLevel = 60, requiredLevel = 60, description = "The powerful and unyielding white stallion." },
  ["Dark Iron Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30022, itemLevel = 60, requiredLevel = 60, description = "Forged in fire and definitely not for cuddling." },
  ["Dark Riding Crab"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30008, itemLevel = 60, requiredLevel = 60, description = "Carries emotional baggage and you." },
  ["Dark Riding Talbuk"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 92018, itemLevel = 40, requiredLevel = nil, description = "" },
  ["Darkmoon Dancing Bear"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81102, itemLevel = 20, requiredLevel = nil, description = "These fearsome mounts have a habit of suddenly breaking out into dance amid battle, much to the annoyance of their riders." },
  ["Desert Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30026, itemLevel = 60, requiredLevel = 60, description = "A scorpid adapted to harsh desert environments." },
  ["Diamond Crustacean"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30011, itemLevel = 60, requiredLevel = 60, description = "May or may not be sentient. Won't stop judging you." },
  ["Dire Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 5665, itemLevel = 40, requiredLevel = 40, description = "Can howl loudly enough to be heard for miles." },
  ["Emerald Drake"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30018, itemLevel = 60, requiredLevel = 60, description = "Dreamy, green, and very-very sleepy." },
  ["Emerald Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 8588, itemLevel = 40, requiredLevel = 40, description = "Bred from the fiercest stock anywhere and guaranteed not to bite (much)." },
  ["Fluorescent Green Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13325, itemLevel = 40, requiredLevel = nil, description = "The trusted mechanical steed of Engineer Figgles, made by accident trying to make improved models of his mechanical whelps." },
  ["Frost Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 13329, itemLevel = 40, requiredLevel = 40, description = "Male rams will often smash their thick skulls against each other for hours to impress a female. In that way, they're very similar to dwarves." },
  ["Frostwolf Howler"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "wolf", itemID = 19029, itemLevel = 60, requiredLevel = 60, description = "Raised in the Alterac Mountains by the Frostwolf Clan." },
  ["Golden Leopard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 12327, itemLevel = 40, requiredLevel = nil, description = "Meow." },
  ["Gray Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 15277, itemLevel = 40, requiredLevel = 40, description = "The kodo is the backbone of our people. Wherever the Horde goes - in trade, settlement, or war - there you will find the mighty kodo." },
  ["Gray Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 5864, itemLevel = 40, requiredLevel = 40, description = "Male rams will often smash their thick skulls against each other for hours to impress a female. In that way, they're very similar to dwarves." },
  ["Gray Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50073, itemLevel = nil, requiredLevel = nil, description = "A stoic and observant creature, adapting to any environment it encounters." },
  ["Gray Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 1134, itemLevel = 40, requiredLevel = 40, description = "A fierce and loyal companion of the wilderness." },
  ["Green Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13321, itemLevel = 40, requiredLevel = 40, description = "The terradynamic exo-plotters are conjoined by hydraulic imaging to the equilibrium enhancers..." },
  ["Green Qiraji Resonating Crystal"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingSilithid\\RidingSilithid.m2", modelScale = 0.2, x = 0, y = -0.18, z = -0.7, category = "Qiraji", family = "qiraji", itemID = 21323, itemLevel = 60, requiredLevel = 60, description = "A symbol of power and authority, commanding respect on the battlefield." },
  ["Green Rocket Car"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80461, itemLevel = 40, requiredLevel = 40, description = "Fasten your seatbelts, kid!" },
  ["Green Scrapforged Mechaspider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "mech", itemID = 81194, itemLevel = 60, requiredLevel = 60, description = "This mechaspider specializes in drilling, clamping, and shooting at the same time. A typical gnome invention." },
  ["Green Shredder X-0524B"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81191, itemLevel = 60, requiredLevel = 60, description = "The destructive nature of goblins is best characterized by their shredders." },
  ["Green Spectral Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 83152, itemLevel = 20, requiredLevel = nil, description = "A rare and elusive mount, the Green Spectral Tiger is said to be blessed by the spirits of the forest. Those who ride it are said to have a connection to nature itself." },
  ["Green Thunder Lizard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30014, itemLevel = 60, requiredLevel = nil, description = "Lightning doesn't strike twice, but he does." },
  ["Greymane Charger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 83157, itemLevel = 20, requiredLevel = nil, description = "The Greymane Charger is a symbol of the Gilnean strength and resilience. Its sleek, silver coat and lightning-fast speed make it a favorite among Gilnean soldiers." },
  ["Grim Totem Kodo"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Kodobeast\\RidingKodo.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "kodo", itemID = 83159, itemLevel = 20, requiredLevel = nil, description = "The Grim Totem Kodo is a massive, hulking beast, feared by many for its sheer size and strength. Those who ride it are said to have the power of the earth at their command." },
  ["Happy Dalaran Cloud"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81239, itemLevel = 40, requiredLevel = 1, description = "The fluffiest little cloud in Azeroth." },
  ["Horde Worg"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 80447, itemLevel = 20, requiredLevel = nil, description = "If asked to fetch, will most likely bring you back the head of a small mammal or humanoid." },
  ["Ice Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 83153, itemLevel = 20, requiredLevel = nil, description = "This sleek and agile raptor is adapted to the harsh, icy environments of the north. Its sharp claws and teeth make it a formidable mount in battle." },
  ["Icy Blue Mechanostrider Mod A"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13327, itemLevel = 60, requiredLevel = 60, description = "This historic piece of gnomish engineering was forced into retirement due to its extremely \"touchy\" gyroscometer." },
  ["Immortal Champion's Charger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 80692, itemLevel = 60, requiredLevel = nil, description = "But the most important rule, the rule you can never forget, no matter how much he cries, no matter how much he begs, never feed him after midnight." },
  ["Infinite Crustacean"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30010, itemLevel = 60, requiredLevel = nil, description = "Knows exactly where he's going. It just isn't forward." },
  ["Invincible"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "default", itemID = 92051, itemLevel = 20, requiredLevel = nil, description = "The famous steed of Arthas Menethil, who serves its master in life and in death. Riding him is truly a feat of strength." },
  ["Ivory Boar"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 69170, itemLevel = 20, requiredLevel = nil, description = "Believed to descend from the legendary Agamaggan, these boars are now esteemed companions and mounts of the Razorfen tribe." },
  ["Ivory Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50071, itemLevel = nil, requiredLevel = nil, description = "" },
  ["Kul Tiran Warhorse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "horse", itemID = 83156, itemLevel = 20, requiredLevel = nil, description = "The Kul Tiran Warhorse is a sturdy and reliable mount, bred for battle and unafraid of danger. Its massive size and strength make it a formidable ally in combat." },
  ["Long-Forgotten Hippogryph"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81120, itemLevel = 20, requiredLevel = nil, description = "Ancient mounts of the Highborne, they can rarely be found due to their latent magical powers." },
  ["Lovely Pink Furline"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 83476, itemLevel = 40, requiredLevel = nil, description = "A cuddly and adorable creature, enchanting all who lay eyes upon it." },
  ["Lovely Pink Pony"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 83475, itemLevel = 40, requiredLevel = nil, description = "A delightful companion, bringing joy and happiness wherever it goes." },
  ["Lovely Pink Talbuk"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 83477, itemLevel = 40, requiredLevel = nil, description = "What do you call a pink horse?" },
  ["Magic Rooster"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80431, itemLevel = 20, requiredLevel = nil, description = "Magic in the hands of a genius can do wonderful, miraculous things. Magic in the hands of an idiot can make a giant rooster." },
  ["Marsh Riding Crocolisk"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30003, itemLevel = 60, requiredLevel = nil, description = "Stares into your soul like it knows your deepest secret..." },
  ["Marshmallow"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "default", itemID = 83520, itemLevel = 40, requiredLevel = 40, description = "Molkerei's favorite steed." },
  ["Nordrassil Stag"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "default", itemID = 50535, itemLevel = 20, requiredLevel = nil, description = "A majestic steed imbued with the ancient power of Nordrassil, its hooves carry the echoes of nature's strength." },
  ["Old Whistle of the Ivory Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 8589, itemLevel = 40, requiredLevel = nil, description = "" },
  ["Onyxian Drake"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30017, itemLevel = 60, requiredLevel = 60, description = "Nothing says \"I hold a grudge\" like riding her child into battle." },
  ["Ornate Thalassian Unicorn"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "horse", itemID = 80458, itemLevel = 60, requiredLevel = 60, description = "A majestic mount, hailing from the enchanted forests of Quel'Thalas." },
  ["Pale Thunder Lizard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30015, itemLevel = 60, requiredLevel = nil, description = "Lightning doesn't strike twice, but he does." },
  ["Palomino"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 2413, itemLevel = 40, requiredLevel = 40, description = "" },
  ["Palomino Stallion"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 12354, itemLevel = 40, requiredLevel = 40, description = "Human nobles have long favored this majestic breed for its beautiful golden coat and flowing white mane." },
  ["Pink Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50074, itemLevel = nil, requiredLevel = nil, description = "A vibrant and playful bird, spreading joy wherever it goes." },
  ["Pinto"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "default", itemID = 2414, itemLevel = 40, requiredLevel = 40, description = "Its calm temperament makes it ideal to train young children in horseback riding." },
  ["Plagued Boar"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 69171, itemLevel = 20, requiredLevel = nil, description = "Even the incredibly resilient boars stand no chance against the overwhelming might of the Scourge." },
  ["Purple Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13323, itemLevel = 40, requiredLevel = 40, description = "A sleek and stylish machine, perfect for those with a taste for the extraordinary." },
  ["Purple Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "default", itemID = 50075, itemLevel = nil, requiredLevel = nil, description = "Accidentally released by the Darkmoon Faire — makes for a surprisingly sturdy steed." },
  ["Raven Lord"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81100, itemLevel = 20, requiredLevel = nil, description = "The rest be forgotten to walk upon the ground, clipped wings and shame." },
  ["Red & Blue Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13324, itemLevel = 40, requiredLevel = nil, description = "A striking combination of fiery red and cool blue, showcasing the power of opposites." },
  ["Red Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 8563, itemLevel = 40, requiredLevel = 40, description = "The terradynamic exo-plotters are conjoined by hydraulic imaging to the equilibrium enhancers..." },
  ["Red Qiraji Resonating Crystal"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingSilithid\\RidingSilithid.m2", modelScale = 0.2, x = 0, y = -0.18, z = -0.7, category = "Qiraji", family = "qiraji", itemID = 21321, itemLevel = 60, requiredLevel = 60, description = "A symbol of power and authority, commanding respect on the battlefield." },
  ["Red Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30024, itemLevel = 60, requiredLevel = nil, description = "Fiery as a sunset and twice as stubborn." },
  ["Red Rocket Car"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80460, itemLevel = 40, requiredLevel = 40, description = "Always go twenty over the speed limit." },
  ["Red Scrapforged Mechaspider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "mech", itemID = 81195, itemLevel = 60, requiredLevel = 60, description = "Four-legged machine of destruction, for your riding pleasure." },
  ["Red Shredder X-0524A"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81190, itemLevel = 60, requiredLevel = 60, description = "Fueled by a desire to extract and exploit the natural wonders of Azeroth." },
  ["Red Skeletal Horse"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "skeletal", itemID = 13331, itemLevel = 40, requiredLevel = 40, description = "The Forsaken believe that without a purpose, even beasts of burden suffer in undeath." },
  ["Red Thunder Lizard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30016, itemLevel = 60, requiredLevel = nil, description = "Lightning doesn't strike twice, but he does." },
  ["Reinforced Black Pounder"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81250, itemLevel = 40, requiredLevel = 1, description = "A fearsome war machine, built to withstand the harshest of battles." },
  ["Reinforced Blue Pounder"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81251, itemLevel = 40, requiredLevel = 1, description = "A fearsome war machine, built to withstand the harshest of battles." },
  ["Reinforced Green Pounder"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81252, itemLevel = 40, requiredLevel = 1, description = "A fearsome war machine, built to withstand the harshest of battles." },
  ["Reinforced Red Pounder"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81253, itemLevel = 40, requiredLevel = 1, description = "A fiery inferno on wheels, consuming all in its path with relentless fury." },
  ["Rivendare's Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 13335, itemLevel = 60, requiredLevel = 60, description = "When Baron Rivendare became a champion of the Scourge, he condemned his favorite horse to join him in undeath." },
  ["Scarlet Charger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "horse", itemID = 83155, itemLevel = 20, requiredLevel = nil, description = "It is often ridden by those who seek to inspire fear in their enemies." },
  ["Shadowhorn Stag"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50406, itemLevel = 60, requiredLevel = nil, description = "A powerful, beautiful being." },
  ["Silver Riding Scorpid"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30025, itemLevel = 60, requiredLevel = 60, description = "A rare scorpid with a shimmering silver carapace." },
  ["Snowball"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 51249, itemLevel = 60, requiredLevel = 60, description = "Happy New Year!" },
  ["Spectral Gryphon Essence"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "default", itemID = 50405, itemLevel = 60, requiredLevel = 60, description = "" },
  ["Spotted Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 8632, itemLevel = 40, requiredLevel = 40, description = "This hearty mount's ferocious appetite earned it the nickname \"Dragon Belly\" in the night elf language." },
  ["Spotted Leopard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 12325, itemLevel = 40, requiredLevel = nil, description = "Meow." },
  ["Steel Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 50066, itemLevel = 40, requiredLevel = 40, description = "A mechanical marvel, built to withstand the toughest of battles." },
  ["Stormpike Battle Charger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "PvP", family = "horse", itemID = 19030, itemLevel = 60, requiredLevel = 60, description = "" },
  ["Stormwrought Deathsteed"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 950, itemLevel = 60, requiredLevel = 60, description = "The mount of a fallen Death Knight, risen once more in the mists of Balor." },
  ["Stranglethorn Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 8630, itemLevel = 40, requiredLevel = nil, description = "The wonderful thing about tigers is tigers are wonderful things!" },
  ["Striped Dawnsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "cat", itemID = 81227, itemLevel = 40, requiredLevel = nil, description = "Night elves once believed that seeing this light colored saber breed in the wild was an ill omen." },
  ["Striped Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 8631, itemLevel = 40, requiredLevel = 40, description = "This hearty mount's ferocious appetite earned it the nickname \"Dragon Belly\" in the night elf language." },
  ["Striped Nightsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 8629, itemLevel = 40, requiredLevel = 40, description = "Considered one of Azeroth's perfect predators, these agile beasts can sprint through dense forests without making a sound." },
  ["Swamp Riding Crocolisk"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30005, itemLevel = 60, requiredLevel = 60, description = "Stares into your soul like it knows your deepest secret..." },
  ["Swift Riding Turtle"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingTurtle\\RidingTurtle.m2", modelScale = 0.083, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "turtle", itemID = 23720, itemLevel = 20, requiredLevel = nil, description = "Slow and steady might not always win you the race but it'll get you there... eventually." },
  ["Swift Zulian Tiger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 19902, itemLevel = 60, requiredLevel = 60, description = "" },
  ["Tamed Rak'Shiri"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81231, itemLevel = 40, requiredLevel = nil, description = "Taming this savage breed requires patience, strength, and a large supply of fake mice and twine." },
  ["Tawny Leopard"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "cat", itemID = 12326, itemLevel = 40, requiredLevel = nil, description = "Meow." },
  ["Timber Wolf"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\DireWolf\\RidingDireWolf.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "wolf", itemID = 1132, itemLevel = 40, requiredLevel = 40, description = "Can howl loudly enough to be heard for miles." },
  ["Turbo-Charged Flying Machine"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 81238, itemLevel = 40, requiredLevel = 1, description = "Only the most talented engineers have the courage and the mental stamina to create a flying machine that boasts stability and safety. Turbo-charging one is just crazy!" },
  ["Turquoise Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 8591, itemLevel = 40, requiredLevel = 40, description = "Bred from the fiercest stock anywhere and guaranteed not to bite (much)." },
  ["Turquoise Tallstrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50076, itemLevel = nil, requiredLevel = nil, description = "A rare and exotic bird, with feathers as bright as the tropical seas." },
  ["Twilight"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50536, itemLevel = 20, requiredLevel = nil, description = "A mount that embodies the perfect balance between darkness and beauty." },
  ["Twilight Unicorn"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "horse", itemID = 50407, itemLevel = 60, requiredLevel = nil, description = "Once a creature of starlight, now touched by shadow. The Twilight Unicorn walks a forgotten path." },
  ["Unpainted Mechanostrider"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13322, itemLevel = 40, requiredLevel = 40, description = "A work in progress, waiting for its true colors to be revealed." },
  ["Vermilion Deathcharger"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\SkeletalWarHorse\\SkeletalWarHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "skeletal", itemID = 81235, itemLevel = 40, requiredLevel = nil, description = "Some horses merely adopt the dark. This horse was born in it." },
  ["Vermillion Riding Crab"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 30009, itemLevel = 60, requiredLevel = 60, description = "Walks sideways, charges forward." },
  ["Violet Feral Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 23800, itemLevel = 20, requiredLevel = 20, description = "A rare predator from the depths of Wailing Caverns." },
  ["Violet Raptor"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingRaptor\\RidingRaptor.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Horde", family = "raptor", itemID = 8592, itemLevel = 40, requiredLevel = 40, description = "Bred from the fiercest stock anywhere and guaranteed not to bite (much)." },
  ["White Mechanostrider Mod A"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\MechaStrider\\MechaStrider.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "mech", itemID = 13326, itemLevel = 60, requiredLevel = nil, description = "Forced to recall the model after numerous complaints of an \"uncontrollable throttle\", Gnomish engineers now refer to a proto-type blunder as a \"model B\"." },
  ["White Ram"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\Ram\\RidingRam.m2", modelScale = 0.17, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "ram", itemID = 5873, itemLevel = 40, requiredLevel = 40, description = "Male rams will often smash their thick skulls against each other for hours to impress a female. In that way, they're very similar to dwarves." },
  ["White Riding Talbuk"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 92017, itemLevel = 40, requiredLevel = 1, description = "" },
  ["White Stag"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 80425, itemLevel = 60, requiredLevel = nil, description = "A powerful, beautiful being." },
  ["White Stallion"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Racial", family = "horse", itemID = 12353, itemLevel = 40, requiredLevel = 40, description = "The powerful and unyielding white stallion features heavily in the myths of ancient human tribes." },
  ["White Thalassian Unicorn"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "horse", itemID = 80459, itemLevel = 40, requiredLevel = 40, description = "A rare and magical creature, sought after by those who appreciate beauty and elegance." },
  ["White Unicorn"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.144, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "horse", itemID = 50399, itemLevel = 60, requiredLevel = nil, description = "Graceful and elusive, this mount is cherished by the citizens of Quel'Thalas." },
  ["Wildhammer Gryphon"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "default", itemID = 81185, itemLevel = 60, requiredLevel = 60, description = "Gryphons' keen eyesight allows them to see over vast distances and warn their riders of any dangers that lie ahead." },
  ["Winter Veil Reindeer"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 21044, itemLevel = 1, requiredLevel = nil, description = "Happy New Year, and Merry Winter Veil!" },
  ["Winterspring Frostsaber"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\FrostSabre\\RidingFrostSabre.m2", modelScale = 0.16, x = 0, y = -0.18, z = -0.7, category = "Alliance", family = "cat", itemID = 13086, itemLevel = 60, requiredLevel = 60, description = "Taming this savage breed requires patience, strength, and a large supply of fake mice and twine." },
  ["Yellow Qiraji Resonating Crystal"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingSilithid\\RidingSilithid.m2", modelScale = 0.2, x = 0, y = -0.18, z = -0.7, category = "Qiraji", family = "qiraji", itemID = 21324, itemLevel = 60, requiredLevel = 60, description = "A symbol of power and authority, commanding respect on the battlefield." },
  ["Zebra"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50426, itemLevel = 40, requiredLevel = 40, description = "It has stripes!" },
  ["Zhevra"] = { source = "", speed = "", creatureID = nil, displayID = nil, model = "Creature\\RidingHorse\\RidingHorse.m2", modelScale = 0.192, x = 0, y = -0.18, z = -0.7, category = "Turtle WoW", family = "default", itemID = 50400, itemLevel = 40, requiredLevel = nil, description = "Zhevras are rarely used as mounts in Azeroth due to their stubborn nature and tendency to bite." },
}

-- The OctoWoW mount-category export contained eleven confirmed equipment
-- records.  They are not mounts and must never enter the journal, saved
-- collection data, spellbook classification, or achievement bridge.
local ABC_REJECTED_MOUNT_NAMES = {
  ["Brutal Leggings of Ascendancy"] = true,
  ["Brutal Leggings of Conquest"] = true,
  ["Ephemeral Pendant"] = true,
  ["Ethereal Boots of Ascendancy"] = true,
  ["Ethereal Boots of Conquest"] = true,
  ["Fractured Crown of Ascendancy"] = true,
  ["Fractured Crown of Conquest"] = true,
  ["Nathrezim Armor of Deceit"] = true,
  ["Nathrezim Armor of Treachery"] = true,
  ["Shifting Mantle of Ascendancy"] = true,
  ["Shifting Mantle of Conquest"] = true,
}

local function ABC_IsRejectedMountName(name)
  return name and ABC_REJECTED_MOUNT_NAMES[name] == true
end

-- Remove the bad rows from the source table before master lists are built.
for rejectedName in pairs(ABC_REJECTED_MOUNT_NAMES) do
  ABC_OCTOWOW_MOUNTS[rejectedName] = nil
end

function ABC:PurgeRejectedMountData()
  EnsureDB()
  local rejectedAchievementIds = {
    ["mount_dynamic_brutal_leggings_of_ascendancy"] = true,
    ["mount_dynamic_brutal_leggings_of_conquest"] = true,
    ["mount_dynamic_ephemeral_pendant"] = true,
    ["mount_dynamic_ethereal_boots_of_ascendancy"] = true,
    ["mount_dynamic_ethereal_boots_of_conquest"] = true,
    ["mount_dynamic_fractured_crown_of_ascendancy"] = true,
    ["mount_dynamic_fractured_crown_of_conquest"] = true,
    ["mount_dynamic_nathrezim_armor_of_deceit"] = true,
    ["mount_dynamic_nathrezim_armor_of_treachery"] = true,
    ["mount_dynamic_shifting_mantle_of_ascendancy"] = true,
    ["mount_dynamic_shifting_mantle_of_conquest"] = true,
  }

  for rejectedName in pairs(ABC_REJECTED_MOUNT_NAMES) do
    if LeafVE_AchTest_DB and LeafVE_AchTest_DB.collections and LeafVE_AchTest_DB.collections.mounts then
      LeafVE_AchTest_DB.collections.mounts[rejectedName] = nil
    end
    if ABC.runtime and ABC.runtime.mounts then ABC.runtime.mounts[rejectedName] = nil end
    if ABC.masterMountList then ABC.masterMountList[rejectedName] = nil end
    if AshenBannerCollectionsDB and AshenBannerCollectionsDB.models and AshenBannerCollectionsDB.models.mounts then
      AshenBannerCollectionsDB.models.mounts[rejectedName] = nil
    end
    if AshenBannerCollectionsDB and AshenBannerCollectionsDB.modelView and AshenBannerCollectionsDB.modelView.mounts then
      AshenBannerCollectionsDB.modelView.mounts[rejectedName] = nil
    end
    if AshenBannerCollectionsDB and AshenBannerCollectionsDB.portraitView and AshenBannerCollectionsDB.portraitView.mounts then
      AshenBannerCollectionsDB.portraitView.mounts[rejectedName] = nil
    end
  end

  -- Remove false dynamic mount state and any points those old entries awarded.
  local mountState = LeafVE_AchTest_DB and LeafVE_AchTest_DB.mountCollection
  if mountState then
    for dynamicId, entry in pairs(mountState.dynamic or {}) do
      if entry and ABC_IsRejectedMountName(entry.name) then
        mountState.dynamic[dynamicId] = nil
        if mountState.owned then mountState.owned[dynamicId] = nil end
        if mountState.icons then mountState.icons[dynamicId] = nil end
      end
    end
  end
  if LeafVE_AchTest_DB and LeafVE_AchTest_DB.achievements then
    for _, playerAchievements in pairs(LeafVE_AchTest_DB.achievements) do
      if type(playerAchievements) == "table" then
        for rejectedId in pairs(rejectedAchievementIds) do
          playerAchievements[rejectedId] = nil
        end
      end
    end
  end
end

local function ABC_IsOctoWoWMount(name)
  return name and not ABC_IsRejectedMountName(name) and ABC_OCTOWOW_MOUNTS[name] ~= nil
end

ABC.defaultMountData = ABC_OCTOWOW_MOUNTS

BuildMasterLists = function()
  ABC.masterMountList = {}
  for name, base in pairs(ABC_OCTOWOW_MOUNTS) do
    local row = {}
    for k, v in pairs(base) do row[k] = v end
    row.name = name
    row.family = GetModelFamily(row, "mount")
    row.icon = ABC_FAMILY_PORTRAIT_TEXTURES[row.family] or ABC_FAMILY_PORTRAIT_TEXTURES.default
    ABC.masterMountList[name] = row
  end
  ABC.masterCompanionList = {}
  local companionMaster = LeafVE_Ach_CompanionsMaster or ABC.defaultCompanionData
  for name, info in pairs(companionMaster) do
    local base = ABC.defaultCompanionData[name] or {}
    ABC.masterCompanionList[name] = {
      name = name,
      source = (type(info) == "table" and info.source) or base.source or "Companion collection",
      obtainedFrom = (type(info) == "table" and info.obtainedFrom) or base.obtainedFrom,
      sourceConfidence = (type(info) == "table" and info.sourceConfidence) or base.sourceConfidence,
      category = (type(info) == "table" and (info.sourceCategory or info.category)) or base.category,
      sourceCategory = (type(info) == "table" and (info.sourceCategory or info.category)) or base.sourceCategory,
      points = (type(info) == "table" and info.points) or base.points,
      difficulty = (type(info) == "table" and info.difficulty) or base.difficulty,
      achievementId = (type(info) == "table" and info.achievementId) or base.achievementId,
      icon = (type(info) == "table" and info.icon) or base.icon,
      creatureID = base.creatureID,
    }
  end
end
BuildMasterLists()

IsKnownMount = function(spellName)
  return ABC_IsOctoWoWMount(spellName)
end

ClassifySpell = function(spellName, tabName)
  local tab = Lower(tabName)
  if IsKnownCompanion(spellName) then return "companion" end
  if ABC_IsOctoWoWMount(spellName) then return "mount" end
  if string.find(tab, "companion") or string.find(tab, "companions") or string.find(tab, "pet") or string.find(tab, "pets") or string.find(tab, "critter") or string.find(tab, "vanity") then return "companion" end
  return nil
end

MergeData = function(kind, spellName, icon, tabName, spellIndex, bookType)
  EnsureDB()
  if not spellName or spellName == "" then return end
  if kind == "mount" and ABC_IsRejectedMountName(spellName) then return end
  if kind ~= "mount" then
    local key = "companions"
    local defaults = ABC.defaultCompanionData or {}
    local saved = LeafVE_AchTest_DB.collections[key]
    local base = defaults[spellName] or {}
    if type(saved[spellName]) ~= "table" then saved[spellName] = {} end
    saved[spellName].name = spellName
    saved[spellName].icon = icon or saved[spellName].icon or base.icon
    saved[spellName].tabName = tabName or saved[spellName].tabName
    saved[spellName].seenAt = time and time() or saved[spellName].seenAt or 0
    saved[spellName].source = saved[spellName].source or base.source or (tabName and ("Spellbook: "..tabName) or "Spellbook collection")
    ABC.runtime[key][spellName] = { name = spellName, icon = icon or saved[spellName].icon, tabName = tabName, spellIndex = spellIndex, bookType = bookType or BOOK_SPELL, source = saved[spellName].source, creatureID = saved[spellName].creatureID }
    return
  end
  local base = ABC_OCTOWOW_MOUNTS[spellName]
  if not base then return end
  local key = "mounts"
  local saved = LeafVE_AchTest_DB.collections[key]
  if type(saved[spellName]) ~= "table" then saved[spellName] = {} end
  for k, v in pairs(base) do saved[spellName][k] = v end
  saved[spellName].name = spellName
  saved[spellName].icon = icon or saved[spellName].icon or base.icon
  saved[spellName].tabName = tabName or saved[spellName].tabName
  saved[spellName].seenAt = time and time() or saved[spellName].seenAt or 0
  saved[spellName].family = GetModelFamily(saved[spellName], "mount")
  ABC.runtime[key][spellName] = { name = spellName, icon = icon or saved[spellName].icon, tabName = tabName, spellIndex = spellIndex, bookType = bookType or BOOK_SPELL, source = saved[spellName].source, speed = saved[spellName].speed, creatureID = saved[spellName].creatureID, displayID = saved[spellName].displayID, model = saved[spellName].model, modelScale = saved[spellName].modelScale, x = saved[spellName].x, y = saved[spellName].y, z = saved[spellName].z, category = saved[spellName].category, family = saved[spellName].family, itemID = saved[spellName].itemID, itemLevel = saved[spellName].itemLevel, requiredLevel = saved[spellName].requiredLevel, description = saved[spellName].description, url = saved[spellName].url }
end

BuildSortedList = function(kind)
  local saved = GetSavedCollection(kind)
  local runtime = GetRuntimeCollection(kind)
  local master = (kind == "mount") and ABC.masterMountList or (kind == "toy") and ABC.masterToyList or ABC.masterCompanionList
  local function ApplyPointFallback(row)
    if row.points or not LeafVE_AchTest then return end
    if kind == "mount" and LeafVE_AchTest.GetMountPointValue then row.points = LeafVE_AchTest:GetMountPointValue(row.name, row.source)
    elseif kind == "toy" and LeafVE_AchTest.GetToyPointValue then row.points = LeafVE_AchTest:GetToyPointValue(row.name)
    elseif kind ~= "mount" and LeafVE_AchTest.GetCompanionPointValue then row.points = LeafVE_AchTest:GetCompanionPointValue(row.name) end
  end
  local outMap = {}
  for name, mdata in pairs(master or {}) do
    local row = {}
    for k, v in pairs(mdata) do row[k] = v end
    row.name = name
    row.collected = false
    ApplyPointFallback(row)
    outMap[name] = row
  end
  for name, data in pairs(saved) do
    if outMap[name] then
      local r = runtime[name] or {}
      local row = outMap[name] or {}
      for k, v in pairs(data) do row[k] = v end
      for k, v in pairs(r) do row[k] = v end
      -- Acquisition text always comes from the current verified catalogue,
      -- never from stale SavedVariables created by an older build.
      local clean = master and master[name] or nil
      row.source = clean and clean.source or ""
      row.obtainedFrom = clean and clean.obtainedFrom or nil
      row.sourceConfidence = clean and clean.sourceConfidence or nil
      row.url = nil
      row.name = name
      row.collected = true
      ApplyPointFallback(row)
      outMap[name] = row
    end
  end
  local out = {}
  for _, row in pairs(outMap) do table.insert(out, row) end
  table.sort(out, function(a,b) return Lower(a.name or "") < Lower(b.name or "") end)
  return out
end

MountMatchesFilter = function(row, filterValue)
  local filter = filterValue or "All"
  if filter == "All" then return true end
  if filter == "Collected" then return row and row.collected == true end
  if filter == "Missing" then return not (row and row.collected == true) end
  local cat = row and (row.category or "") or ""
  if cat == filter then return true end
  return false
end

ABC.octowowSourceCount = 225
-- end OctoWoW source-of-truth override


-- ---------------------------------------------------------------------------
-- v3.8.0 Locked UI + researched sources
-- No PlayerModel frames, no custom MPQ dependency, and no self-destroying
-- EditBox refresh handlers. Borders are explicit textures for 1.12 safety.
-- ---------------------------------------------------------------------------

local ABC_STABLE_ACQUISITION = {
  ["Admiral Grumbleshell"] = { text = "Reach level 60 with the Slow & Steady leveling challenge.", confidence = "Verified: Turtle challenge" },
  ["Ancient Arctic Wolf"] = { text = "Legacy mount; no longer normally obtainable.", confidence = "Verified: Legacy item" },
  ["Ancient Black Ram"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Ancient Black Wolf"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Ancient Frostsaber"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Ancient Green Kodo"] = { text = "Legacy mount; no longer normally obtainable.", confidence = "Verified: Legacy item" },
  ["Ancient Nightsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Ancient Red Wolf"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Ancient Teal Kodo"] = { text = "Legacy mount; no longer normally obtainable.", confidence = "Verified: Legacy item" },
  ["Armored Black Bear"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Armored Black Steed"] = { text = "Noblegarden mystery-egg reward.", confidence = "Verified: Turtle event/shop" },
  ["Armored Blue Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Brewfest Ram"] = { text = "Brewfest seasonal event reward.", confidence = "Verified: Seasonal event" },
  ["Armored Brown Bear"] = { text = "Zul'Mabe Bearclaw, Bear Merchant in Stonetalon Mountains, at Revantusk Trolls Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Brown Boar"] = { text = "", confidence = "" },
  ["Armored Brown Kodo"] = { text = "Harb Clawhoof, Mulgore; non-Tauren require Thunder Bluff Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Brown Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored Brown Steed"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored Brown Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Crimson Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Darkspear Raptor"] = { text = "Vuh'sha Torntusk, Darkspear Quartermaster in Durotar, at Darkspear Trolls Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Dawnsaber"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Armored Ebon Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Emerald Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Frostmane Bear"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Armored Frostsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Gray Kodo"] = { text = "Harb Clawhoof, Mulgore; non-Tauren require Thunder Bluff Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Gray Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored Gray Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Green Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Green Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Grey Steed"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Armored Ice Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Ironforge Ram"] = { text = "Hemming Silverbeard, Ironforge Quartermaster, at Ironforge Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Ivory Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Ivory Raptor"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Armored Mistsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Nightsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Obsidian Raptor"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Armored Olive Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Orange Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Orgrimmar Wolf"] = { text = "Gorrok, Orgrimmar Quartermaster, at Orgrimmar Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Purple Bear"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Armored Purple Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Razzashi Raptor"] = { text = "Rare drop from Bloodlord Mandokir in Zul’Gurub.", confidence = "Verified: Vanilla drop" },
  ["Armored Red Bear"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Armored Red Deathcharger"] = { text = "Loren Goodcorn, Undercity Quartermaster, at Undercity Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Red Raptor"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Armored Stormsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Stormwind Warhorse"] = { text = "Valiant, Stormwind Quartermaster, at Stormwind Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Swift Palomino"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored Thalassian Unicorn"] = { text = "Vanira Quel'Belore, Unicorn Breeder, with Silvermoon Remnant reputation.", confidence = "Verified: Turtle reputation" },
  ["Armored Thunder Bluff Kodo"] = { text = "Lansa Skyseer, Thunder Bluff Quartermaster in Mulgore, at Thunder Bluff Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Timber Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored Violet Raptor"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Armored White Kodo"] = { text = "Harb Clawhoof, Mulgore; non-Tauren require Thunder Bluff Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored White Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Armored White Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored White Steed"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Armored Wildhammer Gryphon"] = { text = "Alyssa Stormbolt, Wildhammer Quartermaster in the Hinterlands, at Wildhammer Clan Exalted.", confidence = "Verified: Turtle reputation" },
  ["Armored Yellow Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Azure Frostsaber"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Azure Spectral Tiger"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Azure Thunder Lizard"] = { text = "", confidence = "" },
  ["Beige Riding Scorpid"] = { text = "", confidence = "" },
  ["Big Blizzard Bear"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Big Turtle WoW Bear"] = { text = "Turtle promotional/donation reward; appeared in the Noblegarden mystery-egg pool.", confidence = "Verified: Turtle shop" },
  ["Black Battlestrider"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black Bear"] = { text = "", confidence = "" },
  ["Black Boar"] = { text = "Reach level 60 in The Grand Boaring Adventure challenge; also awards The Hambringer title.", confidence = "Verified: Turtle challenge" },
  ["Black Deathcharger"] = { text = "Noblegarden mystery-egg reward.", confidence = "Verified: Turtle event/shop" },
  ["Black Qiraji Resonating Crystal"] = { text = "Legacy Scarab Gong opening-event reward; normally unobtainable after the Ahn’Qiraj opening.", confidence = "Verified: Vanilla event" },
  ["Black Riding Scorpid"] = { text = "", confidence = "" },
  ["Black Scrapforged Mechaspider"] = { text = "Axis Spinpistol at Gnomeregan Exiles Exalted; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Black Spectral Tiger"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Black Stallion"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Black Thunder Lizard"] = { text = "", confidence = "" },
  ["Black Tournament Charger"] = { text = "", confidence = "" },
  ["Black War Kodo"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black War Ram"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black War Raptor"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black War Steed"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black War Tiger"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black War Wolf"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Black Zulian Panther"] = { text = "Rare drop from High Priestess Arlokk in Zul’Gurub; also appeared in Turtle promotional reward pools.", confidence = "Verified: Vanilla/Turtle" },
  ["Blackstone Dragon Guard"] = { text = "", confidence = "" },
  ["Blue Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Blue Qiraji Resonating Crystal"] = { text = "Trash drop inside the Temple of Ahn’Qiraj; primarily usable within the raid.", confidence = "Verified: Vanilla drop" },
  ["Blue Riding Scorpid"] = { text = "", confidence = "" },
  ["Blue Rocket Car"] = { text = "Mirage Raceway repeatable racing rewards / prize boxes in the Shimmering Flats.", confidence = "Verified: Turtle event" },
  ["Blue Scrapforged Mechaspider"] = { text = "Axis Spinpistol at Gnomeregan Exiles Exalted; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Blue Skeletal Horse"] = { text = "Zachariah Post, Tirisfal Glades; non-Forsaken require Undercity Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Brewfest Kodo"] = { text = "Brewfest seasonal event reward.", confidence = "Verified: Seasonal event" },
  ["Brewfest Ram"] = { text = "Brewfest seasonal reward; also included in Turtle promotional egg pools.", confidence = "Verified: Seasonal/Turtle" },
  ["Bronze Drake"] = { text = "Wardens of Time / Black Morass reputation reward; availability has changed across Turtle patches.", confidence = "Verified: Turtle reputation" },
  ["Brown Bear"] = { text = "", confidence = "" },
  ["Brown Horse"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Brown Kodo"] = { text = "Harb Clawhoof, Mulgore; non-Tauren require Thunder Bluff Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Brown Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Brown Skeletal Horse"] = { text = "Zachariah Post, Tirisfal Glades; non-Forsaken require Undercity Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Brown Tallstrider"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Brown Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Brown Zhevra"] = { text = "", confidence = "" },
  ["Celestial Steed"] = { text = "", confidence = "" },
  ["Cenarion Hippogryph"] = { text = "Turtle donation/token-shop mount; do not use the Burning Crusade Cenarion Expedition source.", confidence = "Verified: Turtle shop" },
  ["Chestnut Mare"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Chieftain's Kodo"] = { text = "", confidence = "" },
  ["Cloudwing Hippogryph"] = { text = "", confidence = "" },
  ["Commander's Steed"] = { text = "Faction PvP mount vendor; historically tied to the high-rank PvP mount requirement.", confidence = "Verified: Vanilla PvP" },
  ["Crimson Spectral Tiger"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Dalaran Rain Cloud"] = { text = "Noblegarden mystery-egg reward.", confidence = "Verified: Turtle event/shop" },
  ["Dalaran Warhorse"] = { text = "Lonum Magicus, Dalaran quartermaster near Ambermill, at Dalaran Exalted.", confidence = "Verified: Turtle reputation" },
  ["Dark Iron Scorpid"] = { text = "", confidence = "" },
  ["Dark Riding Crab"] = { text = "", confidence = "" },
  ["Dark Riding Talbuk"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Darkmoon Dancing Bear"] = { text = "Darkmoon Faire / Turtle token-shop catalogue; also appeared in Noblegarden promotional eggs.", confidence = "Verified: Turtle event/shop" },
  ["Desert Riding Scorpid"] = { text = "", confidence = "" },
  ["Diamond Crustacean"] = { text = "", confidence = "" },
  ["Dire Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Emerald Drake"] = { text = "Rare drop from Solnius in Emerald Sanctum.", confidence = "Verified: Turtle drop" },
  ["Emerald Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Fluorescent Green Mechanostrider"] = { text = "Rare drop from Engineer Figgles in Hateforge Quarry.", confidence = "Verified: Turtle drop" },
  ["Frost Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Frostwolf Howler"] = { text = "Frostwolf Clan Exalted reward from the Alterac Valley vendor.", confidence = "Verified: Vanilla reputation" },
  ["Golden Leopard"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Gray Kodo"] = { text = "Harb Clawhoof, Mulgore; non-Tauren require Thunder Bluff Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Gray Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["Gray Tallstrider"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Gray Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Green Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Green Qiraji Resonating Crystal"] = { text = "Trash drop inside the Temple of Ahn’Qiraj; primarily usable within the raid.", confidence = "Verified: Vanilla drop" },
  ["Green Rocket Car"] = { text = "Mirage Raceway repeatable racing rewards / prize boxes in the Shimmering Flats.", confidence = "Verified: Turtle event" },
  ["Green Scrapforged Mechaspider"] = { text = "Axis Spinpistol at Gnomeregan Exiles Exalted; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Green Shredder X-0524B"] = { text = "Durotar Labor Union Exalted vendor reward; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Green Spectral Tiger"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Green Thunder Lizard"] = { text = "", confidence = "" },
  ["Greymane Charger"] = { text = "", confidence = "" },
  ["Grim Totem Kodo"] = { text = "", confidence = "" },
  ["Happy Dalaran Cloud"] = { text = "Noblegarden mystery-egg reward.", confidence = "Verified: Turtle event/shop" },
  ["Horde Worg"] = { text = "", confidence = "" },
  ["Ice Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Icy Blue Mechanostrider Mod A"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Immortal Champion's Charger"] = { text = "Reach level 60 in Turtle WoW Hardcore without dying.", confidence = "Verified: Turtle challenge" },
  ["Infinite Crustacean"] = { text = "", confidence = "" },
  ["Invincible"] = { text = "", confidence = "" },
  ["Ivory Boar"] = { text = "", confidence = "" },
  ["Ivory Tallstrider"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Kul Tiran Warhorse"] = { text = "", confidence = "" },
  ["Long-Forgotten Hippogryph"] = { text = "", confidence = "" },
  ["Lovely Pink Furline"] = { text = "Love is in the Air seasonal event reward.", confidence = "Verified: Seasonal event" },
  ["Lovely Pink Pony"] = { text = "Love is in the Air seasonal event reward.", confidence = "Verified: Seasonal event" },
  ["Lovely Pink Talbuk"] = { text = "Love is in the Air seasonal event reward.", confidence = "Verified: Seasonal event" },
  ["Magic Rooster"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Marsh Riding Crocolisk"] = { text = "", confidence = "" },
  ["Marshmallow"] = { text = "", confidence = "" },
  ["Nordrassil Stag"] = { text = "Quest reward from Evandil Nightwind at Nordanaar, Hyjal, after gathering 500 Bright Dream Shards.", confidence = "Verified: Turtle quest" },
  ["Old Whistle of the Ivory Raptor"] = { text = "Legacy mount; no longer normally obtainable.", confidence = "Verified: Legacy item" },
  ["Onyxian Drake"] = { text = "Rare drop from Onyxia.", confidence = "Verified: Turtle drop" },
  ["Ornate Thalassian Unicorn"] = { text = "Vanira Quel'Belore, Unicorn Breeder, with Silvermoon Remnant reputation.", confidence = "Verified: Turtle reputation" },
  ["Pale Thunder Lizard"] = { text = "", confidence = "" },
  ["Palomino"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Palomino Stallion"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Pink Tallstrider"] = { text = "", confidence = "" },
  ["Pinto"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["Plagued Boar"] = { text = "", confidence = "" },
  ["Purple Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Purple Tallstrider"] = { text = "", confidence = "" },
  ["Raven Lord"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Red & Blue Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Red Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Red Qiraji Resonating Crystal"] = { text = "Trash drop inside the Temple of Ahn’Qiraj; primarily usable within the raid.", confidence = "Verified: Vanilla drop" },
  ["Red Riding Scorpid"] = { text = "", confidence = "" },
  ["Red Rocket Car"] = { text = "Mirage Raceway repeatable racing rewards / prize boxes in the Shimmering Flats.", confidence = "Verified: Turtle event" },
  ["Red Scrapforged Mechaspider"] = { text = "Axis Spinpistol at Gnomeregan Exiles Exalted; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Red Shredder X-0524A"] = { text = "Durotar Labor Union Exalted vendor reward; requires Engineering 300.", confidence = "Verified: Turtle reputation" },
  ["Red Skeletal Horse"] = { text = "Zachariah Post, Tirisfal Glades; non-Forsaken require Undercity Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Red Thunder Lizard"] = { text = "", confidence = "" },
  ["Reinforced Black Pounder"] = { text = "Quest begun by Intact Pounder Mainframe, a rare drop from Crowd Pummeler 9-60 in Gnomeregan.", confidence = "Verified: Turtle quest" },
  ["Reinforced Blue Pounder"] = { text = "Quest begun by Intact Pounder Mainframe, a rare drop from Crowd Pummeler 9-60 in Gnomeregan.", confidence = "Verified: Turtle quest" },
  ["Reinforced Green Pounder"] = { text = "Quest begun by Intact Pounder Mainframe, a rare drop from Crowd Pummeler 9-60 in Gnomeregan.", confidence = "Verified: Turtle quest" },
  ["Reinforced Red Pounder"] = { text = "Quest begun by Intact Pounder Mainframe, a rare drop from Crowd Pummeler 9-60 in Gnomeregan.", confidence = "Verified: Turtle quest" },
  ["Rivendare's Deathcharger"] = { text = "Rare drop from Baron Rivendare in Stratholme.", confidence = "Verified: Vanilla drop" },
  ["Scarlet Charger"] = { text = "Limited-time Alt’lympics/leveling promotion reward for eligible Alliance characters.", confidence = "Verified: Turtle event" },
  ["Shadowhorn Stag"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Silver Riding Scorpid"] = { text = "", confidence = "" },
  ["Snowball"] = { text = "Feast of Winter Veil seasonal reward.", confidence = "Verified: Seasonal event" },
  ["Spectral Gryphon Essence"] = { text = "", confidence = "" },
  ["Spotted Frostsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Spotted Leopard"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Steel Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Stormpike Battle Charger"] = { text = "Stormpike Guard Exalted reward from the Alterac Valley vendor.", confidence = "Verified: Vanilla reputation" },
  ["Stormwrought Deathsteed"] = { text = "Rare drop from Deathlord Tidebane in Stormwrought Ruins.", confidence = "Verified: Turtle drop" },
  ["Stranglethorn Tiger"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Striped Dawnsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Striped Frostsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Striped Nightsaber"] = { text = "Lelanai, Darnassus; non-Night Elves require Darnassus Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Swamp Riding Crocolisk"] = { text = "", confidence = "" },
  ["Swift Riding Turtle"] = { text = "", confidence = "" },
  ["Swift Zulian Tiger"] = { text = "Rare drop from High Priest Thekal in Zul’Gurub.", confidence = "Verified: Vanilla drop" },
  ["Tamed Rak'Shiri"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Tawny Leopard"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Timber Wolf"] = { text = "Ogunaro Wolfrunner, Orgrimmar; non-Orcs require Orgrimmar Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Turbo-Charged Flying Machine"] = { text = "", confidence = "" },
  ["Turquoise Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Turquoise Tallstrider"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["Twilight"] = { text = "", confidence = "" },
  ["Twilight Unicorn"] = { text = "Turtle Shop; formerly named Nightmare Dreamrunner.", confidence = "Verified: Turtle shop" },
  ["Unpainted Mechanostrider"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Vermilion Deathcharger"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["Vermillion Riding Crab"] = { text = "", confidence = "" },
  ["Violet Feral Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["Violet Raptor"] = { text = "Zjolnir, Durotar; non-Trolls require Darkspear Trolls Exalted.", confidence = "Verified: Vanilla vendor" },
  ["White Mechanostrider Mod A"] = { text = "Milli Featherwhistle, Dun Morogh; non-Gnomes require Gnomeregan Exiles Exalted.", confidence = "Verified: Vanilla vendor" },
  ["White Ram"] = { text = "Veron Amberstill, Dun Morogh; non-Dwarves require Ironforge Exalted.", confidence = "Verified: Turtle vendor" },
  ["White Riding Talbuk"] = { text = "Turtle Shop; previously available from Noblegarden mystery eggs.", confidence = "Verified: Turtle shop" },
  ["White Stag"] = { text = "Turtle Shop.", confidence = "Verified: Turtle shop" },
  ["White Stallion"] = { text = "Stormwind horse vendors; non-Humans require Stormwind Exalted.", confidence = "Verified: Turtle vendor" },
  ["White Thalassian Unicorn"] = { text = "Vanira Quel'Belore, Unicorn Breeder, with Silvermoon Remnant reputation.", confidence = "Verified: Turtle reputation" },
  ["White Unicorn"] = { text = "Turtle Shop; previously listed as Ancient Quel’dorei Steed.", confidence = "Verified: Turtle shop" },
  ["Wildhammer Gryphon"] = { text = "Wildhammer Clan reputation reward in the Hinterlands.", confidence = "Verified: Turtle reputation" },
  ["Winter Veil Reindeer"] = { text = "Feast of Winter Veil seasonal reward.", confidence = "Verified: Seasonal event" },
  ["Winterspring Frostsaber"] = { text = "Wintersaber Trainers reputation questline in Winterspring.", confidence = "Verified: Vanilla reputation" },
  ["Yellow Qiraji Resonating Crystal"] = { text = "Trash drop inside the Temple of Ahn’Qiraj; primarily usable within the raid.", confidence = "Verified: Vanilla drop" },
  ["Zebra"] = { text = "Rare world drop in the Barrens on Turtle WoW.", confidence = "Verified: Turtle drop" },
  ["Zhevra"] = { text = "Rare world drop in the Barrens on Turtle WoW.", confidence = "Verified: Turtle drop" },
}

local ABC_STABLE_TEX_SOLID = "Interface\\ChatFrame\\ChatFrameBackground"
local ABC_STABLE_TEX_ICON_FALLBACK = "Interface\\Icons\\INV_Misc_QuestionMark"
local ABC_STABLE_TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"

local function ABC_StableEnsureDB()
  EnsureDB()
  AshenBannerCollectionsDB.use3DProof = false
  ABC.configMode = false
  if type(AshenBannerCollectionsDB.stableSearch) ~= "table" then
    AshenBannerCollectionsDB.stableSearch = { mount = "", companion = "" }
  end
  if type(AshenBannerCollectionsDB.stableSearch.mount) ~= "string" then AshenBannerCollectionsDB.stableSearch.mount = "" end
  if type(AshenBannerCollectionsDB.stableSearch.companion) ~= "string" then AshenBannerCollectionsDB.stableSearch.companion = "" end
end

local function ABC_StableApplySources()
  if type(ABC_OCTOWOW_MOUNTS) ~= "table" then return end
  for name, info in pairs(ABC_STABLE_ACQUISITION) do
    local row = ABC_OCTOWOW_MOUNTS[name]
    if row then
      local confidence = tostring(info and info.confidence or "")
      if string.sub(confidence, 1, 9) == "Verified:" and info.text and info.text ~= "" then
        row.obtainedFrom = info.text
        row.sourceConfidence = confidence
      else
        -- An uncertain source is less useful than no source. Keep the mount
        -- in the journal, but leave acquisition text blank until it can be
        -- tied to a verified Turtle WoW source or a verified Vanilla source.
        row.obtainedFrom = nil
        row.sourceConfidence = nil
      end
    end
  end
end
ABC_StableApplySources()
-- The stable acquisition table is declared after the base master list is
-- built, so rebuild once here to copy verified source text into journal rows.
BuildMasterLists()

local function ABC_StableSetTextureColor(texture, r, g, b, a)
  if not texture then return end
  texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
end

local function ABC_StableMakeSolid(parent, layer)
  local texture = parent:CreateTexture(nil, layer or "ARTWORK")
  texture:SetTexture(ABC_STABLE_TEX_SOLID)
  return texture
end

local function ABC_StableCreateBorder(frame, size, r, g, b, a)
  size = tonumber(size) or 2
  local border = {}
  border.top = ABC_StableMakeSolid(frame, "BORDER")
  border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  border.top:SetHeight(size)

  border.bottom = ABC_StableMakeSolid(frame, "BORDER")
  border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  border.bottom:SetHeight(size)

  border.left = ABC_StableMakeSolid(frame, "BORDER")
  border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
  border.left:SetWidth(size)

  border.right = ABC_StableMakeSolid(frame, "BORDER")
  border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
  border.right:SetWidth(size)

  frame._abcStableBorder = border
  for _, texture in pairs(border) do ABC_StableSetTextureColor(texture, r, g, b, a) end
  return border
end

local function ABC_StableSetBorder(frame, r, g, b, a)
  if not frame or type(frame._abcStableBorder) ~= "table" then return end
  for _, texture in pairs(frame._abcStableBorder) do ABC_StableSetTextureColor(texture, r, g, b, a) end
end

local function ABC_StableBackground(frame, r, g, b, a)
  local bg = ABC_StableMakeSolid(frame, "BACKGROUND")
  bg:SetAllPoints(frame)
  ABC_StableSetTextureColor(bg, r, g, b, a)
  frame._abcStableBackground = bg
  return bg
end

local function ABC_StableSearchText(kind)
  ABC_StableEnsureDB()
  return AshenBannerCollectionsDB.stableSearch[kind] or ""
end

local function ABC_StableSetSearchText(kind, text)
  ABC_StableEnsureDB()
  AshenBannerCollectionsDB.stableSearch[kind] = tostring(text or "")
end

local function ABC_StableSearchViewName(kind)
  if kind == "mount" then return "mounts" end
  if kind == "toy" then return "toys" end
  if kind == "guild" then return "guildcollection" end
  return "companions"
end

local function ABC_StableGetSearchFrame(ui, kind)
  local key = kind == "mount" and "abcStableMountSearch" or kind == "toy" and "abcStableToySearch" or kind == "guild" and "abcStableGuildSearch" or "abcStableCompanionSearch"
  if ui[key] then return ui[key] end

  local holder = CreateFrame("Frame", nil, ui.frame)
  holder:SetWidth(370)
  holder:SetHeight(30)
  holder:SetFrameLevel((ui.scrollFrame and ui.scrollFrame:GetFrameLevel() or ui.frame:GetFrameLevel()) + 8)
  -- Exact same spot, sizes, and gaps as the Achievements/Titles search
  -- bars (see searchLabel/searchBox/clearBtn in LeafVillageAchievements.lua
  -- Build()) so this tab's search bar is indistinguishable from theirs.
  holder:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", 155, -128)

  local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
  label:SetText("Search:")

  local box = CreateFrame("EditBox", nil, holder)
  box:SetWidth(240)
  box:SetHeight(26)
  box:SetPoint("LEFT", label, "RIGHT", 5, 0)
  box:SetAutoFocus(false)
  box:SetMaxLetters(80)
  box:SetFontObject("GameFontHighlight")
  box:SetTextInsets(12, 12, 0, 0)
  if LeafVE_AchTest.SkinAshenEditBox then LeafVE_AchTest.SkinAshenEditBox(box) end

  local placeholder = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  placeholder:SetPoint("LEFT", box, "LEFT", 12, 0)
  placeholder:SetText(kind == "mount" and "name, source, item..." or kind == "toy" and "name or source..." or kind == "guild" and "mount, companion, or toy name..." or "name or source...")
  placeholder:SetTextColor(0.40, 0.40, 0.40)
  holder.placeholder = placeholder

  local clear = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
  clear:SetWidth(58)
  clear:SetHeight(28)
  clear:SetPoint("LEFT", box, "RIGHT", 5, 0)
  clear:SetText("Clear")
  if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(clear) end

  holder.box = box
  holder.kind = kind
  holder._abcElapsed = 0
  holder._abcPending = false
  box._abcSetting = true
  box:SetText(ABC_StableSearchText(kind))
  box._abcSetting = nil
  if box:GetText() and box:GetText() ~= "" then placeholder:Hide() else placeholder:Show() end

  local function ScheduleRefresh()
    holder._abcElapsed = 0
    holder._abcPending = true
  end

  box:SetScript("OnTextChanged", function()
    local value = this:GetText() or ""
    if value ~= "" then holder.placeholder:Hide() else holder.placeholder:Show() end
    if this._abcSetting then return end
    ABC_StableSetSearchText(kind, value)
    ABC.pages[kind] = 1
    ScheduleRefresh()
  end)
  box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  box:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  box:SetScript("OnEditFocusGained", function() ABC_StableSetBorder(this, 0.92, 0.51, 0.14, 1) end)
  box:SetScript("OnEditFocusLost", function() ABC_StableSetBorder(this, 0.33, 0.27, 0.20, 1) end)

  clear:SetScript("OnClick", function()
    ABC_StableSetSearchText(kind, "")
    holder.box._abcSetting = true
    holder.box:SetText("")
    holder.box._abcSetting = nil
    holder.placeholder:Show()
    ABC.pages[kind] = 1
    ScheduleRefresh()
  end)

  holder:SetScript("OnUpdate", function()
    if not this._abcPending then return end
    this._abcElapsed = (this._abcElapsed or 0) + (arg1 or 0)
    if this._abcElapsed >= 0.22 then
      this._abcPending = false
      this._abcElapsed = 0
      if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView == ABC_StableSearchViewName(kind) then
        if kind == "guild" then
          ABC:BuildGuildCollectionView()
        else
          ABC:BuildCollectionView(kind)
        end
      end
    end
  end)

  ui[key] = holder
  return holder
end

local function ABC_StableShowSearch(ui, kind)
  local mountSearch = ABC_StableGetSearchFrame(ui, "mount")
  local companionSearch = ABC_StableGetSearchFrame(ui, "companion")
  local toySearch = ABC_StableGetSearchFrame(ui, "toy")
  local guildSearch = ABC_StableGetSearchFrame(ui, "guild")
  mountSearch:Hide(); companionSearch:Hide(); toySearch:Hide(); guildSearch:Hide()
  if kind == "mount" then mountSearch:Show()
  elseif kind == "toy" then toySearch:Show()
  elseif kind == "guild" then guildSearch:Show()
  else companionSearch:Show() end
end

local function ABC_StableHideSearch(ui)
  if ui.abcStableMountSearch then ui.abcStableMountSearch:Hide() end
  if ui.abcStableCompanionSearch then ui.abcStableCompanionSearch:Hide() end
  if ui.abcStableToySearch then ui.abcStableToySearch:Hide() end
  if ui.abcStableGuildSearch then ui.abcStableGuildSearch:Hide() end
end

-- "Who has this mount" -- guild-wide ownership counts per mount/companion/
-- toy, sorted most-owned first, with items nobody in the guild owns simply
-- never appearing (the source table only ever gains a key once someone's
-- COLSYNC broadcast names it -- see LeafVillageAchievements.lua:OnAddonMessage).
--
-- Lives down here (not next to BuildCollectionView above) because it needs
-- ABC_StableSearchText/ABC_StableGetSearchFrame/ABC_StableEnsureDB as
-- upvalues -- those are locals declared earlier in this same chunk, and a
-- Lua 5.0 local isn't visible to code that appears before its declaration
-- (the earlier draft of this view hit exactly this with ABC_StableEnsureDB;
-- moving the whole view down here avoids the class of bug outright instead
-- of routing around it).
ABC.guildCollectionKind = ABC.guildCollectionKind or "mount"
ABC.guildCollectionExpanded = nil

local ABC_GUILD_COLLECTION_KINDS = {
  {value="mount", label="Mounts"},
  {value="companion", label="Companions"},
  {value="toy", label="Toys"},
  {value="leaderboard", label="Leaderboard"},
}

-- Same visual template as EnsureMountSidebar/EnsureCompanionSidebar above
-- (122px bordered column at the window's left margin, row buttons with a
-- listbox-highlight hover texture and a gold/orange label) -- kind
-- switching for this tab lives here instead of top-of-content sub-tabs, to
-- match how every other collection view puts its left-hand switcher in the
-- same sidebar slot.
function ABC:EnsureGuildCollectionSidebar(ui)
  if not ui or not ui.frame then return nil end
  if ui.guildCollectionSidebarFrame then return ui.guildCollectionSidebarFrame end

  local frame = CreateFrame("Frame", nil, ui.frame)
  frame:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", 18, -98)
  frame:SetPoint("BOTTOMLEFT", ui.frame, "BOTTOMLEFT", 18, 10)
  frame:SetWidth(122)
  frame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  frame:SetBackdropColor(0, 0, 0, 0)
  frame:SetBackdropBorderColor(0.55, 0.42, 0.18, 1)

  -- Same ashen wood-panel texture the achievements/titles sidebars use
  -- (TEX.ashenSidebar in LeafVillageAchievements.lua), not the plain
  -- Blizzard dialog background the other ABC sidebars fall back to -- this
  -- one was still on that fallback, which is why it read as "missing its
  -- background" next to every other tab's themed sidebar.
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
  bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  if LeafVE_AchTest.TEX and LeafVE_AchTest.TEX.ashenSidebar then
    bg:SetTexture(LeafVE_AchTest.TEX.ashenSidebar)
    bg:SetTexCoord(0, 1, 0, 1)
  else
    bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
  end
  bg:SetVertexColor(1, 1, 1, 1)
  frame.bg = bg
  frame.buttons = {}

  for i = 1, table.getn(ABC_GUILD_COLLECTION_KINDS) do
    local def = ABC_GUILD_COLLECTION_KINDS[i]
    local btn = CreateFrame("Button", nil, frame)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -(i - 1) * 27 - 4)
    btn:SetWidth(110)
    btn:SetHeight(24)
    btn.kindValue = def.value

    local hi = btn:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints(btn)
    hi:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
    hi:SetVertexColor(0.72, 0.28, 0.08, 0.65)
    hi:Hide()
    btn.highlight = hi

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", btn, "LEFT", 8, 0)
    label:SetWidth(100)
    label:SetJustifyH("LEFT")
    label:SetText(def.label)
    label:SetTextColor(0.92, 0.78, 0.26)
    btn.label = label

    btn:SetScript("OnClick", function()
      ABC.guildCollectionKind = this.kindValue
      -- Same as EnsureMountSidebar's filter buttons resetting ABC.pages.mount
      -- on filter change -- switching sub-category always lands on page 1.
      ABC.pages.guild = 1
      PlaySound("igMainMenuOptionCheckBoxOn")
      ABC:BuildGuildCollectionView()
    end)
    btn:SetScript("OnEnter", function()
      if this.highlight then this.highlight:Show() end
      if this.label then this.label:SetTextColor(1, 1, 1) end
    end)
    btn:SetScript("OnLeave", function()
      local selected = ABC.guildCollectionKind or "mount"
      if this.kindValue ~= selected then
        if this.highlight then this.highlight:Hide() end
        if this.label then this.label:SetTextColor(0.92, 0.78, 0.26) end
      end
    end)
    table.insert(frame.buttons, btn)
  end

  ui.guildCollectionSidebarFrame = frame
  return frame
end

-- Same active/inactive treatment as RefreshMountSidebar: a persistent
-- highlight + orange label on the selected row, gold on the rest.
function ABC:RefreshGuildCollectionSidebar(ui)
  local frame = self:EnsureGuildCollectionSidebar(ui)
  if not frame then return end
  local selected = ABC.guildCollectionKind or "mount"
  for i = 1, table.getn(frame.buttons or {}) do
    local btn = frame.buttons[i]
    if btn.kindValue == selected then
      if btn.highlight then btn.highlight:Show() end
      if btn.label then btn.label:SetTextColor(1.0, 0.45, 0.18) end
    else
      if btn.highlight then btn.highlight:Hide() end
      if btn.label then btn.label:SetTextColor(0.92, 0.78, 0.26) end
    end
  end
end

local function ABC_StableMatch(row, kind)
  if kind == "mount" then
    if not MountMatchesFilter(row, AshenBannerCollectionsDB.mountFilter or "All") then return false end
  elseif kind == "toy" then
    if not ToyMatchesFilter(row, AshenBannerCollectionsDB.toyFilter or "All") then return false end
  else
    if not CompanionMatchesFilter(row, AshenBannerCollectionsDB.companionFilter or "All") then return false end
  end
  local query = Lower(ABC_StableSearchText(kind))
  if query == "" then return true end
  local haystack = Lower(
      tostring(row and row.name or "").." "
    ..tostring(row and row.source or "").." "
    ..tostring(row and row.category or "").." "
    ..tostring(row and row.family or "").." "
    ..tostring(row and row.description or "").." "
    ..tostring(row and row.obtainedFrom or "")
  )
  return string.find(haystack, query, 1, true) ~= nil
end

local function ABC_StableFilterList(list, kind)
  local out = {}
  for _, row in ipairs(list or {}) do
    if ABC_StableMatch(row, kind) then table.insert(out, row) end
  end
  ABC_SortByRecencyThenName(out)
  return out
end

local function ABC_StableFamilyIcon(data, kind)
  return ABC_ResolveCollectionIcon(data, kind)
end

local function ABC_StableTrim(text, maxLength)
  text = tostring(text or "")
  maxLength = tonumber(maxLength) or 60
  if string.len(text) <= maxLength then return text end
  return string.sub(text, 1, maxLength - 3).."..."
end

-- Card pool: same create-once-reuse-forever convention as achievement/title
-- rows elsewhere in this addon. Cards used to be built fresh (CreateFrame +
-- ~15 sub-widgets: background, border, accent, name/status/date/item text,
-- portrait frame + background + border + glow + icon + ring, source label,
-- detail text, and a conditional Summon/Call button) on every page turn,
-- filter-chip click, tab switch, and the 0.5s icon-refresh ticker, with the
-- old ones left for ClearScrollChild's blanket GetChildren()/GetRegions()
-- sweep to hide -- so both that sweep and the total live frame count grew
-- without bound over a session. Split into a one-time skeleton build
-- (ABC_BuildCardSkeleton) and a per-call content update (ABC_PopulateCard)
-- that writes into the same widgets every time instead of recreating them.
ABC.cardPool = ABC.cardPool or {}

local ABC_CARD_W = 218
-- Shrunk from 198 (21px off the portrait area below) so a full 2-row page
-- fits inside the window's existing scroll viewport instead of needing the
-- window itself grown taller.
local ABC_CARD_H = 177

local function ABC_BuildCardSkeleton(parent, index)
  local card = CreateFrame("Button", nil, parent)
  card:SetWidth(ABC_CARD_W)
  card:SetHeight(ABC_CARD_H)

  -- Colors here are placeholders -- ABC_PopulateCard sets the real ones
  -- (which depend on collected state) via the *Set* helpers below, every
  -- populate. The *Create*/*Make* helpers must only ever run once per
  -- widget: calling them again would mint new textures on top of the old
  -- ones instead of updating them.
  ABC_StableBackground(card, 0, 0, 0, 0.98)
  ABC_StableCreateBorder(card, 2, 0, 0, 0, 1)

  local accent = ABC_StableMakeSolid(card, "ARTWORK")
  accent:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
  accent:SetPoint("TOPRIGHT", card, "TOPRIGHT", -3, -3)
  accent:SetHeight(4)
  card.accent = accent

  -- Warm off-white for the name, matching the achievement/title rows'
  -- convention -- gold is reserved for points/accents there, not names.
  local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nameText:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -13)
  nameText:SetWidth(145)
  nameText:SetJustifyH("LEFT")
  card.nameText = nameText

  local status = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  status:SetPoint("TOPRIGHT", card, "TOPRIGHT", -9, -14)
  card.status = status

  local collectedDate = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  collectedDate:SetPoint("TOP", status, "BOTTOM", 0, -2)
  collectedDate:SetTextColor(0.62, 0.60, 0.56)
  collectedDate:Hide()
  card.collectedDate = collectedDate

  local itemLine = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  itemLine:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
  itemLine:SetWidth(190)
  itemLine:SetJustifyH("LEFT")
  itemLine:SetTextColor(0.62, 0.62, 0.61)
  card.itemLine = itemLine

  -- Shrunk from 91 (21px, matching cardH's own reduction) -- top offset
  -- (-51) is unchanged, so everything below (sourceLabel, and the
  -- fixed-offset-from-bottom detail/summon row) keeps the exact same gap
  -- between them as before; only the portrait's own height shrank.
  local portraitFrame = CreateFrame("Frame", nil, card)
  portraitFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -51)
  portraitFrame:SetWidth(ABC_CARD_W - 16)
  portraitFrame:SetHeight(70)
  ABC_StableBackground(portraitFrame, 0.012, 0.012, 0.012, 1)
  ABC_StableCreateBorder(portraitFrame, 2, 0, 0, 0, 1)
  card.portraitFrame = portraitFrame

  local centerGlow = ABC_StableMakeSolid(portraitFrame, "BACKGROUND")
  centerGlow:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
  centerGlow:SetWidth(138)
  centerGlow:SetHeight(55)
  card.centerGlow = centerGlow

  local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
  portrait:SetPoint("CENTER", portraitFrame, "CENTER", 0, 0)
  portrait:SetWidth(62)
  portrait:SetHeight(62)
  portrait:SetTexCoord(0.06, 0.94, 0.06, 0.94)
  card.portrait = portrait

  -- This depends only on a static global resource, not per-card data, so
  -- it's safe to decide once here instead of every populate.
  if LeafVE_AchTest.TEX and LeafVE_AchTest.TEX.iconFrame then
    local portraitRing = portraitFrame:CreateTexture(nil, "OVERLAY")
    portraitRing:SetWidth(73); portraitRing:SetHeight(73)
    portraitRing:SetPoint("CENTER", portrait, "CENTER", 0, 0)
    portraitRing:SetTexture(LeafVE_AchTest.TEX.iconFrame)
    card.portraitRing = portraitRing
  end

  -- Toys have no verified acquisition source (the catalogue's obtainedFrom
  -- is just generic boilerplate for every entry) -- the item's own flavor
  -- description is far more useful here, so it takes this slot instead.
  local sourceLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sourceLabel:SetPoint("TOPLEFT", portraitFrame, "BOTTOMLEFT", 2, -5)
  sourceLabel:SetWidth(ABC_CARD_W - 20)
  sourceLabel:SetHeight(30)
  sourceLabel:SetJustifyH("LEFT")
  sourceLabel:SetJustifyV("TOP")
  sourceLabel:SetTextColor(0.73, 0.69, 0.61)
  card.sourceLabel = sourceLabel

  -- Points shown in the same gold used for achievement points everywhere
  -- else, instead of buried in the same plain gray as the category text.
  local detail = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  detail:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 9, 9)
  detail:SetJustifyH("LEFT")
  detail:SetTextColor(0.54, 0.52, 0.48)
  card.detail = detail

  local summon = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
  summon:SetWidth(72); summon:SetHeight(21)
  summon:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
  summon:SetScript("OnClick", function()
    -- Reads card.data at click time, not a closure-captured value -- this
    -- button is reused across different mounts/companions as the card gets
    -- repopulated, so a stale closure would summon whatever was shown here
    -- when the button was first built, not what's currently displayed.
    local d = card.data
    if d and d.spellIndex then CastSpell(d.spellIndex, d.bookType or BOOK_SPELL) end
  end)
  if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(summon) end
  summon:Hide()
  card.summonBtn = summon

  -- Same reasoning as the Summon button: reads this.data/this.kind/
  -- this.obtained at hover time so a reused card's tooltip always reflects
  -- whatever it's currently populated with.
  card:SetScript("OnEnter", function()
    local d = this.data
    -- Guild-aggregate cards have no personal collected/missing state (every
    -- card here is "collected" by construction) -- swap the tooltip body for
    -- the owner roster instead, everything else about the hover (border tint,
    -- anchor) stays identical to the collected-card treatment below.
    if this.isGuildCard then
      ABC_StableSetBorder(this, 1.0, 0.58, 0.14, 1)
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText(tostring(d and d.name or "Unknown"), 1, 0.82, 0.36)
      local owners = this.guildOwners or {}
      local ownerCount = table.getn(owners)
      GameTooltip:AddLine(ownerCount == 1 and "Owned by 1 guildie" or ("Owned by "..ownerCount.." guildies"), 0.45, 1.0, 0.42)
      if ownerCount > 0 then
        GameTooltip:AddLine(" ")
        -- Capped so a large guild's full roster on a common mount can't
        -- balloon the tooltip into an unreadable wall of names.
        local shown = owners
        local suffix = ""
        if ownerCount > 30 then
          shown = {}
          for i = 1, 30 do shown[i] = owners[i] end
          suffix = ", and "..(ownerCount - 30).." more"
        end
        GameTooltip:AddLine(table.concat(shown, ", ")..suffix, 0.84, 0.84, 0.82, true)
      end
      GameTooltip:Show()
      return
    end
    local coll = d and d.collected == true
    ABC_StableSetBorder(this, coll and 1.0 or 0.58, coll and 0.58 or 0.48, coll and 0.14 or 0.36, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(tostring(d and d.name or "Unknown"), 1, 0.82, 0.36)
    GameTooltip:AddLine(coll and "Collected" or "Not collected", coll and 0.45 or 0.72, coll and 1.0 or 0.68, coll and 0.42 or 0.62)
    GameTooltip:AddLine("Achievement points: "..tostring(tonumber(d and d.points) or 25), 1.0, 0.72, 0.25)
    if d and d.difficulty then GameTooltip:AddLine("Difficulty tier: "..tostring(d.difficulty), 0.72, 0.72, 0.72) end
    if d and d.description and d.description ~= "" then GameTooltip:AddLine(d.description, 0.90, 0.90, 0.90, true) end
    -- Toys have no verified acquisition source -- obtainedFrom is just
    -- generic boilerplate, so skip the redundant "Source" section for them.
    if this.kind ~= "toy" and this.obtained and this.obtained ~= "" then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("Source", 1.0, 0.72, 0.25)
      GameTooltip:AddLine(tostring(this.obtained), 0.84, 0.84, 0.82, true)
    end
    GameTooltip:Show()
  end)
  card:SetScript("OnLeave", function()
    if this.isGuildCard then
      ABC_StableSetBorder(this, 0.72, 0.43, 0.12, 1)
      GameTooltip:Hide()
      return
    end
    local d = this.data
    local coll = d and d.collected == true
    ABC_StableSetBorder(this, coll and 0.72 or 0.31, coll and 0.43 or 0.27, coll and 0.12 or 0.22, 1)
    GameTooltip:Hide()
  end)

  ABC.cardPool[index] = card
  return card
end

local function ABC_PopulateCard(card, parent, index, data, kind)
  local cols = 3
  local gapX, gapY = 14, 10
  local col = math.mod(index - 1, cols)
  local row = math.floor((index - 1) / cols)
  local collected = data and data.collected == true

  -- parent (shim) is itself pooled/reused by BuildCollectionView now rather
  -- than recreated every call, but reparenting defensively here costs
  -- nothing and guards against that ever changing.
  card:SetParent(parent)
  card:ClearAllPoints()
  card:SetPoint("TOPLEFT", parent, "TOPLEFT", 10 + col * (ABC_CARD_W + gapX), -8 - row * (ABC_CARD_H + gapY))
  card.data = data
  card.kind = kind

  ABC_StableSetTextureColor(card._abcStableBackground, collected and 0.105 or 0.050, collected and 0.070 or 0.046, collected and 0.038 or 0.042, 0.98)
  ABC_StableSetBorder(card, collected and 0.72 or 0.31, collected and 0.43 or 0.27, collected and 0.12 or 0.22, 1)
  ABC_StableSetTextureColor(card.accent, collected and 0.95 or 0.34, collected and 0.45 or 0.30, collected and 0.08 or 0.24, 1)

  -- Only the big portrait below shows the icon now -- a second small copy
  -- up here next to the name was pure duplication on a card this size.
  local iconPath = ABC_StableFamilyIcon(data, kind)

  card.nameText:SetText(ABC_StableTrim(data and data.name or "Unknown", 28))
  card.nameText:SetTextColor(collected and 0.90 or 0.67, collected and 0.88 or 0.65, collected and 0.84 or 0.62)

  card.status:SetText(collected and "COLLECTED" or "MISSING")
  card.status:SetTextColor(collected and 0.42 or 0.68, collected and 0.92 or 0.66, collected and 0.34 or 0.58)

  local collectedTs = collected and ABC_CollectedTimestamp(data) or nil
  if collectedTs and collectedTs > 0 and date then
    card.collectedDate:SetText(date("%m/%d/%Y", collectedTs))
    card.collectedDate:Show()
  else
    card.collectedDate:Hide()
  end

  local secondary
  if kind == "mount" then
    secondary = tostring(data.category or "Mount")
  else
    secondary = tostring(data.sourceCategory or data.category or data.source or "Companion")
  end
  card.itemLine:SetText(ABC_StableTrim(secondary, 38))

  ABC_StableSetBorder(card.portraitFrame, collected and 0.53 or 0.24, collected and 0.30 or 0.22, collected and 0.07 or 0.19, 1)
  ABC_StableSetTextureColor(card.centerGlow, collected and 0.20 or 0.07, collected and 0.075 or 0.07, collected and 0.020 or 0.07, 0.72)

  card.portrait:SetTexture(iconPath or ABC_STABLE_TEX_ICON_FALLBACK)
  -- The original only ever set this for the not-collected case (a fresh
  -- texture defaults to full color) -- now that the same texture is reused
  -- across different data, the collected case has to be reset explicitly
  -- too, or a card that was last shown dimmed would stay dimmed forever.
  if collected then
    card.portrait:SetVertexColor(1, 1, 1, 1)
  else
    card.portrait:SetVertexColor(0.34, 0.34, 0.34, 0.86)
  end

  if card.portraitRing then
    card.portraitRing:SetVertexColor(1, 1, 1, collected and 0.92 or 0.55)
  end

  local obtained = data and data.obtainedFrom or nil
  card.obtained = obtained
  if kind == "toy" then
    local description = data and data.description or nil
    if description and description ~= "" then
      card.sourceLabel:SetText(ABC_StableTrim(description, 78))
    else
      card.sourceLabel:SetText("")
    end
  elseif obtained and obtained ~= "" then
    card.sourceLabel:SetText("Source: "..ABC_StableTrim(obtained, 78))
  else
    card.sourceLabel:SetText("")
  end

  card.detail:SetWidth(collected and 122 or 195)
  local pointValue = tonumber(data and data.points) or 25
  local detailText = "|cFFFFD433"..tostring(pointValue).." pts|r  |  "..(kind == "mount" and tostring(data.category or "Mount") or tostring(data.sourceCategory or data.category or data.source or "Companion"))
  -- Level requirement gets its own soft-blue badge instead of blending
  -- into the plain category text as one more pipe-separated clause.
  if kind == "mount" and data.requiredLevel then detailText = detailText.."  |  |cFF6DAEDBLv "..tostring(data.requiredLevel).."|r" end
  card.detail:SetText(ABC_StableTrim(detailText, 64))

  if collected and data.spellIndex then
    card.summonBtn:SetText(kind == "mount" and "Summon" or "Call")
    card.summonBtn:Show()
  else
    card.summonBtn:Hide()
  end

  card:Show()
end

local function ABC_StableCard(parent, index, data, kind)
  local card = ABC.cardPool[index] or ABC_BuildCardSkeleton(parent, index)
  -- Cards are pooled by index and shared across every kind/view that uses
  -- this card system, including the guild-aggregate grid below -- clear its
  -- guild flag here so a card last shown on the Guild tab doesn't keep
  -- reading as one after being repopulated for a personal Mounts/Companions/
  -- Toys view.
  card.isGuildCard = false
  ABC_PopulateCard(card, parent, index, data, kind)
  table.insert(ABC.activeCards, card)
  return card
end

-- Guild-aggregate variant of ABC_StableCard: same pooled skeleton and the
-- exact same ABC_PopulateCard fill logic (data.collected is always forced
-- true by BuildGuildCollectionView, so every card renders in the warm/gold
-- "collected" treatment -- background, border, accent, portrait, source
-- line, points/category/level detail all come out identical to a personal
-- collected card), then a few fields are overridden afterward for the parts
-- that mean something different for aggregate ownership data rather than a
-- personal collected/missing state.
local function ABC_StableGuildCard(parent, index, data, kind)
  local card = ABC.cardPool[index] or ABC_BuildCardSkeleton(parent, index)
  ABC_PopulateCard(card, parent, index, data, kind)

  local ownerCount = tonumber(data and data.ownerCount) or 0
  card.status:SetText(ownerCount == 1 and "1 GUILDIE" or (tostring(ownerCount).." GUILDIES"))
  card.status:SetTextColor(0.42, 0.92, 0.34)
  -- No personal earned-date applies to an aggregate ownership card.
  card.collectedDate:Hide()
  -- Summoning someone else's mount/companion isn't a thing.
  card.summonBtn:Hide()

  card.isGuildCard = true
  card.guildOwners = data and data.owners or {}

  table.insert(ABC.activeCards, card)
  return card
end

-- Card-grid rendering, byte-for-byte the same layout system BuildCollectionView
-- uses for the personal Mounts/Companions/Toys tabs (see ABC_BuildCardSkeleton/
-- ABC_PopulateCard/ABC_StableCard below) instead of a bespoke flat list --
-- that mismatch (rows vs. cards) was the actual reason this tab kept reading
-- as "different style" through two earlier passes that only fixed the
-- sidebar/search bar. ABC_StableGuildCard (defined right after ABC_StableCard,
-- once the card-pool helpers exist) does the same get-or-build-skeleton +
-- populate + pool-track sequence, then overrides the handful of fields that
-- mean something different for aggregate guild data (owner count instead of
-- collected/missing, no per-item date, no Summon button).
function ABC:BuildGuildCollectionView()
  if not LeafVE_AchTest or not LeafVE_AchTest.UI then return end
  local ui = LeafVE_AchTest.UI
  if not ui.frame or not ui.scrollChild then return end

  ABC.buildingCollectionView = true

  ui.currentAchList = nil
  ui.currentAchOwner = nil
  if ui.achievementFrames then
    for i = 1, table.getn(ui.achievementFrames) do
      if ui.achievementFrames[i] then ui.achievementFrames[i]:Hide() end
    end
  end
  if ui.summaryFrame then ui.summaryFrame:Hide() end
  if ui.titleSummaryFrame then ui.titleSummaryFrame:Hide() end

  ABC_StableEnsureDB()
  if ABC.modelLabFrame then ABC.modelLabFrame:Hide() end
  ReleaseActiveModels()
  HideOriginalFilters(ui)
  ClearScrollChild(ui)
  ShowFrame(ui.scrollFrame)
  ShowFrame(ui.contentArt)
  -- Same reasoning as BuildCollectionView: card pages are capped to fit the
  -- viewport, so there's nothing to scroll here either.
  HideFrame(ui.scrollbar)
  HideFrame(ui.scrollTrack)
  HideFrame(ui.scrollThumb)
  HideFrame(ui.scrollUp)
  HideFrame(ui.scrollDown)
  HideFrame(ui.sidebarFrame)
  HideFrame(ui.titleSidebarFrame)
  HideFrame(ui.adminFrame)
  HideFrame(ui.companionSidebarFrame)
  HideFrame(ui.mountSidebarFrame)
  HideFrame(ui.abcMountSidebarFrame)
  HideFrame(ui.abcCompanionSidebarFrame)
  HideFrame(ui.abcToySidebarFrame)

  ShowFrame(self:EnsureGuildCollectionSidebar(ui))
  self:RefreshGuildCollectionSidebar(ui)

  -- Same search-bar dispatcher BuildCollectionView uses -- hides the mount/
  -- companion/toy search bars and shows this tab's own.
  ABC_StableShowSearch(ui, "guild")

  local kind = ABC.guildCollectionKind or "mount"
  if kind == "leaderboard" then
    self:BuildGuildLeaderboardView(ui)
    return
  end
  local dbKey = (kind == "mount" and "mounts") or (kind == "toy" and "toys") or "companions"

  -- Full master-list data (category/source/points/requiredLevel/description)
  -- for every item of this kind, keyed by name, so guild rows can carry the
  -- same rich fields personal cards show instead of just a name and count.
  local fullList = BuildSortedList(kind)
  local byName = {}
  for _, row in ipairs(fullList) do byName[row.name] = row end

  -- Only items with at least one known owner ever appear -- the bucket
  -- itself never gains a key for anything nobody's synced ownership of.
  local bucket = (LeafVE_AchTest_DB.guildCollections and LeafVE_AchTest_DB.guildCollections[dbKey]) or {}
  local query = Lower(ABC_StableSearchText("guild") or "")
  local rows = {}
  for name, owners in pairs(bucket) do
    if query == "" or string.find(Lower(name), query, 1, true) then
      local ownerNames = {}
      for playerName in pairs(owners) do table.insert(ownerNames, playerName) end
      if table.getn(ownerNames) > 0 then
        table.sort(ownerNames)
        local base = byName[name]
        local data = {}
        if base then
          for k, v in pairs(base) do data[k] = v end
        end
        data.name = name
        -- Always the "collected" (gold/warm) card variant -- everything in
        -- this list has at least one owner by construction, there's no
        -- personal locked/missing state to represent here.
        data.collected = true
        data.owners = ownerNames
        data.ownerCount = table.getn(ownerNames)
        table.insert(rows, data)
      end
    end
  end
  table.sort(rows, function(a, b)
    if a.ownerCount ~= b.ownerCount then return a.ownerCount > b.ownerCount end
    return Lower(a.name) < Lower(b.name)
  end)

  local header = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 10, -4)
  header:SetText(kind == "mount" and "Guild Mount Collection" or kind == "toy" and "Guild Toy Collection" or "Guild Companion Collection")
  header:SetTextColor(1.0, 0.82, 0.36)

  local totalRows = table.getn(rows)
  local summary = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
  summary:SetText(tostring(totalRows).." "..(kind == "mount" and "mounts" or kind == "toy" and "toys" or "companions").." owned across the guild")
  summary:SetTextColor(0.78, 0.78, 0.78)

  -- No progress bar here -- BuildCollectionView's bar tracks personal percent
  -- collected, and there's no equivalent single completion number for an
  -- aggregate guild list, so the card grid starts right under the summary
  -- line instead of leaving the bar's vertical slot empty.
  local shim = ui.abcCardShim
  if not shim then
    shim = CreateFrame("Frame", nil, ui.scrollChild)
    ui.abcCardShim = shim
  end
  shim:SetParent(ui.scrollChild)
  shim:ClearAllPoints()
  shim:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -14)
  shim:SetWidth(690); shim:SetHeight(1)
  shim:Show()

  local firstCardY = 60
  if shim.GetTop and ui.scrollChild.GetTop then
    local shimTop, childTop = shim:GetTop(), ui.scrollChild:GetTop()
    if shimTop and childTop then firstCardY = childTop - shimTop end
  end

  if totalRows == 0 then
    -- Same reasoning as BuildCollectionView's own empty branch: no card gets
    -- populated below, so without this, whatever the previous tab (a
    -- personal Mounts/Companions/Toys view, or a different guild sub-kind)
    -- left shown in the pool stayed visible right through this empty state
    -- instead of the grid actually clearing.
    for i = 1, table.getn(ABC.cardPool) do
      if ABC.cardPool[i] then ABC.cardPool[i]:Hide() end
    end
    local bucketHasAny = false
    for _ in pairs(bucket) do bucketHasAny = true; break end
    local empty = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    empty:SetPoint("TOPLEFT", shim, "TOPLEFT", 18, -22)
    empty:SetWidth(640); empty:SetJustifyH("LEFT")
    if query ~= "" and bucketHasAny then
      empty:SetText("No results found. Try a different search.")
    else
      empty:SetText("No guild data yet -- it fills in as guildies log in with an updated addon.")
    end
    empty:SetTextColor(1.0, 0.82, 0.36)
    SetScrollHeight(ui, 420)
    ABC.buildingCollectionView = false
    return
  end

  local perPage = self.cardsPerPage or 6
  local totalPages = math.ceil(math.max(totalRows, 1) / perPage)
  if totalPages < 1 then totalPages = 1 end
  -- Single shared page counter for all three guild sub-kinds (not per-kind)
  -- to match the search box's own ABC.pages["guild"] = 1 reset on text
  -- change/clear (ABC_StableGetSearchFrame above) -- keeping one key means
  -- that reset actually reaches the counter this view reads, instead of a
  -- per-kind key the search box doesn't know to touch.
  local page = tonumber(self.pages.guild) or 1
  if page < 1 then page = 1 end
  if page > totalPages then page = totalPages end
  self.pages.guild = page

  local firstIndex = (page - 1) * perPage + 1
  local lastIndex = math.min(firstIndex + perPage - 1, totalRows)
  local localIndex = 1
  for i = firstIndex, lastIndex do
    local rowData = rows[i]
    local ok, err = pcall(ABC_StableGuildCard, shim, localIndex, rowData, kind)
    if not ok then
      Print("Guild card error for "..tostring(rowData and rowData.name or "Unknown")..": "..tostring(err))
      CreateCardFailure(shim, localIndex, rowData, err)
    end
    localIndex = localIndex + 1
  end
  for i = localIndex, table.getn(ABC.cardPool) do
    if ABC.cardPool[i] then ABC.cardPool[i]:Hide() end
  end

  local maxRows = math.ceil(perPage / 3)
  local pagerY = firstCardY + maxRows * 187 + 8

  local pageText = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageText:SetWidth(70); pageText:SetJustifyH("CENTER")
  pageText:SetPoint("TOP", ui.scrollChild, "TOPLEFT", 345, -pagerY)
  pageText:SetText("Page "..tostring(page).." / "..tostring(totalPages))
  pageText:SetTextColor(0.85, 0.78, 0.62)

  local prevBtn = CreateFrame("Button", nil, ui.scrollChild)
  prevBtn:SetWidth(24); prevBtn:SetHeight(24)
  prevBtn:SetPoint("RIGHT", pageText, "LEFT", -8, 0)
  prevBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
  prevBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
  prevBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  prevBtn:SetScript("OnClick", function()
    ABC.pages.guild = math.max((tonumber(ABC.pages.guild) or 1) - 1, 1)
    ABC:BuildGuildCollectionView()
  end)
  if page <= 1 then
    prevBtn:Disable()
    prevBtn:SetAlpha(0.35)
  end

  local nextBtn = CreateFrame("Button", nil, ui.scrollChild)
  nextBtn:SetWidth(24); nextBtn:SetHeight(24)
  nextBtn:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
  nextBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  nextBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
  nextBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  nextBtn:SetScript("OnClick", function()
    ABC.pages.guild = math.min((tonumber(ABC.pages.guild) or 1) + 1, totalPages)
    ABC:BuildGuildCollectionView()
  end)
  if page >= totalPages then
    nextBtn:Disable()
    nextBtn:SetAlpha(0.35)
  end

  SetScrollHeight(ui, pagerY + 24 + 10)
  ABC.buildingCollectionView = false
end

-- Guild-wide "top collectors" leaderboard: ranks players by how many
-- distinct mounts/companions/toys they own, one top-10 column per kind,
-- built by inverting the same guildCollections[dbKey][itemName][playerName]
-- = true tables the item-grid view above reads. Reuses the "guild" search
-- box as a player-name filter instead of an item-name one.
function ABC:BuildGuildLeaderboardView(ui)
  local header = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 10, -4)
  header:SetText("Guild Collector Leaderboard")
  header:SetTextColor(1.0, 0.82, 0.36)

  local summary = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
  summary:SetText("Top 10 collectors by distinct mounts, companions, and toys owned")
  summary:SetTextColor(0.78, 0.78, 0.78)

  local query = Lower(ABC_StableSearchText("guild") or "")

  local columns = {
    {dbKey = "mounts", title = "Top Mount Collectors"},
    {dbKey = "companions", title = "Top Companion Collectors"},
    {dbKey = "toys", title = "Top Toy Collectors"},
  }

  local columnWidth = 220
  local startX = 10
  local startY = 60
  local rowHeight = 16

  for colIndex = 1, table.getn(columns) do
    local col = columns[colIndex]
    local bucket = (LeafVE_AchTest_DB.guildCollections and LeafVE_AchTest_DB.guildCollections[col.dbKey]) or {}

    -- Invert item->owners into player->count.
    local counts = {}
    for _, owners in pairs(bucket) do
      for playerName in pairs(owners) do
        counts[playerName] = (counts[playerName] or 0) + 1
      end
    end

    local ranked = {}
    for playerName, count in pairs(counts) do
      if query == "" or string.find(Lower(playerName), query, 1, true) then
        table.insert(ranked, {name = playerName, count = count})
      end
    end
    table.sort(ranked, function(a, b)
      if a.count ~= b.count then return a.count > b.count end
      return Lower(a.name) < Lower(b.name)
    end)

    local x = startX + (colIndex - 1) * columnWidth

    local colTitle = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colTitle:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", x, -startY)
    colTitle:SetText(col.title)
    colTitle:SetTextColor(1.0, 0.82, 0.36)

    if table.getn(ranked) == 0 then
      local emptyText = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      emptyText:SetPoint("TOPLEFT", colTitle, "BOTTOMLEFT", 4, -8)
      emptyText:SetWidth(columnWidth - 14)
      emptyText:SetJustifyH("LEFT")
      emptyText:SetText(query ~= "" and "No matches." or "No guild data yet.")
      emptyText:SetTextColor(0.6, 0.6, 0.6)
    else
      local limit = math.min(10, table.getn(ranked))
      for i = 1, limit do
        local entry = ranked[i]
        local rowText = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowText:SetPoint("TOPLEFT", colTitle, "BOTTOMLEFT", 4, -8 - (i - 1) * rowHeight)
        rowText:SetWidth(columnWidth - 14)
        rowText:SetJustifyH("LEFT")
        local rankColor = (i == 1 and "|cFFFFD700") or (i == 2 and "|cFFC0C0C0") or (i == 3 and "|cFFCD7F32") or "|cFFFFFFFF"
        rowText:SetText(rankColor..tostring(i)..".|r "..tostring(entry.name).." |cFF88CCFF("..tostring(entry.count)..")|r")
      end
    end
  end

  SetScrollHeight(ui, startY + 10 * rowHeight + 40)
  ABC.buildingCollectionView = false
end

function ABC:BuildCollectionView(kind)
  if not LeafVE_AchTest or not LeafVE_AchTest.UI then return end
  local ui = LeafVE_AchTest.UI
  if not ui.frame or not ui.scrollChild then return end

  -- Set for the duration of this build so the ScanSpellbook call below
  -- doesn't also trigger its own nested UI:Refresh() -- on a first-ever
  -- load (scanCount == 0) that used to build the whole view (header,
  -- progress bar, cards) a second time on top of the one already in
  -- progress here, which is what caused the visible flash/flicker.
  ABC.buildingCollectionView = true

  -- Collection cards exclusively own the scroll child on these tabs. Clear
  -- stale virtual-list state so no achievement rows can be resurrected by a
  -- scrollbar callback.
  ui.currentAchList = nil
  ui.currentAchOwner = nil
  if ui.achievementFrames then
    for i = 1, table.getn(ui.achievementFrames) do
      if ui.achievementFrames[i] then ui.achievementFrames[i]:Hide() end
    end
  end
  -- Many call sites (filter-chip clicks on this same tab, etc.) call this
  -- directly rather than through UI:Refresh, so its own summaryFrame:Hide()
  -- never runs for those -- hidden here too so nothing from the Summary
  -- tab can be left showing regardless of how this got called.
  if ui.summaryFrame then ui.summaryFrame:Hide() end
  if ui.titleSummaryFrame then ui.titleSummaryFrame:Hide() end

  ABC_StableEnsureDB()
  if ABC.modelLabFrame then ABC.modelLabFrame:Hide() end
  ReleaseActiveModels()
  HideOriginalFilters(ui)
  ClearScrollChild(ui)
  ShowFrame(ui.scrollFrame)
  ShowFrame(ui.contentArt)
  -- Card pages are capped to always fit within the viewport (see the
  -- BuildCollectionView height math below), so there's never anything to
  -- scroll here. Hide the scrollbar chrome instead of leaving it visible
  -- (and interactive) with nothing for it to actually do -- it would
  -- otherwise stay shown from a previous Achievements/Titles view, since
  -- the base Refresh()'s own scrollbar handling is bypassed by the early
  -- return this view is reached through.
  HideFrame(ui.scrollbar)
  HideFrame(ui.scrollTrack)
  HideFrame(ui.scrollThumb)
  HideFrame(ui.scrollUp)
  HideFrame(ui.scrollDown)
  HideFrame(ui.sidebarFrame)
  HideFrame(ui.titleSidebarFrame)
  HideFrame(ui.adminFrame)

  -- Both collection sidebars use the same screen region.  Always hide both
  -- first so a stale frame from the previous tab can never overlap the
  -- active category list.
  HideFrame(ui.abcMountSidebarFrame)
  HideFrame(ui.abcCompanionSidebarFrame)
  HideFrame(ui.abcToySidebarFrame)
  HideFrame(ui.guildCollectionSidebarFrame)

  if kind == "mount" then
    HideFrame(ui.companionSidebarFrame)
    HideFrame(ui.abcCompanionSidebarFrame)
    HideFrame(ui.abcToySidebarFrame)
    ShowFrame(self:EnsureMountSidebar(ui))
    self:RefreshMountSidebar(ui)
  elseif kind == "toy" then
    HideFrame(ui.companionSidebarFrame)
    HideFrame(ui.abcMountSidebarFrame)
    HideFrame(ui.abcCompanionSidebarFrame)
    ShowFrame(self:EnsureToySidebar(ui))
    self:RefreshToySidebar(ui)
  else
    HideFrame(ui.companionSidebarFrame)
    HideFrame(ui.abcMountSidebarFrame)
    HideFrame(ui.abcToySidebarFrame)
    ShowFrame(self:EnsureCompanionSidebar(ui))
    self:RefreshCompanionSidebar(ui)
  end
  ABC_StableShowSearch(ui, kind)

  if ABC.scanCount == 0 then ABC:ScanSpellbook(false) end
  local fullList = BuildSortedList(kind)
  local list = ABC_StableFilterList(fullList, kind)

  local header = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 10, -4)
  header:SetText(kind == "mount" and "Mount Collection" or kind == "toy" and "Toy Collection" or "Companion Collection")
  header:SetTextColor(1.0, 0.82, 0.36)

  local collected = 0
  for _, row in ipairs(fullList) do if row.collected then collected = collected + 1 end end
  local summary = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summary:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
  local suffix = table.getn(list) ~= table.getn(fullList) and ("  -  "..tostring(table.getn(list)).." shown") or ""
  summary:SetText(tostring(collected).." / "..tostring(table.getn(fullList)).." collected"..suffix)
  summary:SetTextColor(0.78, 0.78, 0.78)

  -- Pooled/reused across rebuilds instead of created fresh every call --
  -- a brand-new StatusBar can render fully-filled for one frame before
  -- SetValue visually takes effect (its fill-texture crop depends on the
  -- frame already having been laid out once), which is what was showing
  -- up as a flash on first load. A reused bar has already been through
  -- that once, so updating its value never hits this.
  local barKey = kind == "mount" and "abcMountBar" or kind == "toy" and "abcToyBar" or "abcCompanionBar"
  local bar = ui[barKey]
  if not bar then
    bar = CreateFrame("StatusBar", nil, ui.scrollChild)
    bar:SetWidth(160); bar:SetHeight(7)
    bar:SetStatusBarTexture(ABC_STABLE_TEX_STATUS)
    -- Ashen gold, matching the achievement/title progress bars instead of
    -- this tab's previous orange-red.
    bar:SetStatusBarColor(0.93, 0.76, 0.20)
    local barBg = ABC_StableMakeSolid(bar, "BACKGROUND")
    barBg:SetAllPoints(bar)
    ABC_StableSetTextureColor(barBg, 0.10, 0.08, 0.06, 0.95)
    ui[barKey] = bar
  end
  bar:SetParent(ui.scrollChild)
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -5)
  bar:SetMinMaxValues(0, math.max(table.getn(fullList), 1))
  bar:SetValue(collected)
  bar:Show()

  local refresh = CreateFrame("Button", nil, ui.scrollChild, "UIPanelButtonTemplate")
  refresh:SetWidth(62); refresh:SetHeight(22)
  refresh:SetPoint("TOPRIGHT", ui.scrollChild, "TOPRIGHT", -10, -1)
  refresh:SetText("Rescan")
  refresh:SetScript("OnClick", function() ABC:ScanSpellbook(true) end)
  refresh:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("Rescan Spellbook", 1, 0.82, 0.36)
    GameTooltip:AddLine("Re-checks your spellbook for "..(kind == "mount" and "mounts" or kind == "toy" and "toys" or "companions").." the addon may have missed.", 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
  end)
  refresh:SetScript("OnLeave", function() GameTooltip:Hide() end)
  if LeafVE_AchTest.SkinAshenButton then LeafVE_AchTest.SkinAshenButton(refresh) end

  local perPage = self.cardsPerPage or 6
  local totalPages = math.ceil(math.max(table.getn(list), 1) / perPage)
  if totalPages < 1 then totalPages = 1 end
  local page = tonumber(self.pages[kind]) or 1
  if page < 1 then page = 1 end
  if page > totalPages then page = totalPages end
  self.pages[kind] = page

  -- Anchored to the progress bar's actual bottom edge (not a guessed fixed
  -- offset) so the card grid always starts right after the header/summary/
  -- bar block regardless of font metrics -- no overlap, no wasted space.
  -- Pooled the same way `bar` above already is: the cards parent to this,
  -- so recreating it fresh every call (as before) would leave every
  -- previous call's cards hanging off an abandoned parent frame instead of
  -- the reused card pool actually being reachable from the current one.
  local shim = ui.abcCardShim
  if not shim then
    shim = CreateFrame("Frame", nil, ui.scrollChild)
    ui.abcCardShim = shim
  end
  shim:SetParent(ui.scrollChild)
  shim:ClearAllPoints()
  shim:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -8)
  shim:SetWidth(690); shim:SetHeight(1)
  shim:Show()

  local firstCardY = 82
  if shim.GetTop and ui.scrollChild.GetTop then
    local shimTop, childTop = shim:GetTop(), ui.scrollChild:GetTop()
    if shimTop and childTop then firstCardY = childTop - shimTop end
  end

  if table.getn(list) == 0 then
    -- No card gets populated below, so nothing else re-hides whatever the
    -- previous tab (a different kind, or Guild) left shown in the pool --
    -- without this, those stale cards stayed visible right through this
    -- empty state instead of the grid actually going empty.
    for i = 1, table.getn(ABC.cardPool) do
      if ABC.cardPool[i] then ABC.cardPool[i]:Hide() end
    end
    local empty = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    empty:SetPoint("TOPLEFT", shim, "TOPLEFT", 18, -22)
    empty:SetWidth(640); empty:SetJustifyH("LEFT")
    empty:SetText("No results found. Try a different search or category.")
    empty:SetTextColor(1.0, 0.82, 0.36)
    SetScrollHeight(ui, 420)
    ABC.buildingCollectionView = false
    return
  end

  local firstIndex = (page - 1) * perPage + 1
  local lastIndex = math.min(firstIndex + perPage - 1, table.getn(list))
  local localIndex = 1
  for i = firstIndex, lastIndex do
    local rowData = list[i]
    local ok, err = pcall(ABC_StableCard, shim, localIndex, rowData, kind)
    if not ok then
      Print("Stable 2D card error for "..tostring((rowData and rowData.name) or "Unknown")..": "..tostring(err))
      CreateCardFailure(shim, localIndex, rowData, err)
    end
    localIndex = localIndex + 1
  end
  -- A shorter last page (or a filter that now matches fewer items) means
  -- some pool slots that were shown by a previous call aren't touched by
  -- the loop above -- hide whatever's left over instead of leaving stale
  -- cards visible below wherever this page's real content ends.
  for i = localIndex, table.getn(ABC.cardPool) do
    if ABC.cardPool[i] then ABC.cardPool[i]:Hide() end
  end

  -- Pager position is derived from a full page's row count (perPage / 3
  -- columns), not however many cards actually landed on this page -- a
  -- last page with only 1 row of cards would otherwise pull the pager up
  -- to sit right under that single row instead of staying anchored near
  -- the bottom of the page like every other page.
  local maxRows = math.ceil(perPage / 3)

  -- Page controls centered below the card grid, its own row instead of
  -- crammed into the header next to Rescan. Real spellbook page-turn
  -- arrows instead of plain text buttons.
  local pagerY = firstCardY + maxRows * 187 + 8

  local pageText = ui.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageText:SetWidth(70); pageText:SetJustifyH("CENTER")
  pageText:SetPoint("TOP", ui.scrollChild, "TOPLEFT", 345, -pagerY)
  pageText:SetText("Page "..tostring(page).." / "..tostring(totalPages))
  pageText:SetTextColor(0.85, 0.78, 0.62)

  local prevBtn = CreateFrame("Button", nil, ui.scrollChild)
  prevBtn:SetWidth(24); prevBtn:SetHeight(24)
  prevBtn:SetPoint("RIGHT", pageText, "LEFT", -8, 0)
  prevBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
  prevBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
  prevBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  prevBtn:SetScript("OnClick", function()
    ABC.pages[kind] = math.max((tonumber(ABC.pages[kind]) or 1) - 1, 1)
    ABC:BuildCollectionView(kind)
  end)
  if page <= 1 then
    prevBtn:Disable()
    prevBtn:SetAlpha(0.35)
  end

  local nextBtn = CreateFrame("Button", nil, ui.scrollChild)
  nextBtn:SetWidth(24); nextBtn:SetHeight(24)
  nextBtn:SetPoint("LEFT", pageText, "RIGHT", 8, 0)
  nextBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  nextBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
  nextBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  nextBtn:SetScript("OnClick", function()
    ABC.pages[kind] = math.min((tonumber(ABC.pages[kind]) or 1) + 1, totalPages)
    ABC:BuildCollectionView(kind)
  end)
  if page >= totalPages then
    nextBtn:Disable()
    nextBtn:SetAlpha(0.35)
  end

  SetScrollHeight(ui, pagerY + 24 + 10)
  ABC.buildingCollectionView = false
end

ABC.Help = function(self)
  Print("Commands:")
  Print("/abcoll scan - rescan Turtle spellbook collections")
  Print("/abcoll dump - print detected collection entries")
  Print("/abcoll open - open/rebuild the collection window")
  Print("This build is 2D-only; model lab and 3D commands are disabled.")
end

SlashCmdList["ASHENBANNERCOLLECTIONS"] = function(msg)
  msg = Trim(msg or "")
  local lmsg = Lower(msg)
  if msg == "" or lmsg == "help" then ABC:Help()
  elseif lmsg == "scan" then ABC:ScanSpellbook(true)
  elseif lmsg == "dump" then ABC:ScanSpellbook(false); ABC:PrintDump()
  elseif lmsg == "open" then
    if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.Build then LeafVE_AchTest.UI:Build() end
  else ABC:Help() end
end

ABC_MOUNT_ICON_REFRESH = CreateFrame("Frame", nil, UIParent)
ABC_MOUNT_ICON_REFRESH.pending = false
ABC_MOUNT_ICON_REFRESH.elapsed = 0
ABC_MOUNT_ICON_REFRESH.attempts = 0
pcall(function() ABC_MOUNT_ICON_REFRESH:RegisterEvent("GET_ITEM_INFO_RECEIVED") end)
ABC_MOUNT_ICON_REFRESH:SetScript("OnEvent", function()
  if LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView == "mounts" then
    this.pending = true
    this.elapsed = 0
    this.attempts = 0
    this:Show()
  end
end)
ABC_MOUNT_ICON_REFRESH:SetScript("OnUpdate", function()
  if not this.pending then this:Hide(); return end
  this.elapsed = (this.elapsed or 0) + (arg1 or 0)
  if this.elapsed < 0.50 then return end
  this.elapsed = 0
  this.attempts = (this.attempts or 0) + 1
  if ABC and ABC.BuildCollectionView and LeafVE_AchTest and LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView == "mounts" then
    ABC:BuildCollectionView("mount")
  end
  if this.attempts >= 4 then
    this.pending = false
    this:Hide()
  end
end)
ABC_MOUNT_ICON_REFRESH:Hide()

ABC_StableEnsureDB()
ABC:PurgeRejectedMountData()
Print("Integrated 2D collections loaded. Verified mount-family icons are active.")
