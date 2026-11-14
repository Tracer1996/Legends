-- LeafVE_Ach_Relationships.lua
-- Port of RelationshipAchievements database and event logic into LeafVillageAchievements.

local RA_TO_LEAFVE = {
  [101] = "ra_101",
  [102] = "ra_102",
  [103] = "casual_guild_join",
  [104] = "ra_104",
  [105] = "ra_105",
  [106] = "ra_106",
  [107] = "ra_107",
  [108] = "ra_108",
  [109] = "ra_109",
  [110] = "ra_110",
  [111] = "ra_111",
  [201] = "lvl_10",
  [202] = "lvl_20",
  [203] = "lvl_30",
  [204] = "lvl_40",
  [205] = "lvl_50",
  [206] = "lvl_60",
  [207] = "ra_207",
  [208] = "ra_208",
  [209] = "ra_209",
  [210] = "ra_210",
  [211] = "casual_mount_60",
  [212] = "casual_epic_mount",
  [213] = "casual_deaths_100",
  [214] = "kill_1000",
  [215] = "kill_10000",
  [216] = "lvl_05",
  [217] = "ra_217",
  [218] = "lvl_15",
  [219] = "lvl_25",
  [220] = "lvl_35",
  [221] = "lvl_45",
  [222] = "lvl_55",
  [223] = "ra_223",
  [224] = "ra_224",
  [301] = "ra_301",
  [302] = "ra_302",
  [303] = "ra_303",
  [304] = "casual_quest_100",
  [305] = "quest_250",
  [306] = "casual_quest_500",
  [307] = "casual_quest_1000",
  [308] = "quest_2000",
  [309] = "ra_309",
  [310] = "ra_310",
  [311] = "ra_311",
  [312] = "ra_312",
  [313] = "ra_313",
  [401] = "ra_401",
  [402] = "ra_402",
  [403] = "ra_403",
  [404] = "ra_404",
  [405] = "ra_405",
  [406] = "ra_406",
  [407] = "ra_407",
  [408] = "ra_408",
  [409] = "ra_409",
  [410] = "ra_410",
  [411] = "ra_411",
  [412] = "ra_412",
  [413] = "ra_413",
  [414] = "ra_414",
  [415] = "ra_415",
  [416] = "ra_416",
  [417] = "ra_417",
  [418] = "ra_418",
  [419] = "ra_419",
  [420] = "ra_420",
  [421] = "ra_421",
  [422] = "ra_422",
  [423] = "ra_423",
  [424] = "ra_424",
  [425] = "ra_425",
  [426] = "ra_426",
  [427] = "ra_427",
  [428] = "ra_428",
  [429] = "ra_429",
  [430] = "ra_430",
  [431] = "ra_431",
  [432] = "ra_432",
  [433] = "ra_433",
  [434] = "ra_434",
  [435] = "ra_435",
  [436] = "ra_436",
  [437] = "ra_437",
  [450] = "ra_450",
  [451] = "ra_451",
  [501] = "ra_501",
  [502] = "pvp_hk_100",
  [503] = "pvp_hk_1000",
  [504] = "pvp_hk_10000",
  [505] = "ra_505",
  [506] = "ra_506",
  [507] = "ra_507",
  [508] = "pvp_duel_10",
  [509] = "pvp_duel_100",
  [510] = "pvp_wsg_win_10",
  [511] = "pvp_av_win_10",
  [512] = "pvp_ab_win_10",
  [513] = "ra_513",
  [514] = "ra_514",
  [515] = "ra_515",
  [601] = "ra_601",
  [602] = "ra_602",
  [603] = "ra_603",
  [604] = "ra_604",
  [605] = "ra_605",
  [606] = "ra_606",
  [607] = "ra_607",
  [608] = "ra_608",
  [609] = "ra_609",
  [610] = "ra_610",
  [611] = "ra_611",
  [612] = "ra_612",
  [613] = "ra_613",
  [614] = "ra_614",
  [615] = "ra_615",
  [616] = "ra_616",
  [617] = "ra_617",
  [618] = "ra_618",
  [619] = "ra_619",
  [620] = "ra_620",
  [621] = "ra_621",
  [622] = "ra_622",
  [650] = "ra_650",
  [651] = "ra_651",
  [652] = "ra_652",
  [653] = "ra_653",
  [654] = "ra_654",
  [655] = "ra_655",
  [656] = "ra_656",
  [680] = "ra_680",
  [681] = "ra_681",
  [682] = "ra_682",
  [683] = "ra_683",
  [684] = "ra_684",
  [701] = "ra_701",
  [702] = "ra_702",
  [703] = "ra_703",
  [704] = "ra_704",
  [707] = "prof_firstaid_300",
  [708] = "prof_alchemy_300",
  [709] = "prof_blacksmithing_300",
  [710] = "prof_enchanting_300",
  [711] = "prof_engineering_300",
  [712] = "prof_herbalism_300",
  [713] = "prof_leatherworking_300",
  [714] = "prof_mining_300",
  [715] = "prof_skinning_300",
  [716] = "prof_tailoring_300",
  [801] = "ra_801",
  [802] = "ra_802",
  [803] = "ra_803",
  [804] = "reputation_exalted_1",
  [805] = "reputation_exalted_5",
  [806] = "reputation_exalted_10",
  [807] = "ra_807",
  [808] = "ra_808",
  [809] = "ra_809",
  [810] = "ra_810",
  [811] = "ra_811",
  [812] = "ra_812",
  [813] = "ra_813",
  [901] = "ra_901",
  [902] = "ra_902",
  [903] = "ra_903",
  [904] = "ra_904",
  [905] = "ra_905",
  [906] = "ra_906",
  [907] = "ra_907",
  [908] = "ra_908",
  [909] = "ra_909",
  [910] = "ra_910",
  [911] = "ra_911",
  [1001] = "ra_1001",
  [1002] = "ra_1002",
  [1003] = "ra_1003",
  [1004] = "ra_1004",
  [1005] = "ra_1005",
  [1006] = "ra_1006",
  [1101] = "ra_1101",
  [1102] = "ra_1102",
  [1103] = "ra_1103",
  [1104] = "ra_1104",
  [1105] = "ra_1105",
  [1106] = "ra_1106",
  [1107] = "ra_1107",
  [1108] = "ra_1108",
  [1109] = "ra_1109",
  [1110] = "ra_1110",
  [1111] = "ra_1111",
  [1112] = "ra_1112",
  [1113] = "ra_1113",
  [1201] = "ra_1201",
  [1202] = "ra_1202",
  [1203] = "ra_1203",
  [1204] = "ra_1204",
  [1205] = "casual_pet_collector",
  [1206] = "ra_1206",
  [1207] = "ra_1207",
  [1208] = "ra_1208",
  [1209] = "ra_1209",
  [1301] = "ra_1301",
  [1302] = "ra_1302",
  [1303] = "ra_1303",
  [1304] = "ra_1304",
  [1305] = "ra_1305",
  [1306] = "ra_1306",
  [1307] = "ra_1307",
  [1308] = "ra_1308",
  [1309] = "ra_1309",
  [1401] = "casual_fish_1",
  [1402] = "ra_1402",
  [1403] = "prof_fishing_300",
  [1404] = "ra_1404",
  [1405] = "ra_1405",
  [1406] = "ra_1406",
  [1501] = "casual_first_dish",
  [1502] = "ra_1502",
  [1503] = "prof_cooking_300",
  [1504] = "ra_1504",
  [1505] = "ra_1505",
  [1506] = "ra_1506",
  [1601] = "ra_1601",
  [1602] = "ra_1602",
  [1603] = "ra_1603",
  [1604] = "ra_1604",
  [1605] = "ra_1605",
  [1606] = "ra_1606",
  [1701] = "ra_1701",
  [1702] = "ra_1702",
  [1703] = "ra_1703",
  [1704] = "ra_1704",
  [1705] = "ra_1705",
  [1706] = "ra_1706",
  [1707] = "ra_1707",
  [1801] = "ra_1801",
  [1802] = "ra_1802",
  [1803] = "ra_1803",
  [1804] = "ra_1804",
  [1805] = "ra_1805",
  [1806] = "ra_1806",
  [1807] = "ra_1807",
  [1808] = "ra_1808",
  [1901] = "ra_1901",
  [1902] = "ra_1902",
  [1903] = "ra_1903",
  [1904] = "ra_1904",
  [1905] = "ra_1905",
  [1906] = "ra_1906",
  [1907] = "ra_1907",
  [2001] = "ra_2001",
  [2002] = "ra_2002",
  [2003] = "ra_2003",
  [2004] = "ra_2004",
  [2005] = "ra_2005",
  [2006] = "ra_2006",
  [2007] = "ra_2007",
  [2008] = "ra_2008",
  [2101] = "ra_2101",
  [2102] = "ra_2102",
  [2103] = "ra_2103",
  [2104] = "ra_2104",
  [2105] = "ra_2105",
  [2106] = "ra_2106",
  [2107] = "ra_2107",
}

local RA_scanReady = false

local function AwardRA(id)
  local leafId = RA_TO_LEAFVE[id]
  if leafId and LeafVE_AchTest and LeafVE_AchTest.AwardAchievement then
    LeafVE_AchTest:AwardAchievement(leafId, not RA_scanReady)
  end
end

local function RA_CheckProgress()
  if LeafVE_AchTest and LeafVE_AchTest.CheckCachedProgressAchievements then
    LeafVE_AchTest:CheckCachedProgressAchievements(not RA_scanReady)
  end
end

local function RegisterRelationshipAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  LeafVE_AchTest:AddAchievement("ra_101", {
    id="ra_101",
    name="The Stormwind Rendezvous",
    desc="Log in for the first time.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_102", {
    id="ra_102",
    name="Making Friends",
    desc="Add a friend to your friends list.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_104", {
    id="ra_104",
    name="Well Read",
    desc="Read the achievement panel for the first time.",
    category="General",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_105", {
    id="ra_105",
    name="Party Time",
    desc="Join a party.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_106", {
    id="ra_106",
    name="Money in the Bank",
    desc="Use a bank for the first time.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_107", {
    id="ra_107",
    name="Big Spender",
    desc="Purchase an item from an auction house.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_108", {
    id="ra_108",
    name="Take a Chill Pill",
    desc="Bind to an inn.",
    category="General",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_109", {
    id="ra_109",
    name="Represent",
    desc="Equip a tabard.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_110", {
    id="ra_110",
    name="Mailbox Hero",
    desc="Send your first piece of mail.",
    category="General",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_111", {
    id="ra_111",
    name="Trainee",
    desc="Visit a class trainer.",
    category="General",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_207", {
    id="ra_207",
    name="First Death",
    desc="Die for the first time. It happens to everyone.",
    category="Character",
    points=5,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_208", {
    id="ra_208",
    name="Got My Mind On My Money",
    desc="Loot 100 gold.",
    category="Character",
    points=10,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_209", {
    id="ra_209",
    name="Got My Mind On My Money II",
    desc="Loot 1,000 gold.",
    category="Character",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_210", {
    id="ra_210",
    name="Got My Mind On My Money III",
    desc="Loot 10,000 gold.",
    category="Character",
    points=50,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_217", {
    id="ra_217",
    name="Weapon Master",
    desc="Reach 300 skill in a weapon.",
    category="Character",
    points=10,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_301", {
    id="ra_301",
    name="The First Step",
    desc="Complete 1 quest.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_302", {
    id="ra_302",
    name="10 Quests Completed",
    desc="Complete 10 quests.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_303", {
    id="ra_303",
    name="50 Quests Completed",
    desc="Complete 50 quests.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_309", {
    id="ra_309",
    name="Daily Chores",
    desc="Complete a daily quest.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_401", {
    id="ra_401",
    name="Explore Elwynn Forest",
    desc="Explore Elwynn Forest.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_402", {
    id="ra_402",
    name="Explore Westfall",
    desc="Explore Westfall.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_403", {
    id="ra_403",
    name="Explore Duskwood",
    desc="Explore Duskwood.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_404", {
    id="ra_404",
    name="Explore Redridge Mountains",
    desc="Explore Redridge Mountains.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_405", {
    id="ra_405",
    name="Explore Stranglethorn Vale",
    desc="Explore Stranglethorn Vale.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_406", {
    id="ra_406",
    name="Explore Blasted Lands",
    desc="Explore the Blasted Lands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_407", {
    id="ra_407",
    name="Explore Burning Steppes",
    desc="Explore the Burning Steppes.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_408", {
    id="ra_408",
    name="Explore Searing Gorge",
    desc="Explore Searing Gorge.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_409", {
    id="ra_409",
    name="Explore Loch Modan",
    desc="Explore Loch Modan.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_410", {
    id="ra_410",
    name="Explore Wetlands",
    desc="Explore the Wetlands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_411", {
    id="ra_411",
    name="Explore Arathi Highlands",
    desc="Explore Arathi Highlands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_412", {
    id="ra_412",
    name="Explore Hillsbrad Foothills",
    desc="Explore Hillsbrad Foothills.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_413", {
    id="ra_413",
    name="Explore Silverpine Forest",
    desc="Explore Silverpine Forest.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_414", {
    id="ra_414",
    name="Explore Tirisfal Glades",
    desc="Explore Tirisfal Glades.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_415", {
    id="ra_415",
    name="Explore Western Plaguelands",
    desc="Explore Western Plaguelands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_416", {
    id="ra_416",
    name="Explore Eastern Plaguelands",
    desc="Explore Eastern Plaguelands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_417", {
    id="ra_417",
    name="Explore The Hinterlands",
    desc="Explore The Hinterlands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_418", {
    id="ra_418",
    name="Explore Badlands",
    desc="Explore the Badlands.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_419", {
    id="ra_419",
    name="Explore Swamp of Sorrows",
    desc="Explore the Swamp of Sorrows.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_420", {
    id="ra_420",
    name="Explore Deadwind Pass",
    desc="Explore Deadwind Pass.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_421", {
    id="ra_421",
    name="Explore Durotar",
    desc="Explore Durotar.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_422", {
    id="ra_422",
    name="Explore The Barrens",
    desc="Explore The Barrens.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_423", {
    id="ra_423",
    name="Explore Ashenvale",
    desc="Explore Ashenvale.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_424", {
    id="ra_424",
    name="Explore Feralas",
    desc="Explore Feralas.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_425", {
    id="ra_425",
    name="Explore Tanaris",
    desc="Explore Tanaris.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_426", {
    id="ra_426",
    name="Explore Silithus",
    desc="Explore Silithus.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_427", {
    id="ra_427",
    name="Explore Winterspring",
    desc="Explore Winterspring.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_428", {
    id="ra_428",
    name="Explore Un'Goro Crater",
    desc="Explore Un'Goro Crater.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_429", {
    id="ra_429",
    name="Explore Mulgore",
    desc="Explore Mulgore.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_430", {
    id="ra_430",
    name="Explore Teldrassil",
    desc="Explore Teldrassil.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_431", {
    id="ra_431",
    name="Explore Darkshore",
    desc="Explore Darkshore.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_432", {
    id="ra_432",
    name="Explore Stonetalon Mountains",
    desc="Explore Stonetalon Mountains.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_433", {
    id="ra_433",
    name="Explore Desolace",
    desc="Explore Desolace.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_434", {
    id="ra_434",
    name="Explore Dustwallow Marsh",
    desc="Explore Dustwallow Marsh.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_435", {
    id="ra_435",
    name="Explore Thousand Needles",
    desc="Explore Thousand Needles.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_436", {
    id="ra_436",
    name="Explore Azshara",
    desc="Explore Azshara.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_437", {
    id="ra_437",
    name="Explore Moonglade",
    desc="Explore Moonglade.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_450", {
    id="ra_450",
    name="World Explorer",
    desc="Explore all 37 listed zones of Azeroth.",
    category="Exploration",
    points=50,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_451", {
    id="ra_451",
    name="Well Traveled",
    desc="Visit 10 zones.",
    category="Exploration",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Map_01",
  })
  LeafVE_AchTest:AddAchievement("ra_501", {
    id="ra_501",
    name="First Blood",
    desc="Deliver a killing blow to an enemy player.",
    category="PvP",
    points=10,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_505", {
    id="ra_505",
    name="Warsong Gulch Victory",
    desc="Win a Warsong Gulch match.",
    category="PvP",
    points=10,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_506", {
    id="ra_506",
    name="Alterac Valley Victory",
    desc="Win an Alterac Valley match.",
    category="PvP",
    points=10,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_507", {
    id="ra_507",
    name="Arathi Basin Victory",
    desc="Win an Arathi Basin match.",
    category="PvP",
    points=10,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_513", {
    id="ra_513",
    name="Blood Sport",
    desc="Kill an enemy player of your own level or higher.",
    category="PvP",
    points=10,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_514", {
    id="ra_514",
    name="Bloodthirsty",
    desc="Get 50 killing blows on enemy players.",
    category="PvP",
    points=15,
    icon="Interface\\Icons\\Ability_PVP",
  })
  LeafVE_AchTest:AddAchievement("ra_601", {
    id="ra_601",
    name="Ragefire Chasm",
    desc="Defeat Taragaman the Hungerer in Ragefire Chasm.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_602", {
    id="ra_602",
    name="The Deadmines",
    desc="Defeat Edwin VanCleef in the Deadmines.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_603", {
    id="ra_603",
    name="Wailing Caverns",
    desc="Defeat Mutanus the Devourer.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_604", {
    id="ra_604",
    name="Shadowfang Keep",
    desc="Defeat Archmage Arugal.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_605", {
    id="ra_605",
    name="The Stockade",
    desc="Defeat Bazil Thredd in The Stockade.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_606", {
    id="ra_606",
    name="Blackfathom Deeps",
    desc="Defeat Aku'mai.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_607", {
    id="ra_607",
    name="Razorfen Kraul",
    desc="Defeat Charlga Razorflank.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_608", {
    id="ra_608",
    name="Gnomeregan",
    desc="Defeat Mekgineer Thermaplugg.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_609", {
    id="ra_609",
    name="Razorfen Downs",
    desc="Defeat Amnennar the Coldbringer.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_610", {
    id="ra_610",
    name="Scarlet Monastery",
    desc="Defeat Scarlet Commander Mograine and High Inquisitor Whitemane.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_611", {
    id="ra_611",
    name="Uldaman",
    desc="Defeat Archaedas.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_612", {
    id="ra_612",
    name="Zul'Farrak",
    desc="Defeat Chief Ukorz Sandscalp.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_613", {
    id="ra_613",
    name="Maraudon",
    desc="Defeat Princess Theradras.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_614", {
    id="ra_614",
    name="Sunken Temple",
    desc="Defeat Shade of Eranikus.",
    category="Dungeons",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_615", {
    id="ra_615",
    name="Blackrock Depths",
    desc="Defeat Emperor Dagran Thaurissan.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_616", {
    id="ra_616",
    name="Lower Blackrock Spire",
    desc="Defeat Overlord Wyrmthalak.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_617", {
    id="ra_617",
    name="Upper Blackrock Spire",
    desc="Defeat General Drakkisath.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_618", {
    id="ra_618",
    name="Stratholme",
    desc="Defeat Baron Rivendare.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_619", {
    id="ra_619",
    name="Scholomance",
    desc="Defeat Darkmaster Gandling.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_620", {
    id="ra_620",
    name="Dire Maul: East",
    desc="Defeat Alzzin the Wildshaper.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_621", {
    id="ra_621",
    name="Dire Maul: West",
    desc="Defeat Prince Tortheldrin.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_622", {
    id="ra_622",
    name="Dire Maul: North",
    desc="Defeat King Gordok.",
    category="Dungeons",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_650", {
    id="ra_650",
    name="Molten Core",
    desc="Defeat Ragnaros in the Molten Core.",
    category="Raids",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_651", {
    id="ra_651",
    name="Onyxia's Lair",
    desc="Defeat Onyxia.",
    category="Raids",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_652", {
    id="ra_652",
    name="Blackwing Lair",
    desc="Defeat Nefarian in Blackwing Lair.",
    category="Raids",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_653", {
    id="ra_653",
    name="Zul'Gurub",
    desc="Defeat Hakkar the Soulflayer.",
    category="Raids",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_654", {
    id="ra_654",
    name="Ruins of Ahn'Qiraj",
    desc="Defeat Ossirian the Unscarred.",
    category="Raids",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_655", {
    id="ra_655",
    name="Temple of Ahn'Qiraj",
    desc="Defeat C'Thun.",
    category="Raids",
    points=50,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_656", {
    id="ra_656",
    name="Naxxramas",
    desc="Defeat Kel'Thuzad in Naxxramas.",
    category="Raids",
    points=50,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_515", {
    id="ra_515",
    name="Battleground Regular",
    desc="Win 25 battlegrounds of any type.",
    category="PvP",
    points=25,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })

  LeafVE_AchTest:AddAchievement("ra_680", {
    id="ra_680",
    name="Classic Dungeonmaster",
    desc="Complete all 22 vanilla 5-man dungeon end bosses.",
    category="Dungeons",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  })
  LeafVE_AchTest:AddAchievement("ra_681", {
    id="ra_681",
    name="Classic Raider",
    desc="Defeat 5 vanilla raid end bosses.",
    category="Raids",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_682", {
    id="ra_682",
    name="Ready for BWL",
    desc="Complete the attunement to Blackwing Lair.",
    category="Raids",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_683", {
    id="ra_683",
    name="MC Attuned",
    desc="Complete the attunement to Molten Core.",
    category="Raids",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_684", {
    id="ra_684",
    name="Onyxia Attuned",
    desc="Complete the Onyxia attunement chain.",
    category="Raids",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",
  })
  LeafVE_AchTest:AddAchievement("ra_701", {
    id="ra_701",
    name="Apprentice",
    desc="Learn a primary profession.",
    category="Professions",
    points=10,
    icon="Interface\\Icons\\Trade_Engineering",
  })
  LeafVE_AchTest:AddAchievement("ra_702", {
    id="ra_702",
    name="Journeyman",
    desc="Reach 150 skill in a primary profession.",
    category="Professions",
    points=10,
    icon="Interface\\Icons\\Trade_Engineering",
  })
  LeafVE_AchTest:AddAchievement("ra_703", {
    id="ra_703",
    name="Expert",
    desc="Reach 225 skill in a primary profession.",
    category="Professions",
    points=10,
    icon="Interface\\Icons\\Trade_Engineering",
  })
  LeafVE_AchTest:AddAchievement("ra_704", {
    id="ra_704",
    name="Artisan",
    desc="Reach 300 skill in a primary profession.",
    category="Professions",
    points=25,
    icon="Interface\\Icons\\Trade_Engineering",
  })
  LeafVE_AchTest:AddAchievement("ra_801", {
    id="ra_801",
    name="Friend of a Faction",
    desc="Reach Friendly with any faction you did not start with.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_802", {
    id="ra_802",
    name="Honored",
    desc="Reach Honored with any faction.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_803", {
    id="ra_803",
    name="Revered",
    desc="Reach Revered with any faction.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_807", {
    id="ra_807",
    name="Argent Dawn",
    desc="Reach Exalted with the Argent Dawn.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_808", {
    id="ra_808",
    name="Thorium Brotherhood",
    desc="Reach Exalted with the Thorium Brotherhood.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_809", {
    id="ra_809",
    name="Timbermaw Hold",
    desc="Reach Exalted with Timbermaw Hold.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_810", {
    id="ra_810",
    name="Cenarion Circle",
    desc="Reach Exalted with the Cenarion Circle.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_811", {
    id="ra_811",
    name="Brood of Nozdormu",
    desc="Reach Exalted with the Brood of Nozdormu.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_812", {
    id="ra_812",
    name="Zandalar Tribe",
    desc="Reach Exalted with the Zandalar Tribe.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_813", {
    id="ra_813",
    name="Hydraxian Waterlords",
    desc="Reach Exalted with the Hydraxian Waterlords.",
    category="Reputation",
    points=10,
    icon="Interface\\Icons\\INV_BannerPVP_02",
  })
  LeafVE_AchTest:AddAchievement("ra_901", {
    id="ra_901",
    name="Merrymaker",
    desc="Attend the Feast of Winter Veil.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_902", {
    id="ra_902",
    name="Flame Warden",
    desc="Attend the Midsummer Fire Festival.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_903", {
    id="ra_903",
    name="Trick or Treat!",
    desc="Receive a treat on Hallow's End.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_904", {
    id="ra_904",
    name="Elders of the Dungeons",
    desc="Honor an Elder inside a dungeon.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_905", {
    id="ra_905",
    name="Noble Garden",
    desc="Attend Noblegarden.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_906", {
    id="ra_906",
    name="Love is in the Air",
    desc="Attend Love is in the Air.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_907", {
    id="ra_907",
    name="Children's Week",
    desc="Attend Children's Week.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_908", {
    id="ra_908",
    name="Harvest Festival",
    desc="Attend the Harvest Festival.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_909", {
    id="ra_909",
    name="Lunar Festival",
    desc="Attend the Lunar Festival.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_910", {
    id="ra_910",
    name="Brewmaster",
    desc="Attend Brewfest.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_911", {
    id="ra_911",
    name="Darkmoon Faire Attendee",
    desc="Visit the Darkmoon Faire.",
    category="World Events",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Gift_01",
  })
  LeafVE_AchTest:AddAchievement("ra_1001", {
    id="ra_1001",
    name="Scarab Lord",
    desc="Bang the Gong at the gates of Ahn'Qiraj.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1002", {
    id="ra_1002",
    name="Grand Marshal",
    desc="Attain the rank of Grand Marshal in the Alliance.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1003", {
    id="ra_1003",
    name="High Warlord",
    desc="Attain the rank of High Warlord in the Horde.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1004", {
    id="ra_1004",
    name="Atiesh, Greatstaff of the Guardian",
    desc="Wield Atiesh.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1005", {
    id="ra_1005",
    name="Thunderfury, Blessed Blade of the Windseeker",
    desc="Wield Thunderfury.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1006", {
    id="ra_1006",
    name="Sulfuras, Hand of Ragnaros",
    desc="Wield Sulfuras.",
    category="Feats of Strength",
    points=0,
    icon="Interface\\Icons\\Achievement_Arena_5v5_3",
  })
  LeafVE_AchTest:AddAchievement("ra_1101", {
    id="ra_1101",
    name="The Warrior's Path",
    desc="Reach level 60 as a Warrior.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1102", {
    id="ra_1102",
    name="The Paladin's Path",
    desc="Reach level 60 as a Paladin.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1103", {
    id="ra_1103",
    name="The Hunter's Path",
    desc="Reach level 60 as a Hunter.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1104", {
    id="ra_1104",
    name="The Rogue's Path",
    desc="Reach level 60 as a Rogue.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1105", {
    id="ra_1105",
    name="The Priest's Path",
    desc="Reach level 60 as a Priest.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1106", {
    id="ra_1106",
    name="The Shaman's Path",
    desc="Reach level 60 as a Shaman.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1107", {
    id="ra_1107",
    name="The Mage's Path",
    desc="Reach level 60 as a Mage.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1108", {
    id="ra_1108",
    name="The Warlock's Path",
    desc="Reach level 60 as a Warlock.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1109", {
    id="ra_1109",
    name="The Druid's Path",
    desc="Reach level 60 as a Druid.",
    category="Class",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1110", {
    id="ra_1110",
    name="Trained",
    desc="Train a new class ability.",
    category="Class",
    points=5,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1111", {
    id="ra_1111",
    name="Talented",
    desc="Spend your first talent point.",
    category="Class",
    points=10,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1112", {
    id="ra_1112",
    name="Fully Specialized",
    desc="Spend all 51 talent points.",
    category="Class",
    points=15,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1113", {
    id="ra_1113",
    name="Respec'd",
    desc="Reset your talents at a class trainer.",
    category="Class",
    points=5,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1201", {
    id="ra_1201",
    name="Pack Rat",
    desc="Equip a 16-slot bag.",
    category="Collections",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1202", {
    id="ra_1202",
    name="Bag Full of Bags",
    desc="Equip four bags at once.",
    category="Collections",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1204", {
    id="ra_1204",
    name="Little Friends",
    desc="Own a non-combat pet.",
    category="Collections",
    points=10,
    icon="Interface\\Icons\\INV_Box_PetCarrier_01",
  })

  LeafVE_AchTest:AddAchievement("ra_1203", {
    id="ra_1203",
    name="Vain",
    desc="Equip a shirt.",
    category="Collections",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1206", {
    id="ra_1206",
    name="Stable Master",
    desc="Own 5 mounts.",
    category="Collections",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1207", {
    id="ra_1207",
    name="Leading the Cavalry",
    desc="Own 25 mounts.",
    category="Collections",
    points=50,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1208", {
    id="ra_1208",
    name="Well Equipped",
    desc="Equip a full set of blue (rare) gear.",
    category="Collections",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1209", {
    id="ra_1209",
    name="Epic",
    desc="Equip an epic (purple) item.",
    category="Collections",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Bag_08",
  })
  LeafVE_AchTest:AddAchievement("ra_1301", {
    id="ra_1301",
    name="Shell of a Time",
    desc="Log in on OctoWoW.",
    category="OctoWoW",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1302", {
    id="ra_1302",
    name="High Elf Ally",
    desc="Create a High Elf character on OctoWoW.",
    category="OctoWoW",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1303", {
    id="ra_1303",
    name="Goblin Trader",
    desc="Create a Goblin character on OctoWoW.",
    category="OctoWoW",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1304", {
    id="ra_1304",
    name="OctoWoW Custom Content",
    desc="Complete a custom OctoWoW quest.",
    category="OctoWoW",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1305", {
    id="ra_1305",
    name="Karazhan Crypt",
    desc="Set foot in Karazhan Crypt on OctoWoW.",
    category="OctoWoW",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1306", {
    id="ra_1306",
    name="Emerald Sanctum",
    desc="Defeat a boss in the Emerald Sanctum on OctoWoW.",
    category="OctoWoW",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1307", {
    id="ra_1307",
    name="OctoWoW Hero",
    desc="Reach level 60 on OctoWoW.",
    category="OctoWoW",
    points=25,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1308", {
    id="ra_1308",
    name="OctoWoW Explorer",
    desc="Visit an OctoWoW-only zone.",
    category="OctoWoW",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1309", {
    id="ra_1309",
    name="OctoWoW Reveler",
    desc="Participate in an OctoWoW community event.",
    category="OctoWoW",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Shell_02",
  })
  LeafVE_AchTest:AddAchievement("ra_1402", {
    id="ra_1402",
    name="Fisherman",
    desc="Reach 150 in Fishing.",
    category="Fishing",
    points=10,
    icon="Interface\\Icons\\Trade_Fishing",
  })
  LeafVE_AchTest:AddAchievement("ra_1404", {
    id="ra_1404",
    name="Deadliest Catch",
    desc="Catch a rare fish.",
    category="Fishing",
    points=10,
    icon="Interface\\Icons\\Trade_Fishing",
  })
  LeafVE_AchTest:AddAchievement("ra_1405", {
    id="ra_1405",
    name="The Old Gnome and the Sea",
    desc="Catch 500 fish.",
    category="Fishing",
    points=15,
    icon="Interface\\Icons\\Trade_Fishing",
  })
  LeafVE_AchTest:AddAchievement("ra_1406", {
    id="ra_1406",
    name="Nat Pagle's Apprentice",
    desc="Fish up a piece of gear.",
    category="Fishing",
    points=10,
    icon="Interface\\Icons\\Trade_Fishing",
  })
  LeafVE_AchTest:AddAchievement("ra_1502", {
    id="ra_1502",
    name="Sous Chef",
    desc="Reach 150 in Cooking.",
    category="Cooking",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Food_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1504", {
    id="ra_1504",
    name="Well Fed",
    desc="Eat a cooked dish.",
    category="Cooking",
    points=5,
    icon="Interface\\Icons\\INV_Misc_Food_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1505", {
    id="ra_1505",
    name="Iron Chef",
    desc="Learn 25 unique recipes.",
    category="Cooking",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Food_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1506", {
    id="ra_1506",
    name="Gourmet",
    desc="Cook a rare feast.",
    category="Cooking",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Food_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1601", {
    id="ra_1601",
    name="One Life to Live",
    desc="Roll a Hardcore character.",
    category="Hardcore",
    points=10,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1602", {
    id="ra_1602",
    name="Survivor",
    desc="Reach level 20 on a Hardcore character.",
    category="Hardcore",
    points=15,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1603", {
    id="ra_1603",
    name="Untouchable",
    desc="Reach level 40 on a Hardcore character.",
    category="Hardcore",
    points=25,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1604", {
    id="ra_1604",
    name="Hardcore Hero",
    desc="Reach level 60 on a Hardcore character.",
    category="Hardcore",
    points=50,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1605", {
    id="ra_1605",
    name="Close Call",
    desc="Survive dropping below 10% health.",
    category="Hardcore",
    points=10,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1606", {
    id="ra_1606",
    name="No Retreat",
    desc="Defeat an elite of your level solo.",
    category="Hardcore",
    points=15,
    icon="Interface\\Icons\\Ability_Hunter_SurvivalInstincts",
  })
  LeafVE_AchTest:AddAchievement("ra_1701", {
    id="ra_1701",
    name="Say Hello",
    desc="Emote /wave at another player.",
    category="Social",
    points=5,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1702", {
    id="ra_1702",
    name="Dance Off",
    desc="Use the /dance emote.",
    category="Social",
    points=5,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1703", {
    id="ra_1703",
    name="Guildmate",
    desc="Have 10 members in your guild.",
    category="Social",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1704", {
    id="ra_1704",
    name="Popular",
    desc="Add 5 friends to your friends list.",
    category="Social",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1705", {
    id="ra_1705",
    name="Chatty",
    desc="Send 100 messages in chat.",
    category="Social",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1706", {
    id="ra_1706",
    name="Group Therapy",
    desc="Complete a dungeon with a full party.",
    category="Social",
    points=15,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_1707", {
    id="ra_1707",
    name="Wedding Bells",
    desc="Attend an in-game wedding.",
    category="Social",
    points=15,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_310", {
    id="ra_310",
    name="Loremaster of Elwynn",
    desc="Complete every quest in Elwynn Forest.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_311", {
    id="ra_311",
    name="Loremaster of Durotar",
    desc="Complete every quest in Durotar.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_312", {
    id="ra_312",
    name="Class Quest Hero",
    desc="Complete a class-specific quest chain.",
    category="Quests",
    points=15,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_313", {
    id="ra_313",
    name="Group Effort",
    desc="Complete a group (elite) quest.",
    category="Quests",
    points=10,
    icon="Interface\\Icons\\INV_Letter_15",
  })
  LeafVE_AchTest:AddAchievement("ra_223", {
    id="ra_223",
    name="Deep Pockets",
    desc="Carry 500 gold at once.",
    category="Character",
    points=10,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1801", {
    id="ra_1801",
    name="Stormwind Sightseer",
    desc="Visit Stormwind City.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1802", {
    id="ra_1802",
    name="Ironforge Ironmonger",
    desc="Visit Ironforge.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1803", {
    id="ra_1803",
    name="Darnassian Diplomat",
    desc="Visit Darnassus.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1804", {
    id="ra_1804",
    name="Undercity Underling",
    desc="Visit the Undercity.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1805", {
    id="ra_1805",
    name="Orgrimmar Outrider",
    desc="Visit Orgrimmar.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1806", {
    id="ra_1806",
    name="Thunder Bluff Traveler",
    desc="Visit Thunder Bluff.",
    category="Cities",
    points=10,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1807", {
    id="ra_1807",
    name="Alliance Tourist",
    desc="Visit all Alliance capital cities.",
    category="Cities",
    points=25,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1808", {
    id="ra_1808",
    name="Horde Tourist",
    desc="Visit all Horde capital cities.",
    category="Cities",
    points=25,
    icon="Interface\\Icons\\Ability_TownWatch",
  })
  LeafVE_AchTest:AddAchievement("ra_1901", {
    id="ra_1901",
    name="First Silver",
    desc="Earn your first silver piece.",
    category="Character",
    points=5,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1902", {
    id="ra_1902",
    name="First Gold",
    desc="Earn your first gold piece.",
    category="Character",
    points=10,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1903", {
    id="ra_1903",
    name="Filthy Rich",
    desc="Carry 1,000 gold at once.",
    category="Character",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1904", {
    id="ra_1904",
    name="Made of Money",
    desc="Carry 10,000 gold at once.",
    category="Character",
    points=50,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })
  LeafVE_AchTest:AddAchievement("ra_1905", {
    id="ra_1905",
    name="Auction House Regular",
    desc="List 50 auctions.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_1906", {
    id="ra_1906",
    name="Big Winner",
    desc="Win 100 auctions.",
    category="General",
    points=15,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_1907", {
    id="ra_1907",
    name="Vendor Trash",
    desc="Sell 500 items to a vendor.",
    category="General",
    points=10,
    icon="Interface\\Icons\\INV_Misc_Note_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2001", {
    id="ra_2001",
    name="Private",
    desc="Attain the PvP rank of Private / Scout.",
    category="Titles",
    points=10,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2002", {
    id="ra_2002",
    name="Sergeant",
    desc="Attain PvP rank 3 (Sergeant).",
    category="Titles",
    points=10,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2003", {
    id="ra_2003",
    name="Knight",
    desc="Attain the PvP rank of Knight / Stone Guard.",
    category="Titles",
    points=15,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2004", {
    id="ra_2004",
    name="Champion",
    desc="Attain PvP rank 9 (Knight-Champion / Centurion).",
    category="Titles",
    points=15,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2005", {
    id="ra_2005",
    name="Marshal",
    desc="Attain PvP rank 12 (Marshal / General).",
    category="Titles",
    points=25,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2006", {
    id="ra_2006",
    name="Field Marshal",
    desc="Attain the PvP rank of Field Marshal / Warlord.",
    category="Titles",
    points=25,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2007", {
    id="ra_2007",
    name="Elder",
    desc="Honor all Elders during the Lunar Festival.",
    category="Titles",
    points=15,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2008", {
    id="ra_2008",
    name="The Diplomat",
    desc="Reach Exalted with a faction of the opposite continent.",
    category="Titles",
    points=15,
    icon="Interface\\Icons\\INV_Misc_TabardPVP_01",
  })
  LeafVE_AchTest:AddAchievement("ra_2101", {
    id="ra_2101",
    name="Classic Combatant",
    desc="Kill a boss in a pre-Cataclysm zone.",
    category="Legacy",
    points=5,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2102", {
    id="ra_2102",
    name="Old World Traveler",
    desc="Ride a zeppelin or boat between continents.",
    category="Legacy",
    points=5,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2103", {
    id="ra_2103",
    name="Blackrock Veteran",
    desc="Complete a run of Blackrock Depths from start to finish.",
    category="Legacy",
    points=15,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2104", {
    id="ra_2104",
    name="Ony Head Turn-In",
    desc="Deliver the head of Onyxia to a capital city.",
    category="Legacy",
    points=15,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2105", {
    id="ra_2105",
    name="AQ Gate Opener",
    desc="Contribute to opening the gates of Ahn'Qiraj.",
    category="Legacy",
    points=25,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2106", {
    id="ra_2106",
    name="Silithyst Runner",
    desc="Turn in 10 Silithyst for your faction.",
    category="Legacy",
    points=10,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_2107", {
    id="ra_2107",
    name="Dire Maul Book Club",
    desc="Read a book in the Dire Maul library.",
    category="Legacy",
    points=10,
    icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
  })
  LeafVE_AchTest:AddAchievement("ra_224", {
    id="ra_224",
    name="Wealthy",
    desc="Carry 5,000 gold at once.",
    category="Character",
    points=25,
    icon="Interface\\Icons\\INV_Misc_QuestionMark",
  })

  if LeafVE_AchTest.RegisterProgressDef then
    LeafVE_AchTest:RegisterProgressDef("ra_1206", {counter="mountCount", goal=5})
    LeafVE_AchTest:RegisterProgressDef("ra_1207", {counter="mountCount", goal=25})
    LeafVE_AchTest:RegisterProgressDef("ra_1402", {counter="fishingSkill", goal=150})
    LeafVE_AchTest:RegisterProgressDef("ra_1405", {counter="fishCount", goal=500})
    LeafVE_AchTest:RegisterProgressDef("ra_1502", {counter="cookingSkill", goal=150})
    LeafVE_AchTest:RegisterProgressDef("ra_1505", {counter="recipesLearned", goal=25})
    LeafVE_AchTest:RegisterProgressDef("ra_1704", {counter="friendCount", goal=5})
    LeafVE_AchTest:RegisterProgressDef("ra_1705", {counter="chatCount", goal=100})
    LeafVE_AchTest:RegisterProgressDef("ra_1807", {counter="allianceCitiesVisited", goal=3})
    LeafVE_AchTest:RegisterProgressDef("ra_1808", {counter="hordeCitiesVisited", goal=3})
    LeafVE_AchTest:RegisterProgressDef("ra_1905", {counter="auctionsListed", goal=50})
    LeafVE_AchTest:RegisterProgressDef("ra_1906", {counter="auctionsWon", goal=100})
    LeafVE_AchTest:RegisterProgressDef("ra_1907", {counter="vendorSales", goal=500})
    LeafVE_AchTest:RegisterProgressDef("ra_208", {counter="goldLooted", goal=100})
    LeafVE_AchTest:RegisterProgressDef("ra_209", {counter="goldLooted", goal=1000})
    LeafVE_AchTest:RegisterProgressDef("ra_210", {counter="goldLooted", goal=10000})
    LeafVE_AchTest:RegisterProgressDef("ra_2106", {counter="silithystTurnIns", goal=10})
    LeafVE_AchTest:RegisterProgressDef("ra_217", {counter="weaponSkill", goal=300})
    LeafVE_AchTest:RegisterProgressDef("ra_301", {counter="questCount", goal=1})
    LeafVE_AchTest:RegisterProgressDef("ra_302", {counter="questCount", goal=10})
    LeafVE_AchTest:RegisterProgressDef("ra_303", {counter="questCount", goal=50})
    LeafVE_AchTest:RegisterProgressDef("ra_450", {counter="zoneCount", goal=37})
    LeafVE_AchTest:RegisterProgressDef("ra_451", {counter="zoneCount", goal=10})
    LeafVE_AchTest:RegisterProgressDef("ra_514", {counter="pvpKills", goal=50})
    LeafVE_AchTest:RegisterProgressDef("ra_515", {counter="bgWins", goal=25})
    LeafVE_AchTest:RegisterProgressDef("ra_1204", {counter="petCount", goal=1})
    LeafVE_AchTest:RegisterProgressDef("ra_680", {counter="dungeonsCleared", goal=22})
    LeafVE_AchTest:RegisterProgressDef("ra_681", {counter="raidsCleared", goal=5})
    LeafVE_AchTest:RegisterProgressDef("ra_701", {counter="profSkill", goal=1})
    LeafVE_AchTest:RegisterProgressDef("ra_702", {counter="profSkill", goal=150})
    LeafVE_AchTest:RegisterProgressDef("ra_703", {counter="profSkill", goal=225})
    LeafVE_AchTest:RegisterProgressDef("ra_704", {counter="profSkill", goal=300})
  end
end

local RA_ZONE_MAP = {
  ["Elwynn Forest"] = 401,
  ["Westfall"] = 402,
  ["Duskwood"] = 403,
  ["Redridge Mountains"] = 404,
  ["Stranglethorn Vale"] = 405,
  ["Blasted Lands"] = 406,
  ["Burning Steppes"] = 407,
  ["Searing Gorge"] = 408,
  ["Loch Modan"] = 409,
  ["Wetlands"] = 410,
  ["Arathi Highlands"] = 411,
  ["Hillsbrad Foothills"] = 412,
  ["Silverpine Forest"] = 413,
  ["Tirisfal Glades"] = 414,
  ["Western Plaguelands"] = 415,
  ["Eastern Plaguelands"] = 416,
  ["The Hinterlands"] = 417,
  ["Badlands"] = 418,
  ["Swamp of Sorrows"] = 419,
  ["Deadwind Pass"] = 420,
  ["Durotar"] = 421,
  ["The Barrens"] = 422,
  ["Ashenvale"] = 423,
  ["Feralas"] = 424,
  ["Tanaris"] = 425,
  ["Silithus"] = 426,
  ["Winterspring"] = 427,
  ["Un'Goro Crater"] = 428,
  ["Mulgore"] = 429,
  ["Teldrassil"] = 430,
  ["Darkshore"] = 431,
  ["Stonetalon Mountains"] = 432,
  ["Desolace"] = 433,
  ["Dustwallow Marsh"] = 434,
  ["Thousand Needles"] = 435,
  ["Azshara"] = 436,
  ["Moonglade"] = 437,
}

local RA_CITY_MAP = {
  ["Stormwind City"] = 1801,
  ["Ironforge"] = 1802,
  ["Darnassus"] = 1803,
  ["Undercity"] = 1804,
  ["Orgrimmar"] = 1805,
  ["Thunder Bluff"] = 1806,
}

local RA_FACTION_MAP = {
  ["Argent Dawn"] = 807,
  ["Thorium Brotherhood"] = 808,
  ["Timbermaw Hold"] = 809,
  ["Cenarion Circle"] = 810,
  ["Brood of Nozdormu"] = 811,
  ["Zandalar Tribe"] = 812,
  ["Hydraxian Waterlords"] = 813,
}

local RA_BOSS_MAP = {
  ["Taragaman the Hungerer"] = {id=601, raid=false},
  ["Edwin VanCleef"] = {id=602, raid=false},
  ["Mutanus the Devourer"] = {id=603, raid=false},
  ["Archmage Arugal"] = {id=604, raid=false},
  ["Bazil Thredd"] = {id=605, raid=false},
  ["Aku'mai"] = {id=606, raid=false},
  ["Charlga Razorflank"] = {id=607, raid=false},
  ["Mekgineer Thermaplugg"] = {id=608, raid=false},
  ["Amnennar the Coldbringer"] = {id=609, raid=false},
  ["High Inquisitor Whitemane"] = {id=610, raid=false},
  ["Archaedas"] = {id=611, raid=false},
  ["Chief Ukorz Sandscalp"] = {id=612, raid=false},
  ["Princess Theradras"] = {id=613, raid=false},
  ["Shade of Eranikus"] = {id=614, raid=false},
  ["Emperor Dagran Thaurissan"] = {id=615, raid=false},
  ["Overlord Wyrmthalak"] = {id=616, raid=false},
  ["General Drakkisath"] = {id=617, raid=false},
  ["Baron Rivendare"] = {id=618, raid=false},
  ["Darkmaster Gandling"] = {id=619, raid=false},
  ["Alzzin the Wildshaper"] = {id=620, raid=false},
  ["Prince Tortheldrin"] = {id=621, raid=false},
  ["King Gordok"] = {id=622, raid=false},
  ["Ragnaros"] = {id=650, raid=true},
  ["Onyxia"] = {id=651, raid=true},
  ["Nefarian"] = {id=652, raid=true},
  ["Hakkar"] = {id=653, raid=true},
  ["Ossirian the Unscarred"] = {id=654, raid=true},
  ["C'Thun"] = {id=655, raid=true},
  ["Kel'Thuzad"] = {id=656, raid=true},
}

local RA_ALLIANCE_CITIES = {
  ["Darnassus"] = true,
  ["Ironforge"] = true,
  ["Stormwind City"] = true,
}
local RA_HORDE_CITIES = {
  ["Orgrimmar"] = true,
  ["Thunder Bluff"] = true,
  ["Undercity"] = true,
}

local RA_KNOWN_COMPANIONS_LIST = {
  "Ancona Chicken",
  "Azure Whelpling",
  "Bombay Cat",
  "Black Kingsnake",
  "Black Tabby",
  "Blue Dragonhawk Hatchling",
  "Brown Prairie Dog",
  "Brown Rabbit",
  "Brown Snake",
  "Calico Cat",
  "Cat Carrier (Bombay)",
  "Cat Carrier (Black Tabby)",
  "Cat Carrier (Cornish Rex)",
  "Cat Carrier (Orange Tabby)",
  "Cat Carrier (Siamese)",
  "Cat Carrier (Silver Tabby)",
  "Cat Carrier (White Kitten)",
  "Chicken Egg",
  "Cockroach",
  "Cornish Rex",
  "Crimson Whelpling",
  "Dark Whelpling",
  "Disgusting Oozeling",
  "Emerald Whelpling",
  "Firefly",
  "Frog",
  "Golden Dragonhawk Hatchling",
  "Great Horned Owl",
  "Green Wing Macaw",
  "Hawk Owl",
  "Hyacinth Macaw",
  "Island Frog",
  "Jubling",
  "Lifelike Mechanical Toad",
  "Lifelike Toad",
  "Little Fawn",
  "Mana Wyrmling",
  "Mechanical Squirrel Box",
  "Mini Diablo",
  "Mulgore Hatchling",
  "Orange Tabby",
  "Panda Cub",
  "Parrot Cage (Green Wing Macaw)",
  "Parrot Cage (Hyacinth Macaw)",
  "Parrot Cage (Senegal)",
  "Peddlefeet",
  "Personal World Destroyer",
  "Prairie Dog Whistle",
  "Red Dragonhawk Hatchling",
  "Sprite Darter Hatchling",
  "Senegal",
  "Siamese",
  "Silver Tabby",
  "Smolderweb Hatchling",
  "Snowshoe Rabbit",
  "Snowy Owl",
  "Speedy",
  "Stinker",
  "Tiny Green Dragon",
  "Tiny Red Dragon",
  "Tranquil Mechanical Yeti",
  "Tree Frog Box",
  "Turquoise Turtle",
  "Wanderer's Companion",
  "Westfall Chicken",
  "White Kitten",
  "Whiskers the Rat",
  "Winter Reindeer",
  "Winter's Little Helper",
  "Worg Carrier",
  "Worg Pup",
  "Wolpertinger",
  "Zergling",
  "Baby Blizzard Bear",
  "Baby Crocolisk",
  "Baby Murloc",
  "Baby Ogre",
  "Baby Shark",
  "Baby Tallstrider",
  "Baby Turtle",
  "Bat Cub",
  "Bloodsail Cannonball",
  "Blue Moth",
  "Bronze Whelpling",
  "Captured Firefly",
  "Clockwork Rocket Bot",
  "Cobra Hatchling",
  "Coral Whelpling",
  "Corrupt Whelpling",
  "Deviate Hatchling",
  "Elekk Plushie",
  "Ethereal Soul-Trader",
  "Fel Whelpling",
  "Forest Frog",
  "Fox Kit",
  "Ghost Cat",
  "Ghostly Skull",
  "Gorilla Hatchling",
  "Grunty",
  "Hippogryph Hatchling",
  "Ivory Raptor",
  "Jade Whelpling",
  "Lil' Alexstrasza",
  "Lil' Deathwing",
  "Lil' K.T.",
  "Lil' Ragnaros",
  "Lil' Smoky",
  "Lil' Tarecgosa",
  "Lil' Timmy",
  "Lil' Wickerman",
  "Lil' XT",
  "Lucky Cricket",
  "Magical Crawdad",
  "Mechanical Chicken",
  "Micro Sentry",
  "Mini Tyrael",
  "Moonkin Hatchling",
  "Murky",
  "Naga Hatchling",
  "Netherwhelp",
  "Nightsaber Cub",
  "Onyx Whelpling",
  "Pandaren Monk",
  "Peanut",
  "Perky Pug",
  "Piglet's Collar",
  "Pink Elekk",
  "Plague Rat",
  "Polar Bear Cub",
  "Purple Turtle",
  "Quilen Cub",
  "Raptor Hatchling",
  "Red Panda",
  "Reef Wanderer",
  "Riding Turtle Hatchling",
  "Sand Kitten",
  "Sandbox Tiger",
  "Sandstone Drake",
  "Sea Pony",
  "Shore Crab",
  "Silithid Hatchling",
  "Snowball",
  "Snowy Rabbit",
  "Spectral Tiger Cub",
  "Stormwind Rat",
  "Swamp Frog",
  "Tiny Emerald Whelpling",
  "Tiny Sporebat",
  "Tricorne",
  "Turkey",
  "Undercity Cockroach",
  "Wisp",
  "Withers",
  "Ziggy the Sifaka",
  "Green Steam Tonk",
  "Purple Steam Tonk",
  "Blue Steam Tonk",
  "Red Steam Tonk",
  "Yellow Steam Tonk",
  "Steam Tonk",
  "Steam Tonk Controller",
  "Control Console",
  "Lulu",
  "Mr. Wiggles",
  "Pet Bombling",
  "Lifelike Mechanical Toad",
  "Tranquil Mechanical Yeti",
  "Mechanical Squirrel",
  "Green Kitten",
  "Black Kitten",
  "Orange Kitten",
  "Cornish Rex Cat",
  "Bombay Cat",
  "Siamese Cat",
  "Silver Tabby Cat",
}
local RA_KNOWN_COMPANIONS_SET = {}
for _, n in ipairs(RA_KNOWN_COMPANIONS_LIST) do RA_KNOWN_COMPANIONS_SET[string.lower(n)] = true end

local RA_KNOWN_MOUNTS_LIST = {
  "Brown Wolf",
  "Dire Wolf",
  "Timber Wolf",
  "Red Wolf",
  "Winter Wolf",
  "Frostwolf",
  "Black Wolf",
  "Arctic Wolf",
  "Swift Brown Wolf",
  "Swift Timber Wolf",
  "Swift Gray Wolf",
  "Swift Frostwolf",
  "Black Skeletal Horse",
  "Blue Skeletal Horse",
  "Brown Skeletal Horse",
  "Red Skeletal Horse",
  "Green Skeletal Warhorse",
  "Purple Skeletal Warhorse",
  "Red Skeletal Warhorse",
  "Grey Kodo",
  "Brown Kodo",
  "Green Kodo",
  "Teal Kodo",
  "Great White Kodo",
  "Great Grey Kodo",
  "Great Brown Kodo",
  "Great Green Kodo",
  "Ivory Raptor",
  "Emerald Raptor",
  "Turquoise Raptor",
  "Violet Raptor",
  "Obsidian Raptor",
  "Swift Blue Raptor",
  "Swift Olive Raptor",
  "Swift Orange Raptor",
  "Whistle of the Emerald Raptor",
  "Whistle of the Ivory Raptor",
  "Whistle of the Turquoise Raptor",
  "Whistle of the Violet Raptor",
  "Whistle of the Mottled Red Raptor",
  "Pinto",
  "Palomino",
  "Chestnut Mare",
  "Brown Horse",
  "White Stallion",
  "Black Stallion",
  "Swift Brown Steed",
  "Swift Palomino",
  "Swift White Steed",
  "Gray Ram",
  "Brown Ram",
  "White Ram",
  "Black Ram",
  "Frost Ram",
  "Swift Gray Ram",
  "Swift Brown Ram",
  "Swift White Ram",
  "Mechanostrider",
  "Blue Mechanostrider",
  "Green Mechanostrider",
  "Red Mechanostrider",
  "White Mechanostrider",
  "Yellow Mechanostrider",
  "Unpainted Mechanostrider",
  "Swift Green Mechanostrider",
  "Swift White Mechanostrider",
  "Swift Yellow Mechanostrider",
  "Striped Frostsaber",
  "Striped Nightsaber",
  "Spotted Frostsaber",
  "Striped Dawnsaber",
  "Swift Frostsaber",
  "Swift Mistsaber",
  "Swift Stormsaber",
  "Reins of the Striped Frostsaber",
  "Reins of the Striped Nightsaber",
  "Reins of the Spotted Frostsaber",
  "Summon Warhorse",
  "Summon Charger",
  "Summon Felsteed",
  "Summon Dreadsteed",
  "Warhorse",
  "Charger",
  "Felsteed",
  "Dreadsteed",
  "Black Battlestrider",
  "Black War Kodo",
  "Black War Ram",
  "Black War Raptor",
  "Black War Steed",
  "Black War Tiger",
  "Black War Wolf",
  "Horn of the Black War Wolf",
  "Horn of the Black Wolf",
  "Horn of the Brown Wolf",
  "Horn of the Dire Wolf",
  "Horn of the Red Wolf",
  "Horn of the Timber Wolf",
  "Horn of the Arctic Wolf",
  "Horn of the Frostwolf",
  "Horn of the Swift Brown Wolf",
  "Horn of the Swift Gray Wolf",
  "Horn of the Swift Timber Wolf",
  "Rivendare's Deathcharger",
  "Deathcharger's Reins",
  "Reins of the Rivendare's Deathcharger",
  "Winterspring Frostsaber",
  "Reins of the Winterspring Frostsaber",
  "Swift Zulian Tiger",
  "Reins of the Swift Zulian Tiger",
  "Swift Razzashi Raptor",
  "Reins of the Swift Razzashi Raptor",
  "Qiraji Battle Tank",
  "Reins of the Blue Qiraji Battle Tank",
  "Reins of the Green Qiraji Battle Tank",
  "Reins of the Red Qiraji Battle Tank",
  "Reins of the Yellow Qiraji Battle Tank",
  "Tawny Sabercat",
  "Reins of the Tawny Sabercat",
  "Cenarion War Hippogryph",
  "Reins of the Cenarion War Hippogryph",
  "Zebra",
  "Reins of the Zebra",
  "Whistle of the Zebra",
  "Zhevra",
  "Reins of the Zhevra",
  "Silver Riding Turtle",
  "Reins of the Silver Riding Turtle",
  "Riding Turtle",
  "Reins of the Riding Turtle",
  "Sea Turtle",
  "Reins of the Sea Turtle",
  "Brown Ostrich",
  "White Ostrich",
  "Black Ostrich",
  "Reins of the Ostrich",
  "Swift Ostrich",
  "Reins of the Swift Ostrich",
  "Camel",
  "Brown Camel",
  "Tan Camel",
  "White Camel",
  "Reins of the Camel",
  "Swift Camel",
  "Reins of the Swift Camel",
  "Reindeer",
  "Winter Reindeer",
  "Reins of the Reindeer",
  "Great Elk",
  "Reins of the Great Elk",
  "Moose",
  "Reins of the Moose",
  "Swift Moose",
  "Boar",
  "War Boar",
  "Reins of the War Boar",
  "Swift War Boar",
  "Bear Mount",
  "Riding Bear",
  "Reins of the Riding Bear",
  "Swift Bear",
  "Polar Bear",
  "Reins of the Polar Bear",
  "Cheetah",
  "Reins of the Cheetah",
  "Swift Cheetah",
  "Lion",
  "White Lion",
  "Reins of the White Lion",
  "Steam Tank Mount",
  "Steamscale",
  "Mechano-Hog",
  "Goblin Trike",
  "Trike",
  "Reins of the Trike",
  "Snow Leopard",
  "Reins of the Snow Leopard",
  "Ochre Skeletal Warhorse",
  "Ancona Chicken Mount",
  "Turtle Mount",
  "Great Sea Turtle",
  "Black Panther",
  "Reins of the Black Panther",
  "Giraffe",
  "Reins of the Giraffe",
  "Hyena",
  "Reins of the Hyena",
  "Ram of Ironforge",
  "Kodo of Thunder Bluff",
}
local RA_KNOWN_MOUNTS_SET = {}
for _, n in ipairs(RA_KNOWN_MOUNTS_LIST) do RA_KNOWN_MOUNTS_SET[string.lower(n)] = true end

local function RA_PlayerName()
  if not LeafVE_AchTest or not LeafVE_AchTest.ShortName then return nil end
  return LeafVE_AchTest.ShortName(UnitName("player"))
end

local function RA_SetCounter(counter, value)
  local me = RA_PlayerName()
  if not me then return end
  if LeafVE_AchTest and LeafVE_AchTest.SetCounter then
    LeafVE_AchTest.SetCounter(me, counter, value)
  end
end

local function RA_IncrCounter(counter, amount)
  local me = RA_PlayerName()
  if not me then return end
  if LeafVE_AchTest and LeafVE_AchTest.IncrCounter then
    LeafVE_AchTest.IncrCounter(me, counter, amount or 1)
    RA_CheckProgress()
  end
end

local RA_ScanTip = CreateFrame("GameTooltip", "LeafVE_RelationshipScanTip", UIParent, "GameTooltipTemplate")
RA_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")

local function RA_TooltipText(index, book)
  if not RA_ScanTip.ClearLines then return "" end
  RA_ScanTip:ClearLines()
  RA_ScanTip:SetSpell(index, book)
  local text = ""
  for line = 1, RA_ScanTip:NumLines() do
    local fs = getglobal("LeafVE_RelationshipScanTipTextLeft"..line)
    if fs then
      local t = fs:GetText()
      if t then text = text .. "\n" .. t end
    end
  end
  return string.lower(text)
end

-- Throttles for the expensive scans below -- each is reachable from many
-- different events (RA_ScanSpellbook alone from MERCHANT_SHOW,
-- SPELLS_CHANGED, TIME_PLAYED_MSG, UNIT_MODEL_CHANGED, LEARNED_SPELL_IN_TAB,
-- and RA_ScanCharacter's own internal call), several of which fire in
-- bursts during normal play (rep grinding, gathering, shapeshifting).
-- Guarding inside each function protects it no matter which caller reaches
-- it, rather than needing every call site individually throttled.
local RA_lastScanSpellbookAt = 0
local RA_lastScanEquipmentAndBagsAt = 0
local RA_lastScanCompanionsAt = 0
local RA_lastScanCharacterAt = 0

local function RA_ScanSpellbook(silent)
  if not GetSpellName then return end
  local now = GetTime and GetTime() or 0
  if now > 0 and (now - RA_lastScanSpellbookAt) < 2 then return end
  RA_lastScanSpellbookAt = now
  local book = BOOKTYPE_SPELL or "spell"
  local mounts, pets = 0, 0
  local hasEpicMount = false
  local seen = {}
  local i = 1
  while true do
    local name, rank = GetSpellName(i, book)
    if not name then break end
    local key = name .. "||" .. (rank or "")
    if not seen[key] then
      seen[key] = true
      local tip = RA_TooltipText(i, book)
      local isMount = string.find(tip, "mount speed", 1, true) or string.find(tip, "rideable", 1, true)
      local isPet = (string.find(tip, "companion", 1, true) or string.find(tip, "right click to dismiss", 1, true) or string.find(tip, "small pet", 1, true) or string.find(tip, "critter", 1, true) or string.find(tip, "summons and dismisses a", 1, true) or string.find(tip, "summons and dismisses your", 1, true) or string.find(tip, "summon a small", 1, true) or string.find(tip, "vanity pet", 1, true) or string.find(tip, "non-combat pet", 1, true))
      if isPet and (string.find(tip, "summons your pet", 1, true) or string.find(tip, "combat pet", 1, true)) then isPet = nil end
      if isPet and (string.find(tip, "mount speed", 1, true) or string.find(tip, "rideable", 1, true)) then isPet = nil end
      if isMount then
        mounts = mounts + 1
        if string.find(tip, "100%", 1, true) or string.find(tip, "epic", 1, true) then hasEpicMount = true end
      elseif isPet then
        pets = pets + 1
      end
      if (not isPet) and (not isMount) and RA_KNOWN_COMPANIONS_SET[string.lower(name)] then pets = pets + 1 end
      if (not isMount) and (not isPet) and RA_KNOWN_MOUNTS_SET[string.lower(name)] then mounts = mounts + 1 end
    end
    i = i + 1
  end
  if GetNumSkillLines then
    for s = 1, GetNumSkillLines() do
      local skill, header, rank = GetSkillLineInfo(s)
      if not header and skill == "Riding" and rank and rank > 0 then
        if mounts < 1 then mounts = 1 end
        if rank >= 150 then hasEpicMount = true end
      end
    end
  end
  RA_SetCounter("mountCount", mounts)
  RA_SetCounter("petCount", pets)
  if mounts >= 1 then AwardRA(211) end
  if mounts >= 5 then AwardRA(1206) end
  if mounts >= 25 then AwardRA(1207) end
  if hasEpicMount and (UnitLevel("player") or 1) >= 60 then AwardRA(212) end
  if pets >= 1 then AwardRA(1204) end
  if pets >= 10 then AwardRA(1205) end
  if RA_scanReady then RA_CheckProgress() end
end

local function RA_ScanPvPRank()
  if not UnitPVPRank then return end
  local raw = UnitPVPRank("player") or 0
  if GetPVPLifetimeStats then
    local _, _, highest = GetPVPLifetimeStats()
    if highest and highest > raw then raw = highest end
  end
  if raw == 0 then return end
  local rank = raw
  if rank >= 5 then rank = rank - 4 end
  if rank < 1 then return end
  if rank >= 1  then AwardRA(2001) end
  if rank >= 3  then AwardRA(2002) end
  if rank >= 6  then AwardRA(2003) end
  if rank >= 9  then AwardRA(2004) end
  if rank >= 12 then AwardRA(2005) end
  if rank >= 13 then AwardRA(2006) end
  if rank >= 14 then
    local _, faction = UnitFactionGroup("player")
    if faction == "Horde" then AwardRA(1003) else AwardRA(1002) end
  end
end

local function RA_ScanPvPKills()
  if not GetPVPLifetimeStats then return end
  local honorable = GetPVPLifetimeStats() or 0
  RA_SetCounter("honorKills", honorable)
  RA_SetCounter("pvpKills", honorable)
  if honorable >= 1 then AwardRA(501) end
  if RA_scanReady then RA_CheckProgress() end
end

local RA_QUALITY_BY_COLOR = {
  ["ff9d9d9d"] = 0, ["ffffffff"] = 1, ["ff1eff00"] = 2,
  ["ff0070dd"] = 3, ["ffa335ee"] = 4, ["ffff8000"] = 5,
}
local function RA_QualityFromLink(link)
  if not link then return nil end
  local _, _, color = string.find(link, "|c(%x%x%x%x%x%x%x%x)")
  if not color then return nil end
  return RA_QUALITY_BY_COLOR[string.lower(color)]
end

local function RA_ScanEquipmentAndBags()
  local now = GetTime and GetTime() or 0
  if now > 0 and (now - RA_lastScanEquipmentAndBagsAt) < 1 then return end
  RA_lastScanEquipmentAndBagsAt = now
  if GetInventoryItemLink then
    if GetInventoryItemLink("player", 4) then AwardRA(1203) end
    if GetInventoryItemLink("player", 19) then AwardRA(109) end
    local requiredSlots = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16}
    local optionalSlots = {17,18}
    local allRare, missing, epic = true, false, false
    for i = 1, table.getn(requiredSlots) do
      local slot = requiredSlots[i]
      local link = GetInventoryItemLink("player", slot)
      if not link then
        missing = true
      else
        local _, _, q = GetItemInfo(link)
        local quality = q or RA_QualityFromLink(link)
        if quality and quality >= 4 then epic = true end
        if not quality or quality < 3 then allRare = false end
        local itemName = GetItemInfo(link)
        if itemName == "Atiesh, Greatstaff of the Guardian" then AwardRA(1004) end
        if itemName == "Thunderfury, Blessed Blade of the Windseeker" then AwardRA(1005) end
        if itemName == "Sulfuras, Hand of Ragnaros" then AwardRA(1006) end
      end
    end
    for i = 1, table.getn(optionalSlots) do
      local slot = optionalSlots[i]
      local link = GetInventoryItemLink("player", slot)
      if link then
        local _, _, q = GetItemInfo(link)
        local quality = q or RA_QualityFromLink(link)
        if quality and quality >= 4 then epic = true end
      end
    end
    if not missing and allRare then AwardRA(1208) end
    if epic then AwardRA(1209) end
  end
  if GetContainerNumSlots then
    local bags, has16 = 0, false
    for bag = 1, 4 do
      local slots = GetContainerNumSlots(bag) or 0
      if slots > 0 then bags = bags + 1 end
      if slots >= 16 then has16 = true end
    end
    if bags >= 4 then AwardRA(1202) end
    if has16 then AwardRA(1201) end
  end
end

local function RA_CountTable(t)
  local n = 0
  if t then for _ in pairs(t) do n = n + 1 end end
  return n
end

local function RA_ScanCompanions()
  if not GetNumCompanions then return end
  local now = GetTime and GetTime() or 0
  if now > 0 and (now - RA_lastScanCompanionsAt) < 1 then return end
  RA_lastScanCompanionsAt = now
  local counted = {}
  local types = {"CRITTER","COMPANION","COMPANIONS","PET","MINIPET"}
  for _, ctype in ipairs(types) do
    local ok, num = pcall(GetNumCompanions, ctype)
    if ok and num and num > 0 then
      for i = 1, num do
        local ok2, _, name = pcall(GetCompanionInfo, ctype, i)
        if ok2 and name and name ~= "" then counted[name] = true else counted[ctype.."_"..i] = true end
      end
    end
  end
  local total = RA_CountTable(counted)
  RA_SetCounter("petCount", total)
  if total >= 1 then AwardRA(1204) end
  if total >= 10 then AwardRA(1205) end
  if RA_scanReady then RA_CheckProgress() end
end

local function RA_ScanCharacter()
  local now = GetTime and GetTime() or 0
  if now > 0 and (now - RA_lastScanCharacterAt) < 2 then return end
  RA_lastScanCharacterAt = now
  local lvl = UnitLevel("player") or 1
  if lvl >= 5  then AwardRA(216) end
  if lvl >= 10 then AwardRA(201) end
  if lvl >= 15 then AwardRA(218) end
  if lvl >= 20 then AwardRA(202) end
  if lvl >= 25 then AwardRA(219) end
  if lvl >= 30 then AwardRA(203) end
  if lvl >= 35 then AwardRA(220) end
  if lvl >= 40 then AwardRA(204) end
  if lvl >= 45 then AwardRA(221) end
  if lvl >= 50 then AwardRA(205) end
  if lvl >= 55 then AwardRA(222) end
  if lvl >= 60 then AwardRA(206) end
  local race = UnitRace("player")
  if race == "High Elf" or race == "HighElf" then AwardRA(1302) end
  if race == "Goblin" then AwardRA(1303) end
  if lvl >= 60 then
    local _, class = UnitClass("player")
    if class == "WARRIOR" then AwardRA(1101)
    elseif class == "PALADIN" then AwardRA(1102)
    elseif class == "HUNTER" then AwardRA(1103)
    elseif class == "ROGUE" then AwardRA(1104)
    elseif class == "PRIEST" then AwardRA(1105)
    elseif class == "SHAMAN" then AwardRA(1106)
    elseif class == "MAGE" then AwardRA(1107)
    elseif class == "WARLOCK" then AwardRA(1108)
    elseif class == "DRUID" then AwardRA(1109) end
    AwardRA(1307)
  end
  if GetGuildInfo and GetGuildInfo("player") then
    AwardRA(103)
    if GetNumGuildMembers and GetNumGuildMembers() >= 10 then AwardRA(1703) end
  end
  if GetNumPartyMembers and GetNumPartyMembers() > 0 then AwardRA(105) end
  if GetNumFriends and GetNumFriends() > 0 then
    AwardRA(102)
    RA_SetCounter("friendCount", GetNumFriends())
  end
  if GetMoney then
    local copper = GetMoney() or 0
    if copper >= 100       then AwardRA(1901) end
    if copper >= 10000     then AwardRA(1902) end
    if copper >= 5000000   then AwardRA(223) end
    if copper >= 10000000  then AwardRA(1903) end
    if copper >= 50000000  then AwardRA(224) end
    if copper >= 100000000 then AwardRA(1904) end
  end
  RA_ScanEquipmentAndBags()
  RA_ScanSpellbook(true)
  RA_ScanCompanions()
  RA_ScanPvPRank()
  RA_ScanPvPKills()
  if GetNumSkillLines then
    local profSet = {["Alchemy"]=true,["Blacksmithing"]=true,["Enchanting"]=true,["Engineering"]=true,["Herbalism"]=true,["Leatherworking"]=true,["Mining"]=true,["Skinning"]=true,["Tailoring"]=true,["Jewelcrafting"]=true}
    local highestProf, highestWeapon = 0, 0
    for i = 1, GetNumSkillLines() do
      local name, isHeader, rank = GetSkillLineInfo(i)
      if not isHeader and rank and rank > 0 then
        if name == "Cooking" then RA_SetCounter("cookingSkill", rank) end
        if name == "Fishing" then RA_SetCounter("fishingSkill", rank) end
        local isWeapon = (name == "Swords" or name == "Two-Handed Swords" or name == "Axes" or name == "Two-Handed Axes" or name == "Maces" or name == "Two-Handed Maces" or name == "Daggers" or name == "Fist Weapons" or name == "Polearms" or name == "Staves" or name == "Bows" or name == "Crossbows" or name == "Guns" or name == "Wands" or name == "Thrown")
        if isWeapon then
          if rank > highestWeapon then highestWeapon = rank end
        elseif profSet[name] then
          if rank > highestProf then highestProf = rank end
        end
      end
    end
    RA_SetCounter("profSkill", highestProf)
    RA_SetCounter("weaponSkill", highestWeapon)
  end
  if GetNumFactions then
    local friendly, honored, revered, exalted = 0, 0, 0, 0
    for i = 1, GetNumFactions() do
      local name, _, standing, _, _, _, _, _, isHeader = GetFactionInfo(i)
      if not isHeader and standing then
        if standing >= 5 then friendly = friendly + 1 end
        if standing >= 6 then honored = honored + 1 end
        if standing >= 7 then revered = revered + 1 end
        if standing >= 8 then
          exalted = exalted + 1
          if RA_FACTION_MAP[name] then AwardRA(RA_FACTION_MAP[name]) end
        end
      end
    end
    if friendly >= 1 then AwardRA(801) end
    if honored >= 1 then AwardRA(802) end
    if revered >= 1 then AwardRA(803) end
    if exalted >= 1 then AwardRA(804) end
    if exalted >= 5 then AwardRA(805) end
    if exalted >= 10 then AwardRA(806) end
    RA_SetCounter("exaltedCount", exalted)
  end
  if RA_scanReady then RA_CheckProgress() end
end

local function RA_OnLevelUp()
  RA_ScanCharacter()
end

local RA_lastQuestCredit = 0
local function RA_OnQuestComplete()
  local now = time()
  if RA_lastQuestCredit == now then return end
  RA_lastQuestCredit = now
  RA_IncrCounter("questCount", 1)
  local title = GetTitleText and GetTitleText() or ""
  local low = string.lower(title or "")
  if string.find(low, "attunement to the core") then AwardRA(683) end
  if string.find(low, "blackhand's command") then AwardRA(682) end
  if string.find(low, "onyxia") or string.find(low, "great masquerade") then AwardRA(684) end
  if string.find(low, "head of onyxia") or string.find(low, "victory for the alliance") or string.find(low, "victory for the horde") then AwardRA(2104) end
  if string.find(low, "silithyst") then RA_IncrCounter("silithystTurnIns", 1) end
  if string.find(low, "class") then AwardRA(312) end
end

local RA_seenZones = {}
local RA_seenCities = {}
local function RA_OnZoneChanged()
  local zone = ""
  if GetRealZoneText then zone = GetRealZoneText() or "" end
  if zone == "" and GetZoneText then zone = GetZoneText() or "" end
  if not zone or zone == "" then return end
  local leafCity = RA_CITY_MAP[zone]
  if leafCity and not RA_seenCities[zone] then
    RA_seenCities[zone] = true
    AwardRA(RA_CITY_MAP[zone])
    if RA_ALLIANCE_CITIES[zone] then RA_IncrCounter("allianceCitiesVisited", 1) end
    if RA_HORDE_CITIES[zone] then RA_IncrCounter("hordeCitiesVisited", 1) end
  end
  local lowZone = string.lower(zone)
  if string.find(lowZone, "karazhan crypt") then AwardRA(1305) end
  if string.find(lowZone, "emerald sanctum") then AwardRA(1308) end
  if not RA_seenZones[zone] then
    RA_seenZones[zone] = true
    if RA_ZONE_MAP[zone] then AwardRA(RA_ZONE_MAP[zone]) end
    RA_IncrCounter("zoneCount", 1)
  end
end

local function RA_OnHonorGain(msg)
  if GetPVPLifetimeStats then
    RA_ScanPvPKills()
  elseif msg and string.find(string.lower(msg), "honorable kill") then
    AwardRA(501)
    RA_IncrCounter("honorKills", 1)
    RA_IncrCounter("pvpKills", 1)
  end
  RA_CheckProgress()
end

local function RA_OnLootMessage(msg)
  if not msg then return end
  local clean = string.gsub(msg, ",", "")
  local _, _, g = string.find(clean, "(%d+) Gold")
  if g then RA_IncrCounter("goldLooted", tonumber(g)) end
  local low = string.lower(msg)
  if string.find(low, "fish") or string.find(low, "snapper") or string.find(low, "trout") or string.find(low, "salmon") or string.find(low, "catfish") or string.find(low, "eel") then
    AwardRA(1401)
    RA_IncrCounter("fishCount", 1)
  end
  if string.find(low, "you create") and (string.find(low, "food") or string.find(low, "meal") or string.find(low, "roast") or string.find(low, "stew")) then AwardRA(1501) end
end

local RA_seenDungeonBosses = {}
local RA_seenRaidBosses = {}
local function RA_OnEnemyDeath(msg)
  if not msg then return end
  if string.find(msg, "You have slain") or string.find(msg, "slain by you") then
    RA_IncrCounter("killCount", 1)
  end
  for boss, info in pairs(RA_BOSS_MAP) do
    if string.find(msg, boss, 1, true) then
      AwardRA(info.id)
      local seen = info.raid and RA_seenRaidBosses or RA_seenDungeonBosses
      if not seen[boss] then
        seen[boss] = true
        RA_IncrCounter(info.raid and "raidsCleared" or "dungeonsCleared", 1)
      end
    end
  end
end

local function RA_TryParseQuestCount(msg)
  if not msg then return end
  local patterns = {
    "[Qq]uests? [Cc]ompleted:?%s*(%d+)",
    "[Cc]ompleted [Qq]uests?:?%s*(%d+)",
    "[Tt]otal [Qq]uests?:?%s*(%d+)",
    "[Qq]uests?[^%d]-(%d+)%s*completed",
  }
  for i = 1, table.getn(patterns) do
    local _, _, num = string.find(msg, patterns[i])
    if num then
      local n = tonumber(num)
      if n and n > 0 then
        RA_SetCounter("questCount", n)
        return true
      end
    end
  end
end

local function RA_OnSystemMessage(msg)
  if not msg then return end
  RA_TryParseQuestCount(msg)
  local _, _, winner = string.find(msg, "^(.-) has defeated ")
  if winner and winner == UnitName("player") then RA_IncrCounter("duelWins", 1) end
  if string.find(msg, "home is now") or string.find(msg, "bound to") then AwardRA(108) end
  local low = string.lower(msg)
  if string.find(low, "learned a new") or string.find(low, "you have learned") then AwardRA(1110) end
  if string.find(low, "darkmoon faire") then AwardRA(911) end
  if string.find(low, "trick or treat") then AwardRA(903) end
  if string.find(low, "lunar festival") then AwardRA(909) end
  if string.find(low, "winter veil") then AwardRA(901) end
  if string.find(msg, "[Vv]ictory") or string.find(msg, "wins!") then
    if string.find(msg, "Warsong Gulch") then
      AwardRA(505)
    elseif string.find(msg, "Alterac Valley") then
      AwardRA(506)
    elseif string.find(msg, "Arathi Basin") then
      AwardRA(507)
    end
  end
  RA_CheckProgress()
end

local function RA_OnTextEmote(msg, sender)
  if not msg then return end
  local me = UnitName("player")
  local mine = (sender and sender == me) or string.find(msg, "^You ")
  if not mine then return end
  local low = string.lower(msg)
  if string.find(low, "wave") then AwardRA(1701) end
  if string.find(low, "dance") then AwardRA(1702) end
end

local RA_auctionHooked = false
local function RA_HookAuctionHouse()
  if RA_auctionHooked then return end
  if not StartAuction and not PostAuction and not BuyoutAuction and not PlaceAuctionBid then return end
  RA_auctionHooked = true
  if StartAuction then
    local _orig = StartAuction
    StartAuction = function(minBid, buyoutPrice, runTime)
      _orig(minBid, buyoutPrice, runTime)
      RA_IncrCounter("auctionsListed", 1)
    end
  end
  if PostAuction then
    local _orig = PostAuction
    PostAuction = function(minBid, buyoutPrice, runTime, stackSize, numStacks)
      _orig(minBid, buyoutPrice, runTime, stackSize, numStacks)
      RA_IncrCounter("auctionsListed", numStacks or 1)
    end
  end
  if BuyoutAuction then
    local _orig = BuyoutAuction
    BuyoutAuction = function(index)
      _orig(index)
      AwardRA(107)
      RA_IncrCounter("auctionsWon", 1)
    end
  end
  if PlaceAuctionBid then
    local _orig = PlaceAuctionBid
    PlaceAuctionBid = function(listType, index, bid)
      _orig(listType, index, bid)
      local buyout = select(11, GetAuctionItemInfo(listType, index)) or select(9, GetAuctionItemInfo(listType, index))
      if buyout and bid and bid >= buyout and buyout > 0 then
        AwardRA(107)
        RA_IncrCounter("auctionsWon", 1)
      end
    end
  end
end

local function RA_MerchantOpen()
  return MerchantFrame and MerchantFrame:IsVisible()
end
local _origUseContainerItem = UseContainerItem
if _origUseContainerItem then
  UseContainerItem = function(bag, slot, target)
    local sellable = false
    if RA_MerchantOpen() and GetContainerItemLink then
      local link = GetContainerItemLink(bag, slot)
      if link then sellable = true end
    end
    _origUseContainerItem(bag, slot, target)
    if sellable then RA_IncrCounter("vendorSales", 1) end
  end
end

local _origStaticPopupShow = StaticPopup_Show
if _origStaticPopupShow then
  StaticPopup_Show = function(which, text_arg1, text_arg2, data)
    local popup = _origStaticPopupShow(which, text_arg1, text_arg2, data)
    if which == "CONFIRM_BINDER" then RA_pendingInnBind = true end
    return popup
  end
end

local _origDoEmote = DoEmote
if _origDoEmote then
  DoEmote = function(token, target)
    _origDoEmote(token, target)
    if not token then return end
    local t = string.lower(token)
    if t == "wave" then AwardRA(1701)
    elseif t == "dance" then AwardRA(1702) end
  end
end

local _origSendMail = SendMail
if _origSendMail then
  SendMail = function(name, subject, body)
    _origSendMail(name, subject, body)
    AwardRA(110)
  end
end

local RA_frame = CreateFrame("Frame", "LeafVE_RelationshipsFrame")
local function RA_SafeRegister(name)
  pcall(RA_frame.RegisterEvent, RA_frame, name)
end
local RA_events = {
  "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_DEAD",
  "QUEST_COMPLETE","QUEST_TURNED_IN","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED",
  "ZONE_CHANGED_INDOORS","CHAT_MSG_COMBAT_HONOR_GAIN","CHAT_MSG_COMBAT_FACTION_CHANGE",
  "SKILL_LINES_CHANGED","CHAT_MSG_LOOT","CHAT_MSG_MONEY","CHAT_MSG_COMBAT_HOSTILE_DEATH",
  "CHAT_MSG_COMBAT_XP_GAIN","CHAT_MSG_SYSTEM","UPDATE_FACTION","PARTY_MEMBERS_CHANGED",
  "FRIENDLIST_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_UNGHOST","PLAYER_ALIVE",
  "CHAT_MSG_TEXT_EMOTE","CHAT_MSG_EMOTE","PLAYER_PVP_RANK_CHANGED","PLAYER_PVP_KILLS_CHANGED",
  "PLAYER_PVPKILLS_CHANGED","HONOR_CURRENCY_UPDATE","HEARTHSTONE_BOUND",
  "BANKFRAME_OPENED","TRAINER_SHOW","MAIL_SEND_SUCCESS","PLAYER_EQUIPMENT_CHANGED",
  "BAG_UPDATE","CHARACTER_POINTS_CHANGED","SPELLS_CHANGED","UNIT_HEALTH","PLAYER_MONEY",
  "UNIT_INVENTORY_CHANGED","ADDON_LOADED","MERCHANT_SHOW","MERCHANT_CLOSED",
  "TIME_PLAYED_MSG","UNIT_PET","UNIT_MODEL_CHANGED","LEARNED_SPELL_IN_TAB",
  "COMPANION_LEARNED","COMPANION_UPDATE","COMPANION_UNLEARNED","PET_UI_UPDATE"
}
for i = 1, table.getn(RA_events) do RA_SafeRegister(RA_events[i]) end

local RA_loginScanDone = false
local function RA_OnLogin()
  AwardRA(101)
  AwardRA(1301)
  if not RA_loginScanDone then
    RA_loginScanDone = true
    local scanner = CreateFrame("Frame")
    local acc = 0
    scanner:SetScript("OnUpdate", function()
      acc = acc + (arg1 or 0)
      if acc >= 2 then
        RA_ScanCharacter()
        if ShowFriends then ShowFriends() end
        if GuildRoster then GuildRoster() end
        RA_CheckProgress()
        RA_scanReady = true
        this:SetScript("OnUpdate", nil)
      end
    end)
  end
end

RA_frame:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then RA_OnLogin()
  elseif event == "PLAYER_ENTERING_WORLD" then
    RA_OnZoneChanged()
    RA_ScanPvPRank()
  elseif event == "PLAYER_LEVEL_UP" then RA_OnLevelUp()
  elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
    if event == "PLAYER_DEAD" then
      AwardRA(207)
    end
  elseif event == "QUEST_COMPLETE" or event == "QUEST_TURNED_IN" then RA_OnQuestComplete()
  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then RA_OnZoneChanged()
  elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then RA_OnHonorGain(arg1)
  elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then RA_ScanCharacter()
  elseif event == "SKILL_LINES_CHANGED" then RA_ScanCharacter()
  elseif event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_MONEY" then RA_OnLootMessage(arg1)
  elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "CHAT_MSG_COMBAT_XP_GAIN" then RA_OnEnemyDeath(arg1)
  elseif event == "CHAT_MSG_SYSTEM" then RA_OnSystemMessage(arg1)
  elseif event == "CHAT_MSG_TEXT_EMOTE" or event == "CHAT_MSG_EMOTE" then RA_OnTextEmote(arg1, arg2)
  elseif event == "PLAYER_PVP_RANK_CHANGED" or event == "HONOR_CURRENCY_UPDATE" or event == "PLAYER_PVPKILLS_CHANGED" or event == "PLAYER_PVP_KILLS_CHANGED" then
    RA_ScanPvPRank()
    RA_ScanPvPKills()
  elseif event == "HEARTHSTONE_BOUND" then AwardRA(108)
  elseif event == "BANKFRAME_OPENED" then AwardRA(106)
  elseif event == "TRAINER_SHOW" then AwardRA(111)
  elseif event == "MAIL_SEND_SUCCESS" then AwardRA(110)
  elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" or event == "BAG_UPDATE" then
    if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
    RA_ScanEquipmentAndBags()
  elseif event == "ADDON_LOADED" then
    if arg1 == "LeafVillageAchievements" then RegisterRelationshipAchievements() end
    if arg1 == "Blizzard_AuctionUI" then RA_HookAuctionHouse() end
  elseif event == "MERCHANT_SHOW" then
    RA_ScanEquipmentAndBags()
    RA_ScanSpellbook(true)
  elseif event == "CHARACTER_POINTS_CHANGED" then RA_ScanCharacter()
  elseif event == "SPELLS_CHANGED" then RA_ScanSpellbook(true)
  elseif event == "PLAYER_MONEY" then
    if GetMoney then
      local copper = GetMoney() or 0
      if copper >= 100       then AwardRA(1901) end
      if copper >= 10000     then AwardRA(1902) end
      if copper >= 5000000   then AwardRA(223) end
      if copper >= 10000000  then AwardRA(1903) end
      if copper >= 50000000  then AwardRA(224) end
      if copper >= 100000000 then AwardRA(1904) end
    end
    RA_CheckProgress()
  elseif event == "UNIT_HEALTH" and arg1 == "player" then
    local maxHealth = UnitHealthMax("player") or 0
    if maxHealth > 0 and UnitHealth("player") > 0 and UnitHealth("player") * 10 < maxHealth then AwardRA(1605) end
  elseif event == "UPDATE_FACTION" then RA_ScanCharacter()
  elseif event == "PARTY_MEMBERS_CHANGED" then
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then AwardRA(105) end
  elseif event == "FRIENDLIST_UPDATE" then
    if GetNumFriends and GetNumFriends() > 0 then
      AwardRA(102)
      RA_SetCounter("friendCount", GetNumFriends())
      RA_CheckProgress()
    end
  elseif event == "GUILD_ROSTER_UPDATE" then
    if GetGuildInfo and GetGuildInfo("player") then
      AwardRA(103)
      if GetNumGuildMembers and GetNumGuildMembers() >= 10 then AwardRA(1703) end
    end
  elseif event == "TIME_PLAYED_MSG" then RA_ScanSpellbook(true)
  elseif event == "UNIT_PET" or event == "UNIT_MODEL_CHANGED" then
    if arg1 == "player" then
      RA_ScanSpellbook(true)
      RA_ScanCompanions()
    end
  elseif event == "COMPANION_LEARNED" or event == "COMPANION_UPDATE" or event == "COMPANION_UNLEARNED" or event == "PET_UI_UPDATE" then
    RA_ScanCompanions()
  elseif event == "LEARNED_SPELL_IN_TAB" then
    RA_ScanSpellbook(true)
    RA_ScanCompanions()
  end
end)

RA_HookAuctionHouse()
RegisterRelationshipAchievements()