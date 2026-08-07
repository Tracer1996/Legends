-- LeafVE_Ach_Mounts.lua
-- Mount collection catalog, spellbook scanner, and model metadata.
-- Vanilla/Turtle WoW 1.12, Lua 5.0 compatible.

local MOUNT_CATALOG = {
  {id="mount_ancona_chicken_mount", name="Ancona Chicken Mount", creatureId=7394, family="bird", source="Turtle WoW mount", icon="Interface\\Icons\\Spell_Magic_PolymorphChicken"},
  {id="mount_arctic_wolf", name="Arctic Wolf", creatureId=5198, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_bear_mount", name="Bear Mount", creatureId=1129, family="bear", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_PolarBear_White"},
  {id="mount_black_battlestrider", name="Black Battlestrider",itemID=18243, creatureId=14334, family="mechanostrider", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_black_ostrich", name="Black Ostrich", creatureId=17476, family="bird", source="Turtle WoW mount", icon="Interface\\Icons\\Spell_Magic_PolymorphChicken"},
  {id="mount_black_panther", name="Black Panther", creatureId=977, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_black_ram", name="Black Ram", creatureId=12370, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_black_skeletal_horse", name="Black Skeletal Horse", creatureId=6486, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_black_stallion", name="Black Stallion",itemID=2411, creatureId=308, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_black_war_kodo", name="Black War Kodo",itemID=18247, creatureId=14333, family="kodo", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_black_war_ram", name="Black War Ram",itemID=18244, creatureId=14335, family="ram", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_black_war_raptor", name="Black War Raptor",itemID=18246, creatureId=14330, family="raptor", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_black_war_steed", name="Black War Steed",itemID=18241, creatureId=14332, family="horse", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_black_war_tiger", name="Black War Tiger",itemID=18242, creatureId=977, family="cat", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_black_war_wolf", name="Black War Wolf",itemID=18245, creatureId=14329, family="wolf", source="PvP reward mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_black_wolf", name="Black Wolf", creatureId=356, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_blue_mechanostrider", name="Blue Mechanostrider",itemID=8595, creatureId=12363, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_blue_qiraji_battle_tank", name="Blue Qiraji Battle Tank", creatureId=15713, family="qiraji", source="Dungeon or raid mount", icon="Interface\\Icons\\INV_Misc_Qirajicrystal_04"},
  {id="mount_blue_ram", name="Blue Ram", creatureId=4778, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_blue_skeletal_horse", name="Blue Skeletal Horse",itemID=13332, creatureId=12341, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_boar", name="Boar", creatureId=4535, family="boar", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Boar"},
  {id="mount_brown_camel", name="Brown Camel", creatureId=284, family="camel", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_brown_horse", name="Brown Horse",itemID=5656, creatureId=284, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_brown_kodo", name="Brown Kodo",itemID=15290, creatureId=12354, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_brown_ostrich", name="Brown Ostrich", creatureId=7394, family="bird", source="Turtle WoW mount", icon="Interface\\Icons\\Spell_Magic_PolymorphChicken"},
  {id="mount_brown_ram", name="Brown Ram",itemID=5872, creatureId=12372, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_brown_skeletal_horse", name="Brown Skeletal Horse",itemID=13333, creatureId=12342, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_brown_wolf", name="Brown Wolf",itemID=5668, creatureId=358, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_camel", name="Camel", creatureId=284, family="camel", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_cenarion_war_hippogryph", name="Cenarion War Hippogryph", creatureId=24488, family="hippogryph", source="Mount collection", icon="Interface\\Icons\\Ability_Mount_Gryphon_01"},
  {id="mount_charger", name="Charger", creatureId=14565, family="horse", source="Class mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_cheetah", name="Cheetah", creatureId=977, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_chestnut_mare", name="Chestnut Mare",itemID=5655, creatureId=4269, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_dire_wolf", name="Dire Wolf",itemID=5665, creatureId=12351, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_dreadsteed", name="Dreadsteed", creatureId=14505, family="horse", source="Class mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_emerald_raptor", name="Emerald Raptor",itemID=8588, creatureId=12346, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_felsteed", name="Felsteed", creatureId=304, family="horse", source="Class mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_frost_ram", name="Frost Ram",itemID=13329, creatureId=12371, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_frostwolf", name="Frostwolf", creatureId=14744, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_giraffe", name="Giraffe", creatureId=18739, family="giraffe", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_TallStrider"},
  {id="mount_goblin_trike", name="Goblin Trike", creatureId=2109, family="mechanical", source="Turtle WoW mount", icon="Interface\\Icons\\INV_Misc_Gear_01"},
  {id="mount_gray_ram", name="Gray Ram",itemID=5864, creatureId=12373, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_great_brown_kodo", name="Great Brown Kodo", creatureId=14549, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_great_elk", name="Great Elk", creatureId=15665, family="elk", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Stag"},
  {id="mount_great_green_kodo", name="Great Green Kodo", creatureId=12151, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_great_grey_kodo", name="Great Grey Kodo", creatureId=14550, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_great_sea_turtle", name="Great Sea Turtle", creatureId=17266, family="turtle", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Turtle"},
  {id="mount_great_white_kodo", name="Great White Kodo", creatureId=14542, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_green_kodo", name="Green Kodo", creatureId=12356, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_green_mechanostrider", name="Green Mechanostrider",itemID=13321, creatureId=12367, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_green_qiraji_battle_tank", name="Green Qiraji Battle Tank", creatureId=15715, family="qiraji", source="Dungeon or raid mount", icon="Interface\\Icons\\INV_Misc_Qirajicrystal_04"},
  {id="mount_green_skeletal_warhorse", name="Green Skeletal Warhorse", creatureId=12344, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_grey_kodo", name="Grey Kodo", creatureId=12355, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_hyena", name="Hyena", creatureId=4534, family="hyena", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Hyena"},
  {id="mount_ivory_raptor", name="Ivory Raptor", creatureId=12348, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_kodo_of_thunder_bluff", name="Kodo of Thunder Bluff", creatureId=12354, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_lion", name="Lion", creatureId=977, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_mechano_hog", name="Mechano-Hog", creatureId=2109, family="mechanical", source="Turtle WoW mount", icon="Interface\\Icons\\INV_Misc_Gear_01"},
  {id="mount_mechanostrider", name="Mechanostrider", creatureId=12363, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_moose", name="Moose", creatureId=15665, family="elk", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Stag"},
  {id="mount_mottled_red_raptor", name="Mottled Red Raptor", creatureId=12345, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_obsidian_raptor", name="Obsidian Raptor", creatureId=7703, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_ochre_skeletal_warhorse", name="Ochre Skeletal Warhorse", creatureId=11156, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_palomino", name="Palomino",itemID=2413, creatureId=306, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_pinto", name="Pinto",itemID=2414, creatureId=307, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_polar_bear", name="Polar Bear", creatureId=1196, family="bear", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_PolarBear_White"},
  {id="mount_purple_skeletal_warhorse", name="Purple Skeletal Warhorse", creatureId=14558, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_ram_of_ironforge", name="Ram of Ironforge", creatureId=12373, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_red_mechanostrider", name="Red Mechanostrider",itemID=8563, creatureId=12365, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_red_qiraji_battle_tank", name="Red Qiraji Battle Tank", creatureId=15716, family="qiraji", source="Dungeon or raid mount", icon="Interface\\Icons\\INV_Misc_Qirajicrystal_04"},
  {id="mount_red_skeletal_horse", name="Red Skeletal Horse",itemID=13331, creatureId=12343, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_red_skeletal_warhorse", name="Red Skeletal Warhorse", creatureId=14331, family="skeletal", source="Undead racial mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_red_wolf", name="Red Wolf", creatureId=4270, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_reindeer", name="Reindeer", creatureId=15665, family="elk", source="Mount collection", icon="Interface\\Icons\\Ability_Hunter_Pet_Stag"},
  {id="mount_riding_bear", name="Riding Bear", creatureId=1129, family="bear", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_PolarBear_White"},
  {id="mount_riding_turtle", name="Riding Turtle", creatureId=17266, family="turtle", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Turtle"},
  {id="mount_rivendare_s_deathcharger", name="Rivendare's Deathcharger",itemID=13335, creatureId=14568, family="skeletal", source="Dungeon or raid mount", icon="Interface\\Icons\\Ability_Mount_Undeadhorse"},
  {id="mount_sea_turtle", name="Sea Turtle", creatureId=17266, family="turtle", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Turtle"},
  {id="mount_silver_riding_turtle", name="Silver Riding Turtle", creatureId=17266, family="turtle", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Turtle"},
  {id="mount_snow_leopard", name="Snow Leopard", creatureId=10336, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_spotted_frostsaber", name="Spotted Frostsaber",itemID=8632, creatureId=12359, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_steam_tank_mount", name="Steam Tank Mount", creatureId=2109, family="mechanical", source="Turtle WoW mount", icon="Interface\\Icons\\INV_Misc_Gear_01"},
  {id="mount_steamscale", name="Steamscale", creatureId=2109, family="mechanical", source="Turtle WoW mount", icon="Interface\\Icons\\INV_Misc_Gear_01"},
  {id="mount_striped_dawnsaber", name="Striped Dawnsaber",itemID=81227, creatureId=12361, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_striped_frostsaber", name="Striped Frostsaber",itemID=8631, creatureId=12358, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_striped_nightsaber", name="Striped Nightsaber",itemID=8629, creatureId=12360, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_swift_bear", name="Swift Bear", creatureId=1189, family="bear", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_PolarBear_White"},
  {id="mount_swift_blue_raptor", name="Swift Blue Raptor", creatureId=14545, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_swift_brown_ram", name="Swift Brown Ram", creatureId=14546, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_swift_brown_steed", name="Swift Brown Steed", creatureId=14561, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_swift_brown_wolf", name="Swift Brown Wolf", creatureId=14540, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_swift_camel", name="Swift Camel", creatureId=14561, family="camel", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_swift_cheetah", name="Swift Cheetah", creatureId=977, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_swift_frostsaber", name="Swift Frostsaber", creatureId=14556, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_swift_frostwolf", name="Swift Frostwolf", creatureId=14744, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_swift_gray_ram", name="Swift Gray Ram", creatureId=14548, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_swift_gray_wolf", name="Swift Gray Wolf", creatureId=14541, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_swift_green_mechanostrider", name="Swift Green Mechanostrider", creatureId=14553, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_swift_mistsaber", name="Swift Mistsaber", creatureId=14555, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_swift_moose", name="Swift Moose", creatureId=24906, family="elk", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Stag"},
  {id="mount_swift_olive_raptor", name="Swift Olive Raptor", creatureId=14543, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_swift_orange_raptor", name="Swift Orange Raptor", creatureId=14544, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_swift_ostrich", name="Swift Ostrich", creatureId=17476, family="bird", source="Turtle WoW mount", icon="Interface\\Icons\\Spell_Magic_PolymorphChicken"},
  {id="mount_swift_palomino", name="Swift Palomino", creatureId=14561, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_swift_razzashi_raptor", name="Swift Razzashi Raptor", creatureId=15090, family="raptor", source="Dungeon or raid mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_swift_stormsaber", name="Swift Stormsaber", creatureId=14602, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_swift_timber_wolf", name="Swift Timber Wolf", creatureId=14539, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_swift_war_boar", name="Swift War Boar", creatureId=4535, family="boar", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Boar"},
  {id="mount_swift_white_mechanostrider", name="Swift White Mechanostrider", creatureId=14552, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_swift_white_ram", name="Swift White Ram", creatureId=14547, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_swift_white_steed", name="Swift White Steed", creatureId=14560, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_swift_yellow_mechanostrider", name="Swift Yellow Mechanostrider", creatureId=14551, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_swift_zulian_tiger", name="Swift Zulian Tiger",itemID=19902, creatureId=15104, family="cat", source="Dungeon or raid mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_tan_camel", name="Tan Camel", creatureId=306, family="camel", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_tawny_sabercat", name="Tawny Sabercat", creatureId=12361, family="cat", source="Mount collection", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_teal_kodo", name="Teal Kodo", creatureId=12357, family="kodo", source="Tauren racial mount", icon="Interface\\Icons\\Ability_Mount_Kodo_03"},
  {id="mount_timber_wolf", name="Timber Wolf",itemID=1132, creatureId=12353, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_trike", name="Trike", creatureId=2109, family="mechanical", source="Turtle WoW mount", icon="Interface\\Icons\\INV_Misc_Gear_01"},
  {id="mount_turquoise_raptor", name="Turquoise Raptor",itemID=8591, creatureId=12349, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_turtle_mount", name="Turtle Mount", creatureId=17266, family="turtle", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Turtle"},
  {id="mount_unpainted_mechanostrider", name="Unpainted Mechanostrider",itemID=13322, creatureId=12366, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_violet_raptor", name="Violet Raptor",itemID=8592, creatureId=12350, family="raptor", source="Troll racial mount", icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="mount_war_boar", name="War Boar", creatureId=4535, family="boar", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Hunter_Pet_Boar"},
  {id="mount_warhorse", name="Warhorse", creatureId=9158, family="horse", source="Class mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_white_camel", name="White Camel", creatureId=305, family="camel", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_white_lion", name="White Lion", creatureId=15926, family="cat", source="Night Elf racial mount", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_white_mechanostrider", name="White Mechanostrider", creatureId=12368, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_white_ostrich", name="White Ostrich", creatureId=17476, family="bird", source="Turtle WoW mount", icon="Interface\\Icons\\Spell_Magic_PolymorphChicken"},
  {id="mount_white_ram", name="White Ram",itemID=5873, creatureId=1262, family="ram", source="Dwarf racial mount", icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="mount_white_stallion", name="White Stallion",itemID=12353, creatureId=305, family="horse", source="Human racial mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_winter_reindeer", name="Winter Reindeer", creatureId=15706, family="elk", source="Mount collection", icon="Interface\\Icons\\Ability_Hunter_Pet_Stag"},
  {id="mount_winter_wolf", name="Winter Wolf", creatureId=359, family="wolf", source="Orc racial mount", icon="Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
  {id="mount_winterspring_frostsaber", name="Winterspring Frostsaber",itemID=13086, creatureId=14556, family="cat", source="Mount collection", icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="mount_yellow_mechanostrider", name="Yellow Mechanostrider", creatureId=14551, family="mechanostrider", source="Gnome racial mount", icon="Interface\\Icons\\Ability_Mount_MechaStrider"},
  {id="mount_yellow_qiraji_battle_tank", name="Yellow Qiraji Battle Tank", creatureId=15714, family="qiraji", source="Dungeon or raid mount", icon="Interface\\Icons\\INV_Misc_Qirajicrystal_04"},
  {id="mount_zebra", name="Zebra",itemID=50426, creatureId=27541, family="zhevra", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="mount_zhevra", name="Zhevra",itemID=50400, creatureId=27541, family="zhevra", source="Turtle WoW mount", icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
}


local MOUNT_CATEGORY = "Mounts"
local MOUNT_ICON = "Interface\\Icons\\Ability_Mount_RidingHorse"

local MOUNT_FAMILY_ICONS = {
  horse="Interface\\Icons\\Ability_Mount_RidingHorse", skeletal="Interface\\Icons\\Ability_Mount_Undeadhorse",
  wolf="Interface\\Icons\\Ability_Mount_WhiteDireWolf", ram="Interface\\Icons\\Ability_Mount_MountainRam",
  kodo="Interface\\Icons\\Ability_Mount_Kodo_03", raptor="Interface\\Icons\\Ability_Mount_Raptor",
  cat="Interface\\Icons\\Ability_Mount_BlackPanther", mechanostrider="Interface\\Icons\\Ability_Mount_MechaStrider",
  mechanical="Interface\\Icons\\Ability_Mount_MechaStrider", qiraji="Interface\\Icons\\INV_Misc_Qirajicrystal_04",
  turtle="Interface\\Icons\\Ability_Hunter_Pet_Turtle", bear="Interface\\Icons\\Ability_Mount_PolarBear_White",
  boar="Interface\\Icons\\Ability_Hunter_Pet_Boar", gryphon="Interface\\Icons\\Ability_Mount_Gryphon_01",
  hippogryph="Interface\\Icons\\Ability_Mount_Gryphon_01", drake="Interface\\Icons\\Ability_Mount_Drake_Red",
  scorpid="Interface\\Icons\\Ability_Hunter_Pet_Scorpid", crab="Interface\\Icons\\Ability_Hunter_Pet_Crab",
  crocolisk="Interface\\Icons\\Ability_Hunter_Pet_Crocolisk", talbuk="Interface\\Icons\\Ability_Hunter_Pet_Stag",
  bird="Interface\\Icons\\Ability_Hunter_Pet_TallStrider", elk="Interface\\Icons\\Ability_Hunter_Pet_Stag",
  zhevra="Interface\\Icons\\Ability_Mount_RidingHorse", giraffe="Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
  hyena="Interface\\Icons\\Ability_Hunter_Pet_Hyena", camel="Interface\\Icons\\Ability_Mount_RidingHorse",
  thunderlizard="Interface\\Icons\\Spell_Nature_Lightning", cloud="Interface\\Icons\\Spell_Nature_Cyclone",
}

local MOUNT_ITEM_ICON_CACHE={}
local function GetMountItemTexture(entry)
  if not entry or not entry.itemID or not GetItemInfo then return nil end
  local itemID=tonumber(entry.itemID)
  if not itemID or itemID<=0 then return nil end
  if MOUNT_ITEM_ICON_CACHE[itemID] then return MOUNT_ITEM_ICON_CACHE[itemID] end
  local itemName,itemLink,quality,itemLevel,requiredLevel,itemType,itemSubType,stackCount,equipSlot,texture=GetItemInfo(itemID)
  if texture and texture~="" then MOUNT_ITEM_ICON_CACHE[itemID]=texture return texture end
  return nil
end

local MOUNT_POINT_OVERRIDES = {
  ["Black Qiraji Battle Tank"] = 100,
  ["Rivendare's Deathcharger"] = 100,
  ["Swift Razzashi Raptor"] = 100,
  ["Swift Zulian Tiger"] = 100,
  ["Winterspring Frostsaber"] = 100,
  ["Naxxramas Deathcharger"] = 100,
  ["Black War Kodo"] = 75, ["Black War Ram"] = 75, ["Black War Raptor"] = 75,
  ["Black War Steed"] = 75, ["Black War Tiger"] = 75, ["Black War Wolf"] = 75,
}

local function GetMountPointValue(name, source)
  local override=MOUNT_POINT_OVERRIDES[tostring(name or "")]
  if override then return override end
  local text=string.lower(tostring(name or "").." "..tostring(source or ""))
  if string.find(text,"rivendare",1,true) or string.find(text,"zulian",1,true)
    or string.find(text,"razzashi",1,true) or string.find(text,"black qiraji",1,true)
    or string.find(text,"naxxramas",1,true) or string.find(text,"winterspring",1,true) then return 100 end
  if string.find(text,"dungeon",1,true) or string.find(text,"raid",1,true)
    or string.find(text,"qiraji",1,true) or string.find(text,"rare drop",1,true) then return 75 end
  if string.find(text,"pvp",1,true) or string.find(text,"reputation",1,true)
    or string.find(text,"turtle wow",1,true) or string.find(text,"seasonal",1,true)
    or string.find(text,"event",1,true) then return 50 end
  return 25
end

local function MountDifficulty(points)
  if points>=100 then return "Prestige" end
  if points>=75 then return "Rare" end
  if points>=50 then return "Uncommon" end
  return "Common"
end

for _,entry in ipairs(MOUNT_CATALOG) do
  entry.points=GetMountPointValue(entry.name,entry.source)
  entry.difficulty=MountDifficulty(entry.points)
  entry.achievementId=entry.id
  entry.icon=MOUNT_FAMILY_ICONS[entry.family or ""] or entry.icon or MOUNT_ICON
end

local MOUNT_MILESTONES = {
  {id="mount_collector_10",name="Stable Starter",goal=10,points=50},
  {id="mount_collector_25",name="Seasoned Rider",goal=25,points=100},
  {id="mount_collector_50",name="Mount Wrangler",goal=50,points=150},
  {id="mount_collector_75",name="Master of the Reins",goal=75,points=200},
  {id="mount_collector_100",name="A Hundred Saddles",goal=100,points=250},
}

local MOUNT_TOTAL=table.getn(MOUNT_CATALOG)
table.insert(MOUNT_MILESTONES,{id="mount_collector_all",name="Master of the Stables",goal=MOUNT_TOTAL,points=500})

-- Chat titles awarded alongside the milestone achievements above, mirroring
-- COMPANION_TITLE_DEFS in LeafVE_Ach_Companions.lua.
local MOUNT_TITLE_DEFS = {
  {id="title_mount_rider",name="Rider",achievement="mount_collector_10",desc="Awarded for collecting 10 mounts.",icon="Interface\\Icons\\Ability_Mount_RidingHorse"},
  {id="title_mount_horseman",name="Horseman",achievement="mount_collector_25",desc="Awarded for collecting 25 mounts.",icon="Interface\\Icons\\Ability_Mount_MountainRam"},
  {id="title_mount_cavalier",name="Cavalier",achievement="mount_collector_50",desc="Awarded for collecting 50 mounts.",icon="Interface\\Icons\\Ability_Mount_Raptor"},
  {id="title_mount_steedmaster",name="Steedmaster",achievement="mount_collector_75",desc="Awarded for collecting 75 mounts.",icon="Interface\\Icons\\Ability_Mount_BlackPanther"},
  {id="title_mount_stablemaster",name="Stablemaster",achievement="mount_collector_100",desc="Awarded for collecting 100 mounts.",icon="Interface\\Icons\\Ability_Mount_Gryphon_01"},
  {id="title_mount_ridemaster",name="Ridemaster",achievement="mount_collector_all",desc="Awarded for collecting every mount.",icon="Interface\\Icons\\Ability_Mount_Drake_Red"},
}

local MOUNT_MODEL_PRESETS = {
  -- Scales are intentionally close to 1.0. The previous 0.4-0.7 values made
  -- many creatures look like tiny silhouettes inside the preview box.
  wolf={scale=0.95,x=0,y=0,z=-0.10,facing=0.55},
  skeletal={scale=0.88,x=0,y=0,z=-0.12,facing=0.55},
  kodo={scale=0.68,x=0,y=0,z=-0.08,facing=0.58},
  raptor={scale=0.88,x=0,y=0,z=-0.16,facing=0.58},
  horse={scale=0.86,x=0,y=0,z=-0.12,facing=0.55},
  ram={scale=0.92,x=0,y=0,z=-0.10,facing=0.55},
  mechanostrider={scale=0.90,x=0,y=0,z=-0.13,facing=0.56},
  cat={scale=0.95,x=0,y=0,z=-0.10,facing=0.58},
  qiraji={scale=0.78,x=0,y=0,z=-0.08,facing=0.56},
  turtle={scale=0.88,x=0,y=0,z=-0.06,facing=0.58},
  hippogryph={scale=0.68,x=0,y=0,z=-0.08,facing=0.56},
  bird={scale=0.92,x=0,y=0,z=-0.08,facing=0.58},
  camel={scale=0.76,x=0,y=0,z=-0.16,facing=0.55},
  elk={scale=0.72,x=0,y=0,z=-0.14,facing=0.58},
  boar={scale=0.92,x=0,y=0,z=-0.08,facing=0.58},
  bear={scale=0.80,x=0,y=0,z=-0.08,facing=0.58},
  zhevra={scale=0.82,x=0,y=0,z=-0.12,facing=0.56},
  giraffe={scale=0.58,x=0,y=0,z=-0.20,facing=0.56},
  hyena={scale=0.95,x=0,y=0,z=-0.08,facing=0.58},
  mechanical={scale=0.78,x=0,y=0,z=-0.08,facing=0.56},
}

local MOUNT_FAMILY_FALLBACK = {
  wolf=358,skeletal=6486,kodo=12354,raptor=6075,horse=284,ram=12373,
  mechanostrider=12363,cat=12358,qiraji=15713,turtle=17266,hippogryph=24488,
  bird=7394,camel=284,elk=15665,boar=4535,bear=1129,zhevra=27541,
  giraffe=18739,hyena=4534,mechanical=2109,
}

-- Multiple known-good creatures per family. If a custom or obsolete creature
-- entry cannot be rendered by the client, the UI can still show a correctly
-- sized family preview instead of leaving a blank card.
local MOUNT_FAMILY_CANDIDATES = {
  wolf={358,356,5198,12351,14329},
  skeletal={6486,12341,12342,12344},
  kodo={12354,12355,12356,14549,14550},
  raptor={6075,12346,12347,12348,14330},
  horse={284,308,4269,14505,14565,14332},
  ram={12373,12370,12371,12372,14335},
  mechanostrider={12363,12364,12365,12367,14334},
  cat={12358,977,14336},
  qiraji={15713,15714,15715,15716},
  turtle={17266,3653},
  hippogryph={24488,9521},
  bird={7394,17476},
  camel={284},
  elk={15665},
  boar={4535},
  bear={1129},
  zhevra={27541},
  giraffe={18739},
  hyena={4534},
  mechanical={2109},
}

local function MountTrim(text)
  local s=tostring(text or "")
  s=string.gsub(s,"^%s+","")
  s=string.gsub(s,"%s+$","")
  return s
end

local function MountNormalize(text)
  local s=string.lower(MountTrim(text))
  s=string.gsub(s,"^summon:%s*","")
  s=string.gsub(s,"^summon%s+","")
  s=string.gsub(s,"^reins of the%s+","")
  s=string.gsub(s,"^reins of%s+","")
  s=string.gsub(s,"^horn of the%s+","")
  s=string.gsub(s,"^horn of%s+","")
  s=string.gsub(s,"^whistle of the%s+","")
  s=string.gsub(s,"^whistle of%s+","")
  s=string.gsub(s,"^harness:%s*","")
  s=string.gsub(s,"^riding%s+","")
  s=string.gsub(s,"[^a-z0-9]+"," ")
  s=string.gsub(s,"^%s+","")
  s=string.gsub(s,"%s+$","")
  s=string.gsub(s,"%s+"," ")
  s=string.gsub(s,"grey","gray")
  return s
end

local function MountSlug(text)
  return string.gsub(MountNormalize(text),"%s+","_")
end

local function DetectMountFamily(name)
  local s=MountNormalize(name)
  if string.find(s,"skeletal",1,true) or string.find(s,"deathcharger",1,true) or string.find(s,"invincible",1,true) then return "skeletal" end
  if string.find(s,"wolf",1,true) or string.find(s,"howler",1,true) then return "wolf" end
  if string.find(s,"kodo",1,true) then return "kodo" end
  if string.find(s,"raptor",1,true) then return "raptor" end
  if string.find(s,"ram",1,true) then return "ram" end
  if string.find(s,"saber",1,true) or string.find(s,"tiger",1,true) or string.find(s,"panther",1,true)
    or string.find(s,"cheetah",1,true) or string.find(s,"lion",1,true) or string.find(s,"leopard",1,true)
    or string.find(s,"furline",1,true) then return "cat" end
  if string.find(s,"mechanostrider",1,true) or string.find(s,"battlestrider",1,true) then return "mechanostrider" end
  if string.find(s,"qiraji",1,true) or string.find(s,"silithid",1,true) then return "qiraji" end
  if string.find(s,"turtle",1,true) or string.find(s,"grumbleshell",1,true) then return "turtle" end
  if string.find(s,"bear",1,true) then return "bear" end
  if string.find(s,"boar",1,true) then return "boar" end
  if string.find(s,"gryphon",1,true) then return "gryphon" end
  if string.find(s,"hippogryph",1,true) then return "hippogryph" end
  if string.find(s,"drake",1,true) or string.find(s,"dragon",1,true) then return "drake" end
  if string.find(s,"scorpid",1,true) then return "scorpid" end
  if string.find(s,"crab",1,true) or string.find(s,"crustacean",1,true) then return "crab" end
  if string.find(s,"crocolisk",1,true) then return "crocolisk" end
  if string.find(s,"talbuk",1,true) then return "talbuk" end
  if string.find(s,"tallstrider",1,true) or string.find(s,"ostrich",1,true) or string.find(s,"chicken",1,true)
    or string.find(s,"rooster",1,true) or string.find(s,"raven lord",1,true) then return "bird" end
  if string.find(s,"reindeer",1,true) or string.find(s,"elk",1,true) or string.find(s,"moose",1,true)
    or string.find(s,"stag",1,true) then return "elk" end
  if string.find(s,"zebra",1,true) or string.find(s,"zhevra",1,true) then return "zhevra" end
  if string.find(s,"giraffe",1,true) then return "giraffe" end
  if string.find(s,"hyena",1,true) then return "hyena" end
  if string.find(s,"camel",1,true) then return "camel" end
  if string.find(s,"thunder lizard",1,true) then return "thunderlizard" end
  if string.find(s,"cloud",1,true) then return "cloud" end
  if string.find(s,"rocket car",1,true) or string.find(s,"shredder",1,true) or string.find(s,"pounder",1,true)
    or string.find(s,"steam",1,true) or string.find(s,"trike",1,true) or string.find(s,"mechano",1,true)
    or string.find(s,"flying machine",1,true) then return "mechanical" end
  if string.find(s,"horse",1,true) or string.find(s,"steed",1,true) or string.find(s,"stallion",1,true)
    or string.find(s,"mare",1,true) or string.find(s,"pinto",1,true) or string.find(s,"palomino",1,true)
    or string.find(s,"charger",1,true) or string.find(s,"pony",1,true) or string.find(s,"unicorn",1,true) then return "horse" end
  return "horse"
end

local MOUNT_BY_KEY={}
for _,entry in ipairs(MOUNT_CATALOG) do
  MOUNT_BY_KEY[MountNormalize(entry.name)]=entry
  MOUNT_BY_KEY[string.gsub(MountNormalize(entry.name),"gray","grey")]=entry
end
MOUNT_BY_KEY[MountNormalize("Deathcharger's Reins")]=MOUNT_BY_KEY[MountNormalize("Rivendare's Deathcharger")]
MOUNT_BY_KEY[MountNormalize("Reins of the Rivendare's Deathcharger")]=MOUNT_BY_KEY[MountNormalize("Rivendare's Deathcharger")]


local function RegisterMountAchievement(entry)
  if not entry or not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  entry.points=entry.points or GetMountPointValue(entry.name,entry.source)
  entry.difficulty=entry.difficulty or MountDifficulty(entry.points)
  entry.achievementId=entry.achievementId or entry.id
  LeafVE_AchTest:AddAchievement(entry.achievementId,{
    id=entry.achievementId,name=entry.name,
    desc="Collect "..tostring(entry.name or "this mount")..". Source: "..tostring(entry.obtainedFrom or entry.source or "Mount collection")..".",
    category=MOUNT_CATEGORY,points=entry.points,icon=entry.icon or MOUNT_ICON,
    collectionType="mount",mountType="individual",source=entry.source,
    obtainedFrom=entry.obtainedFrom,difficulty=entry.difficulty,itemID=entry.itemID,
  })
end

local function RegisterMountAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  for _,entry in ipairs(MOUNT_CATALOG) do RegisterMountAchievement(entry) end
  for _,milestone in ipairs(MOUNT_MILESTONES) do
    LeafVE_AchTest:AddAchievement(milestone.id,{
      id=milestone.id,name=milestone.name,desc="Collect "..milestone.goal.." mounts.",
      category=MOUNT_CATEGORY,points=milestone.points,icon=MOUNT_ICON,
      collectionType="mount",mountType="milestone",
    })
    if LeafVE_AchTest.RegisterProgressDef then LeafVE_AchTest:RegisterProgressDef(milestone.id,{counter="mountCount",goal=milestone.goal}) end
  end
  if LeafVE_AchTest.AddTitle then
    for _,titleData in ipairs(MOUNT_TITLE_DEFS) do
      LeafVE_AchTest:AddTitle({id=titleData.id,name=titleData.name,chatName=titleData.name,achievement=titleData.achievement,prefix=false,category=MOUNT_CATEGORY,icon=titleData.icon or MOUNT_ICON,desc=titleData.desc})
    end
  end
end

local function AwardMountMilestones(total,silent)
  for _,milestone in ipairs(MOUNT_MILESTONES) do
    if total>=milestone.goal then LeafVE_AchTest:AwardAchievement(milestone.id,silent) end
  end
end

function LeafVE_AchTest:GetMountPointValue(name,source)
  return GetMountPointValue(name,source)
end

function LeafVE_AchTest:GetMountAchievementId(name)
  local entry=MOUNT_BY_KEY[MountNormalize(name)]
  return entry and (entry.achievementId or entry.id) or nil
end

RegisterMountAchievements()

local function EnsureMountState()
  if not LeafVE_AchTest_DB then return nil end
  if not LeafVE_AchTest_DB.mountCollection then LeafVE_AchTest_DB.mountCollection={} end
  local state=LeafVE_AchTest_DB.mountCollection
  if not state.owned then state.owned={} end
  if not state.icons then state.icons={} end
  if not state.dynamic then state.dynamic={} end
  return state
end

local MountScanTip=CreateFrame("GameTooltip","LeafVE_MountCollectionScanTip",UIParent,"GameTooltipTemplate")
MountScanTip:SetOwner(UIParent,"ANCHOR_NONE")

local function GetMountTooltipText(index,book)
  if not MountScanTip or not MountScanTip.ClearLines then return "" end
  MountScanTip:ClearLines()
  MountScanTip:SetSpell(index,book)
  local text=""
  local line
  for line=1,MountScanTip:NumLines() do
    local fs=getglobal("LeafVE_MountCollectionScanTipTextLeft"..line)
    if fs and fs:GetText() then text=text.."\n"..string.lower(fs:GetText()) end
  end
  return text
end

local MOUNT_REJECTED_SPELL_NAMES = {
  ["brutal leggings of ascendancy"] = true,
  ["brutal leggings of conquest"] = true,
  ["ephemeral pendant"] = true,
  ["ethereal boots of ascendancy"] = true,
  ["ethereal boots of conquest"] = true,
  ["fractured crown of ascendancy"] = true,
  ["fractured crown of conquest"] = true,
  ["nathrezim armor of deceit"] = true,
  ["nathrezim armor of treachery"] = true,
  ["shifting mantle of ascendancy"] = true,
  ["shifting mantle of conquest"] = true,
}

local function LooksLikeMountSpell(name,tooltip)
  local normalizedName=MountNormalize(name)
  if MOUNT_REJECTED_SPELL_NAMES[normalizedName] then return false end
  if MOUNT_BY_KEY[normalizedName] then return true end

  -- "mount speed" and the word "rideable" by themselves are unsafe: item
  -- effects and equipment passives can contain those phrases.  Unknown Turtle
  -- mounts are accepted only when their spell tooltip actually summons a
  -- rideable mount.
  local tip=string.lower(tostring(tooltip or ""))
  local summons=string.find(tip,"summons",1,true)
  local rideable=string.find(tip,"rideable",1,true)
  if summons and rideable then return true end
  if string.find(tip,"summons and dismisses your mount",1,true) then return true end
  return false
end

local function CopyDynamicEntries(state)
  local out={}
  local _,entry
  for _,entry in pairs(state.dynamic or {}) do table.insert(out,entry) end
  table.sort(out,function(a,b) return string.lower(tostring(a.name or ""))<string.lower(tostring(b.name or "")) end)
  return out
end

function LeafVE_AchTest:GetMountCollectionState()
  return EnsureMountState()
end

function LeafVE_AchTest:GetMountCollectionEntries()
  local out={}
  local _,entry
  for _,entry in ipairs(MOUNT_CATALOG) do table.insert(out,entry) end
  local state=EnsureMountState()
  if state then
    local dynamic=CopyDynamicEntries(state)
    for _,entry in ipairs(dynamic) do table.insert(out,entry) end
  end
  return out
end

function LeafVE_AchTest:GetMountModelPreset(family)
  return MOUNT_MODEL_PRESETS[family or ""] or MOUNT_MODEL_PRESETS.horse
end

function LeafVE_AchTest:GetMountFamilyFallback(family)
  return MOUNT_FAMILY_FALLBACK[family or ""] or MOUNT_FAMILY_FALLBACK.horse
end

function LeafVE_AchTest:GetMountFamilyIcon(family)
  return MOUNT_FAMILY_ICONS[family or ""] or MOUNT_ICON
end

function LeafVE_AchTest:GetMountDisplayIcon(entry,owned)
  local state=EnsureMountState()
  if owned and state and state.icons and entry and entry.id and state.icons[entry.id] then return state.icons[entry.id] end
  local itemTexture=GetMountItemTexture(entry)
  if itemTexture then return itemTexture end
  if entry and entry.icon and entry.icon~="" then return entry.icon end
  return MOUNT_FAMILY_ICONS[(entry and entry.family) or ""] or MOUNT_ICON
end

function LeafVE_AchTest:GetMountCreatureCandidates(entry)
  local candidates={}
  local seen={}
  local function AddCandidate(id)
    local n=tonumber(id)
    if n and n>0 and not seen[n] then
      seen[n]=true
      table.insert(candidates,n)
    end
  end

  if entry then
    AddCandidate(entry.creatureId)
    if type(entry.creatureIds)=="table" then
      local _,id
      for _,id in ipairs(entry.creatureIds) do AddCandidate(id) end
    end
  end

  local family=entry and entry.family or "horse"
  local familyCandidates=MOUNT_FAMILY_CANDIDATES[family or ""] or MOUNT_FAMILY_CANDIDATES.horse
  local _,id
  for _,id in ipairs(familyCandidates or {}) do AddCandidate(id) end
  AddCandidate(MOUNT_FAMILY_FALLBACK[family or ""] or MOUNT_FAMILY_FALLBACK.horse)
  return candidates
end

-- Same real spellbook icon (GetSpellTexture at scan time) written into the
-- same shared table the Collections module's own scan and the achievement
-- row/toast/card all read from -- one consistent storage location instead
-- of icons living only on the local achievement definition. Mirrors
-- CaptureCompanionIcon in LeafVE_Ach_Companions.lua.
local function CaptureMountIcon(name,icon)
  if not icon or icon=="" or not name or name=="" or not LeafVE_AchTest_DB then return end
  LeafVE_AchTest_DB.collections=LeafVE_AchTest_DB.collections or {}
  LeafVE_AchTest_DB.collections.mounts=LeafVE_AchTest_DB.collections.mounts or {}
  local saved=LeafVE_AchTest_DB.collections.mounts
  if type(saved[name])~="table" then saved[name]={} end
  saved[name].icon=icon
end

function LeafVE_AchTest:ScanMountCollection(silent)
  local state=EnsureMountState()
  if not state or not GetSpellName then return end
  local owned={}
  local icons={}
  local dynamic={}
  local book=BOOKTYPE_SPELL or "spell"
  local index=1
  while true do
    local spellName=GetSpellName(index,book)
    if not spellName then break end
    local tooltip=GetMountTooltipText(index,book)
    if LooksLikeMountSpell(spellName,tooltip) then
      local entry=MOUNT_BY_KEY[MountNormalize(spellName)]
      local spellIcon=GetSpellTexture and GetSpellTexture(index,book) or nil
      if entry then
        owned[entry.id]=true
        if spellIcon then
          icons[entry.id]=spellIcon
          entry.icon=spellIcon
          -- Keyed by the literal spell name (not the catalog's display
          -- name) to guarantee this lands on the exact same table entry
          -- as the Collections module's own scan, which keys off
          -- GetSpellName's raw result too.
          CaptureMountIcon(spellName,spellIcon)
        end
        RegisterMountAchievement(entry)
        LeafVE_AchTest:AwardAchievement(entry.achievementId or entry.id,silent)
      else
        local family=DetectMountFamily(spellName)
        local dynamicId="mount_dynamic_"..MountSlug(spellName)
        dynamic[dynamicId]={
          id=dynamicId,name=spellName,creatureId=MOUNT_FAMILY_FALLBACK[family] or MOUNT_FAMILY_FALLBACK.horse,
          family=family,source="Detected Turtle WoW mount",icon=spellIcon or "Interface\\Icons\\INV_Misc_QuestionMark",dynamic=true,
          points=GetMountPointValue(spellName,"Detected Turtle WoW mount"),
        }
        dynamic[dynamicId].difficulty=MountDifficulty(dynamic[dynamicId].points)
        dynamic[dynamicId].achievementId=dynamicId
        owned[dynamicId]=true
        if spellIcon then
          icons[dynamicId]=spellIcon
          CaptureMountIcon(spellName,spellIcon)
        end
        RegisterMountAchievement(dynamic[dynamicId])
        LeafVE_AchTest:AwardAchievement(dynamicId,silent)
      end
    end
    index=index+1
  end
  state.owned=owned
  state.icons=icons
  state.dynamic=dynamic
  state.lastScan=time and time() or 0
  if LeafVE_AchTest.SetCounter and LeafVE_AchTest.ShortName then
    local me=LeafVE_AchTest.ShortName(UnitName("player"))
    if me then
      local total=0
      local _id
      for _id in pairs(owned) do total=total+1 end
      LeafVE_AchTest.SetCounter(me,"mountCount",total)
      AwardMountMilestones(total,silent)
      if LeafVE_AchTest_DB and LeafVE_AchTest_DB.achievements and LeafVE_AchTest_DB.achievements[me] then
        local earned=LeafVE_AchTest_DB.achievements[me]
        for _,catalogEntry in ipairs(MOUNT_CATALOG) do
          if earned[catalogEntry.achievementId or catalogEntry.id] then earned[catalogEntry.achievementId or catalogEntry.id].points=catalogEntry.points end
        end
        for dynamicId,dynamicEntry in pairs(dynamic) do if earned[dynamicId] then earned[dynamicId].points=dynamicEntry.points end end
        for _,milestone in ipairs(MOUNT_MILESTONES) do if earned[milestone.id] then earned[milestone.id].points=milestone.points end end
      end
    end
  end
  if LeafVE_AchTest.UI and LeafVE_AchTest.UI.currentView=="mounts" and LeafVE_AchTest.UI.RefreshMounts then
    LeafVE_AchTest.UI:RefreshMounts()
  end
end

LeafVE_AchTest.MountCatalog=MOUNT_CATALOG
LeafVE_AchTest.MountModelPresets=MOUNT_MODEL_PRESETS

local mountCollectionEvents=CreateFrame("Frame")
mountCollectionEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
mountCollectionEvents:RegisterEvent("SPELLS_CHANGED")
mountCollectionEvents:SetScript("OnEvent",function()
  if event=="PLAYER_ENTERING_WORLD" then
    LeafVE_AchTest:ScanMountCollection(true)
  elseif event=="SPELLS_CHANGED" then
    LeafVE_AchTest:ScanMountCollection(false)
  end
end)
