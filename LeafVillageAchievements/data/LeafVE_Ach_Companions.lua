-- LeafVE_Ach_Companions.lua
-- Turtle WoW companion collection achievements and shared collection metadata.
-- Vanilla/Turtle WoW 1.12, Lua 5.0 compatible.

local COMPANION_CATEGORY = "Companions"
local COMPANION_ICON = "Interface\\Icons\\INV_Misc_Toy_07"

local COMPANION_CATALOG = {
  {name="Dream Frog", source="Drop", obtainedFrom="Rare Turtle WoW frog-collection reward; consult the current companion guide for the exact custom source.", sourceConfidence="Turtle custom source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Infinite Frog", source="Drop", obtainedFrom="Rare Turtle WoW frog-collection reward; consult the current companion guide for the exact custom source.", sourceConfidence="Turtle custom source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Azure Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Bullfrog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Dart Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Golden Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Island Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Pink Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Poison Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Pond Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Snow Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tree Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Wood Frog", source="Collection", obtainedFrom="Turtle WoW frog collection from custom vendors, events, quests, or zone drops depending on the color.", sourceConfidence="Turtle companion guide category", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Gilnean Raven", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Little Ball of Spider Web", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Midnight", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Mr. Bigglesworth", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="A Jubling's Tiny Home", source="Event", obtainedFrom="Darkmoon Faire quest from Morja: lure Jubjub with Dark Iron Ale, complete the quest, then wait for the egg to hatch.", sourceConfidence="Verified: Darkmoon Faire quest", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Albino Snake", source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Albino Snapjaw", source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Amani Eagle", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Ancona Chicken", source="Vendor", obtainedFrom="Buy from Magus Tirth in the Shimmering Flats after using /chicken and /beckon.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Arcane Elemental", source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Azure Whelpling", source="Drop", obtainedFrom="Rare drop from blue dragonkin in Azshara.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Baby Shark", source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Beaky", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Black Kingsnake", source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Black Piglet", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Black Tabby", source="Drop", obtainedFrom="Rare drop from Dalaran-affiliated enemies around Ambermill and the Alterac foothills.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Black-Footed Fox", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Blitzen", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Bombay", source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Bone Golem", source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Brightwing", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Bronze Whelpling", source="Rare Drop", obtainedFrom="Rare Turtle WoW custom drop, instance reward, or limited collection reward; exact source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Brown Snake", source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Caravan Kodo", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Cheeky Monkey", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Cockatiel", source="Vendor", obtainedFrom="Buy from Narkk in Booty Bay.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Core Hound Pup", source="Raid", obtainedFrom="High-end raid or account reward associated with Molten Core-themed content.", sourceConfidence="Strong raid reward evidence", sourceCategory="Raid", points=75, difficulty="Rare"},
  {name="Cornish Rex", source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Corrupted Kitten", source="Quest", obtainedFrom="Turtle WoW custom quest or reputation reward tied to corrupted-feline content.", sourceConfidence="Turtle custom source; exact step may vary", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Cottontail Rabbit", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Cracked Raptor Egg", source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Crimson Snake", source="Vendor", obtainedFrom="Buy from Xan'tish in Orgrimmar.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Crimson Whelpling", source="Drop", obtainedFrom="Rare drop from red dragonkin in the Wetlands.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Dalaran Cloud Familiar", source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Dark Whelpling", source="Drop", obtainedFrom="Rare drop from black dragonkin in the Badlands and Burning Steppes.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Darkmoon Tonk", source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Diablo Stone", source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Eagle Owl", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Egg of Turtlhu", source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Emerald Whelpling", source="Drop", obtainedFrom="Rare drop from green dragonkin in the Swamp of Sorrows.", sourceConfidence="Verified: Vanilla rare drop", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Enchanted Broom", source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Field Repair Bot 75B", source="Profession", obtainedFrom="Engineering-created Turtle WoW utility companion.", sourceConfidence="Strong Turtle profession evidence", sourceCategory="Profession", points=50, difficulty="Uncommon"},
  {name="Finn the Shark", source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Flipper", source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Forworn Mule", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Frostwolf Ghostpup", source="Reputation", obtainedFrom="Faction-themed Turtle WoW quest, reputation, or event reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Glitterwing", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Golden Dragonhawk Hatchling", source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Great Horned Owl", source="Vendor", obtainedFrom="Buy from Shylenai in Darnassus.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Green Helper Box", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Green Steam Tonk", source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Green Water Snake", source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Green Wing Macaw", source="Drop", obtainedFrom="Drop from enemies throughout The Deadmines.", sourceConfidence="Verified: Vanilla dungeon drop", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Gurky", source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Hawk Owl", source="Vendor", obtainedFrom="Buy from Shylenai in Darnassus.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Hawksbill Snapjaw", source="Collection", obtainedFrom="Turtle WoW coastal/island companion reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Hedwig", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="High Elf Orphan Whistle", source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Hippogryph Hatchling", source="Promotion", obtainedFrom="Legacy trading-card/promotional companion; Turtle WoW availability may be limited or promotional.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Hyacinth Macaw", source="Drop", obtainedFrom="Extremely rare world drop from Bloodsail pirates in Stranglethorn Vale.", sourceConfidence="Verified: Vanilla very rare drop", sourceCategory="Drop", points=100, difficulty="Prestige"},
  {name="Hyjal Bear Cub", source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Infinite Whelpling", source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Jingling Bell", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Kirin Tor Familiar", source="Reputation", obtainedFrom="Turtle WoW Dalaran/Kirin Tor custom content reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Leatherback Snapjaw", source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lil' K.T.", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop or special promotional companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Lil' Ragnaros", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop or special promotional companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Little Fawn", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Little Pony", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Loggerhead Snapjaw", source="Collection", obtainedFrom="Turtle WoW snapjaw companion from custom coastal/island content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lost Farm Sheep", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lovely Pink Fox", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Lulu", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Mechanical Auctioneer", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Mechanical Chicken", source="Quest", obtainedFrom="Complete all three OOX escort quest chains, then finish An OOX of Your Own in Booty Bay.", sourceConfidence="Verified: Vanilla quest chain", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Mechanical Squirrel Box", source="Profession", obtainedFrom="Craft with Engineering from Schematic: Mechanical Squirrel, or obtain the bind-on-use pet from another engineer.", sourceConfidence="Verified: Vanilla Engineering", sourceCategory="Profession", points=25, difficulty="Common"},
  {name="Mini Krampus", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Moonkin Hatchling", source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Murky", source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Mysterious Fortune Teller", source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Olive Snapjaw", source="Collection", obtainedFrom="Turtle WoW coastal/island companion reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Orange Tabby", source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Panda Collar", source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Peddlefeet", source="Event", obtainedFrom="Love is in the Air seasonal reward, commonly purchased with Love Tokens.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Pengu", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Phoenix Hatchling", source="Dungeon", obtainedFrom="Rare dungeon or raid-themed companion reward on Turtle WoW.", sourceConfidence="Strong rare-instance evidence", sourceCategory="Dungeon", points=75, difficulty="Rare"},
  {name="Piglet's Collar", source="Event", obtainedFrom="Children's Week orphan quest reward.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Poley", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Prairie Dog Whistle", source="Vendor", obtainedFrom="Buy from Halpa in Thunder Bluff.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Prince Herman II", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Purple Steam Tonk", source="Event", obtainedFrom="Darkmoon Faire prize or vendor reward.", sourceConfidence="Strong Darkmoon Faire evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Red Dragon Orb", source="Rare Drop", obtainedFrom="Rare Turtle WoW custom drop, instance reward, or limited collection reward; exact source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Red Helper Box", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Scarlet Snake", source="Collection", obtainedFrom="Turtle WoW custom snake companion from a vendor, quest, or world drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Scotty", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Senegal", source="Vendor", obtainedFrom="Buy from Narkk in Booty Bay.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Siamese", source="Drop", obtainedFrom="Drop from Cookie in The Deadmines.", sourceConfidence="Verified: Vanilla dungeon drop", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Silver Tabby", source="Vendor", obtainedFrom="Buy from Donni Anthania at the Crazy Cat Lady house in Elwynn Forest.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Smolderweb Hatchling", source="Dungeon", obtainedFrom="Complete En-Ay-Es-Tee-Why in Lower Blackrock Spire.", sourceConfidence="Verified: Vanilla dungeon quest", sourceCategory="Dungeon", points=50, difficulty="Uncommon"},
  {name="Snowshoe", source="Vendor", obtainedFrom="Buy the rabbit crate from Yarlyn Amberstill at Amberstill Ranch in Dun Morogh.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Snowy Owl", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Spectral Cub", source="Drop", obtainedFrom="Rare Turtle WoW custom drop or high-end content reward.", sourceConfidence="Strong Turtle rare-reward evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Spectral Faeling", source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Speedy", source="Collection", obtainedFrom="Turtle WoW custom collection reward; exact acquisition is listed in the current companion guide/database.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Sprite Darter Hatchling", source="Quest", obtainedFrom="Alliance quest chain in Feralas; Turtle WoW also provides faction-accessible acquisition paths.", sourceConfidence="Verified: Vanilla/Turtle quest", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Summon: Auctioneer", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Summon: Barber", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Summon: Surgeon", source="Turtle Shop", obtainedFrom="Turtle WoW donation/token-shop utility companion.", sourceConfidence="Strong Turtle shop evidence", sourceCategory="Turtle Shop", points=25, difficulty="Common"},
  {name="Sunscale Hatchling", source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Teldrassil Sproutling", source="Quest", obtainedFrom="Night Elf/Hyjal custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Quest", points=50, difficulty="Uncommon"},
  {name="Terky", source="Promotion", obtainedFrom="Limited promotional murloc companion; Turtle WoW availability varies by event or promotion.", sourceConfidence="Strong promotional evidence", sourceCategory="Promotion", points=100, difficulty="Prestige"},
  {name="Thalassian Tender", source="Reputation", obtainedFrom="High Elf/Silvermoon custom quest or reputation reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Reputation", points=50, difficulty="Uncommon"},
  {name="Tiny Green Dragon", source="Drop", obtainedFrom="Rare dragonkin companion drop; farm the matching dragonflight mobs listed in the Turtle database.", sourceConfidence="Strong Vanilla/Turtle drop evidence", sourceCategory="Drop", points=75, difficulty="Rare"},
  {name="Tiny Pterodactyl", source="Drop", obtainedFrom="Turtle WoW dinosaur/raptor custom drop or quest reward.", sourceConfidence="Strong Turtle custom-content evidence", sourceCategory="Drop", points=50, difficulty="Uncommon"},
  {name="Tiny Shore Crab", source="Collection", obtainedFrom="Turtle WoW aquatic/island custom content reward or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tiny Snowman", source="Event", obtainedFrom="Feast of Winter Veil seasonal reward.", sourceConfidence="Strong seasonal evidence", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Tiny Warp Stalker", source="Turtle WoW", obtainedFrom="Turtle WoW custom companion; exact acquisition source is not verified in the bundled catalogue.", sourceConfidence="Unverified Turtle source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Tirisfal Bat", source="Collection", obtainedFrom="Turtle WoW custom bird companion from a zone quest, reputation vendor, event, or drop.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Undercity Cockroach", source="Vendor", obtainedFrom="Buy from Jeremiah Payson beneath the Undercity bank.", sourceConfidence="Verified: Vanilla vendor", sourceCategory="Vendor", points=25, difficulty="Common"},
  {name="Water Waveling", source="Collection", obtainedFrom="Turtle WoW magical companion from custom reputation, event, quest, or rare content.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Westfall Chicken", source="Quest", obtainedFrom="Complete CLUCK! by repeatedly using /chicken on a chicken, then feeding it Special Chicken Feed.", sourceConfidence="Verified: Vanilla quest", sourceCategory="Quest", points=25, difficulty="Common"},
  {name="Whiskers the Rat", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="White Kitten", source="Vendor", obtainedFrom="Buy from Lil Timmy during his limited Stormwind patrol spawn.", sourceConfidence="Verified: Vanilla rare vendor", sourceCategory="Vendor", points=50, difficulty="Uncommon"},
  {name="White Tiger Cub", source="Collection", obtainedFrom="Turtle WoW custom quest, vendor, event, or zone-drop companion.", sourceConfidence="Turtle custom source", sourceCategory="Collection", points=50, difficulty="Uncommon"},
  {name="Worg Pup", source="Dungeon", obtainedFrom="Complete Kibler's Exotic Pets in Lower Blackrock Spire.", sourceConfidence="Verified: Vanilla dungeon quest", sourceCategory="Dungeon", points=50, difficulty="Uncommon"},
  {name="Mr Wiggles", source="Event", obtainedFrom="Children's Week orphan quest reward.", sourceConfidence="Verified: Seasonal event", sourceCategory="Event", points=50, difficulty="Uncommon"},
  {name="Zergling Leash", source="Promotion", obtainedFrom="Legacy Collector’s Edition promotional companion; availability on Turtle WoW may be through special promotions or shop rotations.", sourceConfidence="Verified legacy promotion; Turtle availability varies", sourceCategory="Promotion", points=100, difficulty="Prestige"},
}

local COMPANION_MILESTONES = {
  {id="casual_pet_collector", name="Companion Tender", desc="Collect 10 Turtle WoW companions.", goal=10, points=50},
  {id="casual_pet_fanatic", name="Companion Handler", desc="Collect 25 Turtle WoW companions.", goal=25, points=100},
  {id="companion_collector_50", name="Companion Tamer", desc="Collect 50 Turtle WoW companions.", goal=50, points=150},
  {id="companion_collector_75", name="Companion Wrangler", desc="Collect 75 Turtle WoW companions.", goal=75, points=200},
  {id="companion_collector_100", name="Companion Menagerist", desc="Collect 100 Turtle WoW companions.", goal=100, points=250},
}

local COMPANION_TITLE_DEFS = {
  {id="title_companion_tender", name="Tender", achievement="casual_pet_collector", desc="Awarded for collecting 10 Turtle WoW companions."},
  {id="title_companion_tamer", name="Tamer", achievement="companion_collector_50", desc="Awarded for collecting 50 Turtle WoW companions."},
  {id="title_companion_wrangler", name="Wrangler", achievement="companion_collector_75", desc="Awarded for collecting 75 Turtle WoW companions."},
  {id="title_companion_menagerist", name="Menagerist", achievement="companion_collector_100", desc="Awarded for collecting 100 Turtle WoW companions."},
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
    icon=data.icon or COMPANION_ICON, achievementId=data.id,
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
table.insert(COMPANION_TITLE_DEFS,{id="title_companion_master",name="Petmaster",achievement="companion_collector_all",desc="Awarded for collecting every Turtle WoW companion."})

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
      sourceConfidence=data.sourceConfidence,difficulty=data.difficulty,
    })
  end
  for _,milestone in ipairs(COMPANION_MILESTONES) do
    LeafVE_AchTest:AddAchievement(milestone.id,{id=milestone.id,name=milestone.name,desc=milestone.desc,category=COMPANION_CATEGORY,points=milestone.points,icon=COMPANION_ICON,companionType="milestone",collectionType="companion"})
    if LeafVE_AchTest.RegisterProgressDef then LeafVE_AchTest:RegisterProgressDef(milestone.id,{counter="companions",goal=milestone.goal}) end
  end
  if LeafVE_AchTest.AddTitle then
    for _,titleData in ipairs(COMPANION_TITLE_DEFS) do
      LeafVE_AchTest:AddTitle({id=titleData.id,name=titleData.name,chatName=titleData.name,achievement=titleData.achievement,prefix=false,category=COMPANION_CATEGORY,icon=COMPANION_ICON,desc=titleData.desc})
    end
  end
end

local function AddDetectedCompanion(seen,name)
  local id=COMPANION_LOOKUP[Slugify(name)]
  if id then seen[id]=true end
end

local function ScanBagRange(seen,bagStart,bagEnd)
  if not GetContainerNumSlots or not GetContainerItemLink then return end
  for bag=bagStart,bagEnd do
    local slotCount=GetContainerNumSlots(bag) or 0
    for slot=1,slotCount do
      local itemName=GetItemNameFromLink(GetContainerItemLink(bag,slot))
      if itemName and itemName~="" then AddDetectedCompanion(seen,itemName) end
    end
  end
end

local function IsBankAccessible()
  if not GetContainerNumSlots then return false end
  return (GetContainerNumSlots(-1) or 0)>0
end

local function ScanSpellbook(seen)
  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellName then return end
  local tabCount=GetNumSpellTabs() or 0
  for tabIndex=1,tabCount do
    local _,_,offset,spellCount=GetSpellTabInfo(tabIndex)
    offset=offset or 0; spellCount=spellCount or 0
    for spellOffset=1,spellCount do
      local spellName=GetSpellName(offset+spellOffset,BOOKTYPE_SPELL or "spell")
      if spellName and spellName~="" then AddDetectedCompanion(seen,spellName) end
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

local function ScanCompanions(forceSilent,includeSpellbook,includeBank)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement or not LeafVE_AchTest.SetCounter then return end
  local me=LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  if not me then return end
  local moduleState=GetCompanionModuleState(); if not moduleState then return end
  local bankAccessible=includeBank and IsBankAccessible()
  local isSeedScan=not moduleState.seeded
  local isBankSeedScan=bankAccessible and not moduleState.bankSeeded
  local silent=forceSilent or isSeedScan or isBankSeedScan
  local seen={}
  ScanBagRange(seen,0,4)
  if bankAccessible then ScanBagRange(seen,-1,-1); ScanBagRange(seen,5,10) end
  if includeSpellbook then ScanSpellbook(seen) end
  for achievementId in pairs(seen) do LeafVE_AchTest:AwardAchievement(achievementId,silent) end
  RefreshStoredPointValues(me)
  local totalOwned=CountOwnedCompanions(me)
  LeafVE_AchTest.SetCounter(me,"companions",totalOwned)
  AwardCompanionMilestones(totalOwned,silent)
  moduleState.seeded=true
  if bankAccessible then moduleState.bankSeeded=true end
end

RegisterCompanionAchievements()

local companionFrame=CreateFrame("Frame")
companionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
companionFrame:RegisterEvent("BAG_UPDATE")
companionFrame:RegisterEvent("SPELLS_CHANGED")
companionFrame:RegisterEvent("BANKFRAME_OPENED")
companionFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
local companionReady=false
companionFrame:SetScript("OnEvent",function()
  if event=="PLAYER_ENTERING_WORLD" then companionReady=true; ScanCompanions(true,true,true); return end
  if not companionReady then return end
  if event=="BAG_UPDATE" then ScanCompanions(false,false,true)
  elseif event=="SPELLS_CHANGED" then ScanCompanions(false,true,false)
  elseif event=="BANKFRAME_OPENED" or event=="PLAYERBANKSLOTS_CHANGED" then ScanCompanions(false,false,true) end
end)
