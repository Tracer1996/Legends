-- GENERATED from AshenKeeper\AshenKeeper_Config.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- AshenKeeper configuration. ALL prices, rewards, targets and RP lines live in this file
-- (admins can override most values at runtime; overrides are stored in AshenKeeperDB).
-- itemID = 0 means "not verified": the name is then used for matching and the icon falls back.

------------------------------------------------------------------------------
-- Quartermaster shop (AE price list)
-- requisitionType: "MAJOR" (flasks only) or "MINOR"
-- priority: CRITICAL / SECONDARY (current raid tier: Molten Core + Blackwing Lair)
-- stock is only used in manual stock mode; in bag mode stock = what the Keeper really holds.
-- price is the BASE price: the shop charges price x QuartermasterPriceMultiplier (now 1: price is the shop price).
-- donateAE: AE paid per item donated (else price x QuartermasterItemDonationRate); never more than half the price.
-- Prices and donateAE follow /ak donaterate on the 10/23 Auction House scan: shop = gold x ~645 AE/g (Mongoose
-- = 2000), donateAE = 30% of the shop price. Items added from the consumables guide (marked "guide") were
-- priced from older aux history (or an estimate, "est") until the next scan: /ak ahscan, then /ak donaterate apply.
-- lvl: required level to buy it (the item's own "Requires Level"; 0 = none, e.g. bags). The Keeper checks the
-- buyer's level in its guild roster.
-- fb: Flamebound only (QuartermasterFlameboundRank and every rank above it). Officers can switch it per item in
-- Manage > Shop. Every flask defaults to it.
------------------------------------------------------------------------------
QuartermasterItems = {
  FLASK_TITANS     = { code = "FT", itemID = 13510, name = "Flask of the Titans",              price = 20000, donateAE = 6000, lvl = 50, fb = true, requisitionType = "MAJOR", stock = 0, reserve = 4, enabled = true, priority = "CRITICAL" },
  FLASK_SUPREME    = { code = "SP", itemID = 13512, name = "Flask of Supreme Power",           price = 18750, donateAE = 5625, lvl = 50, fb = true, requisitionType = "MAJOR", stock = 0, reserve = 4, enabled = true, priority = "CRITICAL" },
  GREATER_FIRE_POT = { code = "GF", itemID = 13457, name = "Greater Fire Protection Potion",   price = 1425, donateAE = 428,  lvl = 48, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  MONGOOSE         = { code = "MG", itemID = 13452, name = "Elixir of the Mongoose",           price = 2000, donateAE = 600,  lvl = 46, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  WF_FIREWATER     = { code = "FW", itemID = 12820, name = "Winterfall Firewater",             price = 150,  lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  MANA_OIL         = { code = "MO", itemID = 20748, name = "Brilliant Mana Oil",               price = 5950, donateAE = 1785, lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  ELIXIR_GIANTS    = { code = "EG", itemID = 9206,  name = "Elixir of Giants",                 price = 900,  donateAE = 270,  lvl = 38, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  GREATER_ARCANE_E = { code = "GE", itemID = 13454, name = "Greater Arcane Elixir",            price = 1300, donateAE = 390,  lvl = 47, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  SHARPENING_STONE = { code = "SS", itemID = 18262, name = "Elemental Sharpening Stone",       price = 2000, donateAE = 600,  lvl = 50, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  GREATER_ARCANE_P = { code = "GA", itemID = 13461, name = "Greater Arcane Protection Potion", price = 550,  donateAE = 165,  lvl = 48, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  FORTITUDE        = { code = "EF", itemID = 3825,  name = "Elixir of Fortitude",              price = 250,  donateAE = 75,   lvl = 25, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  WISDOM           = { code = "EW", itemID = 3383,  name = "Elixir of Wisdom",                 price = 60,   donateAE = 18,   lvl = 10, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  DREAMTONIC       = { code = "DT", itemID = 61423, name = "Dreamtonic",                       price = 700,  donateAE = 210,  lvl = 50, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  -- Levelling potions, oils and bags.
  HEAL_MINOR       = { code = "H1", itemID = 118,   name = "Minor Healing Potion",             price = 10,   donateAE = 3,    lvl = 1,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  HEAL_LESSER      = { code = "H2", itemID = 858,   name = "Lesser Healing Potion",            price = 10,   donateAE = 3,    lvl = 3,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  HEAL_POT         = { code = "H3", itemID = 929,   name = "Healing Potion",                   price = 10,   donateAE = 3,    lvl = 12, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  HEAL_GREATER     = { code = "H4", itemID = 1710,  name = "Greater Healing Potion",           price = 25,   donateAE = 8,    lvl = 21, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  HEAL_SUPERIOR    = { code = "H5", itemID = 3928,  name = "Superior Healing Potion",          price = 20,   donateAE = 6,    lvl = 35, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  HEAL_MAJOR       = { code = "H6", itemID = 13446, name = "Major Healing Potion",             price = 250,  donateAE = 75,   lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  MANA_MINOR       = { code = "M1", itemID = 2455,  name = "Minor Mana Potion",                price = 10,   donateAE = 3,    lvl = 5,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_LESSER      = { code = "M2", itemID = 3385,  name = "Lesser Mana Potion",               price = 15,   donateAE = 5,    lvl = 14, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_POT         = { code = "M3", itemID = 3827,  name = "Mana Potion",                      price = 50,   donateAE = 15,   lvl = 22, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_GREATER     = { code = "M4", itemID = 6149,  name = "Greater Mana Potion",              price = 30,   donateAE = 9,    lvl = 31, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_SUPERIOR    = { code = "M5", itemID = 13443, name = "Superior Mana Potion",             price = 200,  donateAE = 60,   lvl = 41, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_MAJOR       = { code = "M6", itemID = 13444, name = "Major Mana Potion",                price = 1000, donateAE = 300,  lvl = 49, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  MANA_OIL_MINOR   = { code = "O1", itemID = 20745, name = "Minor Mana Oil",                   price = 350,  donateAE = 105,  lvl = 20, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  MANA_OIL_LESSER  = { code = "O2", itemID = 20747, name = "Lesser Mana Oil",                  price = 1400, donateAE = 420,  lvl = 40, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  WIZ_OIL_MINOR    = { code = "W1", itemID = 20744, name = "Minor Wizard Oil",                 price = 90,   donateAE = 27,   lvl = 5,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  WIZ_OIL_LESSER   = { code = "W2", itemID = 20746, name = "Lesser Wizard Oil",                price = 650,  donateAE = 195,  lvl = 30, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  WIZ_OIL          = { code = "W3", itemID = 20750, name = "Wizard Oil",                       price = 2775, donateAE = 833,  lvl = 40, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  WIZ_OIL_BRILL    = { code = "W4", itemID = 20749, name = "Brilliant Wizard Oil",             price = 8225, donateAE = 2468, lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },
  SWIFTNESS        = { code = "SW", itemID = 2459,  name = "Swiftness Potion",                 price = 195,  donateAE = 59,   lvl = 5,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  FREE_ACTION      = { code = "FA", itemID = 5634,  name = "Free Action Potion",               price = 275,  donateAE = 83,   lvl = 20, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  BAG_MAGEWEAVE    = { code = "B1", itemID = 10050, name = "Mageweave Bag",                    price = 775,  donateAE = 233,  lvl = 0, donateTarget = 10, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  BAG_RUNECLOTH    = { code = "B2", itemID = 14046, name = "Runecloth Bag",                    price = 1600, donateAE = 480,  lvl = 0, donateTarget = 10, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  BAG_TRAVELER     = { code = "B3", itemID = 4500,  name = "Traveler's Backpack",              price = 5175, donateAE = 1553, lvl = 0, donateTarget = 10, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  BAG_MOONCLOTH    = { code = "B4", itemID = 14155, name = "Mooncloth Bag",                    price = 17675, donateAE = 5303, lvl = 0, donateTarget = 10, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },
  -- From the consumables guide (Azzco, TWOW). guide = priced from aux history (Aug/Sep), est = estimated (no history).
  SUPERIOR_DEF     = { code = "SD", itemID = 13445, name = "Elixir of Superior Defense",       price = 900,  donateAE = 270,  lvl = 43, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  GIFT_ARTHAS      = { code = "AR", itemID = 9088,  name = "Gift of Arthas",                   price = 135,  donateAE = 41,   lvl = 38, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  STONESHIELD      = { code = "GS", itemID = 13455, name = "Greater Stoneshield Potion",       price = 700,  donateAE = 210,  lvl = 46, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  MAGEBLOOD        = { code = "MB", itemID = 20007, name = "Mageblood Potion",                 price = 2575, donateAE = 773,  lvl = 40, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- est
  GREATER_FIREPWR  = { code = "FP", itemID = 21546, name = "Elixir of Greater Firepower",      price = 1350, donateAE = 405,  lvl = 40, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  FROST_POWER      = { code = "FR", itemID = 17708, name = "Elixir of Frost Power",            price = 975,  donateAE = 293,  lvl = 28, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- est
  SHADOW_POWER     = { code = "SH", itemID = 9264,  name = "Elixir of Shadow Power",           price = 1550, donateAE = 465,  lvl = 40, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  DREAMSHARD_ELIX  = { code = "DS", itemID = 61224, name = "Dreamshard Elixir",                price = 925,  donateAE = 278,  lvl = 46, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  RESTORATIVE      = { code = "RP", itemID = 9030,  name = "Restorative Potion",               price = 475,  donateAE = 143,  lvl = 32, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  HOURGLASS_SAND   = { code = "HS", itemID = 19183, name = "Hourglass Sand",                   price = 650,  donateAE = 195,  lvl = 0,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- est
  GREATER_SHADOW_P = { code = "PS", itemID = 13459, name = "Greater Shadow Protection Potion", price = 1225, donateAE = 368,  lvl = 48, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "CRITICAL" },   -- guide
  HOLY_WATER       = { code = "HW", itemID = 13180, name = "Stratholme Holy Water",            price = 325,  donateAE = 98,   lvl = 0,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- est
  GREATER_NATURE_P = { code = "PN", itemID = 13458, name = "Greater Nature Protection Potion", price = 700,  donateAE = 210,  lvl = 48, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  GREATER_FROST_P  = { code = "PF", itemID = 13456, name = "Greater Frost Protection Potion",  price = 275,  donateAE = 83,   lvl = 48, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  NATURE_PROT      = { code = "NP", itemID = 6052,  name = "Nature Protection Potion",         price = 85,   donateAE = 26,   lvl = 28, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  PURIFICATION     = { code = "PU", itemID = 13462, name = "Purification Potion",              price = 425,  donateAE = 128,  lvl = 47, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  LIMITED_INVULN   = { code = "LI", itemID = 3387,  name = "Limited Invulnerability Potion",   price = 775,  donateAE = 233,  lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  LUCIDITY         = { code = "LU", itemID = 61225, name = "Lucidity Potion",                  price = 975,  donateAE = 293,  lvl = 46, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- est
  FROST_OIL        = { code = "FO", itemID = 3829,  name = "Frost Oil",                        price = 275,  donateAE = 83,   lvl = 30, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  IMMOLATION_OIL   = { code = "OI", itemID = 8956,  name = "Oil of Immolation",                price = 450,  donateAE = 135,  lvl = 31, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  SAPPER_CHARGE    = { code = "GC", itemID = 10646, name = "Goblin Sapper Charge",             price = 775,  donateAE = 233,  lvl = 0,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  DYNAMITE_II      = { code = "DY", itemID = 18588, name = "Ez-Thro Dynamite II",              price = 130,  donateAE = 39,   lvl = 30, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  CONSECRATED_STN  = { code = "CS", itemID = 23122, name = "Consecrated Sharpening Stone",     price = 650,  donateAE = 195,  lvl = 50, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  BLESSED_WIZ_OIL  = { code = "BW", itemID = 23123, name = "Blessed Wizard Oil",               price = 650,  donateAE = 195,  lvl = 50, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  -- food and drink (guide)
  HARDENED_MUSH    = { code = "HM", itemID = 51717, name = "Hardened Mushroom",                price = 450,  donateAE = 135,  lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  POWER_MUSH       = { code = "PM", itemID = 51720, name = "Power Mushroom",                   price = 375,  donateAE = 113,  lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  FISHE_CHOCOLAT   = { code = "LF", itemID = 84040, name = "Le Fishe Au Chocolat",             price = 975,  donateAE = 293,  lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  GURUBASHI_GUMBO  = { code = "GG", itemID = 53015, name = "Gurubashi Gumbo",                  price = 650,  donateAE = 195,  lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- est
  TELABIM_MEDLEY   = { code = "TM", itemID = 60978, name = "Danonzo's Tel'Abim Medley",        price = 625,  donateAE = 188,  lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  TELABIM_SURPRISE = { code = "TS", itemID = 60976, name = "Danonzo's Tel'Abim Surprise",      price = 300,  donateAE = 90,   lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  TELABIM_DELIGHT  = { code = "TD", itemID = 60977, name = "Danonzo's Tel'Abim Delight",       price = 500,  donateAE = 150,  lvl = 55, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  NIGHTFIN_SOUP    = { code = "NS", itemID = 13931, name = "Nightfin Soup",                    price = 275,  donateAE = 83,   lvl = 35, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  RUMSEY_RUM       = { code = "RR", itemID = 21151, name = "Rumsey Rum Black Label",           price = 30,   donateAE = 9,    lvl = 0,  requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  MEDIVH_MERLOT    = { code = "MM", itemID = 61174, name = "Medivh's Merlot",                  price = 1100, donateAE = 330,  lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
  MEDIVH_BLUE      = { code = "MU", itemID = 61175, name = "Medivh's Merlot Blue",             price = 1375, donateAE = 413,  lvl = 45, requisitionType = "MINOR", stock = 0, reserve = 0, enabled = true, priority = "SECONDARY" },  -- guide
}

-- Display / evaluation order (pairs() order is undefined in Lua 5.0).
QuartermasterOrder = {
  "FLASK_TITANS", "FLASK_SUPREME", "GREATER_FIRE_POT", "MONGOOSE", "WF_FIREWATER",
  "MANA_OIL", "ELIXIR_GIANTS", "GREATER_ARCANE_E", "SHARPENING_STONE",
  "GREATER_ARCANE_P", "FORTITUDE", "WISDOM", "DREAMTONIC",
  "HEAL_MAJOR", "MANA_MAJOR", "WIZ_OIL_BRILL",
  "SUPERIOR_DEF", "STONESHIELD", "MAGEBLOOD", "GREATER_FIREPWR", "SHADOW_POWER", "DREAMSHARD_ELIX",
  "RESTORATIVE", "HOURGLASS_SAND", "GREATER_SHADOW_P", "GIFT_ARTHAS", "FROST_POWER", "HOLY_WATER",
  "GREATER_NATURE_P", "GREATER_FROST_P", "NATURE_PROT", "PURIFICATION", "LIMITED_INVULN", "LUCIDITY",
  "FROST_OIL", "IMMOLATION_OIL", "SAPPER_CHARGE", "DYNAMITE_II", "CONSECRATED_STN", "BLESSED_WIZ_OIL",
  "HARDENED_MUSH", "POWER_MUSH", "FISHE_CHOCOLAT", "GURUBASHI_GUMBO", "TELABIM_MEDLEY", "TELABIM_SURPRISE",
  "TELABIM_DELIGHT", "NIGHTFIN_SOUP", "RUMSEY_RUM", "MEDIVH_MERLOT", "MEDIVH_BLUE",
  "HEAL_MINOR", "HEAL_LESSER", "HEAL_POT", "HEAL_GREATER", "HEAL_SUPERIOR",
  "MANA_MINOR", "MANA_LESSER", "MANA_POT", "MANA_GREATER", "MANA_SUPERIOR",
  "MANA_OIL_MINOR", "MANA_OIL_LESSER", "WIZ_OIL_MINOR", "WIZ_OIL_LESSER", "WIZ_OIL",
  "SWIFTNESS", "FREE_ACTION", "BAG_MAGEWEAVE", "BAG_RUNECLOTH", "BAG_TRAVELER", "BAG_MOONCLOTH",
}

-- Shop sub-tabs (Quartermaster window > Shop), in tab order (tab = shorter button text), and the sub-tab of each shop item. Items not listed
-- here (officer-added ones) are sorted by name: "Flask ..." / "Elixir" / "Potion" / oils and stones / bags, else
-- Other. Officers can move an item in Manage > Shop (the Keeper keeps that in AshenKeeperDB.items[key].grp).
QuartermasterShopGroups = {
  { key = "all",    label = "All" },
  { key = "flask",  label = "Flasks" },
  { key = "elixir", label = "Elixirs" },
  { key = "potion", label = "Potions" },
  { key = "oil",    label = "Weapon Oils & Stones", tab = "Oils" },
  { key = "food",   label = "Food & Drink", tab = "Food" },
  { key = "bag",    label = "Bags" },
  { key = "other",  label = "Other" },
}
QuartermasterItemGroups = {
  FLASK_TITANS = "flask", FLASK_SUPREME = "flask",
  MONGOOSE = "elixir", ELIXIR_GIANTS = "elixir", GREATER_ARCANE_E = "elixir", FORTITUDE = "elixir", WISDOM = "elixir",
  DREAMTONIC = "elixir", SUPERIOR_DEF = "elixir", GIFT_ARTHAS = "elixir", GREATER_FIREPWR = "elixir", FROST_POWER = "elixir",
  SHADOW_POWER = "elixir", DREAMSHARD_ELIX = "elixir",
  GREATER_FIRE_POT = "potion", GREATER_ARCANE_P = "potion", HEAL_MINOR = "potion", HEAL_LESSER = "potion", HEAL_POT = "potion",
  HEAL_GREATER = "potion", HEAL_SUPERIOR = "potion", HEAL_MAJOR = "potion", MANA_MINOR = "potion", MANA_LESSER = "potion",
  MANA_POT = "potion", MANA_GREATER = "potion", MANA_SUPERIOR = "potion", MANA_MAJOR = "potion", SWIFTNESS = "potion",
  FREE_ACTION = "potion", STONESHIELD = "potion", MAGEBLOOD = "potion", RESTORATIVE = "potion", GREATER_SHADOW_P = "potion",
  GREATER_NATURE_P = "potion", GREATER_FROST_P = "potion", NATURE_PROT = "potion", PURIFICATION = "potion",
  LIMITED_INVULN = "potion", LUCIDITY = "potion",
  MANA_OIL = "oil", SHARPENING_STONE = "oil", MANA_OIL_MINOR = "oil", MANA_OIL_LESSER = "oil", WIZ_OIL_MINOR = "oil",
  WIZ_OIL_LESSER = "oil", WIZ_OIL = "oil", WIZ_OIL_BRILL = "oil", FROST_OIL = "oil", CONSECRATED_STN = "oil", BLESSED_WIZ_OIL = "oil",
  WF_FIREWATER = "food", HARDENED_MUSH = "food", POWER_MUSH = "food", FISHE_CHOCOLAT = "food", GURUBASHI_GUMBO = "food",
  TELABIM_MEDLEY = "food", TELABIM_SURPRISE = "food", TELABIM_DELIGHT = "food", NIGHTFIN_SOUP = "food", RUMSEY_RUM = "food",
  MEDIVH_MERLOT = "food", MEDIVH_BLUE = "food",
  BAG_MAGEWEAVE = "bag", BAG_RUNECLOTH = "bag", BAG_TRAVELER = "bag", BAG_MOONCLOTH = "bag",
  -- Other: explosives, sand, holy water, the drinkable Oil of Immolation
  HOURGLASS_SAND = "other", HOLY_WATER = "other", SAPPER_CHARGE = "other", DYNAMITE_II = "other", IMMOLATION_OIL = "other",
}

------------------------------------------------------------------------------
-- Requisition board: raid materials the guild pays AE for.
-- ae = reward each, target = how many the guild wants stocked, overstockAE = reward once the
-- target is reached (0 = stop paying), locked = value is protected from casual edits.
------------------------------------------------------------------------------
QuartermasterMaterials = {
  ELEMENTAL_FIRE   = { code = "EFI", itemID = 7068,  name = "Elemental Fire",         ae = 100,  target = 120, overstockAE = 0, enabled = true, priority = "CRITICAL", locked = true },
  BLACK_LOTUS      = { code = "BLO", itemID = 13468, name = "Black Lotus",            ae = 964,  target = 10,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  FIREBLOOM        = { code = "FBL", itemID = 4625,  name = "Firebloom",              ae = 184,  target = 60,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  GOLDEN_SANSAM    = { code = "GSA", itemID = 13464, name = "Golden Sansam",          ae = 74,   target = 60,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  STONESCALE_OIL   = { code = "STO", itemID = 13423, name = "Stonescale Oil",         ae = 95,   target = 60,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  DREAMFOIL        = { code = "DRF", itemID = 13463, name = "Dreamfoil",              ae = 72,   target = 60,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  MTN_SILVERSAGE   = { code = "MSS", itemID = 13465, name = "Mountain Silversage",    ae = 137,  target = 60,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  PLAGUEBLOOM      = { code = "PLB", itemID = 13466, name = "Plaguebloom",            ae = 142,  target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  LARGE_BRILL_SHD  = { code = "LBS", itemID = 14344, name = "Large Brilliant Shard",  ae = 638,  target = 30,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  ELEMENTAL_EARTH  = { code = "EEA", itemID = 7067,  name = "Elemental Earth",        ae = 123,  target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  WF_FIREWATER_MAT = { code = "WFW", itemID = 12820, name = "Winterfall Firewater",   ae = 45,   target = 40,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  WF_EKO           = { code = "EKO", itemID = 12431, name = "Winterfall E'ko",        ae = 27,   target = 40,  overstockAE = 0, enabled = true, priority = "CRITICAL" },
  GROMSBLOOD       = { code = "GRM", itemID = 8846,  name = "Gromsblood",             ae = 119,  target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  SUNGRASS         = { code = "SUN", itemID = 8838,  name = "Sungrass",               ae = 67,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  PURPLE_LOTUS     = { code = "PLO", itemID = 8831,  name = "Purple Lotus",           ae = 16,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  DREAM_DUST       = { code = "DRD", itemID = 11176, name = "Dream Dust",             ae = 46,   target = 40,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  DENSE_STONE      = { code = "DEN", itemID = 12365, name = "Dense Stone",            ae = 26,   target = 100, overstockAE = 0, enabled = true, priority = "SECONDARY" },
  SMALL_DREAM_SHD  = { code = "SDS", itemID = 61198, name = "Small Dream Shard",      ae = 242,  target = 30,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  GOLDTHORN        = { code = "GTH", itemID = 3821,  name = "Goldthorn",              ae = 6,    target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  WILD_STEELBLOOM  = { code = "WSB", itemID = 3355,  name = "Wild Steelbloom",        ae = 37,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  MAGEROYAL        = { code = "MAG", itemID = 785,   name = "Mageroyal",              ae = 1,    target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  BRIARTHORN       = { code = "BRI", itemID = 2450,  name = "Briarthorn",             ae = 10,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },
  -- Materials for guide consumables that can't be traded (they go here instead of the shop); priced from aux
  -- history (Frozen Rune: estimate) until the next scan.
  FROSTMAUL_EKO    = { code = "FME", itemID = 12436, name = "Frostmaul E'ko",         ae = 145,  target = 40,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Juju Might
  SCORPOK_PINCER   = { code = "SCP", itemID = 8393,  name = "Scorpok Pincer",         ae = 48,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Ground Scorpok Assay, R.O.I.D.S.
  BOAR_LUNG        = { code = "BBL", itemID = 8392,  name = "Blasted Boar Lung",      ae = 5,    target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Ground Scorpok Assay, R.O.I.D.S.
  SNICKERFANG_JOWL = { code = "SNJ", itemID = 8391,  name = "Snickerfang Jowl",       ae = 46,   target = 60,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Ground Scorpok Assay, R.O.I.D.S.
  BASILISK_BRAIN   = { code = "BAB", itemID = 8394,  name = "Basilisk Brain",         ae = 17,   target = 100, overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Cerebral Cortex Compound
  VULTURE_GIZZARD  = { code = "VGZ", itemID = 8396,  name = "Vulture Gizzard",        ae = 34,   target = 40,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- Cerebral Cortex Compound
  FROZEN_RUNE      = { code = "FRZ", itemID = 22682, name = "Frozen Rune",            ae = 5809, target = 20,  overstockAE = 0, enabled = true, priority = "SECONDARY" },   -- guide (Naxx), est
}

QuartermasterMaterialOrder = {
  "ELEMENTAL_FIRE", "BLACK_LOTUS", "FIREBLOOM", "GOLDEN_SANSAM", "STONESCALE_OIL", "DREAMFOIL",
  "MTN_SILVERSAGE", "PLAGUEBLOOM", "LARGE_BRILL_SHD", "ELEMENTAL_EARTH", "WF_FIREWATER_MAT", "WF_EKO",
  "GROMSBLOOD", "SUNGRASS", "PURPLE_LOTUS", "DREAM_DUST", "DENSE_STONE", "SMALL_DREAM_SHD",
  "GOLDTHORN", "WILD_STEELBLOOM", "MAGEROYAL", "BRIARTHORN",
  "FROSTMAUL_EKO", "SCORPOK_PINCER", "BOAR_LUNG", "SNICKERFANG_JOWL", "BASILISK_BRAIN", "VULTURE_GIZZARD", "FROZEN_RUNE",
}

------------------------------------------------------------------------------
-- Weekly requisition rules (slot based, NOT an AE spending cap)
------------------------------------------------------------------------------
QuartermasterWeekly = {
  majors = 1,           -- Major requisitions (flasks) per player per week
  minors = 30,          -- Minor requisitions (potions, elixirs, oils...) per player per week without a Major
  minorsWithMajor = 15, -- ... and once a Major was taken that week. A Major can only be taken while the minors
                        -- taken so far are at most this many (so nobody ends a week above this with a flask).
  perItem = 10,         -- most units of any ONE shop item a player can take per week (nil = no per-item cap)
}
QuartermasterMaxPerOrder = 10   -- most units in a single purchase (one trade); the weekly limits still apply

-- Weekly AE allowance by guild rank (lower case; "Member: Born" counts as "born"). What a member can spend in a
-- week = this allowance (drawn from their banked balance, unused allowance does not roll over) + AE earned this
-- week + donations this week - this week's purchases. Never more than their whole balance. A rank that is not
-- listed gets 0. Set the whole table to nil to let everyone spend their full balance again.
QuartermasterWeeklyAllowance = {
  flamebound = 2000,
  ember = 1000,
  born = 0,                  -- Born: no allowance; they can still spend AE earned this week and their donation credit
  ["oath captain"] = 2000,   -- officer ranks: same as Flamebound (change if wanted)
  ["banner warden"] = 2000,
  ["flame keeper"] = 2000,
  flame = 2000,
}

-- Every shop price above is multiplied by this (3 = three times the AE cost). Prices an admin sets by hand
-- (/ak price ...) are used exactly as typed. 1 since rev 11: the prices above are the shop prices.
QuartermasterPriceMultiplier = 1

------------------------------------------------------------------------------
-- RP dialogue pools (pick one at random; {item} {n} {ae} are substituted)
------------------------------------------------------------------------------
QuartermasterDialogue = {
  open        = { "Looking to spend what you've earned?", "The stores are open. Choose carefully.", "Ah. The Banner's quartermaster at your service." },
  buy_ok      = { "The stores have been updated. Make it count.", "Done. Don't waste it.", "Taken from the stores and recorded in the Ledger." },
  no_funds    = { "The Ledger is considerably lighter than your ambition.", "Come back when the Ledger agrees with you." },
  oos         = { "You've come too late. The stores are empty.", "Nothing left on that shelf, I'm afraid." },
  reserved    = { "The remainder is spoken for. Campaign stock.", "That stock is held back for the raid. Not for sale." },
  major_used  = { "Your Major requisition has already been spoken for this week.", "No flask this week. The Ledger is clear on that." },
  minor_limit = { "Your minor requisitions are spent. See me after the reset.", "That's your allotment for the week." },
  disabled    = { "That item isn't being issued right now." },
  offline     = { "The quartermaster has stepped away from the stores." },
  donate_ok   = { "Good. The Banner can use these.", "Recorded. The stores thank you." },
  donate_big  = { "Now that's a contribution worth recording.", "The Banner will remember this." },
  donate_full = { "The requisition is fulfilled. The stores are full of that already.", "No more of those are needed. Hold on to them." },
  trade_fail  = { "The exchange fell through. Nothing was taken from your Ledger.", "Trade cancelled. Your Ledger is untouched." },
  on_hold     = { "Your account is on hold for officer review.", "The Ledger doesn't add up. An officer has to look at it first." },
  too_low     = { "That's beyond you for now. Come back with a few more levels.", "You couldn't even use that yet." },
  rank_only   = { "Flasks are for the Flamebound. Earn the rank first.", "That shelf is kept for the Flamebound." },
}

-- Flamebound-only items (fb above): this rank and every rank above it (by guild rank index). If nobody holds the
-- rank right now (its index is unknown), these rank names count instead.
QuartermasterFlameboundRank = "Flamebound"
QuartermasterFlameboundRanks = { "flamebound", "oath captain", "banner warden", "flame keeper", "flame" }

-- A donation worth at least this much AE counts as "large".
QuartermasterBigDonationAE = 1000

-- Shop items (potions, flasks, elixirs...) can also be donated. Each one is credited at this fraction of its
-- shop price (0.3 = 30%) unless they have a donateAE. They add to the shop's stock. Set to 0 to accept materials only.
QuartermasterItemDonationRate = 0.3

-- Every donation stops at its board target: the Keeper only accepts up to what is still needed. Shop items
-- (potions...) are needed until the Keeper holds this many of each (per item: donateTarget above, or an
-- officer's Target in Manage > Potions).
QuartermasterItemDonationTarget = 20

-- Boss-kill AE is paid by the Ashen Banner addon (LeafVillageLegends) on each player's own client, which reads
-- these (its own defaults are the same). A raid boss pays 25 + 5 per guildie in the raid; it only pays when the
-- boss is on the raid boss list, the player was not paid for that boss today (server day), and the raid is at
-- least this share guild members. Refused awards are logged (LeafVE_DB.bossAELog).
QuartermasterDailyBossAECap = 1250      -- per player per server day: one Molten Core (10 bosses x 125)
QuartermasterBossAEMaxGuildies = 20     -- guildies counted for the bonus, so one boss pays at most 125
QuartermasterBossAEMinGuildShare = 0.70
QuartermasterBossAEBosses = nil         -- nil = the Ashen Banner's raid boss list; or e.g. { "Lucifron", "Magmadar" }

-- AE fail-safe on the Keeper (Shop.lua, AK.Integrity). Every player's AE lives in their own SavedVariables, so the
-- Keeper only accepts a reported increase up to what could really have been earned since the last report:
-- per server day the boss cap above + this allowance for everything else (login, quests, dungeons, group ticks,
-- shoutouts, duties...), doubled on weekends like the points themselves. Anything above it is HELD (not spendable)
-- and the player is put on hold until an Oath Captain+ clears it (Manage > Log, or /qm release|discard <name>).
QuartermasterDailyOtherAEAllowance = 1500
QuartermasterWeekendAEMultiplier = 2
QuartermasterLoginAE = 20               -- the Ashen Banner's daily login reward (once per server day)
-- Offline jump: the Keeper saw the player log off, and their first report after logging back in (within this many
-- seconds) may only be higher by the login reward + what they earned after their last report before logging off
-- (AE the Keeper heard announced live, plus this much unheard).
-- Only applied when the Keeper itself was online the whole time: it heard a fresh total from them (at most
-- QuartermasterOfflineFreshWindow seconds before they logged off), saw the logoff and the login, and was not
-- offline, reloaded or relogged in between. Otherwise only the per-day check above applies (never an OFFLINE flag).
QuartermasterOfflineTailAE = 250
QuartermasterOfflineCheckWindow = 900
QuartermasterOfflineFreshWindow = 2100  -- the Keeper asks for the leaderboard every 30 min
QuartermasterKeeperGapSeconds = 300     -- no Keeper heartbeat for this long (frozen, asleep, clock jump) = it was offline
QuartermasterKeeperSettleSeconds = 120  -- logoffs seen this soon after the Keeper logs in are ignored (roster still loading)

-- Donations are paused while the Keeper has fewer empty slots than this in his normal bags (herb/soul bags
-- don't count). Purchases are not affected; splitting a stack for a purchase also uses an empty slot.
QuartermasterDonationFreeSlots = 2      -- 2 = one slot always stays free for splitting a stack for a purchase

-- The character that scans the Auction House (/ak ahscan) and sends the prices to the Keeper. The Keeper only
-- accepts prices from this character, and asks it for a fresh scan once the last one is a day old (when it
-- stands at the Auction House). Prices are only stored and shown (/ak ahprices, Manage > Log), never applied.
QuartermasterAHScanner = "Ashenkeeper"
QuartermasterAHScanMaxAge = 86400

-- /ak donaterate (on the Keeper) re-prices from the last scan (gold = median of the 5 cheapest listings):
--   shop price  = gold x the shop rate (rounded to 5 AE, to 25 AE from 200 up, at least QuartermasterShopMinPrice).
--                 The shop rate is QuartermasterShopAEPerGold, or when that is nil, whatever keeps the anchor item
--                 at its anchor price (Elixir of the Mongoose = 2000 AE).
--   donation AE = shop items: QuartermasterDonateShare of the (new) shop price (also when the item had no
--                 listings: then of its current price). Materials: gold x QuartermasterDonateShare x the shop
--                 rate (a material that is also a shop item: the share of that shop price); without a shop rate
--                 gold x QuartermasterDonateAEPerGold. Rounded to whole AE, at least 1, at most half the shop price.
-- Preview first, "/ak donaterate apply" to set it; never applied by itself. Materials without listings and locked
-- ones (Elemental Fire) keep their values; entries in QuartermasterDonateAEFixed keep their donation AE.
QuartermasterShopAEPerGold = nil
QuartermasterShopAnchor = { key = "MONGOOSE", ae = 2000 }
QuartermasterShopMinPrice = 10
QuartermasterDonateShare = 0.30
QuartermasterDonateAEPerGold = 250
QuartermasterDonateAEFixed = {}

-- Guild ranks that may manage the requisition board and shop through Grizzwick (Manage tab / ADMIN_REQ).
-- Checked on the Keeper by guild rank INDEX: this rank and every rank above it. If nobody currently holds
-- that rank (so its index is unknown), the names in QuartermasterAdminRanks are used instead.
QuartermasterAdminMinRank = "Oath Captain"
QuartermasterAdminRanks = { "flame", "flame keeper", "banner warden", "oath captain" }
