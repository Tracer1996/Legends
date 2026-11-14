-- LeafVE_ConsumablesDB.lua
-- Internal database of food and drink item IDs for Vanilla / Turtle WoW.
-- Provides a deterministic consumable classifier keyed by item ID.
--
-- Current use: reference data for future inventory-hookâ€“based detection
-- (UseContainerItem / UseInventoryItem / UseAction hooks) that can
-- supplement the channel-event and chat-message approach in
-- LeafVillageAchievements.lua.
--
-- Classification:
--   LeafVE_ConsumablesDB.food[itemID]  = true  â†’ food item (restores health)
--   LeafVE_ConsumablesDB.drink[itemID] = true  â†’ drink item (restores mana)
--
-- Item IDs are from the Vanilla 1.12 / Turtle WoW item database.

LeafVE_ConsumablesDB = LeafVE_ConsumablesDB or {}
LeafVE_ConsumablesDB.food  = {}
LeafVE_ConsumablesDB.drink = {}

-- ---------------------------------------------------------------------------
-- Food (health-restoring, eaten consumables)
-- ---------------------------------------------------------------------------
local food = LeafVE_ConsumablesDB.food

-- Levels 1â€“10
food[117]   = true  -- Tough Jerky
food[422]   = true  -- Charred Wolf Meat
food[724]   = true  -- Cured Ham Steak
food[1015]  = true  -- Shiny Red Apple
food[1016]  = true  -- Tel'Abim Banana
food[1017]  = true  -- Snapvine Watermelon
food[1018]  = true  -- Goldenbark Apple
food[1019]  = true  -- Moon Harvest Pumpkin
food[1020]  = true  -- Deep Fried Plantains
food[1407]  = true  -- Mutton Chop
food[2070]  = true  -- Coyote Steak
food[2680]  = true  -- Roasted Kodo Meat
food[2683]  = true  -- Roasted Moongraze Stag
food[2684]  = true  -- Roasted Boar Meat
food[4540]  = true  -- Dalaran Sharp
food[4599]  = true  -- Tough Hunk of Bread
food[4601]  = true  -- Dwarven Mild
food[4602]  = true  -- Fine Aged Cheddar
food[4603]  = true  -- Freshly Baked Bread
food[4604]  = true  -- Mulgore Spice Bread
food[4606]  = true  -- Soft Banana Bread
food[4608]  = true  -- Moist Cornbread
food[4609]  = true  -- Haunch of Meat

-- Levels 10â€“30 (cooked and raw fish / meats)
food[1179]  = true  -- Herb Baked Egg
food[4457]  = true  -- Crocolisk Steak
food[4458]  = true  -- Blood Sausage
food[4459]  = true  -- Mok'Nathal Shortribs
food[4460]  = true  -- Soothing Turtle Bisque
food[4461]  = true  -- Big Bear Steak
food[4462]  = true  -- Hot Lion Chops
food[4463]  = true  -- Tasty Lion Steak
food[4464]  = true  -- Dry Pork Ribs
food[4592]  = true  -- Brilliant Smallfish (raw)
food[4538]  = true  -- Longjaw Mud Snapper (cooked)
food[5487]  = true  -- Clam Chowder
food[5524]  = true  -- Bristle Whisker Catfish (cooked)
food[5525]  = true  -- Loch Frenzy Delight
food[6038]  = true  -- Giant Clam Scorcho
food[6291]  = true  -- Fillet of Frenzy

-- Levels 30â€“50
food[4544]  = true  -- Crispy Bat Wing
food[12202] = true  -- Roast Raptor
food[12207] = true  -- Jungle Stew
food[12212] = true  -- Smoked Bear Meat
food[12216] = true  -- Tender Wolf Steak
food[13724] = true  -- Dragonbreath Chili (Well Fed, +2% Fire Dmg)
food[13938] = true  -- Monster Omelet (Well Fed, +8 Spi)

-- Levels 50â€“60 (Well Fed buffs)
food[13927] = true  -- Grilled Squid (+10 Agility)
food[13928] = true  -- Hot Smoked Bass (+6 Spi)
food[17222] = true  -- Baked Salmon (+6 Spi)
food[18254] = true  -- Runn Tum Tuber Surprise (+10 Intellect)
food[20074] = true  -- Heavy Crocolisk Stew (+8 Spi)
food[20075] = true  -- Nightfin Soup (+8 MP5)
food[20452] = true  -- Smoked Desert Dumplings (+20 Str)
food[20636] = true  -- Sagefish Delight (+6 MP5)
food[20637] = true  -- Lobster Stew (+20 Spi)
food[20638] = true  -- Mightfish Steak (+6 all stats)
food[21023] = true  -- Dirge's Kickin' Chimaerok Chops (+25 Str)
food[22895] = true  -- Alterac Swiss (+8 Spi)
food[8932]  = true  -- Savory Deviate Delight (polymorphs player)

-- Holiday / seasonal
food[5097]  = true  -- Gingerbread Cookie
food[17197] = true  -- Gingerbread Cookie (seasonal variant)
food[21215] = true  -- Egg Nog

-- ---------------------------------------------------------------------------
-- Drinks (mana-restoring beverages)
-- ---------------------------------------------------------------------------
local drink = LeafVE_ConsumablesDB.drink

-- Purchased / crafted water
drink[159]   = true  -- Refreshing Spring Water (vendor)
drink[1205]  = true  -- Melon Juice
drink[1207]  = true  -- Moonberry Juice
drink[1645]  = true  -- Moonberry Juice (alt ID)
drink[1708]  = true  -- Sweet Nectar
drink[3927]  = true  -- Morning Glory Dew (inn keeper)
drink[8766]  = true  -- Goldthorn Tea

-- Conjured Water (mage ranks 1â€“7)
drink[3702]  = true  -- Conjured Water (rank 1)
drink[3703]  = true  -- Conjured Fresh Water (rank 2)
drink[3704]  = true  -- Conjured Purified Water (rank 3)
drink[4825]  = true  -- Conjured Water (rank 1, alt)
drink[5349]  = true  -- Conjured Purified Water (rank 3, alt)
drink[5350]  = true  -- Conjured Fresh Water (rank 2, alt)
drink[8077]  = true  -- Conjured Sparkling Water (rank 4)
drink[8078]  = true  -- Conjured Mineral Water (rank 5)
drink[8079]  = true  -- Conjured Sparkling Water (rank 6)
drink[9453]  = true  -- Crystal Water
drink[24249] = true  -- Conjured Glacier Water (rank 7)

-- Alcoholic / novelty drinks
drink[19221] = true  -- Rumsey Rum Light
drink[19299] = true  -- Rumsey Rum Black Label
drink[19300] = true  -- Gordok Green Grog
drink[20978] = true  -- Rumsey Rum