-- Relationships Achievements Database
-- Categories and achievement definitions for OctoWoW / Turtle WoW / Vanilla 1.12.
--
-- Fields:
--   id       unique numeric id
--   cat      category id (see RelationshipsAchievements_Categories)
--   name     display name
--   desc     description shown in the row
--   points   achievement point value (0/5/10/25/50)
--   account  true = account-wide, false/nil = character-based
--   icon     texture path (vanilla 1.12-safe icon path)
--   progress optional table describing progress tracking:
--              stat  = key in RelationshipsAchievementsCharDB (or DB if accountStat)
--              max   = goal number, shown as "current/max"
--              accountStat = true if the counter lives in RelationshipsAchievementsDB

RelationshipsAchievements_Categories = {
    { id = 1,  name = "General" },
    { id = 2,  name = "Character" },
    { id = 3,  name = "Quests" },
    { id = 4,  name = "Exploration" },
    { id = 5,  name = "Player vs. Player" },
    { id = 6,  name = "Dungeons & Raids" },
    { id = 7,  name = "Professions" },
    { id = 8,  name = "Reputation" },
    { id = 9,  name = "World Events" },
    { id = 11, name = "Class" },
    { id = 12, name = "Collections" },
    { id = 14, name = "Fishing" },
    { id = 15, name = "Cooking" },
    { id = 16, name = "Hardcore" },
    { id = 17, name = "Social" },
    { id = 18, name = "Cities" },
    { id = 20, name = "Titles" },
    { id = 21, name = "Legacy" },
    { id = 13, name = "OctoWoW" },
    { id = 10, name = "Feats of Strength" },
}

RelationshipsAchievements_List = {

    -- ============ GENERAL ============
    { id = 101, cat = 1, name = "The Stormwind Rendezvous",  desc = "Log in for the first time.",                       points = 10, account = true, icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { id = 102, cat = 1, name = "Making Friends",            desc = "Add a friend to your friends list.",               points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { id = 103, cat = 1, name = "Guild Member",              desc = "Join a guild.",                                    points = 10, icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01" },
    { id = 104, cat = 1, name = "Well Read",                 desc = "Read the achievement panel for the first time.",   points = 5,  account = true, icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { id = 105, cat = 1, name = "Party Time",                desc = "Join a party.",                                    points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { id = 106, cat = 1, name = "Money in the Bank",         desc = "Use a bank for the first time.",                   points = 10, icon = "Interface\\Icons\\INV_Misc_Bag_15" },
    { id = 107, cat = 1, name = "Big Spender",               desc = "Purchase an item from an auction house.",          points = 10, icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    { id = 108, cat = 1, name = "Take a Chill Pill",         desc = "Bind to an inn.",                                  points = 5,  icon = "Interface\\Icons\\INV_Misc_Rune_01" },
    { id = 109, cat = 1, name = "Represent",                 desc = "Equip a tabard.",                                  points = 10, icon = "Interface\\Icons\\INV_Shirt_Guildtabard_01" },
    { id = 110, cat = 1, name = "Mailbox Hero",              desc = "Send your first piece of mail.",                   points = 5,  icon = "Interface\\Icons\\INV_Letter_04" },
    { id = 111, cat = 1, name = "Trainee",                   desc = "Visit a class trainer.",                           points = 5,  icon = "Interface\\Icons\\INV_Misc_Book_11" },

    -- ============ CHARACTER (levels, deaths, gold) ============
    { id = 201, cat = 2, name = "Level 10",  desc = "Reach level 10.",  points = 10, icon = "Interface\\Icons\\INV_Misc_Note_02" },
    { id = 202, cat = 2, name = "Level 20",  desc = "Reach level 20.",  points = 10, icon = "Interface\\Icons\\Spell_Nature_EnchantArmor" },
    { id = 203, cat = 2, name = "Level 30",  desc = "Reach level 30.",  points = 10, icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { id = 204, cat = 2, name = "Level 40",  desc = "Reach level 40. Time to buy a mount!", points = 10, icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
    { id = 205, cat = 2, name = "Level 50",  desc = "Reach level 50.",  points = 10, icon = "Interface\\Icons\\INV_Sword_48" },
    { id = 206, cat = 2, name = "Level 60",  desc = "Reach the maximum level of 60.", points = 25, icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = 207, cat = 2, name = "First Death",             desc = "Die for the first time. It happens to everyone.", points = 5,  icon = "Interface\\Icons\\Ability_Rogue_FeignDeath" },
    { id = 208, cat = 2, name = "Got My Mind On My Money",  desc = "Loot 100 gold.",                                    points = 10, icon = "Interface\\Icons\\INV_Misc_Coin_01",
        progress = { stat = "goldLooted", max = 100 } },
    { id = 209, cat = 2, name = "Got My Mind On My Money II", desc = "Loot 1,000 gold.",                                points = 25, icon = "Interface\\Icons\\INV_Misc_Coin_02",
        progress = { stat = "goldLooted", max = 1000 } },
    { id = 210, cat = 2, name = "Got My Mind On My Money III",desc = "Loot 10,000 gold.",                               points = 50, icon = "Interface\\Icons\\INV_Misc_Coin_03",
        progress = { stat = "goldLooted", max = 10000 } },
    { id = 211, cat = 2, name = "Apprentice Riding",  desc = "Purchase your first mount at level 40.",     points = 10, icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
    { id = 212, cat = 2, name = "Journeyman Riding",  desc = "Purchase an epic mount at level 60.",         points = 25, icon = "Interface\\Icons\\Ability_Mount_JungleTiger" },
    { id = 213, cat = 2, name = "Died a Hundred Deaths", desc = "Die 100 times.", points = 10, icon = "Interface\\Icons\\Ability_Rogue_FeignDeath",
        progress = { stat = "deaths", max = 100 } },
    { id = 214, cat = 2, name = "Bloody Rare",        desc = "Kill 1,000 enemies.", points = 10, icon = "Interface\\Icons\\Ability_Warrior_Innerrage",
        progress = { stat = "killCount", max = 1000 } },
    { id = 215, cat = 2, name = "The Butcher",        desc = "Kill 10,000 enemies.", points = 25, icon = "Interface\\Icons\\Ability_Warrior_Rampage",
        progress = { stat = "killCount", max = 10000 } },
    { id = 216, cat = 2, name = "Level 5",            desc = "Reach level 5.",   points = 5, icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { id = 217, cat = 2, name = "Weapon Master",      desc = "Reach 300 skill in a weapon.", points = 10, icon = "Interface\\Icons\\INV_Sword_04",
        progress = { stat = "weaponSkill", max = 300 } },

    -- ============ QUESTS ============
    { id = 301, cat = 3, name = "The First Step",       desc = "Complete 1 quest.",       points = 10, icon = "Interface\\Icons\\INV_Scroll_03",
        progress = { stat = "questCount", max = 1 } },
    { id = 302, cat = 3, name = "10 Quests Completed",  desc = "Complete 10 quests.",     points = 10, icon = "Interface\\Icons\\INV_Scroll_03",
        progress = { stat = "questCount", max = 10 } },
    { id = 303, cat = 3, name = "50 Quests Completed",  desc = "Complete 50 quests.",     points = 10, icon = "Interface\\Icons\\INV_Scroll_04",
        progress = { stat = "questCount", max = 50 } },
    { id = 304, cat = 3, name = "100 Quests Completed", desc = "Complete 100 quests.",    points = 10, icon = "Interface\\Icons\\INV_Scroll_05",
        progress = { stat = "questCount", max = 100 } },
    { id = 305, cat = 3, name = "250 Quests Completed", desc = "Complete 250 quests.",    points = 25, icon = "Interface\\Icons\\INV_Scroll_06",
        progress = { stat = "questCount", max = 250 } },
    { id = 306, cat = 3, name = "500 Quests Completed", desc = "Complete 500 quests.",    points = 25, icon = "Interface\\Icons\\INV_Scroll_07",
        progress = { stat = "questCount", max = 500 } },
    { id = 307, cat = 3, name = "1000 Quests Completed",desc = "Complete 1,000 quests.",  points = 50, icon = "Interface\\Icons\\INV_Scroll_08",
        progress = { stat = "questCount", max = 1000 } },
    { id = 308, cat = 3, name = "2000 Quests Completed",desc = "Complete 2,000 quests.",  points = 50, icon = "Interface\\Icons\\INV_Scroll_08",
        progress = { stat = "questCount", max = 2000 } },
    { id = 309, cat = 3, name = "Daily Chores",         desc = "Complete a daily quest.", points = 10, icon = "Interface\\Icons\\INV_Misc_Note_02" },

    -- ============ EXPLORATION ============
    -- Eastern Kingdoms
    { id = 401, cat = 4, name = "Explore Elwynn Forest",      desc = "Explore Elwynn Forest.",       points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 402, cat = 4, name = "Explore Westfall",           desc = "Explore Westfall.",            points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 403, cat = 4, name = "Explore Duskwood",           desc = "Explore Duskwood.",            points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 404, cat = 4, name = "Explore Redridge Mountains", desc = "Explore Redridge Mountains.",  points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 405, cat = 4, name = "Explore Stranglethorn Vale", desc = "Explore Stranglethorn Vale.",  points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 406, cat = 4, name = "Explore Blasted Lands",      desc = "Explore the Blasted Lands.",   points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 407, cat = 4, name = "Explore Burning Steppes",    desc = "Explore the Burning Steppes.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 408, cat = 4, name = "Explore Searing Gorge",      desc = "Explore Searing Gorge.",       points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 409, cat = 4, name = "Explore Loch Modan",         desc = "Explore Loch Modan.",          points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 410, cat = 4, name = "Explore Wetlands",           desc = "Explore the Wetlands.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 411, cat = 4, name = "Explore Arathi Highlands",   desc = "Explore Arathi Highlands.",    points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 412, cat = 4, name = "Explore Hillsbrad Foothills",desc = "Explore Hillsbrad Foothills.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 413, cat = 4, name = "Explore Silverpine Forest",  desc = "Explore Silverpine Forest.",   points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 414, cat = 4, name = "Explore Tirisfal Glades",    desc = "Explore Tirisfal Glades.",     points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 415, cat = 4, name = "Explore Western Plaguelands",desc = "Explore Western Plaguelands.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 416, cat = 4, name = "Explore Eastern Plaguelands",desc = "Explore Eastern Plaguelands.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 417, cat = 4, name = "Explore The Hinterlands",    desc = "Explore The Hinterlands.",     points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 418, cat = 4, name = "Explore Badlands",           desc = "Explore the Badlands.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 419, cat = 4, name = "Explore Swamp of Sorrows",   desc = "Explore the Swamp of Sorrows.",points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 420, cat = 4, name = "Explore Deadwind Pass",      desc = "Explore Deadwind Pass.",       points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    -- Kalimdor
    { id = 421, cat = 4, name = "Explore Durotar",            desc = "Explore Durotar.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 422, cat = 4, name = "Explore The Barrens",        desc = "Explore The Barrens.",         points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 423, cat = 4, name = "Explore Ashenvale",          desc = "Explore Ashenvale.",           points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 424, cat = 4, name = "Explore Feralas",            desc = "Explore Feralas.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 425, cat = 4, name = "Explore Tanaris",            desc = "Explore Tanaris.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 426, cat = 4, name = "Explore Silithus",           desc = "Explore Silithus.",            points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 427, cat = 4, name = "Explore Winterspring",       desc = "Explore Winterspring.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 428, cat = 4, name = "Explore Un'Goro Crater",     desc = "Explore Un'Goro Crater.",      points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 429, cat = 4, name = "Explore Mulgore",            desc = "Explore Mulgore.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 430, cat = 4, name = "Explore Teldrassil",         desc = "Explore Teldrassil.",          points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 431, cat = 4, name = "Explore Darkshore",          desc = "Explore Darkshore.",           points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 432, cat = 4, name = "Explore Stonetalon Mountains", desc = "Explore Stonetalon Mountains.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 433, cat = 4, name = "Explore Desolace",           desc = "Explore Desolace.",            points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 434, cat = 4, name = "Explore Dustwallow Marsh",   desc = "Explore Dustwallow Marsh.",    points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 435, cat = 4, name = "Explore Thousand Needles",   desc = "Explore Thousand Needles.",    points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 436, cat = 4, name = "Explore Azshara",            desc = "Explore Azshara.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 437, cat = 4, name = "Explore Moonglade",          desc = "Explore Moonglade.",           points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    -- Meta
    { id = 450, cat = 4, name = "World Explorer",             desc = "Explore all 37 listed zones of Azeroth.", points = 50, icon = "Interface\\Icons\\INV_Misc_Map_01",
        progress = { stat = "zoneCount", max = 37 } },
    { id = 451, cat = 4, name = "Well Traveled",              desc = "Visit 10 zones.", points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01",
        progress = { stat = "zoneCount", max = 10 } },

    -- ============ PVP ============
    { id = 501, cat = 5, name = "First Blood",              desc = "Deliver a killing blow to an enemy player.", points = 10, icon = "Interface\\Icons\\INV_Sword_48" },
    { id = 502, cat = 5, name = "100 Honorable Kills",      desc = "Get 100 honorable kills.",   points = 10, icon = "Interface\\Icons\\INV_BannerPVP_01",
        progress = { stat = "honorKills", max = 100 } },
    { id = 503, cat = 5, name = "1000 Honorable Kills",     desc = "Get 1,000 honorable kills.", points = 25, icon = "Interface\\Icons\\INV_BannerPVP_02",
        progress = { stat = "honorKills", max = 1000 } },
    { id = 504, cat = 5, name = "10,000 Honorable Kills",   desc = "Get 10,000 honorable kills.",points = 50, icon = "Interface\\Icons\\INV_BannerPVP_03",
        progress = { stat = "honorKills", max = 10000 } },
    { id = 505, cat = 5, name = "Warsong Gulch Victory",    desc = "Win a Warsong Gulch match.", points = 10, icon = "Interface\\Icons\\INV_BannerPVP_01" },
    { id = 506, cat = 5, name = "Alterac Valley Victory",   desc = "Win an Alterac Valley match.", points = 10, icon = "Interface\\Icons\\INV_BannerPVP_03" },
    { id = 507, cat = 5, name = "Arathi Basin Victory",     desc = "Win an Arathi Basin match.", points = 10, icon = "Interface\\Icons\\INV_BannerPVP_02" },
    { id = 508, cat = 5, name = "Duelist",                  desc = "Win 10 duels.",              points = 10, icon = "Interface\\Icons\\INV_Sword_04",
        progress = { stat = "duelWins", max = 10 } },
    { id = 509, cat = 5, name = "Grand Duelist",            desc = "Win 100 duels.",             points = 25, icon = "Interface\\Icons\\INV_Sword_11",
        progress = { stat = "duelWins", max = 100 } },
    { id = 510, cat = 5, name = "Warsong Marathon",         desc = "Win 10 Warsong Gulch matches.",  points = 25, icon = "Interface\\Icons\\INV_BannerPVP_01",
        progress = { stat = "wsgWins", max = 10 } },
    { id = 511, cat = 5, name = "Veteran of Alterac",       desc = "Win 10 Alterac Valley matches.", points = 25, icon = "Interface\\Icons\\INV_BannerPVP_03",
        progress = { stat = "avWins", max = 10 } },
    { id = 512, cat = 5, name = "Master of Arathi",         desc = "Win 10 Arathi Basin matches.",   points = 25, icon = "Interface\\Icons\\INV_BannerPVP_02",
        progress = { stat = "abWins", max = 10 } },
    { id = 513, cat = 5, name = "Blood Sport",              desc = "Kill an enemy player of your own level or higher.", points = 10, icon = "Interface\\Icons\\INV_Sword_04" },
    { id = 514, cat = 5, name = "Bloodthirsty",             desc = "Get 50 killing blows on enemy players.", points = 15, icon = "Interface\\Icons\\INV_Sword_11",
        progress = { stat = "pvpKills", max = 50 } },
    { id = 515, cat = 5, name = "Battleground Regular",     desc = "Win 25 battlegrounds of any type.",      points = 25, icon = "Interface\\Icons\\INV_BannerPVP_02",
        progress = { stat = "bgWins", max = 25 } },

    -- ============ DUNGEONS & RAIDS ============
    -- 5-mans
    { id = 601, cat = 6, name = "Ragefire Chasm",   desc = "Defeat Taragaman the Hungerer in Ragefire Chasm.",   points = 10, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
    { id = 602, cat = 6, name = "The Deadmines",    desc = "Defeat Edwin VanCleef in the Deadmines.",            points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Human_01" },
    { id = 603, cat = 6, name = "Wailing Caverns",  desc = "Defeat Mutanus the Devourer.",                       points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Murloc_01" },
    { id = 604, cat = 6, name = "Shadowfang Keep",  desc = "Defeat Archmage Arugal.",                            points = 10, icon = "Interface\\Icons\\Ability_Warlock_Baneofdoom" },
    { id = 605, cat = 6, name = "The Stockade",     desc = "Defeat Bazil Thredd in The Stockade.",               points = 10, icon = "Interface\\Icons\\INV_Misc_Key_04" },
    { id = 606, cat = 6, name = "Blackfathom Deeps",desc = "Defeat Aku'mai.",                                    points = 10, icon = "Interface\\Icons\\Spell_Frost_Wisp" },
    { id = 607, cat = 6, name = "Razorfen Kraul",   desc = "Defeat Charlga Razorflank.",                         points = 10, icon = "Interface\\Icons\\INV_Misc_Bone_01" },
    { id = 608, cat = 6, name = "Gnomeregan",       desc = "Defeat Mekgineer Thermaplugg.",                      points = 10, icon = "Interface\\Icons\\Trade_Engineering" },
    { id = 609, cat = 6, name = "Razorfen Downs",   desc = "Defeat Amnennar the Coldbringer.",                   points = 10, icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" },
    { id = 610, cat = 6, name = "Scarlet Monastery",desc = "Defeat Scarlet Commander Mograine and High Inquisitor Whitemane.", points = 15, icon = "Interface\\Icons\\INV_Shield_05" },
    { id = 611, cat = 6, name = "Uldaman",          desc = "Defeat Archaedas.",                                  points = 10, icon = "Interface\\Icons\\INV_Misc_StoneTablet_08" },
    { id = 612, cat = 6, name = "Zul'Farrak",       desc = "Defeat Chief Ukorz Sandscalp.",                      points = 10, icon = "Interface\\Icons\\INV_Sword_16" },
    { id = 613, cat = 6, name = "Maraudon",         desc = "Defeat Princess Theradras.",                         points = 10, icon = "Interface\\Icons\\INV_Misc_Gem_Emerald_02" },
    { id = 614, cat = 6, name = "Sunken Temple",    desc = "Defeat Shade of Eranikus.",                          points = 10, icon = "Interface\\Icons\\Spell_Nature_ShadowWordPain" },
    { id = 615, cat = 6, name = "Blackrock Depths", desc = "Defeat Emperor Dagran Thaurissan.",                  points = 15, icon = "Interface\\Icons\\INV_Hammer_Unique_Sulfuras" },
    { id = 616, cat = 6, name = "Lower Blackrock Spire", desc = "Defeat Overlord Wyrmthalak.",                   points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { id = 617, cat = 6, name = "Upper Blackrock Spire", desc = "Defeat General Drakkisath.",                    points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { id = 618, cat = 6, name = "Stratholme",       desc = "Defeat Baron Rivendare.",                            points = 15, icon = "Interface\\Icons\\Ability_Mount_Undeadhorse" },
    { id = 619, cat = 6, name = "Scholomance",      desc = "Defeat Darkmaster Gandling.",                        points = 15, icon = "Interface\\Icons\\Spell_Shadow_Shadowbolt" },
    { id = 620, cat = 6, name = "Dire Maul: East",  desc = "Defeat Alzzin the Wildshaper.",                      points = 15, icon = "Interface\\Icons\\Ability_Druid_Maul" },
    { id = 621, cat = 6, name = "Dire Maul: West",  desc = "Defeat Prince Tortheldrin.",                         points = 15, icon = "Interface\\Icons\\INV_Sword_43" },
    { id = 622, cat = 6, name = "Dire Maul: North", desc = "Defeat King Gordok.",                                points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Ogre_01" },
    -- Raids
    { id = 650, cat = 6, name = "Molten Core",              desc = "Defeat Ragnaros in the Molten Core.",         points = 25, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
    { id = 651, cat = 6, name = "Onyxia's Lair",            desc = "Defeat Onyxia.",                              points = 25, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
    { id = 652, cat = 6, name = "Blackwing Lair",           desc = "Defeat Nefarian in Blackwing Lair.",          points = 25, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { id = 653, cat = 6, name = "Zul'Gurub",                desc = "Defeat Hakkar the Soulflayer.",               points = 15, icon = "Interface\\Icons\\INV_Misc_Idol_03" },
    { id = 654, cat = 6, name = "Ruins of Ahn'Qiraj",       desc = "Defeat Ossirian the Unscarred.",              points = 15, icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_05" },
    { id = 655, cat = 6, name = "Temple of Ahn'Qiraj",      desc = "Defeat C'Thun.",                              points = 50, icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_04" },
    { id = 656, cat = 6, name = "Naxxramas",                desc = "Defeat Kel'Thuzad in Naxxramas.",             points = 50, icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_03" },
    -- Meta
    { id = 680, cat = 6, name = "Classic Dungeonmaster",    desc = "Complete all 22 vanilla 5-man dungeon end bosses.", points = 25, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        progress = { stat = "dungeonsCleared", max = 22 } },
    { id = 681, cat = 6, name = "Classic Raider",           desc = "Defeat 5 vanilla raid end bosses.", points = 25, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
        progress = { stat = "raidsCleared", max = 5 } },
    { id = 682, cat = 6, name = "Ready for BWL",            desc = "Complete the attunement to Blackwing Lair.", points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01" },
    { id = 683, cat = 6, name = "MC Attuned",               desc = "Complete the attunement to Molten Core.",  points = 10, icon = "Interface\\Icons\\Spell_Fire_Volcano" },
    { id = 684, cat = 6, name = "Onyxia Attuned",           desc = "Complete the Onyxia attunement chain.",   points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },

    -- ============ PROFESSIONS ============
    { id = 701, cat = 7, name = "Apprentice",           desc = "Learn a primary profession.",                    points = 10, icon = "Interface\\Icons\\Trade_Engineering",
        progress = { stat = "profSkill", max = 1 } },
    { id = 702, cat = 7, name = "Journeyman",           desc = "Reach 150 skill in a primary profession.",       points = 10, icon = "Interface\\Icons\\Trade_BlackSmithing",
        progress = { stat = "profSkill", max = 150 } },
    { id = 703, cat = 7, name = "Expert",               desc = "Reach 225 skill in a primary profession.",       points = 10, icon = "Interface\\Icons\\Trade_LeatherWorking",
        progress = { stat = "profSkill", max = 225 } },
    { id = 704, cat = 7, name = "Artisan",              desc = "Reach 300 skill in a primary profession.",       points = 25, icon = "Interface\\Icons\\Trade_Alchemy",
        progress = { stat = "profSkill", max = 300 } },
    { id = 707, cat = 7, name = "Master of the Bandage",desc = "Reach 300 in First Aid.",                        points = 10, icon = "Interface\\Icons\\INV_Misc_Bandage_15" },
    { id = 708, cat = 7, name = "Master Alchemist",     desc = "Reach 300 in Alchemy.",                          points = 10, icon = "Interface\\Icons\\Trade_Alchemy" },
    { id = 709, cat = 7, name = "Master Blacksmith",    desc = "Reach 300 in Blacksmithing.",                    points = 10, icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { id = 710, cat = 7, name = "Master Enchanter",     desc = "Reach 300 in Enchanting.",                       points = 10, icon = "Interface\\Icons\\Trade_Engraving" },
    { id = 711, cat = 7, name = "Master Engineer",      desc = "Reach 300 in Engineering.",                      points = 10, icon = "Interface\\Icons\\Trade_Engineering" },
    { id = 712, cat = 7, name = "Master Herbalist",     desc = "Reach 300 in Herbalism.",                        points = 10, icon = "Interface\\Icons\\INV_Misc_Herb_07" },
    { id = 713, cat = 7, name = "Master Leatherworker", desc = "Reach 300 in Leatherworking.",                   points = 10, icon = "Interface\\Icons\\Trade_LeatherWorking" },
    { id = 714, cat = 7, name = "Master Miner",         desc = "Reach 300 in Mining.",                           points = 10, icon = "Interface\\Icons\\Trade_Mining" },
    { id = 715, cat = 7, name = "Master Skinner",       desc = "Reach 300 in Skinning.",                         points = 10, icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    { id = 716, cat = 7, name = "Master Tailor",        desc = "Reach 300 in Tailoring.",                        points = 10, icon = "Interface\\Icons\\Trade_Tailoring" },

    -- ============ REPUTATION ============
    { id = 801, cat = 8, name = "Friend of a Faction", desc = "Reach Friendly with any faction you did not start with.", points = 10, icon = "Interface\\Icons\\INV_Misc_Rune_01" },
    { id = 802, cat = 8, name = "Honored",             desc = "Reach Honored with any faction.",   points = 10, icon = "Interface\\Icons\\INV_Misc_Rune_02" },
    { id = 803, cat = 8, name = "Revered",             desc = "Reach Revered with any faction.",   points = 10, icon = "Interface\\Icons\\INV_Misc_Rune_03" },
    { id = 804, cat = 8, name = "Exalted",             desc = "Reach Exalted with any faction.",   points = 25, icon = "Interface\\Icons\\INV_Misc_Rune_04" },
    { id = 805, cat = 8, name = "Somebody Likes Me",   desc = "Reach Exalted with 5 factions.",    points = 25, icon = "Interface\\Icons\\INV_Misc_Rune_05",
        progress = { stat = "exaltedCount", max = 5 } },
    { id = 806, cat = 8, name = "Ambassador",          desc = "Reach Exalted with 10 factions.",   points = 50, icon = "Interface\\Icons\\INV_Misc_Rune_05",
        progress = { stat = "exaltedCount", max = 10 } },
    { id = 807, cat = 8, name = "Argent Dawn",         desc = "Reach Exalted with the Argent Dawn.", points = 10, icon = "Interface\\Icons\\INV_Jewelry_Talisman_07" },
    { id = 808, cat = 8, name = "Thorium Brotherhood", desc = "Reach Exalted with the Thorium Brotherhood.", points = 10, icon = "Interface\\Icons\\INV_Ingot_06" },
    { id = 809, cat = 8, name = "Timbermaw Hold",      desc = "Reach Exalted with Timbermaw Hold.", points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Furbolg_01" },
    { id = 810, cat = 8, name = "Cenarion Circle",     desc = "Reach Exalted with the Cenarion Circle.", points = 10, icon = "Interface\\Icons\\INV_Misc_Idol_04" },
    { id = 811, cat = 8, name = "Brood of Nozdormu",   desc = "Reach Exalted with the Brood of Nozdormu.", points = 10, icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_01" },
    { id = 812, cat = 8, name = "Zandalar Tribe",      desc = "Reach Exalted with the Zandalar Tribe.", points = 10, icon = "Interface\\Icons\\INV_Misc_Idol_03" },
    { id = 813, cat = 8, name = "Hydraxian Waterlords",desc = "Reach Exalted with the Hydraxian Waterlords.", points = 10, icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental" },

    -- ============ WORLD EVENTS ============
    { id = 901, cat = 9, name = "Merrymaker",              desc = "Attend the Feast of Winter Veil.",         points = 10, icon = "Interface\\Icons\\INV_Misc_Gift_01" },
    { id = 902, cat = 9, name = "Flame Warden",            desc = "Attend the Midsummer Fire Festival.",      points = 10, icon = "Interface\\Icons\\Spell_Fire_Fire" },
    { id = 903, cat = 9, name = "Trick or Treat!",         desc = "Receive a treat on Hallow's End.",         points = 10, icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { id = 904, cat = 9, name = "Elders of the Dungeons",  desc = "Honor an Elder inside a dungeon.",         points = 10, icon = "Interface\\Icons\\INV_Misc_Firecracker" },
    { id = 905, cat = 9, name = "Noble Garden",            desc = "Attend Noblegarden.",                      points = 10, icon = "Interface\\Icons\\INV_Egg_01" },
    { id = 906, cat = 9, name = "Love is in the Air",      desc = "Attend Love is in the Air.",               points = 10, icon = "Interface\\Icons\\INV_Misc_Gift_02" },
    { id = 907, cat = 9, name = "Children's Week",         desc = "Attend Children's Week.",                  points = 10, icon = "Interface\\Icons\\INV_Misc_Bell_01" },
    { id = 908, cat = 9, name = "Harvest Festival",        desc = "Attend the Harvest Festival.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Food_07" },
    { id = 909, cat = 9, name = "Lunar Festival",          desc = "Attend the Lunar Festival.",               points = 10, icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = 910, cat = 9, name = "Brewmaster",              desc = "Attend Brewfest.",                         points = 10, icon = "Interface\\Icons\\INV_Drink_05" },
    { id = 911, cat = 9, name = "Darkmoon Faire Attendee", desc = "Visit the Darkmoon Faire.",                points = 10, icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Blessings" },

    -- ============ FEATS OF STRENGTH ============
    { id = 1001, cat = 10, name = "Scarab Lord",           desc = "Bang the Gong at the gates of Ahn'Qiraj.",       points = 0, icon = "Interface\\Icons\\INV_Misc_Head_Bug_01" },
    { id = 1002, cat = 10, name = "Grand Marshal",         desc = "Attain the rank of Grand Marshal in the Alliance.", points = 0, icon = "Interface\\Icons\\INV_Shoulder_20" },
    { id = 1003, cat = 10, name = "High Warlord",          desc = "Attain the rank of High Warlord in the Horde.",  points = 0, icon = "Interface\\Icons\\INV_Shoulder_20" },
    { id = 1004, cat = 10, name = "Atiesh, Greatstaff of the Guardian", desc = "Wield Atiesh.",                     points = 0, icon = "Interface\\Icons\\INV_Staff_Medivh" },
    { id = 1005, cat = 10, name = "Thunderfury, Blessed Blade of the Windseeker", desc = "Wield Thunderfury.",     points = 0, icon = "Interface\\Icons\\INV_Sword_39" },
    { id = 1006, cat = 10, name = "Sulfuras, Hand of Ragnaros", desc = "Wield Sulfuras.",                          points = 0, icon = "Interface\\Icons\\INV_Hammer_Unique_Sulfuras" },

    -- ============ CLASS ============
    { id = 1101, cat = 11, name = "The Warrior's Path",   desc = "Reach level 60 as a Warrior.",  points = 25, icon = "Interface\\Icons\\INV_Sword_04" },
    { id = 1102, cat = 11, name = "The Paladin's Path",   desc = "Reach level 60 as a Paladin.",  points = 25, icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
    { id = 1103, cat = 11, name = "The Hunter's Path",    desc = "Reach level 60 as a Hunter.",   points = 25, icon = "Interface\\Icons\\INV_Weapon_Bow_07" },
    { id = 1104, cat = 11, name = "The Rogue's Path",     desc = "Reach level 60 as a Rogue.",    points = 25, icon = "Interface\\Icons\\INV_ThrowingKnife_04" },
    { id = 1105, cat = 11, name = "The Priest's Path",    desc = "Reach level 60 as a Priest.",   points = 25, icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { id = 1106, cat = 11, name = "The Shaman's Path",    desc = "Reach level 60 as a Shaman.",   points = 25, icon = "Interface\\Icons\\Spell_Nature_Lightning" },
    { id = 1107, cat = 11, name = "The Mage's Path",      desc = "Reach level 60 as a Mage.",     points = 25, icon = "Interface\\Icons\\INV_Staff_13" },
    { id = 1108, cat = 11, name = "The Warlock's Path",   desc = "Reach level 60 as a Warlock.",  points = 25, icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
    { id = 1109, cat = 11, name = "The Druid's Path",     desc = "Reach level 60 as a Druid.",    points = 25, icon = "Interface\\Icons\\Ability_Druid_Maul" },
    { id = 1110, cat = 11, name = "Trained",              desc = "Train a new class ability.",    points = 5,  icon = "Interface\\Icons\\INV_Misc_Book_11" },
    { id = 1111, cat = 11, name = "Talented",             desc = "Spend your first talent point.", points = 10, icon = "Interface\\Icons\\Spell_Nature_NatureBlessing" },
    { id = 1112, cat = 11, name = "Fully Specialized",    desc = "Spend all 51 talent points.",   points = 15, icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { id = 1113, cat = 11, name = "Respec'd",             desc = "Reset your talents at a class trainer.", points = 5, icon = "Interface\\Icons\\INV_Scroll_11" },

    -- ============ COLLECTIONS ============
    { id = 1201, cat = 12, name = "Pack Rat",             desc = "Equip a 16-slot bag.",          points = 10, icon = "Interface\\Icons\\INV_Misc_Bag_08" },
    { id = 1202, cat = 12, name = "Bag Full of Bags",     desc = "Equip four bags at once.",      points = 10, icon = "Interface\\Icons\\INV_Misc_Bag_10" },
    { id = 1203, cat = 12, name = "Vain",                 desc = "Equip a shirt.",                points = 5,  icon = "Interface\\Icons\\INV_Shirt_White_01" },
    { id = 1204, cat = 12, name = "Little Friends",       desc = "Own a non-combat pet.",         points = 10, icon = "Interface\\Icons\\INV_Box_PetCarrier_01" },
    { id = 1205, cat = 12, name = "Menagerie",            desc = "Own 10 non-combat pets.",       points = 25, icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
        progress = { stat = "petCount", max = 10 } },
    { id = 1206, cat = 12, name = "Stable Master",        desc = "Own 5 mounts.",                 points = 25, icon = "Interface\\Icons\\Ability_Mount_JungleTiger",
        progress = { stat = "mountCount", max = 5 } },
    { id = 1207, cat = 12, name = "Leading the Cavalry",  desc = "Own 25 mounts.",                points = 50, icon = "Interface\\Icons\\Ability_Mount_Undeadhorse",
        progress = { stat = "mountCount", max = 25 } },
    { id = 1208, cat = 12, name = "Well Equipped",        desc = "Equip a full set of blue (rare) gear.", points = 10, icon = "Interface\\Icons\\INV_Chest_Plate06" },
    { id = 1209, cat = 12, name = "Epic",                 desc = "Equip an epic (purple) item.",  points = 25, icon = "Interface\\Icons\\INV_Chest_Plate07" },

    -- ============ OCTOWOW ============
    { id = 1301, cat = 13, name = "Shell of a Time",      desc = "Log in on OctoWoW.",            points = 10, account = true, icon = "Interface\\Icons\\INV_Misc_MonsterHead_01" },
    { id = 1302, cat = 13, name = "High Elf Ally",        desc = "Create a High Elf character on OctoWoW.", points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Elf_01" },
    { id = 1303, cat = 13, name = "Goblin Trader",        desc = "Create a Goblin character on OctoWoW.",   points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Goblin_01" },
    { id = 1304, cat = 13, name = "OctoWoW Custom Content", desc = "Complete a custom OctoWoW quest.",       points = 15, icon = "Interface\\Icons\\INV_Misc_Note_04" },
    { id = 1305, cat = 13, name = "Karazhan Crypt",       desc = "Set foot in Karazhan Crypt on OctoWoW.",   points = 15, icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_02" },
    { id = 1306, cat = 13, name = "Emerald Sanctum",      desc = "Defeat a boss in the Emerald Sanctum on OctoWoW.", points = 25, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green" },
    { id = 1307, cat = 13, name = "OctoWoW Hero",         desc = "Reach level 60 on OctoWoW.",              points = 25, icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { id = 1308, cat = 13, name = "OctoWoW Explorer",     desc = "Visit an OctoWoW-only zone.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { id = 1309, cat = 13, name = "OctoWoW Reveler",      desc = "Participate in an OctoWoW community event.", points = 15, icon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Blessings" },

    -- ============ FISHING ============
    { id = 1401, cat = 14, name = "First Catch",          desc = "Catch your first fish.",            points = 5,  icon = "Interface\\Icons\\Trade_Fishing" },
    { id = 1402, cat = 14, name = "Fisherman",            desc = "Reach 150 in Fishing.",             points = 10, icon = "Interface\\Icons\\INV_Fishingpole_02",
        progress = { stat = "fishingSkill", max = 150 } },
    { id = 1403, cat = 14, name = "Master Angler",        desc = "Reach 300 in Fishing.",             points = 25, icon = "Interface\\Icons\\INV_Fishingpole_01",
        progress = { stat = "fishingSkill", max = 300 } },
    { id = 1404, cat = 14, name = "Deadliest Catch",      desc = "Catch a rare fish.",                points = 10, icon = "Interface\\Icons\\INV_Misc_Fish_02" },
    { id = 1405, cat = 14, name = "The Old Gnome and the Sea", desc = "Catch 500 fish.", points = 15, icon = "Interface\\Icons\\INV_Misc_Fish_03",
        progress = { stat = "fishCount", max = 500 } },
    { id = 1406, cat = 14, name = "Nat Pagle's Apprentice", desc = "Fish up a piece of gear.",         points = 10, icon = "Interface\\Icons\\INV_Fishingpole_03" },

    -- ============ COOKING ============
    { id = 1501, cat = 15, name = "First Dish",           desc = "Cook your first meal.",             points = 5,  icon = "Interface\\Icons\\INV_Misc_Food_15" },
    { id = 1502, cat = 15, name = "Sous Chef",            desc = "Reach 150 in Cooking.",             points = 10, icon = "Interface\\Icons\\INV_Misc_Food_49",
        progress = { stat = "cookingSkill", max = 150 } },
    { id = 1503, cat = 15, name = "Master Cook",          desc = "Reach 300 in Cooking.",             points = 25, icon = "Interface\\Icons\\INV_Misc_Food_15",
        progress = { stat = "cookingSkill", max = 300 } },
    { id = 1504, cat = 15, name = "Well Fed",             desc = "Eat a cooked dish.",                points = 5,  icon = "Interface\\Icons\\INV_Misc_Food_11" },
    { id = 1505, cat = 15, name = "Iron Chef",            desc = "Learn 25 unique recipes.",          points = 15, icon = "Interface\\Icons\\INV_Misc_Book_01",
        progress = { stat = "recipesLearned", max = 25 } },
    { id = 1506, cat = 15, name = "Gourmet",              desc = "Cook a rare feast.",                points = 15, icon = "Interface\\Icons\\INV_Misc_Food_65" },

    -- ============ HARDCORE ============
    { id = 1601, cat = 16, name = "One Life to Live",     desc = "Roll a Hardcore character.",        points = 10, icon = "Interface\\Icons\\Spell_Holy_GreaterHeal" },
    { id = 1602, cat = 16, name = "Survivor",             desc = "Reach level 20 on a Hardcore character.", points = 15, icon = "Interface\\Icons\\Spell_Holy_Heal" },
    { id = 1603, cat = 16, name = "Untouchable",          desc = "Reach level 40 on a Hardcore character.", points = 25, icon = "Interface\\Icons\\Spell_Holy_Renew" },
    { id = 1604, cat = 16, name = "Hardcore Hero",        desc = "Reach level 60 on a Hardcore character.", points = 50, icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit" },
    { id = 1605, cat = 16, name = "Close Call",           desc = "Survive dropping below 10% health.", points = 10, icon = "Interface\\Icons\\Spell_Shadow_Twilight" },
    { id = 1606, cat = 16, name = "No Retreat",           desc = "Defeat an elite of your level solo.", points = 15, icon = "Interface\\Icons\\Ability_Warrior_Innerrage" },

    -- ============ SOCIAL ============
    { id = 1701, cat = 17, name = "Say Hello",            desc = "Emote /wave at another player.",    points = 5,  icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { id = 1702, cat = 17, name = "Dance Off",            desc = "Use the /dance emote.",             points = 5,  icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01" },
    { id = 1703, cat = 17, name = "Guildmate",            desc = "Have 10 members in your guild.",    points = 10, icon = "Interface\\Icons\\INV_Shirt_Guildtabard_01" },
    { id = 1704, cat = 17, name = "Popular",              desc = "Add 5 friends to your friends list.", points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Human_02",
        progress = { stat = "friendCount", max = 5 } },
    { id = 1705, cat = 17, name = "Chatty",               desc = "Send 100 messages in chat.",        points = 10, icon = "Interface\\Icons\\INV_Letter_04",
        progress = { stat = "chatCount", max = 100 } },
    { id = 1706, cat = 17, name = "Group Therapy",        desc = "Complete a dungeon with a full party.", points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { id = 1707, cat = 17, name = "Wedding Bells",        desc = "Attend an in-game wedding.",        points = 15, icon = "Interface\\Icons\\INV_Misc_Gift_02" },

    -- ============ Additional Quests / Character ============
    { id = 310, cat = 3, name = "Loremaster of Elwynn",   desc = "Complete every quest in Elwynn Forest.", points = 10, icon = "Interface\\Icons\\INV_Misc_Book_11" },
    { id = 311, cat = 3, name = "Loremaster of Durotar",  desc = "Complete every quest in Durotar.",       points = 10, icon = "Interface\\Icons\\INV_Misc_Book_11" },
    { id = 312, cat = 3, name = "Class Quest Hero",       desc = "Complete a class-specific quest chain.", points = 15, icon = "Interface\\Icons\\INV_Scroll_02" },
    { id = 313, cat = 3, name = "Group Effort",           desc = "Complete a group (elite) quest.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Head_Human_02" },
    { id = 218, cat = 2, name = "Level 15",               desc = "Reach level 15.",                        points = 5, icon = "Interface\\Icons\\INV_Misc_Note_02" },
    { id = 219, cat = 2, name = "Level 25",               desc = "Reach level 25.",                        points = 5, icon = "Interface\\Icons\\Spell_Nature_EnchantArmor" },
    { id = 220, cat = 2, name = "Level 35",               desc = "Reach level 35.",                        points = 5, icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { id = 221, cat = 2, name = "Level 45",               desc = "Reach level 45.",                        points = 5, icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
    { id = 222, cat = 2, name = "Level 55",               desc = "Reach level 55.",                        points = 5, icon = "Interface\\Icons\\INV_Sword_48" },
    { id = 223, cat = 2, name = "Deep Pockets",           desc = "Carry 500 gold at once.",                points = 10, icon = "Interface\\Icons\\INV_Misc_Coin_02" },

    -- ============ CITIES ============
    { id = 1801, cat = 18, name = "Stormwind Sightseer",   desc = "Visit Stormwind City.",              points = 10, icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01" },
    { id = 1802, cat = 18, name = "Ironforge Ironmonger",  desc = "Visit Ironforge.",                   points = 10, icon = "Interface\\Icons\\INV_Hammer_16" },
    { id = 1803, cat = 18, name = "Darnassian Diplomat",   desc = "Visit Darnassus.",                   points = 10, icon = "Interface\\Icons\\Spell_Nature_Tranquility" },
    { id = 1804, cat = 18, name = "Undercity Underling",   desc = "Visit the Undercity.",               points = 10, icon = "Interface\\Icons\\Spell_Shadow_DeathPact" },
    { id = 1805, cat = 18, name = "Orgrimmar Outrider",    desc = "Visit Orgrimmar.",                   points = 10, icon = "Interface\\Icons\\INV_Sword_48" },
    { id = 1806, cat = 18, name = "Thunder Bluff Traveler",desc = "Visit Thunder Bluff.",               points = 10, icon = "Interface\\Icons\\Spell_Nature_EarthBind" },
    { id = 1807, cat = 18, name = "Alliance Tourist",      desc = "Visit all Alliance capital cities.", points = 25, icon = "Interface\\Icons\\INV_BannerPVP_02",
        progress = { stat = "allianceCitiesVisited", max = 3 } },
    { id = 1808, cat = 18, name = "Horde Tourist",         desc = "Visit all Horde capital cities.",    points = 25, icon = "Interface\\Icons\\INV_BannerPVP_01",
        progress = { stat = "hordeCitiesVisited", max = 3 } },

    -- ============ WEALTH (moved into Character & General) ============
    { id = 1901, cat = 2,  name = "First Silver",          desc = "Earn your first silver piece.",      points = 5,  icon = "Interface\\Icons\\INV_Misc_Coin_04" },
    { id = 1902, cat = 2,  name = "First Gold",            desc = "Earn your first gold piece.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Coin_01" },
    { id = 1903, cat = 2,  name = "Filthy Rich",           desc = "Carry 1,000 gold at once.",          points = 25, icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    { id = 1904, cat = 2,  name = "Made of Money",         desc = "Carry 10,000 gold at once.",         points = 50, icon = "Interface\\Icons\\INV_Misc_Coin_03" },
    { id = 1905, cat = 1,  name = "Auction House Regular", desc = "List 50 auctions.",                  points = 10, icon = "Interface\\Icons\\INV_Scroll_03",
        progress = { stat = "auctionsListed", max = 50 } },
    { id = 1906, cat = 1,  name = "Big Winner",            desc = "Win 100 auctions.",                  points = 15, icon = "Interface\\Icons\\INV_Misc_Coin_02",
        progress = { stat = "auctionsWon", max = 100 } },
    { id = 1907, cat = 1,  name = "Vendor Trash",          desc = "Sell 500 items to a vendor.",        points = 10, icon = "Interface\\Icons\\INV_Misc_Coin_04",
        progress = { stat = "vendorSales", max = 500 } },

    -- ============ TITLES ============
    { id = 2001, cat = 20, name = "Private",               desc = "Attain the PvP rank of Private / Scout.",             points = 10, icon = "Interface\\Icons\\INV_Shoulder_06" },
    { id = 2002, cat = 20, name = "Sergeant",              desc = "Attain PvP rank 3 (Sergeant).",                        points = 10, icon = "Interface\\Icons\\INV_Shoulder_09" },
    { id = 2003, cat = 20, name = "Knight",                desc = "Attain the PvP rank of Knight / Stone Guard.",        points = 15, icon = "Interface\\Icons\\INV_Shoulder_15" },
    { id = 2004, cat = 20, name = "Champion",              desc = "Attain PvP rank 9 (Knight-Champion / Centurion).",    points = 15, icon = "Interface\\Icons\\INV_Shoulder_17" },
    { id = 2005, cat = 20, name = "Marshal",               desc = "Attain PvP rank 12 (Marshal / General).",              points = 25, icon = "Interface\\Icons\\INV_Shoulder_19" },
    { id = 2006, cat = 20, name = "Field Marshal",         desc = "Attain the PvP rank of Field Marshal / Warlord.",     points = 25, icon = "Interface\\Icons\\INV_Shoulder_20" },
    { id = 2007, cat = 20, name = "Elder",                 desc = "Honor all Elders during the Lunar Festival.",         points = 15, icon = "Interface\\Icons\\INV_Misc_Rune_05" },
    { id = 2008, cat = 20, name = "The Diplomat",          desc = "Reach Exalted with a faction of the opposite continent.", points = 15, icon = "Interface\\Icons\\INV_Misc_Rune_04" },

    -- ============ LEGACY ============
    { id = 2101, cat = 21, name = "Classic Combatant",     desc = "Kill a boss in a pre-Cataclysm zone.",           points = 5,  icon = "Interface\\Icons\\INV_Sword_11" },
    { id = 2102, cat = 21, name = "Old World Traveler",    desc = "Ride a zeppelin or boat between continents.",    points = 5,  icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental" },
    { id = 2103, cat = 21, name = "Blackrock Veteran",     desc = "Complete a run of Blackrock Depths from start to finish.", points = 15, icon = "Interface\\Icons\\INV_Hammer_Unique_Sulfuras" },
    { id = 2104, cat = 21, name = "Ony Head Turn-In",      desc = "Deliver the head of Onyxia to a capital city.",  points = 15, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
    { id = 2105, cat = 21, name = "AQ Gate Opener",        desc = "Contribute to opening the gates of Ahn'Qiraj.",  points = 25, icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_05" },
    { id = 2106, cat = 21, name = "Silithyst Runner",      desc = "Turn in 10 Silithyst for your faction.",         points = 10, icon = "Interface\\Icons\\Spell_Nature_AbolishMagic",
        progress = { stat = "silithystTurnIns", max = 10 } },
    { id = 2107, cat = 21, name = "Dire Maul Book Club",   desc = "Read a book in the Dire Maul library.",          points = 10, icon = "Interface\\Icons\\INV_Misc_Book_07" },
    { id = 224, cat = 2, name = "Wealthy",                desc = "Carry 5,000 gold at once.",              points = 25, icon = "Interface\\Icons\\INV_Misc_Coin_03" },
}

-- Build lookup by id
RelationshipsAchievements_ById = {}
for i = 1, table.getn(RelationshipsAchievements_List) do
    local a = RelationshipsAchievements_List[i]
    RelationshipsAchievements_ById[a.id] = a
end

-- Zone -> exploration achievement id
RelationshipsAchievements_ZoneMap = {
    -- Eastern Kingdoms
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
    -- Kalimdor
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

-- Faction (exact name) -> exalted achievement id
RelationshipsAchievements_FactionMap = {
    ["Argent Dawn"] = 807,
    ["Thorium Brotherhood"] = 808,
    ["Timbermaw Hold"] = 809,
    ["Cenarion Circle"] = 810,
    ["Brood of Nozdormu"] = 811,
    ["Zandalar Tribe"] = 812,
    ["Hydraxian Waterlords"] = 813,
}

-- City (subzone / real zone) name -> city achievement id.
-- Vanilla ZONE_CHANGED_NEW_AREA fires with the capital name when you enter it.
RelationshipsAchievements_CityMap = {
    ["Stormwind City"]  = 1801,
    ["Ironforge"]       = 1802,
    ["Darnassus"]       = 1803,
    ["Undercity"]       = 1804,
    ["Orgrimmar"]       = 1805,
    ["Thunder Bluff"]   = 1806,
}

RelationshipsAchievements_AllianceCities = {
    ["Stormwind City"] = true, ["Ironforge"] = true, ["Darnassus"] = true,
}
RelationshipsAchievements_HordeCities = {
    ["Orgrimmar"] = true, ["Undercity"] = true, ["Thunder Bluff"] = true,
}

-- Exact end-boss names used by the combat death event. This makes every
-- dungeon/raid row earnable without relying on expansion-era encounter APIs.
RelationshipsAchievements_BossMap = {
    ["Taragaman the Hungerer"]={id=601}, ["Edwin VanCleef"]={id=602}, ["Mutanus the Devourer"]={id=603},
    ["Archmage Arugal"]={id=604}, ["Bazil Thredd"]={id=605}, ["Aku'mai"]={id=606}, ["Charlga Razorflank"]={id=607},
    ["Mekgineer Thermaplugg"]={id=608}, ["Amnennar the Coldbringer"]={id=609}, ["High Inquisitor Whitemane"]={id=610},
    ["Archaedas"]={id=611}, ["Chief Ukorz Sandscalp"]={id=612}, ["Princess Theradras"]={id=613},
    ["Shade of Eranikus"]={id=614}, ["Emperor Dagran Thaurissan"]={id=615}, ["Overlord Wyrmthalak"]={id=616},
    ["General Drakkisath"]={id=617}, ["Baron Rivendare"]={id=618}, ["Darkmaster Gandling"]={id=619},
    ["Alzzin the Wildshaper"]={id=620}, ["Prince Tortheldrin"]={id=621}, ["King Gordok"]={id=622},
    ["Ragnaros"]={id=650,raid=true}, ["Onyxia"]={id=651,raid=true}, ["Nefarian"]={id=652,raid=true},
    ["Hakkar"]={id=653,raid=true}, ["Ossirian the Unscarred"]={id=654,raid=true}, ["C'Thun"]={id=655,raid=true},
    ["Kel'Thuzad"]={id=656,raid=true}
}
