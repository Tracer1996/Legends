-- LeafVE_Ach_Companions.lua
-- Turtle WoW companion collection achievements and shared collection metadata.
-- Vanilla/Turtle WoW 1.12, Lua 5.0 compatible.

local COMPANION_CATEGORY = "Companions"
local COMPANION_ICON = "Interface\\Icons\\INV_Misc_Toy_07"

local COMPANION_CATALOG = {
  {name="Dream Frog",itemID=54001, source="Drop", obtainedFrom="Rare Turtle WoW frog-collection reward; consult the current companion guide for the exact custom source.", sourceConfidence="Turtle custom source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Infinite Frog",itemID=54003, source="Drop", obtainedFrom="Rare Turtle WoW frog-collection reward; consult the current companion guide for the exact custom source.", sourceConfidence="Turtle custom source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Azure Frog",itemID=54000, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Bullfrog",itemID=54002, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Dart Frog",itemID=50078, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Golden Frog",itemID=54007, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Island Frog",itemID=50079, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Pink Frog",itemID=54006, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Poison Frog",itemID=54004, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Pond Frog",itemID=54008, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Snow Frog",itemID=54005, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tree Frog",itemID=11026, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Wood Frog",itemID=11027, source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Gilnean Raven",itemID=69000, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Little Ball of Spider Web",itemID=51739, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Midnight",itemID=80010, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Mr. Bigglesworth",itemID=81283, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="A Jubling's Tiny Home",itemID=19450, source="Event", obtainedFrom="Darkmoon Faire quest from Morja: lure Jubjub with Dark Iron Ale, complete the quest, then wait for the egg to hatch.", sourceConfidence="Verified: Darkmoon Faire quest", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Albino Snake",itemID=50067, source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Albino Snapjaw",itemID=18963, source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Amani Eagle",itemID=80878, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Ancona Chicken",itemID=11023, source="Vendor", obtainedFrom="Buy from Magus Tirth in the Shimmering Flats after using /chicken and /beckon.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Arcane Elemental",itemID=80006, source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Azure Whelpling",itemID=50083, source="Drop", obtainedFrom="Rare drop from blue dragonkin in Azshara.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Baby Shark",itemID=21168, source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Beaky",itemID=81243, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Black Kingsnake",itemID=10360, source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Black Piglet",itemID=50058, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Black Tabby",itemID=8491, source="Drop", obtainedFrom="Rare drop from Dalaran-affiliated enemies around Ambermill and the Alterac foothills.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Black-Footed Fox",itemID=80003, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Blitzen",itemID=50014, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Bombay",itemID=8485, source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Bone Golem",itemID=50013, source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Brightwing",itemID=50077, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Bronze Whelpling",itemID=50070, source="Rare Drop", obtainedFrom="Rare Turtle WoW custom drop, instance reward, or limited collection reward; exact source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Brown Snake",itemID=10361, source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Caravan Kodo",itemID=51421, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Cheeky Monkey",itemID=80004, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Cockatiel",itemID=8496, source="Vendor", obtainedFrom="Buy from Narkk in Booty Bay.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Core Hound Pup",itemID=83301, source="Raid", obtainedFrom="High-end raid or account reward associated with Molten Core-themed content.", sourceConfidence="Strong raid reward evidence", sourceCategory="Raid", points=75, difficulty="Rare"},
  {name="Cornish Rex",itemID=8486, source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Corrupted Kitten",itemID=11903, source="Quest", obtainedFrom="Turtle WoW custom quest or reputation reward tied to corrupted-feline content.", sourceConfidence="Turtle custom source; exact step may vary", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Cottontail Rabbit",itemID=50081, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Cracked Raptor Egg",itemID=51700, source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Crimson Snake",itemID=10392, source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Crimson Whelpling",itemID=8499, source="Drop", obtainedFrom="Rare drop from red dragonkin in the Wetlands.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Dalaran Cloud Familiar",itemID=81207, source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Dark Whelpling",itemID=10822, source="Drop", obtainedFrom="Rare drop from black dragonkin in the Badlands and Burning Steppes.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Darkmoon Tonk",itemID=50200, source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Diablo Stone",itemID=13584, source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Eagle Owl",itemID=50080, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Egg of Turtlhu",itemID=50202, source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Emerald Whelpling",itemID=8498, source="Drop", obtainedFrom="Rare drop from green dragonkin in the Swamp of Sorrows.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Enchanted Broom",itemID=80007, source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Field Repair Bot 75B",itemID=50005, source="Profession", obtainedFrom="Engineering-created Turtle WoW utility companion.", sourceConfidence="Strong Turtle profession evidence", sourceCategory="Profession", points=50, difficulty="Uncommon"},
  {name="Finn the Shark",itemID=81248, source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Flipper",itemID=69003, source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Forworn Mule",itemID=50007, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Frostwolf Ghostpup",itemID=50085, source="Reputation", obtainedFrom="Faction-themed Turtle WoW quest, reputation, or event reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Glitterwing",itemID=69006, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Golden Dragonhawk Hatchling",itemID=80000, source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Great Horned Owl",itemID=8500, source="Vendor", obtainedFrom="Buy from Shylenai in Darnassus.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Green Helper Box",itemID=21301, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Green Steam Tonk",itemID=51002, source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Green Water Snake",itemID=50068, source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Green Wing Macaw",itemID=8492, source="Drop", obtainedFrom="Drop from enemies throughout The Deadmines.", sourceConfidence="Verified: Vanilla dungeon drop", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Gurky",itemID=22114, source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Hawk Owl",itemID=8501, source="Vendor", obtainedFrom="Buy from Shylenai in Darnassus.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Hawksbill Snapjaw",itemID=18965, source="Collection", obtainedFrom="Turtle WoW coastal/island companion reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Hedwig",itemID=51251, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="High Elf Orphan Whistle",itemID=80410, source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Hippogryph Hatchling",itemID=23713, source="Promotion", obtainedFrom="Legacy trading-card/promotional companion; Turtle WoW availability may be limited or promotional.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Hyacinth Macaw",itemID=8494, source="Drop", obtainedFrom="Extremely rare world drop from Bloodsail pirates in Stranglethorn Vale.", sourceConfidence="Verified: Vanilla very rare drop", sourceCategory="Drop", points=100, difficulty="Prestige"},
  {name="Hyjal Bear Cub",itemID=51889, source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Infinite Whelpling",itemID=70016, source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Jingling Bell",itemID=21308, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Kirin Tor Familiar",itemID=50084, source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Leatherback Snapjaw",itemID=18966, source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lil' K.T.",itemID=83300, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop or special promotional companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Lil' Ragnaros",itemID=83302, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop or special promotional companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Little Fawn",itemID=51433, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Little Pony",itemID=51259, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Loggerhead Snapjaw",itemID=18964, source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lost Farm Sheep",itemID=51220, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lovely Pink Fox",itemID=67000, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lulu",itemID=51221, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Mechanical Auctioneer",itemID=50009, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Mechanical Chicken",itemID=10398, source="Quest", obtainedFrom="Complete all three OOX escort quest chains, then finish An OOX of Your Own in Booty Bay.", sourceConfidence="Verified: Vanilla quest chain", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Mechanical Squirrel Box", source="Profession", obtainedFrom="Craft with Engineering from Schematic: Mechanical Squirrel, or obtain the bind-on-use pet from another engineer.", sourceConfidence="Verified: Vanilla Engineering", sourceCategory="Profession", points=25, difficulty="Common"},
  {name="Mini Krampus",itemID=84038, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Moonkin Hatchling",itemID=50019, source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Murky",itemID=20371, source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Mysterious Fortune Teller",itemID=51891, source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Olive Snapjaw",itemID=18967, source="Collection", obtainedFrom="Turtle WoW coastal/island companion reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Orange Tabby",itemID=8487, source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Panda Collar",itemID=13583, source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Peddlefeet",itemID=22235, source="Event", obtainedFrom="Love is in the Air seasonal reward, commonly purchased with Love Tokens.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Pengu",itemID=69004, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Phoenix Hatchling",itemID=81150, source="Dungeon", obtainedFrom="Rare dungeon or raid-themed companion reward on Turtle WoW.", sourceConfidence="Strong rare-instance evidence", sourceCategory="Dungeon", points=75, difficulty="Rare"},
  {name="Piglet's Collar",itemID=23007, source="Event", obtainedFrom="Children's Week orphan quest reward.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Poley",itemID=22781, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Prairie Dog Whistle",itemID=10394, source="Vendor", obtainedFrom="Buy from Halpa in Thunder Bluff.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Prince Herman II",itemID=51260, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Purple Steam Tonk",itemID=51003, source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Red Dragon Orb",itemID=19054, source="Rare Drop", obtainedFrom="Rare Turtle WoW custom drop, instance reward, or limited collection reward; exact source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Red Helper Box",itemID=21305, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Scarlet Snake",itemID=50069, source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Scotty",itemID=69002, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Senegal",itemID=8495, source="Vendor", obtainedFrom="Buy from Narkk in Booty Bay.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Siamese",itemID=8490, source="Drop", obtainedFrom="Drop from Cookie in The Deadmines.", sourceConfidence="Verified: Vanilla dungeon drop", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Silver Tabby",itemID=8488, source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Smolderweb Hatchling",itemID=12529, source="Dungeon", obtainedFrom="Complete En-Ay-Es-Tee-Why in Lower Blackrock Spire.", sourceConfidence="Verified: Vanilla dungeon quest", sourceCategory="Dungeon", points=50, difficulty="Uncommon"},
  {name="Snowshoe",itemID=8497, source="Vendor", obtainedFrom="Buy the rabbit crate from Yarlyn Amberstill at Amberstill Ranch in Dun Morogh.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Snowy Owl",itemID=50082, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Spectral Cub",itemID=81258, source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Spectral Faeling",itemID=81151, source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Speedy",itemID=23002, source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Sprite Darter Hatchling",itemID=11474, source="Quest", obtainedFrom="Alliance quest chain in Feralas; Turtle WoW also provides faction-accessible acquisition paths.", sourceConfidence="Verified: Vanilla/Turtle quest", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Summon: Auctioneer",itemID=50602, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Summon: Barber",itemID=50600, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Summon: Surgeon",itemID=50601, source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Sunscale Hatchling",itemID=81183, source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Teldrassil Sproutling",itemID=51007, source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Terky",itemID=22780, source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Thalassian Tender",itemID=80001, source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Tiny Green Dragon",itemID=19055, source="Drop", obtainedFrom="Rare dragonkin companion drop; farm the matching dragonflight mobs listed in the Turtle database.", sourceConfidence="Strong Vanilla/Turtle drop evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Tiny Pterodactyl",itemID=81152, source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Tiny Shore Crab",itemID=81159, source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tiny Snowman",itemID=21309, source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Tiny Warp Stalker",itemID=69001, source="Turtle WoW", obtainedFrom="Turtle WoW custom companion; exact acquisition source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tirisfal Bat",itemID=51858, source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Undercity Cockroach",itemID=10393, source="Vendor", obtainedFrom="Buy from Jeremiah Payson beneath the Undercity bank.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Water Waveling",itemID=81254, source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Westfall Chicken",itemID=11110, source="Quest", obtainedFrom="Complete CLUCK! by repeatedly using /chicken on a chicken, then feeding it Special Chicken Feed.", sourceConfidence="Verified: Vanilla quest", sourceCategory="Quest", points=25, difficulty="Common"},
  {name="Whiskers the Rat",itemID=23015, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="White Kitten",itemID=8489, source="Vendor", obtainedFrom="Buy from Lil Timmy during his limited Stormwind patrol spawn.", sourceConfidence="Verified: Vanilla rare vendor", sourceCategory="Vendor", points=50, difficulty="Uncommon"},
  {name="White Tiger Cub",itemID=23712, source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Worg Pup",itemID=12264, source="Dungeon", obtainedFrom="Complete Kibler's Exotic Pets in Lower Blackrock Spire.", sourceConfidence="Verified: Vanilla dungeon quest", sourceCategory="Dungeon", points=50, difficulty="Uncommon"},
  {name="Mr Wiggles", source="Event", obtainedFrom="Children's Week orphan quest reward.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Zergling Leash",itemID=13582, source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
}

local COMPANION_MILESTONES = {
  {id="casual_pet_collector", name="Companion Tender", desc="Collect 10 Turtle WoW companions.", goal=10, points=50},
  {id="casual_pet_fanatic", name="Companion Handler", desc="Collect 25 Turtle WoW companions.", goal=25, points=100},
  {id="companion_collector_50", name="Companion Tamer", desc="Collect 50 Turtle WoW companions.", goal=50, points=150},
  {id="companion_collector_75", name="Companion Wrangler", desc="Collect 75 Turtle WoW companions.", goal=75, points=200},
  {id="companion_collector_100", name="Companion Menagerist", desc="Collect 100 Turtle WoW companions.", goal=100, points=250},
}

local COMPANION_TITLE_DEFS = {
  {id="title_companion_tender", name="Tender", achievement="casual_pet_collector", desc="Awarded for collecting 10 Turtle WoW companions.", icon="Interface\\Icons\\INV_Box_PetCarrier_01"},
  {id="title_companion_tamer", name="Tamer", achievement="companion_collector_50", desc="Awarded for collecting 50 Turtle WoW companions.", icon="Interface\\Icons\\Ability_Hunter_Pet_Bear"},
  {id="title_companion_wrangler", name="Wrangler", achievement="companion_collector_75", desc="Awarded for collecting 75 Turtle WoW companions.", icon="Interface\\Icons\\INV_Misc_MonsterClaw_04"},
  {id="title_companion_menagerist", name="Menagerist", achievement="companion_collector_100", desc="Awarded for collecting 100 Turtle WoW companions.", icon="Interface\\Icons\\Ability_Hunter_Pet_Owl"},
}

local function Slugify(text)
  local slug=string.lower(tostring(text or ""))
  slug=string.gsub(slug,"'","")
  slug=string.gsub(slug,"[^a-z0-9]+","_")
  slug=string.gsub(slug,"^_+","")
  slug=string.gsub(slug,"_+$","")
  return slug
end

local function SMatch(text,pattern)
  local _,_,c1,c2,c3=string.find(tostring(text or ""),pattern)
  if c1~=nil then return c1,c2,c3 end
  return nil
end

local function GetItemNameFromLink(link)
  return SMatch(link,"%[(.-)%]")
end

local function GetCompanionModuleState()
  if not LeafVE_AchTest_DB then return nil end
  if not LeafVE_AchTest_DB.companionTracker then LeafVE_AchTest_DB.companionTracker={} end
  return LeafVE_AchTest_DB.companionTracker
end

local COMPANION_NAME_OVERRIDES={westfall_chicken="Farm Chicken"}
local MANUAL_COMPANION_ALIASES={
  ["a_jublings_tiny_home"]={"jubling","summon_jubling"},
  ["diablo_stone"]={"diablo"}, ["egg_of_turtlhu"]={"turtlhu"},
  ["green_helper_box"]={"green_helper"}, ["high_elf_orphan_whistle"]={"high_elf_orphan"},
  ["mechanical_squirrel_box"]={"mechanical_squirrel"}, ["panda_collar"]={"panda"},
  ["piglets_collar"]={"piglet"}, ["prairie_dog_whistle"]={"prairie_dog"},
  ["red_dragon_orb"]={"red_dragon"}, ["red_helper_box"]={"red_helper"},
  ["westfall_chicken"]={"farm_chicken"}, ["zergling_leash"]={"zergling"},
}

local COMPANION_BY_ACH_ID={}
local COMPANION_IDS={}
local COMPANION_LOOKUP={}
LeafVE_Ach_CompanionsMaster=LeafVE_Ach_CompanionsMaster or {}

local function RegisterCompanionLookup(name,achievementId)
  local key=Slugify(name)
  if key=="" or not achievementId or achievementId=="" then return end
  if not COMPANION_LOOKUP[key] then COMPANION_LOOKUP[key]=achievementId end
end

local function RegisterMasterName(name,data)
  if not name or name=="" then return end
  LeafVE_Ach_CompanionsMaster[name]={
    name=name, source=data.source, obtainedFrom=data.obtainedFrom,
    sourceConfidence=data.sourceConfidence, category=data.sourceCategory,
    sourceCategory=data.sourceCategory, points=data.points, difficulty=data.difficulty,
    icon=data.icon or COMPANION_ICON, achievementId=data.id, itemID=data.itemID,
  }
end

for _,raw in ipairs(COMPANION_CATALOG) do
  local key=Slugify(raw.name)
  local achievementId="companion_"..key
  local displayName=COMPANION_NAME_OVERRIDES[key] or raw.name
  local data={
    id=achievementId, name=displayName,
    desc="Collect "..displayName..". Source: "..tostring(raw.obtainedFrom or raw.source or "Turtle WoW companion collection").."",
    category=COMPANION_CATEGORY, points=raw.points or 25,
    difficulty=raw.difficulty or "Common", icon=raw.icon or COMPANION_ICON,
    source=raw.source or "Turtle WoW", obtainedFrom=raw.obtainedFrom,
    sourceConfidence=raw.sourceConfidence, sourceCategory=raw.sourceCategory or "Collection",
    itemID=raw.itemID,
  }
  table.insert(COMPANION_IDS,achievementId)
  COMPANION_BY_ACH_ID[achievementId]=data
  RegisterCompanionLookup(raw.name,achievementId)
  RegisterCompanionLookup(displayName,achievementId)
  local aliases=MANUAL_COMPANION_ALIASES[key]
  if aliases then for _,alias in ipairs(aliases) do RegisterCompanionLookup(alias,achievementId) end end
  local summonless=string.gsub(key,"^summon_","")
  if summonless~=key and summonless~="" then RegisterCompanionLookup(summonless,achievementId) end
  -- Keep one catalogue row per companion. The raw name is the spell/item key;
  -- display-name aliases still resolve to the same achievement through COMPANION_LOOKUP.
  RegisterMasterName(raw.name,data)
end

local COMPANION_TOTAL=table.getn(COMPANION_IDS)
table.insert(COMPANION_MILESTONES,{id="companion_collector_all",name="A Complete Menagerie",desc="Collect all "..COMPANION_TOTAL.." Turtle WoW companions.",goal=COMPANION_TOTAL,points=500})
table.insert(COMPANION_TITLE_DEFS,{id="title_companion_master",name="Petmaster",achievement="companion_collector_all",desc="Awarded for collecting every Turtle WoW companion.",icon="Interface\\Icons\\INV_Crown_02"})

function LeafVE_AchTest:GetCompanionPointValue(name)
  local id=COMPANION_LOOKUP[Slugify(name)]
  local data=id and COMPANION_BY_ACH_ID[id]
  return data and data.points or 25
end

function LeafVE_AchTest:GetCompanionAchievementId(name)
  return COMPANION_LOOKUP[Slugify(name)]
end

local function RegisterCompanionAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  for _,achievementId in ipairs(COMPANION_IDS) do
    local data=COMPANION_BY_ACH_ID[achievementId]
    LeafVE_AchTest:AddAchievement(achievementId,{
      id=data.id,name=data.name,desc=data.desc,category=data.category,points=data.points,icon=data.icon,
      companionType="individual",collectionType="companion",source=data.source,obtainedFrom=data.obtainedFrom,
      sourceConfidence=data.sourceConfidence,difficulty=data.difficulty,itemID=data.itemID,
    })
  end
  for _,milestone in ipairs(COMPANION_MILESTONES) do
    LeafVE_AchTest:AddAchievement(milestone.id,{id=milestone.id,name=milestone.name,desc=milestone.desc,category=COMPANION_CATEGORY,points=milestone.points,icon=COMPANION_ICON,companionType="milestone",collectionType="companion"})
    if LeafVE_AchTest.RegisterProgressDef then LeafVE_AchTest:RegisterProgressDef(milestone.id,{counter="companions",goal=milestone.goal}) end
  end
  if LeafVE_AchTest.AddTitle then
    for _,titleData in ipairs(COMPANION_TITLE_DEFS) do
      LeafVE_AchTest:AddTitle({id=titleData.id,name=titleData.name,chatName=titleData.name,achievement=titleData.achievement,prefix=false,category=COMPANION_CATEGORY,icon=titleData.icon or COMPANION_ICON,desc=titleData.desc})
    end
  end
end

-- Written directly into the same DB table the Collections module's own
-- spellbook scan uses (LeafVE_AchTest_DB.collections.companions[name].icon)
-- so the achievement toast/row (which read from there) have the real
-- scanned icon the instant the achievement fires here, instead of racing
-- a separate scan in a different file that might not have run yet.
local function CaptureCompanionIcon(name,icon)
  if not icon or icon=="" or not name or name=="" or not LeafVE_AchTest_DB then return end
  LeafVE_AchTest_DB.collections=LeafVE_AchTest_DB.collections or {}
  LeafVE_AchTest_DB.collections.companions=LeafVE_AchTest_DB.collections.companions or {}
  local saved=LeafVE_AchTest_DB.collections.companions
  if type(saved[name])~="table" then saved[name]={} end
  saved[name].icon=icon
end

local function AddDetectedCompanion(seen,name,icon)
  local id=COMPANION_LOOKUP[Slugify(name)]
  if id then
    seen[id]=true
    if icon then CaptureCompanionIcon(name,icon) end
  end
end

local function ScanSpellbook(seen)
  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellName then return end
  local tabCount=GetNumSpellTabs() or 0
  for tabIndex=1,tabCount do
    local _,_,offset,spellCount=GetSpellTabInfo(tabIndex)
    offset=offset or 0; spellCount=spellCount or 0
    for spellOffset=1,spellCount do
      local spellIndex=offset+spellOffset
      local spellName=GetSpellName(spellIndex,BOOKTYPE_SPELL or "spell")
      if spellName and spellName~="" then
        local icon=GetSpellTexture and GetSpellTexture(spellIndex,BOOKTYPE_SPELL or "spell")
        AddDetectedCompanion(seen,spellName,icon)
      end
    end
  end
end

local function CountOwnedCompanions(playerName)
  local count=0
  for _,achievementId in ipairs(COMPANION_IDS) do
    if LeafVE_AchTest:HasAchievement(playerName,achievementId) then count=count+1 end
  end
  return count
end

local function AwardCompanionMilestones(totalOwned,silent)
  for _,milestone in ipairs(COMPANION_MILESTONES) do
    if totalOwned>=milestone.goal then LeafVE_AchTest:AwardAchievement(milestone.id,silent) end
  end
end

local function RefreshStoredPointValues(playerName)
  if not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.achievements or not playerName then return end
  local earned=LeafVE_AchTest_DB.achievements[playerName]
  if not earned then return end
  for _,achievementId in ipairs(COMPANION_IDS) do
    if earned[achievementId] and COMPANION_BY_ACH_ID[achievementId] then earned[achievementId].points=COMPANION_BY_ACH_ID[achievementId].points end
  end
  for _,milestone in ipairs(COMPANION_MILESTONES) do if earned[milestone.id] then earned[milestone.id].points=milestone.points end end
end

-- Companions are only awarded once actually learned into the spellbook,
-- not just sitting in a bag -- bag presence used to be enough to trigger
-- the achievement (and the toast/announcement) before the player had even
-- summoned/learned the pet.
local function ScanCompanions(forceSilent)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement or not LeafVE_AchTest.SetCounter then return end
  local me=LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  if not me then return end
  local moduleState=GetCompanionModuleState(); if not moduleState then return end
  local isSeedScan=not moduleState.seeded
  local silent=forceSilent or isSeedScan
  local seen={}
  ScanSpellbook(seen)
  for achievementId in pairs(seen) do LeafVE_AchTest:AwardAchievement(achievementId,silent) end
  RefreshStoredPointValues(me)
  local totalOwned=CountOwnedCompanions(me)
  LeafVE_AchTest.SetCounter(me,"companions",totalOwned)
  AwardCompanionMilestones(totalOwned,silent)
  moduleState.seeded=true
end

RegisterCompanionAchievements()

local companionFrame=CreateFrame("Frame")
companionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
companionFrame:RegisterEvent("SPELLS_CHANGED")
local companionReady=false
companionFrame:SetScript("OnEvent",function()
  if event=="PLAYER_ENTERING_WORLD" then companionReady=true; ScanCompanions(true); return end
  if not companionReady then return end
  if event=="SPELLS_CHANGED" then ScanCompanions(false) end
end)
