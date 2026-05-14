-- LeafVillageAchievements - v3.0 - More Titles + Title Search Bar
-- Guild message: [Title] has earned the achievement [Achievement]

LeafVE_AchTest = LeafVE_AchTest or {}
LeafVE_AchTest.name = "LeafVillageAchievements"
LeafVE_AchTest_DB = LeafVE_AchTest_DB or {}
LeafVillageAchievements = LeafVE_AchTest
LeafVillageAchievements_DB = LeafVE_AchTest_DB
LeafVE_AchTest.DEBUG = false -- Set to true for debug messages
LeafVE_AchTest.initialized = false -- Set to true after PLAYER_ENTERING_WORLD backlog scan

local ADDON_COMM_PREFIX = "LeafVEAch"
local LEAFVE_RELEASE_VERSION = "3.0"
local VERSION_REMINDER_INTERVAL = 24 * 60 * 60
local LEAFVE_ANNOUNCEMENT_ITEM_ID = 6948

local THEME = {
  bg = {0.05, 0.04, 0.03, 1.00},
  leaf = {0.42, 0.82, 0.38, 1.00},
  gold = {0.93, 0.76, 0.20, 1.00},
  orange = {1.00, 0.50, 0.00, 1.00},
  border = {0.42, 0.31, 0.12, 1.00}
}

local TEX_ROOT = "Interface\\AddOns\\LeafVillageAchievements\\Media\\achievementframe\\"
local TEX = {
  achievementBg = TEX_ROOT.."ui-achievement-achievementbackground.blp",
  header = TEX_ROOT.."ui-achievement-header.blp",
  categoryBg = TEX_ROOT.."ui-achievement-category-background.blp",
  categoryHi = TEX_ROOT.."ui-achievement-category-highlight.blp",
  parchmentH = TEX_ROOT.."ui-achievement-parchment-horizontal.blp",
  shield = TEX_ROOT.."ui-achievement-shield.blp",
  shieldDesat = TEX_ROOT.."ui-achievement-shield-desaturated.blp",
  iconFrame = TEX_ROOT.."ui-achievement-iconframe.blp",
  shadow = TEX_ROOT.."ui-shadow-backdrop.blp",
  bankBg = "Interface\\ContainerFrame\\UI-Bag-Background",
}

local function Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF2DD35C[AchTest]|r: "..tostring(msg))
  end
end

local function Debug(msg)
  if LeafVE_AchTest.DEBUG then
    Print("|cFFFF0000[DEBUG]|r "..tostring(msg))
  end
end

local function Now() return time() end

-- Lua 5.0 compatibility: string.match does not exist in vanilla WoW
local function smatch(str, pattern)
  local s, _, c1, c2, c3 = string.find(str, pattern)
  if s then return c1 or true, c2, c3 end
  return nil
end

local function ShortName(name)
  if not name or name == "" then 
    name = UnitName("player")
    if not name or name == "" then return nil end
  end
  local dash = string.find(name, "-")
  if dash then return string.sub(name, 1, dash-1) end
  return name
end

local function Trim(s)
  return string.gsub(s or "", "^%s*(.-)%s*$", "%1")
end

local function GetAddonVersion()
  local version = ""
  if GetAddOnMetadata then
    version = Trim(GetAddOnMetadata(LeafVE_AchTest.name, "Version"))
  end
  if not version or version == "" then
    version = LEAFVE_RELEASE_VERSION
  end
  return version
end

local function ParseVersionParts(version)
  local parts = {}
  for part in string.gfind(tostring(version or ""), "(%d+)") do
    table.insert(parts, tonumber(part) or 0)
  end
  return parts
end

local function CompareVersions(leftVersion, rightVersion)
  local leftParts = ParseVersionParts(leftVersion)
  local rightParts = ParseVersionParts(rightVersion)
  local maxParts = math.max(table.getn(leftParts), table.getn(rightParts))

  for i = 1, maxParts do
    local left = leftParts[i] or 0
    local right = rightParts[i] or 0
    if left < right then return -1 end
    if left > right then return 1 end
  end

  return 0
end

local function IsOfficerRank(rankName)
  return rankName == "Anbu" or rankName == "Sannin" or rankName == "Hokage"
end

local function ResolveGuildMemberName(name)
  local query = ShortName(Trim(name))
  if not query or query == "" then return nil end
  if not IsInGuild or not IsInGuild() then return nil end
  if GuildRoster then GuildRoster() end
  local total = GetNumGuildMembers and GetNumGuildMembers() or 0
  local needle = string.lower(query)
  for i = 1, total do
    local fullName = GetGuildRosterInfo and GetGuildRosterInfo(i)
    local shortName = ShortName(fullName)
    if shortName and string.lower(shortName) == needle then
      return shortName
    end
  end
  return nil
end

local function IsPartyOrSelf(name)
  if not name or name == "" then return false end
  -- Combat log uses WoW unit ID tokens ("player", "party1"â€¦"party4", "raid1"â€¦"raid40")
  if name == "player" then return true end
  if smatch(name, "^party%d+$") then return true end
  if smatch(name, "^raid%d+$") then return true end
  name = ShortName(name)
  if not name then return false end
  if name == ShortName(UnitName("player")) then return true end
  local numRaid = GetNumRaidMembers and GetNumRaidMembers() or 0
  if numRaid > 0 then
    for i = 1, numRaid do
      if UnitExists("raid"..i) and ShortName(UnitName("raid"..i)) == name then return true end
    end
  else
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    for i = 1, numParty do
      if UnitExists("party"..i) and ShortName(UnitName("party"..i)) == name then return true end
    end
  end
  return false
end

local function EnsureDB()
  if not LeafVE_AchTest_DB then LeafVE_AchTest_DB = {} end
  if not LeafVE_AchTest_DB.achievements then LeafVE_AchTest_DB.achievements = {} end
  if not LeafVE_AchTest_DB.exploredZones then LeafVE_AchTest_DB.exploredZones = {} end
  if not LeafVE_AchTest_DB.selectedTitles then LeafVE_AchTest_DB.selectedTitles = {} end
  if not LeafVE_AchTest_DB.dungeonProgress then LeafVE_AchTest_DB.dungeonProgress = {} end
  if not LeafVE_AchTest_DB.raidProgress then LeafVE_AchTest_DB.raidProgress = {} end
  if not LeafVE_AchTest_DB.progressCounters then LeafVE_AchTest_DB.progressCounters = {} end
  if not LeafVE_AchTest_DB.progressCache then LeafVE_AchTest_DB.progressCache = {} end
  if not LeafVE_AchTest_DB.completedQuests then LeafVE_AchTest_DB.completedQuests = {} end
  if not LeafVE_AchTest_DB.peakGold then LeafVE_AchTest_DB.peakGold = {} end
  if not LeafVE_AchTest_DB.goldEarnedTotal then LeafVE_AchTest_DB.goldEarnedTotal = {} end
  if not LeafVE_AchTest_DB.goldLastSeen then LeafVE_AchTest_DB.goldLastSeen = {} end
  if type(LeafVE_AchTest_DB.versionInfo) ~= "table" then LeafVE_AchTest_DB.versionInfo = {} end
  if type(LeafVE_AchTest_DB.versionInfo.guildVersions) ~= "table" then LeafVE_AchTest_DB.versionInfo.guildVersions = {} end
  if not LeafVE_AchTest_DB.versionInfo.lastReminderAt then LeafVE_AchTest_DB.versionInfo.lastReminderAt = 0 end

  local installedVersion = GetAddonVersion()
  local latestKnownVersion = LeafVE_AchTest_DB.versionInfo.latestKnownVersion or installedVersion
  if CompareVersions(latestKnownVersion, LEAFVE_RELEASE_VERSION) < 0 then
    latestKnownVersion = LEAFVE_RELEASE_VERSION
  end
  if CompareVersions(latestKnownVersion, installedVersion) < 0 then
    latestKnownVersion = installedVersion
  end
  LeafVE_AchTest_DB.versionInfo.latestKnownVersion = latestKnownVersion
end

local function RecordKnownVersion(playerName, version)
  EnsureDB()
  playerName = ShortName(playerName)
  version = Trim(version)
  if not playerName or version == "" then return end

  LeafVE_AchTest_DB.versionInfo.guildVersions[playerName] = version

  local latestKnownVersion = LeafVE_AchTest_DB.versionInfo.latestKnownVersion or LEAFVE_RELEASE_VERSION
  if CompareVersions(version, latestKnownVersion) > 0 then
    LeafVE_AchTest_DB.versionInfo.latestKnownVersion = version
  end
end

local function GetRequiredAddonVersion()
  EnsureDB()
  local requiredVersion = LeafVE_AchTest_DB.versionInfo.latestKnownVersion or LEAFVE_RELEASE_VERSION
  if CompareVersions(requiredVersion, LEAFVE_RELEASE_VERSION) < 0 then
    requiredVersion = LEAFVE_RELEASE_VERSION
  end
  return requiredVersion
end

if StaticPopupDialogs then
  StaticPopupDialogs["LEAFVE_ACH_OUTDATED_VERSION"] = {
    text = "LeafVillageAchievements %s is required.\nYou are currently on %s.\nPlease update your addon.",
    button1 = "Okay",
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
  }
end

function LeafVE_AchTest:ShowVersionReminder(requiredVersion, currentVersion)
  EnsureDB()
  requiredVersion = requiredVersion or GetRequiredAddonVersion()
  currentVersion = currentVersion or GetAddonVersion()
  LeafVE_AchTest_DB.versionInfo.lastReminderAt = Now()

  if StaticPopup_Show then
    StaticPopup_Show("LEAFVE_ACH_OUTDATED_VERSION", requiredVersion, currentVersion)
  else
    Print("LeafVillageAchievements "..requiredVersion.." is required. You are currently on "..currentVersion..". Please update your addon.")
  end
end

function LeafVE_AchTest:CheckVersionReminder(force)
  EnsureDB()

  local currentVersion = GetAddonVersion()
  local requiredVersion = GetRequiredAddonVersion()
  if CompareVersions(currentVersion, requiredVersion) >= 0 then
    return false
  end

  local lastReminderAt = tonumber(LeafVE_AchTest_DB.versionInfo.lastReminderAt) or 0
  if not force and (Now() - lastReminderAt) < VERSION_REMINDER_INTERVAL then
    return false
  end

  self:ShowVersionReminder(requiredVersion, currentVersion)
  return true
end


-- Maps zone-group key â†’ achievement ID for groups that don't use the explore_tw_ prefix.
local ZONE_GROUP_ACH = {
  kalimdor         = "explore_kalimdor",
  eastern_kingdoms = "explore_eastern_kingdoms",
  elwynn           = "casual_explore_elwynn",
  barrens          = "casual_explore_barrens",
  stonetalon_tw    = "explore_tw_stonetalon",
  arathi_tw        = "explore_tw_arathi",
  badlands_tw      = "explore_tw_badlands",
  ashenvale_tw     = "explore_tw_ashenvale",
}

local function GetZoneGroupAchievementId(groupKey)
  return ZONE_GROUP_ACH[groupKey] or ("explore_tw_"..groupKey)
end

-- Zone-group â†’ list of discoverable zone/subzone names.
-- Kalimdor and Eastern Kingdoms use major zone names (tracked via GetZoneText).
-- Elwynn/Barrens use subzone names (tracked via GetSubZoneText).
-- All other entries are Turtle WoW custom zones (subzone names).
local ZONE_GROUP_ZONES = {
  kalimdor = {"Durotar","Mulgore","The Barrens","Teldrassil","Darkshore","Ashenvale","Stonetalon Mountains","Desolace","Feralas","Thousand Needles","Tanaris","Dustwallow Marsh","Azshara","Felwood","Un'Goro Crater","Moonglade","Winterspring","Silithus"},
  eastern_kingdoms = {"Dun Morogh","Elwynn Forest","Tirisfal Glades","Silverpine Forest","Westfall","Redridge Mountains","Duskwood","Wetlands","Loch Modan","Hillsbrad Foothills","Alterac Mountains","Arathi Highlands","Badlands","Searing Gorge","Burning Steppes","The Hinterlands","Western Plaguelands","Eastern Plaguelands","Stranglethorn Vale","Swamp of Sorrows","Blasted Lands","Deadwind Pass"},
  elwynn = {"Northshire Valley","Northshire Abbey","Crystal Lake","Eastvale Logging Camp","Goldshire","Mirror Lake","Westbrook Garrison","Tower of Azora","Brackwell Pumpkin Patch","The Fargodeep Mine","Jasperlode Mine"},
  barrens = {"The Crossroads","Ratchet","Grol'dom Farm","Lushwater Oasis","Stagnant Oasis","Camp Taurajo","Mor'shan Base Camp","Blackthorn Ridge","The Wailing Caverns","Darsok's Rest","Far Watch Post"},
  balor = {
    "Bilgerat Compound","Ruins of Breezehaven","SI:7 Outpost",
    "Sorrowmore Lake","Stormbreaker Point","Stormwrought Castle",
  },
  gilneas = {
    "Blackthorn's Camp","Brol'ok Mound","Dawnstone Mine","The Dryrock Mine",
    "Dryrock Valley (The Dryrock Pit)","Ebonmere Farm","Freyshear Keep",
    "Gilneas City","Glaymore Stead","The Greymane Wall","Greymane's Watch",
    "Hollow Web Cemetary","Hollow Web Woods","Mossgrove Farm","Northgate Tower",
    "Oldrock Pass","The Overgrown Acre","Ravenshire","Ravenwood Keep",
    "Rosewick Plantation","Ruins of Greyshire","Shademore Tavern",
    "Southmire Orchard","Stillward Church","Vagrant Encampment","Westgate Tower",
  },
  northwind = {
    "Abbey Gardens","Ambershire","Crystal Falls",
    "Northwind Logging Camp","Ruins of Birkhaven","Sherwood Quarry","Stillheart Port",
  },
  lapidis = {
    "Bright Coast","Caelan's Rest","Crown Island","Gor'dosh Heights",
    "Hazzuri Glade","The Rock","Shank's Reef","The Tower of Lapidis",
    "The Wallowing Coast","Zul'Hazu",
  },
  gillijim = {
    "The Broken Reef","Deeptide Sanctum","Distillery Island","Faelon's Folly",
    "Gillijim Canyon","Gillijim Strand","Kalkor Point","Kazon Island",
    "Maul'ogg Post","Maul'ogg Refuge","Ruins of Zul'Razar","The Silver Coast",
    "The Silver Sandbar","Southsea Sandbar","The Tangled Wood","Zul'Razar",
  },
  scarlet_enclave = {
    "The Forbidding Sea","Gloom Hill","Havenshire","King's Harbor",
    "Light's Point","New Avalon",
  },
  grim_reaches = {
    "Dun Kithas","The Grim Hollow","Ruins of Stolgaz Keep",
    "Shatterblade Post","Zarm'Geth Stronghold",
  },
  telabim = {
    "Bixxle's Storehouse","The Derelict Camp","Highvale Rise","The Jagged Isles",
    "The Shallow Strand","Tazzo's Shack","Tel Co. Basecamp","The Washing Shore",
  },
  hyjal = {
    "Barkskin Plateau","Barkskin Village","Bleakhollow Crater","Circle of Power",
    "Darkhollow Pass","The Emerald Gateway","Nordanaar","Nordrassil Glade",
    "The Ruins of Telennas","Zul'Hathar",
  },
  tirisfal_uplands = {
    "The Blacktower Inn","The Corinth Farmstead","Crumblepoint Tower",
    "Glenshire","Gracestone Mine","Ishnu'Danil","The Jagged Hills",
    "The Lafford House","The Remnants Camp","The Rogue Heights",
    "Shalla'Aran","Steepcliff Port","Shatteridge Tower","The Whispering Forest",
  },
  stonetalon_tw = {
    "Boulderslide Ravine","Greatwood Vale","Malaka'jin","Mirkfallon Lake",
    "Stonetalon Peak","The Talondeep Path","Windshear Crag",
  },
  arathi_tw = {
    "Wildtusk Village","Ruins of Zul'rasaz","Farwell Stead",
    "Gallant Square","Livingstone Croft",
  },
  badlands_tw = {
    "Ruins of Corthan","Scalebane Ridge","Crystalline Oasis",
    "Crystalline Pinnacle","Redbrand's Digsite","Angor Digsite","Ruins of Zeth",
  },
  ashenvale_tw = {
    "Forest Song","Thalanaar","Talonbranch Glade",
    "Demon Fall Ridge","Warsong Lumber Camp",
  },
}

local ZONE_NAME_ALIASES = {
  -- â”€â”€ Elwynn Forest â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Northshire"]              = "Northshire Valley",
  ["Northshire Vineyards"]    = "Northshire Valley",
  ["Northshire River"]        = "Northshire Valley",
  ["Echo Ridge Mine"]         = "Northshire Valley",
  ["Fargodeep Mine"]          = "The Fargodeep Mine",
  ["The Fergodeep Mine"]      = "The Fargodeep Mine",
  ["Fergodeep Mine"]          = "The Fargodeep Mine",
  ["The Jasperlode Mine"]     = "Jasperlode Mine",
  ["Jasper Lode Mine"]        = "Jasperlode Mine",
  ["Jasperlode"]              = "Jasperlode Mine",
  ["Eastvale"]                = "Eastvale Logging Camp",
  ["East Vale Logging Camp"]  = "Eastvale Logging Camp",
  ["Lion's Pride Inn"]        = "Goldshire",
  ["Mirror Lake Orchard"]     = "Mirror Lake",
  ["Westbrook"]               = "Westbrook Garrison",
  ["Azora"]                   = "Tower of Azora",
  ["Brackwell"]               = "Brackwell Pumpkin Patch",
  ["Northshire Abby"]         = "Northshire Abbey",

  -- â”€â”€ Barrens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Crossroads"]              = "The Crossroads",
  ["The Ratchet"]             = "Ratchet",
  ["Groldom Farm"]            = "Grol'dom Farm",
  ["Grol'dom"]                = "Grol'dom Farm",
  ["Lushwater"]               = "Lushwater Oasis",
  ["Stagnant"]                = "Stagnant Oasis",
  ["Taurajo"]                 = "Camp Taurajo",
  ["Mor'shan"]                = "Mor'shan Base Camp",
  ["Morshan Base Camp"]       = "Mor'shan Base Camp",
  ["Wailing Caverns"]         = "The Wailing Caverns",
  ["Darsoks Rest"]            = "Darsok's Rest",
  ["Darsok's"]                = "Darsok's Rest",
  ["Far Watch"]               = "Far Watch Post",
  ["Farwatch Post"]           = "Far Watch Post",

  -- â”€â”€ Balor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Bilgerat"]                = "Bilgerat Compound",
  ["Breezehaven"]             = "Ruins of Breezehaven",
  ["SI7 Outpost"]             = "SI:7 Outpost",
  ["SI:7"]                    = "SI:7 Outpost",
  ["Sorrowmore"]              = "Sorrowmore Lake",
  ["Stormbreaker"]            = "Stormbreaker Point",
  ["Stormwrought"]            = "Stormwrought Castle",

  -- â”€â”€ Gilneas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Blackthorn Camp"]         = "Blackthorn's Camp",
  ["Blackthorns Camp"]        = "Blackthorn's Camp",
  ["Brolok Mound"]            = "Brol'ok Mound",
  ["Brol'ok"]                 = "Brol'ok Mound",
  ["Dryrock Mine"]            = "The Dryrock Mine",
  ["The Dryrock Pit"]         = "Dryrock Valley (The Dryrock Pit)",
  ["Dryrock Valley"]          = "Dryrock Valley (The Dryrock Pit)",
  ["Dryrock Pit"]             = "Dryrock Valley (The Dryrock Pit)",
  ["Greymane Wall"]           = "The Greymane Wall",
  ["Greymane's"]              = "Greymane's Watch",
  ["Greymanes Watch"]         = "Greymane's Watch",
  ["Hollow Web Cemetery"]     = "Hollow Web Cemetary",
  ["Holloweb Cemetary"]       = "Hollow Web Cemetary",
  ["Hollowweb Cemetery"]      = "Hollow Web Cemetary",
  ["Overgrown Acre"]          = "The Overgrown Acre",

  -- â”€â”€ Northwind â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Northwind Logging"]       = "Northwind Logging Camp",
  ["Birkhaven"]               = "Ruins of Birkhaven",
  ["Stillheart"]              = "Stillheart Port",

  -- â”€â”€ Lapidis Isle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Caelans Rest"]            = "Caelan's Rest",
  ["Caelan's"]                = "Caelan's Rest",
  ["Gordosh Heights"]         = "Gor'dosh Heights",
  ["Gor'dosh"]                = "Gor'dosh Heights",
  ["Shanks Reef"]             = "Shank's Reef",
  ["Shank's"]                 = "Shank's Reef",
  ["Tower of Lapidis"]        = "The Tower of Lapidis",
  ["Lapidis Tower"]           = "The Tower of Lapidis",
  ["Wallowing Coast"]         = "The Wallowing Coast",
  ["ZulHazu"]                 = "Zul'Hazu",
  ["Zul Hazu"]                = "Zul'Hazu",

  -- â”€â”€ Gillijim's Isle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Broken Reef"]             = "The Broken Reef",
  ["Faelons Folly"]           = "Faelon's Folly",
  ["Faelon's"]                = "Faelon's Folly",
  ["Gillijim's Canyon"]       = "Gillijim Canyon",
  ["Gillijim's Strand"]       = "Gillijim Strand",
  ["Maulogg Post"]            = "Maul'ogg Post",
  ["Maul'ogg"]                = "Maul'ogg Post",
  ["Maulogg Refuge"]          = "Maul'ogg Refuge",
  ["Zul'Razar Ruins"]         = "Ruins of Zul'Razar",
  ["Silver Coast"]            = "The Silver Coast",
  ["Silver Sandbar"]          = "The Silver Sandbar",
  ["Tangled Wood"]            = "The Tangled Wood",
  ["ZulRazar"]                = "Zul'Razar",
  ["Zul Razar"]               = "Zul'Razar",

  -- â”€â”€ Scarlet Enclave â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Forbidding Sea"]          = "The Forbidding Sea",
  ["Kings Harbor"]            = "King's Harbor",
  ["King's"]                  = "King's Harbor",
  ["Lights Point"]            = "Light's Point",
  ["Light's"]                 = "Light's Point",

  -- â”€â”€ Grim Reaches â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Grim Hollow"]             = "The Grim Hollow",
  ["Stolgaz Keep"]            = "Ruins of Stolgaz Keep",
  ["Ruins of Stolgaz"]        = "Ruins of Stolgaz Keep",
  ["ZarmGeth Stronghold"]     = "Zarm'Geth Stronghold",
  ["Zarm'Geth"]               = "Zarm'Geth Stronghold",

  -- â”€â”€ Tel'Abim â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Bixxles Storehouse"]      = "Bixxle's Storehouse",
  ["Bixxle's"]                = "Bixxle's Storehouse",
  ["Derelict Camp"]           = "The Derelict Camp",
  ["Jagged Isles"]            = "The Jagged Isles",
  ["Shallow Strand"]          = "The Shallow Strand",
  ["Tazzos Shack"]            = "Tazzo's Shack",
  ["Tazzo's"]                 = "Tazzo's Shack",
  ["Washing Shore"]           = "The Washing Shore",

  -- â”€â”€ Hyjal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Emerald Gateway"]         = "The Emerald Gateway",
  ["Ruins of Telennas"]       = "The Ruins of Telennas",
  ["Telennas"]                = "The Ruins of Telennas",
  ["ZulHathar"]               = "Zul'Hathar",
  ["Zul Hathar"]              = "Zul'Hathar",
  ["Malakajin"]               = "Malaka'jin",

  -- â”€â”€ Tirisfal Uplands â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Blacktower Inn"]          = "The Blacktower Inn",
  ["Corinth Farmstead"]       = "The Corinth Farmstead",
  ["The Corinth"]             = "The Corinth Farmstead",
  ["IshnuDanil"]              = "Ishnu'Danil",
  ["Ishnu Danil"]             = "Ishnu'Danil",
  ["Jagged Hills"]            = "The Jagged Hills",
  ["Lafford House"]           = "The Lafford House",
  ["Remnants Camp"]           = "The Remnants Camp",
  ["Rogue Heights"]           = "The Rogue Heights",
  ["ShallaAran"]              = "Shalla'Aran",
  ["Shalla Aran"]             = "Shalla'Aran",
  ["Whispering Forest"]       = "The Whispering Forest",

  -- â”€â”€ Stonetalon TW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Talondeep Path"]          = "The Talondeep Path",

  -- â”€â”€ Arathi TW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Zul'rasaz"]               = "Ruins of Zul'rasaz",
  ["Ruins of Zulrasaz"]       = "Ruins of Zul'rasaz",

  -- â”€â”€ Badlands TW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Redbrands Digsite"]       = "Redbrand's Digsite",
  ["Angor Fortress"]          = "Angor Digsite",

  -- â”€â”€ Ashenvale TW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  ["Demon Fall"]              = "Demon Fall Ridge",
  ["Warsong Lumber"]          = "Warsong Lumber Camp",
}

local function NormalizeZoneName(name)
  return ZONE_NAME_ALIASES[name] or name
end

local ACHIEVEMENTS = {
  -- Leveling
  lvl_10={id="lvl_10",name="Level 10",desc="Reach level 10",category="Leveling",points=5,icon="Interface\\Icons\\INV_Boots_05"},
  lvl_20={id="lvl_20",name="Level 20",desc="Reach level 20",category="Leveling",points=10,icon="Interface\\Icons\\INV_Gauntlets_18"},
  lvl_30={id="lvl_30",name="Level 30",desc="Reach level 30",category="Leveling",points=15,icon="Interface\\Icons\\INV_Helmet_08"},
  lvl_40={id="lvl_40",name="Level 40",desc="Reach level 40",category="Leveling",points=20,icon="Interface\\Icons\\INV_Shoulder_23"},
  lvl_50={id="lvl_50",name="Level 50",desc="Reach level 50",category="Leveling",points=25,icon="Interface\\Icons\\INV_Chest_Plate16"},
  lvl_60={id="lvl_60",name="Level 60",desc="Reach maximum level",category="Leveling",points=50,icon="Interface\\Icons\\INV_Crown_01"},

  -- Professions
  prof_dual_artisan={id="prof_dual_artisan",name="Dual Artisan",desc="Reach 300 in two professions",category="Professions",points=50,icon="Interface\\Icons\\INV_Misc_Note_06"},
  prof_alchemy_300={id="prof_alchemy_300",name="Master Alchemist",desc="Reach 300 Alchemy",category="Professions",points=25,icon="Interface\\Icons\\Trade_Alchemy"},
  prof_blacksmithing_300={id="prof_blacksmithing_300",name="Master Blacksmith",desc="Reach 300 Blacksmithing",category="Professions",points=25,icon="Interface\\Icons\\Trade_BlackSmithing"},
  prof_cooking_300={id="prof_cooking_300",name="Master Chef",desc="Reach 300 Cooking",category="Professions",points=25,icon="Interface\\Icons\\INV_Misc_Food_15"},
  prof_enchanting_300={id="prof_enchanting_300",name="Master Enchanter",desc="Reach 300 Enchanting",category="Professions",points=25,icon="Interface\\Icons\\Trade_Engraving"},
  prof_engineering_300={id="prof_engineering_300",name="Master Engineer",desc="Reach 300 Engineering",category="Professions",points=25,icon="Interface\\Icons\\Trade_Engineering"},
  prof_fishing_300={id="prof_fishing_300",name="Master Fisherman",desc="Reach 300 Fishing",category="Professions",points=25,icon="Interface\\Icons\\Trade_Fishing"},
  prof_herbalism_300={id="prof_herbalism_300",name="Master Herbalist",desc="Reach 300 Herbalism",category="Professions",points=25,icon="Interface\\Icons\\Trade_Herbalism"},
  prof_leatherworking_300={id="prof_leatherworking_300",name="Master Leatherworker",desc="Reach 300 Leatherworking",category="Professions",points=25,icon="Interface\\Icons\\Trade_LeatherWorking"},
  prof_firstaid_300={id="prof_firstaid_300",name="Master Medic",desc="Reach 300 First Aid",category="Professions",points=25,icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice"},
  prof_mining_300={id="prof_mining_300",name="Master Miner",desc="Reach 300 Mining",category="Professions",points=25,icon="Interface\\Icons\\Trade_Mining"},
  prof_skinning_300={id="prof_skinning_300",name="Master Skinner",desc="Reach 300 Skinning",category="Professions",points=25,icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01"},
  prof_tailoring_300={id="prof_tailoring_300",name="Master Tailor",desc="Reach 300 Tailoring",category="Professions",points=25,icon="Interface\\Icons\\Trade_Tailoring"},

  -- Gold
  gold_10={id="gold_10",name="Copper Baron",desc="Accumulate 10 gold",category="Gold",points=10,icon="Interface\\Icons\\INV_Misc_Coin_01"},
  gold_5000={id="gold_5000",name="Fortune Builder",desc="Accumulate 5000 gold",category="Gold",points=100,icon="Interface\\Icons\\INV_Crown_01"},
  gold_500={id="gold_500",name="Gold Tycoon",desc="Accumulate 500 gold",category="Gold",points=40,icon="Interface\\Icons\\INV_Misc_Coin_06"},
  gold_100={id="gold_100",name="Silver Merchant",desc="Accumulate 100 gold",category="Gold",points=20,icon="Interface\\Icons\\INV_Misc_Coin_03"},
  gold_1000={id="gold_1000",name="Wealthy Elite",desc="Accumulate 1000 gold",category="Gold",points=75,icon="Interface\\Icons\\INV_Misc_Coin_17"},

  -- Dungeons (Completion â€” all bosses with checkmarks, awarded when all killed)
  dung_bfd_complete={id="dung_bfd_complete",name="Blackfathom Deeps: Dungeon Clear",desc="Defeat all bosses in Blackfathom Deeps",category="Dungeons",points=25,icon="Interface\\Icons\\INV_Misc_Gem_Pearl_01",criteria_key="bfd",criteria_type="dungeon"},
  dung_brd_complete={id="dung_brd_complete",name="Blackrock Depths: Dungeon Clear",desc="Defeat all bosses in Blackrock Depths",category="Dungeons",points=50,icon="Interface\\Icons\\Spell_Fire_LavaSpawn",criteria_key="brd",criteria_type="dungeon"},
  dung_cotbm_complete={id="dung_cotbm_complete",name="Caverns of Time: Dungeon Clear",desc="Defeat all bosses in Caverns of Time: Black Morass",category="Dungeons",points=50,icon="Interface\\Icons\\INV_Misc_Rune_01",criteria_key="cotbm",criteria_type="dungeon"},
  dung_dme_complete={id="dung_dme_complete",name="Dire Maul East: Dungeon Clear",desc="Defeat all bosses in Dire Maul East",category="Dungeons",points=45,icon="Interface\\Icons\\INV_Misc_Key_14",criteria_key="dme",criteria_type="dungeon"},
  dung_dmn_complete={id="dung_dmn_complete",name="Dire Maul North: Dungeon Clear",desc="Defeat all bosses in Dire Maul North",category="Dungeons",points=50,icon="Interface\\Icons\\INV_Crown_01",criteria_key="dmn",criteria_type="dungeon"},
  dung_dmw_complete={id="dung_dmw_complete",name="Dire Maul West: Dungeon Clear",desc="Defeat all bosses in Dire Maul West",category="Dungeons",points=45,icon="Interface\\Icons\\INV_Misc_Book_09",criteria_key="dmw",criteria_type="dungeon"},
  dung_dmr_complete={id="dung_dmr_complete",name="Dragonmaw Retreat: Dungeon Clear",desc="Defeat all bosses in Dragonmaw Retreat",category="Dungeons",points=35,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",criteria_key="dmr",criteria_type="dungeon"},
  dung_gc_complete={id="dung_gc_complete",name="Gilneas City: Dungeon Clear",desc="Defeat all bosses in Gilneas City",category="Dungeons",points=35,icon="Interface\\Icons\\INV_Shield_06",criteria_key="gc",criteria_type="dungeon"},
  dung_gnomer_complete={id="dung_gnomer_complete",name="Gnomeregan: Dungeon Clear",desc="Defeat all bosses in Gnomeregan",category="Dungeons",points=30,icon="Interface\\Icons\\INV_Misc_Gear_01",criteria_key="gnomer",criteria_type="dungeon"},
  dung_hq_complete={id="dung_hq_complete",name="Hateforge Quarry: Dungeon Clear",desc="Defeat all bosses in Hateforge Quarry",category="Dungeons",points=40,icon="Interface\\Icons\\Trade_Mining",criteria_key="hq",criteria_type="dungeon"},
  dung_kc_complete={id="dung_kc_complete",name="Karazhan Crypt: Dungeon Clear",desc="Defeat all bosses in Karazhan Crypt",category="Dungeons",points=50,icon="Interface\\Icons\\Spell_Shadow_SoulGem",criteria_key="kc",criteria_type="dungeon"},
  dung_lbrs_complete={id="dung_lbrs_complete",name="Lower Blackrock Spire: Dungeon Clear",desc="Defeat all bosses in Lower Blackrock Spire",category="Dungeons",points=50,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",criteria_key="lbrs",criteria_type="dungeon"},
  dung_mara_complete={id="dung_mara_complete",name="Maraudon: Dungeon Clear",desc="Defeat all bosses in Maraudon",category="Dungeons",points=40,icon="Interface\\Icons\\INV_Misc_Root_02",criteria_key="mara",criteria_type="dungeon"},
  dung_mara_princess={id="dung_mara_princess",name="Maraudon: Princess Theradras",desc="Defeat Princess Theradras in Maraudon",category="Dungeons",points=25,icon="Interface\\Icons\\INV_Misc_Root_02"},
  dung_rfc_complete={id="dung_rfc_complete",name="Ragefire Chasm: Dungeon Clear",desc="Defeat all bosses in Ragefire Chasm",category="Dungeons",points=15,icon="Interface\\Icons\\Spell_Fire_Incinerate",criteria_key="rfc",criteria_type="dungeon"},
  dung_rfdown_complete={id="dung_rfdown_complete",name="Razorfen Downs: Dungeon Clear",desc="Defeat all bosses in Razorfen Downs",category="Dungeons",points=35,icon="Interface\\Icons\\Spell_Shadow_RaiseDead",criteria_key="rfdown",criteria_type="dungeon"},
  dung_rfk_complete={id="dung_rfk_complete",name="Razorfen Kraul: Dungeon Clear",desc="Defeat all bosses in Razorfen Kraul",category="Dungeons",points=30,icon="Interface\\Icons\\INV_Misc_Head_Boar_01",criteria_key="rfk",criteria_type="dungeon"},
  dung_sm_arm_complete={id="dung_sm_arm_complete",name="Scarlet Monastery - Armory: Dungeon Clear",desc="Defeat all bosses in Scarlet Monastery (Armory)",category="Dungeons",points=20,icon="Interface\\Icons\\INV_Gauntlets_17",criteria_key="sm_arm",criteria_type="dungeon"},
  dung_sm_cat_complete={id="dung_sm_cat_complete",name="Scarlet Monastery - Cathedral: Dungeon Clear",desc="Defeat all bosses in Scarlet Monastery (Cathedral)",category="Dungeons",points=25,icon="Interface\\Icons\\Spell_Holy_Resurrection",criteria_key="sm_cat",criteria_type="dungeon"},
  dung_sm_gy_complete={id="dung_sm_gy_complete",name="Scarlet Monastery - Graveyard: Dungeon Clear",desc="Defeat all bosses in Scarlet Monastery (Graveyard)",category="Dungeons",points=20,icon="Interface\\Icons\\Spell_Shadow_DeathScream",criteria_key="sm_gy",criteria_type="dungeon"},
  dung_sm_lib_complete={id="dung_sm_lib_complete",name="Scarlet Monastery - Library: Dungeon Clear",desc="Defeat all bosses in Scarlet Monastery (Library)",category="Dungeons",points=20,icon="Interface\\Icons\\INV_Misc_Book_11",criteria_key="sm_lib",criteria_type="dungeon"},
  dung_scholo_complete={id="dung_scholo_complete",name="Scholomance: Dungeon Clear",desc="Defeat all bosses in Scholomance",category="Dungeons",points=55,icon="Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",criteria_key="scholo",criteria_type="dungeon"},
  dung_sfk_complete={id="dung_sfk_complete",name="Shadowfang Keep: Dungeon Clear",desc="Defeat all bosses in Shadowfang Keep",category="Dungeons",points=25,icon="Interface\\Icons\\Spell_Shadow_Possession",criteria_key="sfk",criteria_type="dungeon"},
  dung_swv_complete={id="dung_swv_complete",name="Stormwind Vault: Dungeon Clear",desc="Defeat all bosses in Stormwind Vault",category="Dungeons",points=50,icon="Interface\\Icons\\INV_Misc_Key_03",criteria_key="swv",criteria_type="dungeon"},
  dung_swr_complete={id="dung_swr_complete",name="Stormwrought Ruins: Dungeon Clear",desc="Defeat all bosses in Stormwrought Ruins",category="Dungeons",points=30,icon="Interface\\Icons\\Spell_Shadow_Charm",criteria_key="swr",criteria_type="dungeon"},
  dung_strat_complete={id="dung_strat_complete",name="Stratholme: Dungeon Clear",desc="Defeat all bosses in Stratholme",category="Dungeons",points=55,icon="Interface\\Icons\\Spell_Shadow_RaiseDead",criteria_key="strat",criteria_type="dungeon"},
  dung_st_complete={id="dung_st_complete",name="Sunken Temple: Dungeon Clear",desc="Defeat all bosses in The Sunken Temple",category="Dungeons",points=45,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Green",criteria_key="st",criteria_type="dungeon"},
  dung_tcg_complete={id="dung_tcg_complete",name="The Crescent Grove: Dungeon Clear",desc="Defeat all bosses in The Crescent Grove",category="Dungeons",points=25,icon="Interface\\Icons\\Spell_Nature_Regeneration",criteria_key="tcg",criteria_type="dungeon"},
  dung_dm_complete={id="dung_dm_complete",name="The Deadmines: Dungeon Clear",desc="Defeat all bosses in The Deadmines",category="Dungeons",points=20,icon="Interface\\Icons\\INV_Misc_Bandana_03",criteria_key="dm",criteria_type="dungeon"},
  dung_stocks_complete={id="dung_stocks_complete",name="The Stockade: Dungeon Clear",desc="Defeat all bosses in The Stockade",category="Dungeons",points=25,icon="Interface\\Icons\\INV_Misc_Key_03",criteria_key="stocks",criteria_type="dungeon"},
  dung_ulda_complete={id="dung_ulda_complete",name="Uldaman: Dungeon Clear",desc="Defeat all bosses in Uldaman",category="Dungeons",points=35,icon="Interface\\Icons\\INV_Misc_StoneTablet_11",criteria_key="ulda",criteria_type="dungeon"},
  dung_ubrs_complete={id="dung_ubrs_complete",name="Upper Blackrock Spire: Dungeon Clear",desc="Defeat all bosses in Upper Blackrock Spire",category="Dungeons",points=55,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",criteria_key="ubrs",criteria_type="dungeon"},
  dung_wc_complete={id="dung_wc_complete",name="Wailing Caverns: Dungeon Clear",desc="Defeat all bosses in Wailing Caverns",category="Dungeons",points=20,icon="Interface\\Icons\\Spell_Nature_NullifyDisease",criteria_key="wc",criteria_type="dungeon"},
  dung_zf_complete={id="dung_zf_complete",name="Zul'Farrak: Dungeon Clear",desc="Defeat all bosses in Zul'Farrak",category="Dungeons",points=40,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Bronze",criteria_key="zf",criteria_type="dungeon"},

  -- Raids - Molten Core
  raid_mc_geddon={id="raid_mc_geddon",name="Molten Core: Baron Geddon",desc="Defeat Baron Geddon",category="Raids",points=30,icon="Interface\\Icons\\Spell_Fire_ElementalDevastation"},
  raid_mc_garr={id="raid_mc_garr",name="Molten Core: Garr",desc="Defeat Garr",category="Raids",points=25,icon="Interface\\Icons\\Spell_Nature_WispSplode"},
  raid_mc_gehennas={id="raid_mc_gehennas",name="Molten Core: Gehennas",desc="Defeat Gehennas",category="Raids",points=25,icon="Interface\\Icons\\Spell_Shadow_Requiem"},
  raid_mc_golemagg={id="raid_mc_golemagg",name="Molten Core: Golemagg",desc="Defeat Golemagg the Incinerator",category="Raids",points=30,icon="Interface\\Icons\\INV_Misc_MonsterScales_15"},
  raid_mc_lucifron={id="raid_mc_lucifron",name="Molten Core: Lucifron",desc="Defeat Lucifron",category="Raids",points=25,icon="Interface\\Icons\\Spell_Fire_Incinerate"},
  raid_mc_magmadar={id="raid_mc_magmadar",name="Molten Core: Magmadar",desc="Defeat Magmadar",category="Raids",points=25,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  raid_mc_majordomo={id="raid_mc_majordomo",name="Molten Core: Majordomo",desc="Defeat Majordomo Executus",category="Raids",points=40,icon="Interface\\Icons\\INV_Helmet_08"},
  raid_mc_ragnaros={id="raid_mc_ragnaros",name="Molten Core: Ragnaros",desc="Defeat Ragnaros the Firelord",category="Raids",points=100,icon="Interface\\Icons\\Spell_Fire_LavaSpawn"},
  raid_mc_shazzrah={id="raid_mc_shazzrah",name="Molten Core: Shazzrah",desc="Defeat Shazzrah",category="Raids",points=25,icon="Interface\\Icons\\Spell_Nature_Lightning"},
  raid_mc_sulfuron={id="raid_mc_sulfuron",name="Molten Core: Sulfuron Harbinger",desc="Defeat Sulfuron Harbinger",category="Raids",points=30,icon="Interface\\Icons\\Spell_Fire_FireArmor"},

  -- Raids - Onyxia
  raid_onyxia={id="raid_onyxia",name="Onyxia's Lair",desc="Defeat Onyxia",category="Raids",points=75,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},

  -- Raids - Blackwing Lair
  raid_bwl_broodlord={id="raid_bwl_broodlord",name="Blackwing Lair: Broodlord",desc="Defeat Broodlord Lashlayer",category="Raids",points=30,icon="Interface\\Icons\\INV_Bracer_18"},
  raid_bwl_chromaggus={id="raid_bwl_chromaggus",name="Blackwing Lair: Chromaggus",desc="Defeat Chromaggus",category="Raids",points=40,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Bronze"},
  raid_bwl_ebonroc={id="raid_bwl_ebonroc",name="Blackwing Lair: Ebonroc",desc="Defeat Ebonroc",category="Raids",points=25,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  raid_bwl_firemaw={id="raid_bwl_firemaw",name="Blackwing Lair: Firemaw",desc="Defeat Firemaw",category="Raids",points=25,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  raid_bwl_flamegor={id="raid_bwl_flamegor",name="Blackwing Lair: Flamegor",desc="Defeat Flamegor",category="Raids",points=25,icon="Interface\\Icons\\Spell_Fire_Fire"},
  raid_bwl_nefarian={id="raid_bwl_nefarian",name="Blackwing Lair: Nefarian",desc="Defeat Nefarian",category="Raids",points=125,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  raid_bwl_razorgore={id="raid_bwl_razorgore",name="Blackwing Lair: Razorgore",desc="Defeat Razorgore the Untamed",category="Raids",points=30,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  raid_bwl_vaelastrasz={id="raid_bwl_vaelastrasz",name="Blackwing Lair: Vaelastrasz",desc="Defeat Vaelastrasz the Corrupt",category="Raids",points=35,icon="Interface\\Icons\\Spell_Shadow_ShadowWordDominate"},

  -- Raids - Zul'Gurub
  raid_zg_hakkar={id="raid_zg_hakkar",name="Zul'Gurub: Hakkar",desc="Defeat Hakkar the Soulflayer",category="Raids",points=50,icon="Interface\\Icons\\Spell_Shadow_PainSpike"},
  raid_zg_thekal={id="raid_zg_thekal",name="Zul'Gurub: High Priest Thekal",desc="Defeat High Priest Thekal",category="Raids",points=20,icon="Interface\\Icons\\Ability_Druid_Mangle2"},
  raid_zg_venoxis={id="raid_zg_venoxis",name="Zul'Gurub: High Priest Venoxis",desc="Defeat High Priest Venoxis",category="Raids",points=15,icon="Interface\\Icons\\Spell_Nature_NullifyPoison"},
  raid_zg_arlokk={id="raid_zg_arlokk",name="Zul'Gurub: High Priestess Arlokk",desc="Defeat High Priestess Arlokk",category="Raids",points=20,icon="Interface\\Icons\\INV_Misc_MonsterScales_14"},
  raid_zg_jeklik={id="raid_zg_jeklik",name="Zul'Gurub: High Priestess Jeklik",desc="Defeat High Priestess Jeklik",category="Raids",points=15,icon="Interface\\Icons\\Spell_Shadow_UnholyFrenzy"},
  raid_zg_marli={id="raid_zg_marli",name="Zul'Gurub: High Priestess Mar'li",desc="Defeat High Priestess Mar'li",category="Raids",points=15,icon="Interface\\Icons\\Spell_Nature_Polymorph"},

  -- Raids - AQ20
  raid_aq20_ayamiss={id="raid_aq20_ayamiss",name="Ruins of Ahn'Qiraj: Ayamiss",desc="Defeat Ayamiss the Hunter",category="Raids",points=20,icon="Interface\\Icons\\INV_Spear_04"},
  raid_aq20_buru={id="raid_aq20_buru",name="Ruins of Ahn'Qiraj: Buru",desc="Defeat Buru the Gorger",category="Raids",points=20,icon="Interface\\Icons\\INV_Qiraj_JewelEngraved"},
  raid_aq20_rajaxx={id="raid_aq20_rajaxx",name="Ruins of Ahn'Qiraj: General Rajaxx",desc="Defeat General Rajaxx",category="Raids",points=20,icon="Interface\\Icons\\INV_Sword_43"},
  raid_aq20_kurinnaxx={id="raid_aq20_kurinnaxx",name="Ruins of Ahn'Qiraj: Kurinnaxx",desc="Defeat Kurinnaxx",category="Raids",points=15,icon="Interface\\Icons\\INV_Qiraj_JewelBlessed"},
  raid_aq20_moam={id="raid_aq20_moam",name="Ruins of Ahn'Qiraj: Moam",desc="Defeat Moam",category="Raids",points=15,icon="Interface\\Icons\\Spell_Shadow_UnholyStrength"},
  raid_aq20_ossirian={id="raid_aq20_ossirian",name="Ruins of Ahn'Qiraj: Ossirian",desc="Defeat Ossirian the Unscarred",category="Raids",points=40,icon="Interface\\Icons\\INV_Qiraj_JewelGlowing"},

  -- Raids - AQ40
  raid_aq40_sartura={id="raid_aq40_sartura",name="Temple of Ahn'Qiraj: Battleguard Sartura",desc="Defeat Battleguard Sartura",category="Raids",points=30,icon="Interface\\Icons\\INV_Weapon_ShortBlade_25"},
  raid_aq40_bug_trio={id="raid_aq40_bug_trio",name="Temple of Ahn'Qiraj: Bug Trio",desc="Defeat the Silithid Royalty",category="Raids",points=35,icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_02"},
  raid_aq40_cthun={id="raid_aq40_cthun",name="Temple of Ahn'Qiraj: C'Thun",desc="Defeat C'Thun",category="Raids",points=150,icon="Interface\\Icons\\Spell_Shadow_Charm"},
  raid_aq40_fankriss={id="raid_aq40_fankriss",name="Temple of Ahn'Qiraj: Fankriss",desc="Defeat Fankriss the Unyielding",category="Raids",points=30,icon="Interface\\Icons\\INV_Qiraj_Husk"},
  raid_aq40_ouro={id="raid_aq40_ouro",name="Temple of Ahn'Qiraj: Ouro",desc="Defeat Ouro",category="Raids",points=40,icon="Interface\\Icons\\INV_Qiraj_JewelGlowing"},
  raid_aq40_huhuran={id="raid_aq40_huhuran",name="Temple of Ahn'Qiraj: Princess Huhuran",desc="Defeat Princess Huhuran",category="Raids",points=35,icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_03"},
  raid_aq40_skeram={id="raid_aq40_skeram",name="Temple of Ahn'Qiraj: The Prophet Skeram",desc="Defeat The Prophet Skeram",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_MindSteal"},
  raid_aq40_twins={id="raid_aq40_twins",name="Temple of Ahn'Qiraj: Twin Emperors",desc="Defeat the Twin Emperors",category="Raids",points=50,icon="Interface\\Icons\\INV_Jewelry_Ring_AhnQiraj_04"},
  raid_aq40_viscidus={id="raid_aq40_viscidus",name="Temple of Ahn'Qiraj: Viscidus",desc="Defeat Viscidus",category="Raids",points=35,icon="Interface\\Icons\\Spell_Nature_Acid_01"},

  -- Raids - Naxxramas
  raid_naxx_anubrekhan={id="raid_naxx_anubrekhan",name="Naxxramas: Anub'Rekhan",desc="Defeat Anub'Rekhan",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_UnholyStrength"},
  raid_naxx_four_horsemen={id="raid_naxx_four_horsemen",name="Naxxramas: Four Horsemen",desc="Defeat The Four Horsemen",category="Raids",points=60,icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  raid_naxx_gluth={id="raid_naxx_gluth",name="Naxxramas: Gluth",desc="Defeat Gluth",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_AnimateDead"},
  raid_naxx_gothik={id="raid_naxx_gothik",name="Naxxramas: Gothik",desc="Defeat Gothik the Harvester",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_ShadowBolt"},
  raid_naxx_faerlina={id="raid_naxx_faerlina",name="Naxxramas: Grand Widow Faerlina",desc="Defeat Grand Widow Faerlina",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_Possession"},
  raid_naxx_grobbulus={id="raid_naxx_grobbulus",name="Naxxramas: Grobbulus",desc="Defeat Grobbulus",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_CallofBone"},
  raid_naxx_heigan={id="raid_naxx_heigan",name="Naxxramas: Heigan",desc="Defeat Heigan the Unclean",category="Raids",points=35,icon="Interface\\Icons\\Spell_Shadow_DeathScream"},
  raid_naxx_razuvious={id="raid_naxx_razuvious",name="Naxxramas: Instructor Razuvious",desc="Defeat Instructor Razuvious",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain"},
  raid_naxx_kelthuzad={id="raid_naxx_kelthuzad",name="Naxxramas: Kel'Thuzad",desc="Defeat Kel'Thuzad",category="Raids",points=200,icon="Interface\\Icons\\Spell_Shadow_SoulGem"},
  raid_naxx_loatheb={id="raid_naxx_loatheb",name="Naxxramas: Loatheb",desc="Defeat Loatheb",category="Raids",points=50,icon="Interface\\Icons\\Spell_Shadow_CallofBone"},
  raid_naxx_maexxna={id="raid_naxx_maexxna",name="Naxxramas: Maexxna",desc="Defeat Maexxna",category="Raids",points=35,icon="Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01"},
  raid_naxx_noth={id="raid_naxx_noth",name="Naxxramas: Noth",desc="Defeat Noth the Plaguebringer",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_UnholyStrength"},
  raid_naxx_patchwerk={id="raid_naxx_patchwerk",name="Naxxramas: Patchwerk",desc="Defeat Patchwerk",category="Raids",points=30,icon="Interface\\Icons\\INV_Weapon_ShortBlade_25"},
  raid_naxx_sapphiron={id="raid_naxx_sapphiron",name="Naxxramas: Sapphiron",desc="Defeat Sapphiron",category="Raids",points=75,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Blue"},
  raid_naxx_thaddius={id="raid_naxx_thaddius",name="Naxxramas: Thaddius",desc="Defeat Thaddius",category="Raids",points=40,icon="Interface\\Icons\\Spell_Shadow_UnholyFrenzy"},

  -- Raids - Molten Core (Turtle WoW additions)
  raid_mc_twins={id="raid_mc_twins",name="Molten Core: Basalthar & Smoldaris",desc="Defeat Basalthar and Smoldaris",category="Raids",points=25,icon="Interface\\Icons\\INV_Misc_MonsterScales_15"},
  raid_mc_incindis={id="raid_mc_incindis",name="Molten Core: Incindis",desc="Defeat Incindis",category="Raids",points=20,icon="Interface\\Icons\\Spell_Fire_Incinerate"},
  raid_mc_sorcerer={id="raid_mc_sorcerer",name="Molten Core: Sorcerer-Thane Thaurissan",desc="Defeat Sorcerer-Thane Thaurissan",category="Raids",points=25,icon="Interface\\Icons\\Spell_Fire_FireArmor"},

  -- Raids - Zul'Gurub (additional bosses)
  raid_zg_mandokir={id="raid_zg_mandokir",name="Zul'Gurub: Bloodlord Mandokir",desc="Defeat Bloodlord Mandokir",category="Raids",points=20,icon="Interface\\Icons\\Ability_Druid_Mangle2"},
  raid_zg_gahzranka={id="raid_zg_gahzranka",name="Zul'Gurub: Gahz'ranka",desc="Defeat Gahz'ranka",category="Raids",points=15,icon="Interface\\Icons\\INV_Misc_Fish_02"},
  raid_zg_grilek={id="raid_zg_grilek",name="Zul'Gurub: Gri'lek",desc="Defeat Gri'lek",category="Raids",points=15,icon="Interface\\Icons\\INV_Misc_MonsterScales_14"},
  raid_zg_hazzarah={id="raid_zg_hazzarah",name="Zul'Gurub: Hazza'rah",desc="Defeat Hazza'rah",category="Raids",points=15,icon="Interface\\Icons\\Spell_Nature_Polymorph"},
  raid_zg_jindo={id="raid_zg_jindo",name="Zul'Gurub: Jin'do the Hexxer",desc="Defeat Jin'do the Hexxer",category="Raids",points=20,icon="Interface\\Icons\\Spell_Shadow_UnholyFrenzy"},
  raid_zg_renataki={id="raid_zg_renataki",name="Zul'Gurub: Renataki",desc="Defeat Renataki",category="Raids",points=15,icon="Interface\\Icons\\Spell_Nature_NullifyPoison"},
  raid_zg_wushoolay={id="raid_zg_wushoolay",name="Zul'Gurub: Wushoolay",desc="Defeat Wushoolay",category="Raids",points=15,icon="Interface\\Icons\\Spell_Nature_Lightning"},

  -- Raids - Emerald Sanctum (Turtle WoW)
  raid_es_erennius={id="raid_es_erennius",name="Emerald Sanctum: Erennius",desc="Defeat Erennius",category="Raids",points=75,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Green"},
  raid_es_solnius={id="raid_es_solnius",name="Emerald Sanctum: Solnius the Awakener",desc="Defeat Solnius the Awakener",category="Raids",points=50,icon="Interface\\Icons\\Spell_Nature_Regeneration"},

  -- Raids - Lower Karazhan Halls (Turtle WoW)
  raid_lkh_araxxna={id="raid_lkh_araxxna",name="Lower Karazhan Halls: Brood Queen Araxxna",desc="Defeat Brood Queen Araxxna",category="Raids",points=35,icon="Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01"},
  raid_lkh_howlfang={id="raid_lkh_howlfang",name="Lower Karazhan Halls: Clawlord Howlfang",desc="Defeat Clawlord Howlfang",category="Raids",points=30,icon="Interface\\Icons\\Ability_Druid_Mangle2"},
  raid_lkh_grizikil={id="raid_lkh_grizikil",name="Lower Karazhan Halls: Grizikil",desc="Defeat Grizikil",category="Raids",points=30,icon="Interface\\Icons\\Spell_Nature_LightningShield"},
  raid_lkh_blackwald={id="raid_lkh_blackwald",name="Lower Karazhan Halls: Lord Blackwald II",desc="Defeat Lord Blackwald II",category="Raids",points=35,icon="Interface\\Icons\\Spell_Shadow_Possession"},
  raid_lkh_rolfen={id="raid_lkh_rolfen",name="Lower Karazhan Halls: Master Blacksmith Rolfen",desc="Defeat Master Blacksmith Rolfen",category="Raids",points=30,icon="Interface\\Icons\\Trade_BlackSmithing"},
  raid_lkh_moroes={id="raid_lkh_moroes",name="Lower Karazhan Halls: Moroes",desc="Defeat Moroes",category="Raids",points=50,icon="Interface\\Icons\\INV_Misc_Coin_05"},

  -- Raids - Upper Karazhan Halls (Turtle WoW)
  raid_ukh_anomalus={id="raid_ukh_anomalus",name="Upper Karazhan Halls: Anomalus",desc="Defeat Anomalus",category="Raids",points=30,icon="Interface\\Icons\\Spell_Shadow_UnholyStrength"},
  raid_ukh_echo={id="raid_ukh_echo",name="Upper Karazhan Halls: Echo of Medivh",desc="Defeat the Echo of Medivh",category="Raids",points=35,icon="Interface\\Icons\\INV_Misc_Book_09"},
  raid_ukh_gnarlmoon={id="raid_ukh_gnarlmoon",name="Upper Karazhan Halls: Keeper Gnarlmoon",desc="Defeat Keeper Gnarlmoon",category="Raids",points=30,icon="Interface\\Icons\\Spell_Nature_Regeneration"},
  raid_ukh_king={id="raid_ukh_king",name="Upper Karazhan Halls: King",desc="Win the Chess Battle",category="Raids",points=25,icon="Interface\\Icons\\INV_Crown_01"},
  raid_ukh_kruul={id="raid_ukh_kruul",name="Upper Karazhan Halls: Kruul",desc="Defeat Kruul",category="Raids",points=50,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  raid_ukh_incantagos={id="raid_ukh_incantagos",name="Upper Karazhan Halls: Ley-Watcher Incantagos",desc="Defeat Ley-Watcher Incantagos",category="Raids",points=30,icon="Interface\\Icons\\Spell_Nature_Lightning"},
  raid_ukh_mephistroth={id="raid_ukh_mephistroth",name="Upper Karazhan Halls: Mephistroth",desc="Defeat Mephistroth",category="Raids",points=125,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  raid_ukh_rupturan={id="raid_ukh_rupturan",name="Upper Karazhan Halls: Rupturan the Broken",desc="Defeat Rupturan the Broken",category="Raids",points=40,icon="Interface\\Icons\\Ability_Warrior_SavageBlow"},
  raid_ukh_sanvtas={id="raid_ukh_sanvtas",name="Upper Karazhan Halls: Sanv Tas'dal",desc="Defeat Sanv Tas'dal",category="Raids",points=35,icon="Interface\\Icons\\Spell_Shadow_Possession"},

  -- Raid Completions (criteria-based â€” all bosses with checkmarks)
  raid_bwl_complete={id="raid_bwl_complete",name="Blackwing Lair: Raid Clear",desc="Defeat all bosses in Blackwing Lair",category="Raids",points=175,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",criteria_key="bwl",criteria_type="raid"},
  raid_es_complete={id="raid_es_complete",name="Emerald Sanctum: Raid Clear",desc="Defeat all bosses in the Emerald Sanctum",category="Raids",points=175,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Green",criteria_key="es",criteria_type="raid"},
  raid_lkh_complete={id="raid_lkh_complete",name="Lower Karazhan Halls: Raid Clear",desc="Defeat all bosses in Lower Karazhan Halls",category="Raids",points=175,icon="Interface\\Icons\\INV_Misc_Key_14",criteria_key="lkh",criteria_type="raid"},
  raid_mc_complete={id="raid_mc_complete",name="Molten Core: Raid Clear",desc="Defeat all bosses in Molten Core",category="Raids",points=150,icon="Interface\\Icons\\Spell_Fire_Incinerate",criteria_key="mc",criteria_type="raid"},
  raid_naxx_complete={id="raid_naxx_complete",name="Naxxramas: Raid Clear",desc="Defeat all bosses in Naxxramas",category="Raids",points=250,icon="Interface\\Icons\\INV_Misc_Key_15",criteria_key="naxx",criteria_type="raid"},
  raid_onyxia_complete={id="raid_onyxia_complete",name="Onyxia's Lair: Raid Clear",desc="Defeat Onyxia",category="Raids",points=75,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01",criteria_key="onyxia",criteria_type="raid"},
  raid_aq20_complete={id="raid_aq20_complete",name="Ruins of Ahn'Qiraj: Raid Clear",desc="Defeat all bosses in Ruins of Ahn'Qiraj",category="Raids",points=100,icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_04",criteria_key="aq20",criteria_type="raid"},
  raid_aq40_complete={id="raid_aq40_complete",name="Temple of Ahn'Qiraj: Raid Clear",desc="Defeat all bosses in Temple of Ahn'Qiraj",category="Raids",points=200,icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",criteria_key="aq40",criteria_type="raid"},
  raid_ukh_complete={id="raid_ukh_complete",name="Upper Karazhan Halls: Raid Clear",desc="Defeat all bosses in Upper Karazhan Halls",category="Raids",points=200,icon="Interface\\Icons\\INV_Misc_Key_15",criteria_key="ukh",criteria_type="raid"},
  raid_zg_complete={id="raid_zg_complete",name="Zul'Gurub: Raid Clear",desc="Defeat all bosses in Zul'Gurub",category="Raids",points=100,icon="Interface\\Icons\\Ability_Mount_JungleTiger",criteria_key="zg",criteria_type="raid"},

  -- Exploration
  explore_eastern_kingdoms={id="explore_eastern_kingdoms",name="Explore Eastern Kingdoms",desc="Discover all zones in Eastern Kingdoms",category="Exploration",points=50,icon="Interface\\Icons\\INV_BannerPVP_02",criteria_key="eastern_kingdoms",criteria_type="zone_group"},
  explore_kalimdor={id="explore_kalimdor",name="Explore Kalimdor",desc="Discover all zones in Kalimdor",category="Exploration",points=50,icon="Interface\\Icons\\Spell_Nature_ProtectionformNature",criteria_key="kalimdor",criteria_type="zone_group"},
  -- Meta: requires completing specific exploration achievements
  explore_wanderer={id="explore_wanderer",name="Wanderer",desc="Complete Explore Kalimdor and Explore Eastern Kingdoms.",category="Exploration",points=100,icon="Interface\\Icons\\INV_Boots_05",criteria_type="ach_meta",criteria_ids={"explore_kalimdor","explore_eastern_kingdoms"}},
  explore_world_explorer={id="explore_world_explorer",name="World Explorer",desc="Complete all major exploration achievements across Azeroth.",category="Exploration",points=250,icon="Interface\\Icons\\INV_Misc_Spyglass_03",criteria_type="ach_meta",criteria_ids={"explore_kalimdor","explore_eastern_kingdoms","casual_explore_elwynn","casual_explore_barrens","explore_tw_balor","explore_tw_gilneas","explore_tw_northwind","explore_tw_lapidis","explore_tw_gillijim","explore_tw_scarlet_enclave","explore_tw_grim_reaches","explore_tw_telabim","explore_tw_hyjal","explore_tw_tirisfal_uplands"}},

  -- Turtle WoW: Unique zone-group exploration achievements
  explore_tw_balor={id="explore_tw_balor",name="Explorer of Balor",desc="Discover all 6 locations in Balor.",category="Exploration",points=25,icon="Interface\\Icons\\INV_Misc_Platnumdisks",criteria_key="balor",criteria_type="zone_group"},
  explore_tw_gillijim={id="explore_tw_gillijim",name="Explorer of Gillijim's Isle",desc="Discover all 16 locations on Gillijim's Isle.",category="Exploration",points=60,icon="Interface\\Icons\\INV_Misc_Gem_Pearl_01",criteria_key="gillijim",criteria_type="zone_group"},
  explore_tw_gilneas={id="explore_tw_gilneas",name="Explorer of Gilneas",desc="Discover all 26 locations in Gilneas.",category="Exploration",points=75,icon="Interface\\Icons\\INV_Shield_06",criteria_key="gilneas",criteria_type="zone_group"},
  explore_tw_hyjal={id="explore_tw_hyjal",name="Explorer of Hyjal",desc="Discover all 10 locations in Hyjal.",category="Exploration",points=40,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Green",criteria_key="hyjal",criteria_type="zone_group"},
  explore_tw_lapidis={id="explore_tw_lapidis",name="Explorer of Lapidis Isle",desc="Discover all 10 locations on Lapidis Isle.",category="Exploration",points=40,icon="Interface\\Icons\\INV_Misc_Gem_Sapphire_02",criteria_key="lapidis",criteria_type="zone_group"},
  explore_tw_northwind={id="explore_tw_northwind",name="Explorer of Northwind",desc="Discover all 7 locations in Northwind.",category="Exploration",points=30,icon="Interface\\Icons\\Spell_Frost_FrostShock",criteria_key="northwind",criteria_type="zone_group"},
  explore_tw_telabim={id="explore_tw_telabim",name="Explorer of Tel'Abim",desc="Discover all 8 locations on Tel'Abim.",category="Exploration",points=35,icon="Interface\\Icons\\INV_Misc_Herb_BlackLotus",criteria_key="telabim",criteria_type="zone_group"},
  explore_tw_grim_reaches={id="explore_tw_grim_reaches",name="Explorer of the Grim Reaches",desc="Discover all 5 locations in the Grim Reaches.",category="Exploration",points=25,icon="Interface\\Icons\\Spell_Shadow_RaiseDead",criteria_key="grim_reaches",criteria_type="zone_group"},
  explore_tw_scarlet_enclave={id="explore_tw_scarlet_enclave",name="Explorer of the Scarlet Enclave",desc="Discover all 6 locations in the Scarlet Enclave.",category="Exploration",points=25,icon="Interface\\Icons\\Spell_Holy_WordFortitude",criteria_key="scarlet_enclave",criteria_type="zone_group"},
  explore_tw_tirisfal_uplands={id="explore_tw_tirisfal_uplands",name="Explorer of Tirisfal Uplands",desc="Discover all 14 locations in the Tirisfal Uplands.",category="Exploration",points=50,icon="Interface\\Icons\\Spell_Shadow_RagingScream",criteria_key="tirisfal_uplands",criteria_type="zone_group"},
  -- Turtle WoW: vanilla zone additions
  explore_tw_arathi={id="explore_tw_arathi",name="Arathi Pathfinder",desc="Discover 5 new Turtle WoW locations in the Arathi Highlands.",category="Exploration",points=25,icon="Interface\\Icons\\INV_Misc_Map_02",criteria_key="arathi_tw",criteria_type="zone_group"},
  explore_tw_ashenvale={id="explore_tw_ashenvale",name="Ashenvale Pathfinder",desc="Discover 5 new Turtle WoW locations in Ashenvale.",category="Exploration",points=25,icon="Interface\\Icons\\INV_Misc_Map_01",criteria_key="ashenvale_tw",criteria_type="zone_group"},
  explore_tw_badlands={id="explore_tw_badlands",name="Badlands Pathfinder",desc="Discover 7 new Turtle WoW locations in the Badlands.",category="Exploration",points=30,icon="Interface\\Icons\\INV_Misc_Map_01",criteria_key="badlands_tw",criteria_type="zone_group"},
  explore_tw_stonetalon={id="explore_tw_stonetalon",name="Stonetalon Pathfinder",desc="Discover 7 new Turtle WoW locations in Stonetalon Mountains.",category="Exploration",points=30,icon="Interface\\Icons\\INV_Misc_Map_01",criteria_key="stonetalon_tw",criteria_type="zone_group"},
  -- Exploration - Casual
  casual_explore_barrens={id="casual_explore_barrens",name="Barrens Explorer",desc="Discover all areas of The Barrens",category="Exploration",points=10,icon="Interface\\Icons\\INV_Misc_Food_Wheat_01",criteria_key="barrens",criteria_type="zone_group"},
  casual_explore_elwynn={id="casual_explore_elwynn",name="Elwynn Explorer",desc="Discover all areas of Elwynn Forest",category="Exploration",points=10,icon="Interface\\Icons\\INV_Misc_Flower_01",criteria_key="elwynn",criteria_type="zone_group"},

  -- PvP
  pvp_hk_2500={id="pvp_hk_2500",name="Battle-Hardened",desc="Earn 2500 honorable kills",category="PvP",points=75,icon="Interface\\Icons\\INV_Sword_48"},
  pvp_duel_25={id="pvp_duel_25",name="Dueling Champion",desc="Win 25 duels",category="PvP",points=35,icon="Interface\\Icons\\INV_Sword_39"},
  pvp_duel_10={id="pvp_duel_10",name="Duelist",desc="Win 10 duels",category="PvP",points=10,icon="Interface\\Icons\\Ability_Dualwield"},
  pvp_hk_1000={id="pvp_hk_1000",name="Gladiator",desc="Earn 1000 honorable kills",category="PvP",points=50,icon="Interface\\Icons\\INV_Sword_48"},
  pvp_duel_100={id="pvp_duel_100",name="Grand Duelist",desc="Win 100 duels",category="PvP",points=50,icon="Interface\\Icons\\INV_Sword_62"},
  pvp_hk_10000={id="pvp_hk_10000",name="High Warlord",desc="Earn 10000 honorable kills",category="PvP",points=200,icon="Interface\\Icons\\INV_Sword_39"},
  pvp_duel_50={id="pvp_duel_50",name="Master Duelist",desc="Win 50 duels",category="PvP",points=25,icon="Interface\\Icons\\INV_Sword_39"},
  pvp_hk_50={id="pvp_hk_50",name="Skirmisher",desc="Earn 50 honorable kills",category="PvP",points=10,icon="Interface\\Icons\\INV_Sword_27"},
  pvp_hk_100={id="pvp_hk_100",name="Soldier",desc="Earn 100 honorable kills",category="PvP",points=10,icon="Interface\\Icons\\INV_Sword_27"},
  pvp_hk_5000={id="pvp_hk_5000",name="Warlord",desc="Earn 5000 honorable kills",category="PvP",points=100,icon="Interface\\Icons\\INV_Sword_62"},
  pvp_bg_win_1={id="pvp_bg_win_1",name="First Victory",desc="Win your first battleground",category="PvP",points=5,icon="Interface\\Icons\\INV_BannerPVP_02"},
  pvp_bg_win_10={id="pvp_bg_win_10",name="Battleground Veteran",desc="Win 10 battlegrounds",category="PvP",points=20,icon="Interface\\Icons\\INV_BannerPVP_02"},
  pvp_bg_win_50={id="pvp_bg_win_50",name="Battleground Champion",desc="Win 50 battlegrounds",category="PvP",points=50,icon="Interface\\Icons\\INV_BannerPVP_02"},
  pvp_wsg_win_10={id="pvp_wsg_win_10",name="Warsong Victor",desc="Win 10 Warsong Gulch matches",category="PvP",points=25,icon="Interface\\Icons\\INV_Misc_Rune_07"},
  pvp_ab_win_10={id="pvp_ab_win_10",name="Arathi Victor",desc="Win 10 Arathi Basin matches",category="PvP",points=25,icon="Interface\\Icons\\INV_BannerPVP_01"},
  pvp_av_win_10={id="pvp_av_win_10",name="Alterac Victor",desc="Win 10 Alterac Valley matches",category="PvP",points=25,icon="Interface\\Icons\\INV_BannerPVP_03"},

  -- Reputation
  reputation_exalted_1={id="reputation_exalted_1",name="Well Respected",desc="Reach Exalted with 1 faction",category="Reputation",points=15,icon="Interface\\Icons\\INV_Misc_Note_06"},
  reputation_exalted_5={id="reputation_exalted_5",name="Diplomat",desc="Reach Exalted with 5 factions",category="Reputation",points=50,icon="Interface\\Icons\\INV_Misc_Note_06"},
  reputation_exalted_10={id="reputation_exalted_10",name="Ambassador",desc="Reach Exalted with 10 factions",category="Reputation",points=100,icon="Interface\\Icons\\INV_Misc_Note_06"},

  -- Elite Achievements
  elite_cthun_5x={id="elite_cthun_5x",name="Ahn'Qiraj Conqueror",desc="Defeat C'Thun 5 times",category="Elite",points=400,icon="Interface\\Icons\\Spell_Shadow_Charm"},
  elite_baron_5x={id="elite_baron_5x",name="Baron's Nemesis",desc="Defeat Baron Rivendare 5 times",category="Elite",points=200,icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  elite_drakkisath_5x={id="elite_drakkisath_5x",name="Blackrock Champion",desc="Defeat General Drakkisath 5 times",category="Elite",points=200,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  elite_nef_10x={id="elite_nef_10x",name="Blackwing Conqueror",desc="Defeat Nefarian 10 times",category="Elite",points=300,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  elite_nef_5x={id="elite_nef_5x",name="Blackwing Veteran",desc="Defeat Nefarian 5 times",category="Elite",points=200,icon="Interface\\Icons\\Spell_Fire_Incinerate"},
  elite_25_unique_bosses={id="elite_25_unique_bosses",name="Boss Explorer",desc="Kill 25 unique bosses",category="Elite",points=200,icon="Interface\\Icons\\Ability_Warrior_DefensiveStance"},
  elite_50_unique_bosses={id="elite_50_unique_bosses",name="Boss Hunter",desc="Kill 50 unique bosses",category="Elite",points=300,icon="Interface\\Icons\\Spell_Holy_FlashHeal"},
  elite_100_bosses={id="elite_100_bosses",name="Centurion Slayer",desc="Kill 100 total bosses",category="Elite",points=150,icon="Interface\\Icons\\INV_Misc_Trophy_Gold"},
  elite_500_bosses={id="elite_500_bosses",name="Champion Slayer",desc="Kill 500 total bosses",category="Elite",points=300,icon="Interface\\Icons\\INV_Misc_Trophy_Gold"},
  elite_onyxia_10x={id="elite_onyxia_10x",name="Dragon Slayer Supreme",desc="Defeat Onyxia 10 times",category="Elite",points=300,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  elite_onyxia_5x={id="elite_onyxia_5x",name="Dragonbane",desc="Defeat Onyxia 5 times",category="Elite",points=200,icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  elite_all_dungeons_complete={id="elite_all_dungeons_complete",name="Dungeon Completionist",desc="Complete every Classic 5-man dungeon at least once",category="Elite",points=400,icon="Interface\\Icons\\INV_Chest_Cloth_17",criteria_type="dungeon_meta"},
  elite_50_dungeons={id="elite_50_dungeons",name="Dungeon Crawler",desc="Complete 50 dungeon runs",category="Elite",points=150,icon="Interface\\Icons\\INV_Misc_Key_14"},
  elite_100_dungeons={id="elite_100_dungeons",name="Dungeon Veteran",desc="Complete 100 dungeon runs",category="Elite",points=250,icon="Interface\\Icons\\INV_Misc_Key_15"},
  elite_250_dungeons={id="elite_250_dungeons",name="Dungeon Master",desc="Complete 250 dungeon runs",category="Elite",points=350,icon="Interface\\Icons\\INV_Misc_Key_15"},
  elite_500_dungeons={id="elite_500_dungeons",name="Dungeon Grandmaster",desc="Complete 500 dungeon runs",category="Elite",points=500,icon="Interface\\Icons\\INV_Misc_Key_15"},
  elite_250_bosses={id="elite_250_bosses",name="Elite Slayer",desc="Kill 250 total bosses",category="Elite",points=200,icon="Interface\\Icons\\INV_Misc_Trophy_Gold"},
  elite_rag_10x={id="elite_rag_10x",name="Flame Conqueror",desc="Defeat Ragnaros 10 times",category="Elite",points=250,icon="Interface\\Icons\\Spell_Fire_LavaSpawn"},
  elite_kt_5x={id="elite_kt_5x",name="Frost Conqueror",desc="Defeat Kel'Thuzad 5 times",category="Elite",points=500,icon="Interface\\Icons\\Spell_Shadow_SoulGem"},
  elite_pvp_rank_14={id="elite_pvp_rank_14",name="Grand Marshal",desc="Achieve PvP Rank 14",category="Elite",points=1000,icon="Interface\\Icons\\INV_Sword_39"},

  elite_rag_5x={id="elite_rag_5x",name="Molten Core Veteran",desc="Defeat Ragnaros 5 times",category="Elite",points=150,icon="Interface\\Icons\\Spell_Fire_Incinerate"},
  elite_gandling_5x={id="elite_gandling_5x",name="Necromancer's Bane",desc="Defeat Darkmaster Gandling 5 times",category="Elite",points=200,icon="Interface\\Icons\\Spell_Shadow_Charm"},
  elite_all_raids_complete={id="elite_all_raids_complete",name="Raid Completionist",desc="Complete every Classic raid at least once",category="Elite",points=500,icon="Interface\\Icons\\Spell_Holy_Resurrection",criteria_type="raid_meta"},
  elite_25_raids={id="elite_25_raids",name="Raid Initiate",desc="Complete 25 raid runs",category="Elite",points=200,icon="Interface\\Icons\\INV_Misc_Ribbon_01"},
  elite_50_raids={id="elite_50_raids",name="Raid Regular",desc="Complete 50 raid runs",category="Elite",points=300,icon="Interface\\Icons\\INV_Misc_Ribbon_01"},
  elite_100_raids={id="elite_100_raids",name="Raid Veteran",desc="Complete 100 raid runs",category="Elite",points=450,icon="Interface\\Icons\\INV_Misc_Ribbon_01"},
  elite_250_raids={id="elite_250_raids",name="Raid Legend",desc="Complete 250 raid runs",category="Elite",points=650,icon="Interface\\Icons\\INV_Misc_Ribbon_01"},
  elite_kt_3x={id="elite_kt_3x",name="Scourge Slayer",desc="Defeat Kel'Thuzad 3 times",category="Elite",points=300,icon="Interface\\Icons\\Spell_Fire_Incinerate"},
  elite_hakkar_5x={id="elite_hakkar_5x",name="Soulflayer's End",desc="Defeat Hakkar 5 times",category="Elite",points=200,icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain"},

  -- Casual Achievements
  casual_fish_100={id="casual_fish_100",name="Angler",desc="Catch 100 fish",category="Casual",points=10,icon="Interface\\Icons\\Trade_Fishing"},
  casual_emote_100={id="casual_emote_100",name="Chatterbox",desc="Use 100 emotes on other players",category="Casual",points=10,icon="Interface\\Icons\\INV_Letter_15"},
  casual_deaths_50={id="casual_deaths_50",name="Danger Seeker",desc="Die 50 times",category="Casual",points=10,icon="Interface\\Icons\\Ability_Rogue_FeintedStrike"},
  casual_deaths_100={id="casual_deaths_100",name="Death's Door",desc="Die 100 times",category="Casual",points=5,icon="Interface\\Icons\\Spell_Shadow_DeathScream"},
  casual_emote_25={id="casual_emote_25",name="Emotive",desc="Use 25 emotes on other players",category="Casual",points=5,icon="Interface\\Icons\\INV_Misc_Toy_07"},
  casual_epic_mount={id="casual_epic_mount",name="Epic Mount",desc="Obtain an epic mount",category="Casual",points=25,icon="Interface\\Icons\\Ability_Mount_JungleTiger"},
  casual_fall_death={id="casual_fall_death",name="Falling Star",desc="Die from falling 10 times",category="Casual",points=5,icon="Interface\\Icons\\Ability_Rogue_FeintedStrike"},
  casual_mount_60={id="casual_mount_60",name="First Mount",desc="Obtain your first mount",category="Casual",points=10,icon="Interface\\Icons\\Ability_Mount_Raptor"},
  casual_hearthstone_use={id="casual_hearthstone_use",name="Frequent Traveler",desc="Use your hearthstone 50 times",category="Casual",points=10,icon="Interface\\Icons\\INV_Misc_Rune_01"},
  casual_guild_join={id="casual_guild_join",name="Guild Member",desc="Join a guild",category="Casual",points=5,icon="Interface\\Icons\\INV_Shirt_GuildTabard_01"},
  casual_hearthstone_1={id="casual_hearthstone_1",name="Home Is Where the Hearth Is",desc="Use your hearthstone for the first time",category="Casual",points=5,icon="Interface\\Icons\\INV_Misc_Rune_01"},
  casual_drown={id="casual_drown",name="Landlubber",desc="Drown 10 times",category="Casual",points=5,icon="Interface\\Icons\\Spell_Frost_FrostShock"},
  casual_quest_1000={id="casual_quest_1000",name="Loremaster",desc="Complete 1000 quests",category="Casual",points=50,icon="Interface\\Icons\\INV_Misc_Book_09"},
  quest_25={id="quest_25",name="Fresh Boots",desc="Complete 25 quests",category="Quests",points=5,icon="Interface\\Icons\\INV_Boots_05"},
  quest_250={id="quest_250",name="Road-Worn",desc="Complete 250 quests",category="Quests",points=20,icon="Interface\\Icons\\INV_Misc_Map_01"},
  casual_fish_1000={id="casual_fish_1000",name="Master Angler",desc="Catch 1000 fish",category="Casual",points=25,icon="Interface\\Icons\\Trade_Fishing"},
  casual_bank_full={id="casual_bank_full",name="Pack Rat",desc="Fill your bank completely",category="Casual",points=10,icon="Interface\\Icons\\INV_Misc_Bag_22"},
  casual_pet_collector={id="casual_pet_collector",name="Pet Collector",desc="Collect 10 vanity pets",category="Casual",points=15,icon="Interface\\Icons\\INV_Misc_Toy_07"},
  casual_pet_fanatic={id="casual_pet_fanatic",name="Pet Fanatic",desc="Collect 25 vanity pets",category="Casual",points=30,icon="Interface\\Icons\\INV_Misc_Toy_07"},
  casual_quest_500={id="casual_quest_500",name="Quest Master",desc="Complete 500 quests",category="Casual",points=25,icon="Interface\\Icons\\INV_Misc_Note_06"},
  quest_750={id="quest_750",name="Long Road Home",desc="Complete 750 quests",category="Quests",points=35,icon="Interface\\Icons\\INV_Misc_Book_11"},
  casual_quest_100={id="casual_quest_100",name="Quest Starter",desc="Complete 100 quests",category="Casual",points=10,icon="Interface\\Icons\\INV_Misc_Note_06"},
  quest_1500={id="quest_1500",name="Worn Traveler",desc="Complete 1500 quests",category="Quests",points=60,icon="Interface\\Icons\\INV_Misc_Book_09"},
  quest_2000={id="quest_2000",name="Azerothian Odyssey",desc="Complete 2000 quests",category="Quests",points=90,icon="Interface\\Icons\\INV_Misc_Map_02"},
  casual_hearthstone_100={id="casual_hearthstone_100",name="Seasoned Traveler",desc="Use your hearthstone 100 times",category="Casual",points=20,icon="Interface\\Icons\\INV_Misc_Rune_01"},
  casual_party_join={id="casual_party_join",name="Team Player",desc="Join 50 groups",category="Casual",points=10,icon="Interface\\Icons\\INV_Misc_GroupNeedMore"},
  casual_fish_25={id="casual_fish_25",name="Weekend Angler",desc="Catch 25 fish",category="Casual",points=5,icon="Interface\\Icons\\Trade_Fishing"},
  -- Leveling extras (from KAM)
  -- Resurrection tracking
  casual_resurrect_50={id="casual_resurrect_50",name="Phoenix",desc="Get resurrected 50 times",category="Casual",points=25,icon="Interface\\Icons\\Spell_Holy_Resurrection"},
  casual_resurrect_10={id="casual_resurrect_10",name="Second Wind",desc="Get resurrected 10 times",category="Casual",points=10,icon="Interface\\Icons\\Spell_Holy_Resurrection"},
  -- Flight path tracking
  casual_flight_10={id="casual_flight_10",name="Frequent Flyer",desc="Take 10 flight paths",category="Casual",points=10,icon="Interface\\Icons\\Ability_Mount_Gryphon_01"},
  casual_flight_50={id="casual_flight_50",name="Sky Captain",desc="Take 50 flight paths",category="Casual",points=25,icon="Interface\\Icons\\Ability_Mount_Gryphon_01"},
  -- Bandage use tracking
  casual_bandage_100={id="casual_bandage_100",name="Combat Medic",desc="Use 100 bandages",category="Casual",points=20,icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice"},
  casual_bandage_25={id="casual_bandage_25",name="Field Medic",desc="Use 25 bandages",category="Casual",points=10,icon="Interface\\Icons\\Spell_Holy_SealOfSacrifice"},
  -- Loot tracking
  casual_loot_5000={id="casual_loot_5000",name="Hoarder",desc="Loot 5000 items",category="Casual",points=30,icon="Interface\\Icons\\INV_Misc_Bag_22"},
  casual_loot_100={id="casual_loot_100",name="Looter",desc="Loot 100 items",category="Casual",points=5,icon="Interface\\Icons\\INV_Misc_Bag_07"},
  casual_loot_1000={id="casual_loot_1000",name="Treasure Hunter",desc="Loot 1000 items",category="Casual",points=15,icon="Interface\\Icons\\INV_Misc_Bag_22"},
  -- Trade tracking
  casual_trade_10={id="casual_trade_10",name="Trader",desc="Complete 10 trades with other players",category="Casual",points=10,icon="Interface\\Icons\\INV_Misc_Coin_01"},

  -- Legendary Achievements (officer-approved, require streaming or recording)
  legendary_naked_dungeon={id="legendary_naked_dungeon",name="Bare Bones",desc="Clear any level-60 dungeon with your group wearing no armor at all. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",manual=true},
  legendary_full_clear_week={id="legendary_full_clear_week",name="Conqueror of All",desc="Clear MC, BWL, ZG, AQ20, AQ40, and Naxxramas all within a single calendar week. Must be verified by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\Spell_Shadow_SoulGem",manual=true},
  legendary_speed_run_brd={id="legendary_speed_run_brd",name="Speed Demon",desc="Complete a full clear of Blackrock Depths in under 30 minutes. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\Spell_Fire_LavaSpawn",manual=true},
  legendary_flawless_naxx={id="legendary_flawless_naxx",name="The Immortal",desc="Complete all of Naxxramas without any raid member dying the entire run. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\Spell_Shadow_RaiseDead",manual=true},
  legendary_solo_raid_boss={id="legendary_solo_raid_boss",name="The Unsupported",desc="Defeat any raid boss completely alone. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength",manual=true},
  legendary_duel_streak_100={id="legendary_duel_streak_100",name="Undefeated",desc="Win 100 consecutive duels without a single loss. Must be witnessed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Sword_62",manual=true},
  legendary_ironman_60={id="legendary_ironman_60",name="Untouched by Death",desc="Reach level 60 without dying a single time. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Helmet_74",manual=true},
  legendary_onyxia_10={id="legendary_onyxia_10",name="Onyxia 10-Man",desc="Defeat Onyxia with a raid of exactly 10 players. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",manual=true},
  legendary_onyxia_5={id="legendary_onyxia_5",name="Onyxia 5-Man",desc="Defeat Onyxia with a group of exactly 5 players. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",manual=true},
  legendary_solo_60_boss={id="legendary_solo_60_boss",name="Solo Dungeon Boss",desc="Defeat any level 60 dungeon boss completely alone. Must be streamed or recorded and approved by an officer.",category="Legendary",points=1000,icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength",manual=true},
  legendary_no_consumes_t2plus={id="legendary_no_consumes_t2plus",name="No Consumables Raid",desc="Complete a full Tier 2 or higher raid without any raid member using a single consumable. Must be streamed or recorded and approved by two officers.",category="Legendary",points=1000,icon="Interface\\Icons\\INV_Potion_01",manual=true},
  item_ironfoe_weilder={id="item_ironfoe_weilder",name="Ironfoe Weilder",desc="Take up Ironfoe, the hammer of impossible fortune, and let the halls of Blackrock ring with every crushing blow.",category="Elite",points=125,icon="Interface\\Icons\\INV_Hammer_11"},
  item_sulfuras_weilder={id="item_sulfuras_weilder",name="Sulfuras Weilder",desc="Wield Sulfuras, Hand of Ragnaros, and carry the furnace-heart of the Firelord into battle.",category="Elite",points=200,icon="Interface\\Icons\\INV_Hammer_Unique_Sulfuras"},
  item_thunderfury_weilder={id="item_thunderfury_weilder",name="Thunderfury Weilder",desc="Draw Thunderfury, Blessed Blade of the Windseeker, and answer battle with storm, speed, and legend.",category="Elite",points=200,icon="Interface\\Icons\\INV_Sword_39"},
  item_atiesh_weilder={id="item_atiesh_weilder",name="Atiesh Weilder",desc="Raise Atiesh, Greatstaff of the Guardian, and inherit a fragment of Azeroth's oldest arcane burden.",category="Elite",points=200,icon="Interface\\Icons\\INV_Staff_Medivh"},
  item_ashbringer_weilder={id="item_ashbringer_weilder",name="Ashbringer Weilder",desc="Wield Ashbringer and bear a blade feared by the damned and revered by the righteous.",category="Elite",points=200,icon="Interface\\Icons\\INV_Sword_2H_Ashbringer"},
  item_modragzan_heart_of_the_mountain={id="item_modragzan_heart_of_the_mountain",name="Heart of the Mountain",desc="Take up Modrag'zan, Heart of the Mountain, and wield a weapon hewn from the will of the deep places of Blackrock.",category="Elite",points=140,icon="Interface\\Icons\\INV_Hammer_19"},
  item_arms_of_thaurissan_big_bonkers={id="item_arms_of_thaurissan_big_bonkers",name="Arms of the Thaurissan - Big Bonkers",desc="Claim both Ironfoe and Modrag'zan, Heart of the Mountain, and bring the full wrath of Dark Iron royalty to both hands.",category="Elite",points=260,icon="Interface\\Icons\\INV_Hammer_25",criteria_type="ach_meta",criteria_ids={"item_ironfoe_weilder","item_modragzan_heart_of_the_mountain"}},

  -- High-Effort Trackable Achievements
  elite_epochbreaker={id="elite_epochbreaker",name="Conqueror of Ages",desc="Defeat Ragnaros, Nefarian, C'Thun, and Kel'Thuzad at least 5 times each.",category="Elite",points=250,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",criteria_type="ach_meta",criteria_ids={"elite_rag_5x","elite_nef_5x","elite_cthun_5x","elite_kt_5x"}},
  pvp_bg_win_250={id="pvp_bg_win_250",name="Grand Battlemaster",desc="Win 250 battlegrounds.",category="PvP",points=150,icon="Interface\\Icons\\INV_BannerPVP_02"},
  pvp_bg_all_100={id="pvp_bg_all_100",name="Banner of War",desc="Win 100 Warsong Gulch, 100 Arathi Basin, and 100 Alterac Valley matches.",category="PvP",points=220,icon="Interface\\Icons\\INV_Banner_02"},
  pvp_duel_streak_25={id="pvp_duel_streak_25",name="Unbroken Duelist",desc="Win 25 duels in a row without a loss.",category="PvP",points=180,icon="Interface\\Icons\\INV_Sword_62"},
  casual_quest_streak_200={id="casual_quest_streak_200",name="Iron Questline",desc="Turn in 200 quests without dying.",category="Casual",points=120,icon="Interface\\Icons\\INV_Misc_Book_09"},
  explore_world_pathfinder={id="explore_world_pathfinder",name="World Pathfinder",desc="Complete all major exploration achievements across Azeroth and Turtle zones.",category="Exploration",points=200,icon="Interface\\Icons\\INV_Misc_Map_01",criteria_type="ach_meta",criteria_ids={"explore_world_explorer","explore_tw_balor","explore_tw_gillijim","explore_tw_gilneas","explore_tw_hyjal","explore_tw_lapidis","explore_tw_northwind","explore_tw_telabim","explore_tw_grim_reaches","explore_tw_scarlet_enclave","explore_tw_tirisfal_uplands","explore_tw_arathi","explore_tw_ashenvale","explore_tw_badlands","explore_tw_stonetalon"}},
  gold_50000={id="gold_50000",name="Azeroth's Ledger",desc="Accumulate 50,000 lifetime gold earned.",category="Gold",points=180,icon="Interface\\Icons\\INV_Misc_Coin_17"},
  elite_100_unique_bosses={id="elite_100_unique_bosses",name="Trophy Hunter Supreme",desc="Defeat 100 unique tracked bosses.",category="Elite",points=180,icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  kill_100000={id="kill_100000",name="Slayer Eternal",desc="Defeat 100,000 enemies.",category="Kills",points=200,icon="Interface\\Icons\\INV_Sword_27"},
}

local TITLES = {
  -- Leveling Titles
  {id="title_champion",name="Champion",achievement="lvl_60",prefix=false,category="Leveling",icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength"},
  {id="title_elder",name="the Elder",achievement="lvl_60",prefix=false,category="Leveling",icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength"},
  
  -- Molten Core Titles
  {id="title_firelord",name="Firelord",achievement="raid_mc_ragnaros",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Fire_LavaSpawn"},
  {id="title_flamewaker",name="Flamewaker",achievement="raid_mc_sulfuron",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Fire_FireArmor"},
  {id="title_core_hound",name="Core Hound",achievement="raid_mc_magmadar",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  {id="title_molten_destroyer",name="Molten Destroyer",achievement="raid_mc_golemagg",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_MonsterScales_15"},
  
  -- Onyxia/Dragons
  {id="title_dragonslayer",name="Dragonslayer",achievement="raid_onyxia",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  {id="title_dragon_hunter",name="Dragon Hunter",achievement="raid_onyxia",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  
  -- Blackwing Lair Titles
  {id="title_blackwing_slayer",name="Blackwing Slayer",achievement="raid_bwl_nefarian",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  {id="title_dragonkin_slayer",name="Dragonkin Slayer",achievement="raid_bwl_razorgore",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  {id="title_chromatic",name="the Chromatic",achievement="raid_bwl_chromaggus",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Bronze"},
  {id="title_vaels_bane",name="Vael's Bane",achievement="raid_bwl_vaelastrasz",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_ShadowWordDominate"},
  {id="title_broodlord_slayer",name="Broodlord Slayer",achievement="raid_bwl_broodlord",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Bracer_18"},
  
  -- Zul'Gurub Titles
  {id="title_zandalar",name="of Zandalar",achievement="raid_zg_hakkar",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_PainSpike"},
  {id="title_bloodlord",name="Bloodlord",achievement="raid_zg_hakkar",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_PainSpike"},
  {id="title_troll_slayer",name="Troll Slayer",achievement="raid_zg_thekal",prefix=false,category="Raids",icon="Interface\\Icons\\Ability_Druid_Mangle2"},
  {id="title_snake_handler",name="Snake Handler",achievement="raid_zg_venoxis",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Nature_NullifyPoison"},
  
  -- AQ20 Titles
  {id="title_silithid_slayer",name="Silithid Slayer",achievement="raid_aq20_ossirian",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Qiraj_JewelGlowing"},
  {id="title_scarab_hunter",name="Scarab Hunter",achievement="raid_aq20_kurinnaxx",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Qiraj_JewelBlessed"},
  
  -- AQ40 Titles
  {id="title_scarab_lord",name="Scarab Lord",achievement="raid_aq40_cthun",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_Charm"},
  {id="title_qiraji_slayer",name="Qiraji Slayer",achievement="raid_aq40_cthun",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_Charm"},
  {id="title_bug_squasher",name="Bug Squasher",achievement="raid_aq40_bug_trio",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_AhnQirajTrinket_02"},
  {id="title_twin_emperor",name="Twin Emperor",achievement="raid_aq40_twins",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Jewelry_Ring_AhnQiraj_04"},
  {id="title_viscidus_slayer",name="Viscidus Slayer",achievement="raid_aq40_viscidus",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Nature_Acid_01"},
  {id="title_the_prophet",name="the Prophet",achievement="raid_aq40_skeram",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_MindSteal"},
  
  -- Naxxramas Titles
  {id="title_death_demise",name="of the Ashen Verdict",achievement="raid_naxx_kelthuzad",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_SoulGem"},
  {id="title_lich_hunter",name="Lich Hunter",achievement="raid_naxx_kelthuzad",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_SoulGem"},
  {id="title_plaguebearer",name="Plaguebearer",achievement="raid_naxx_loatheb",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_CallofBone"},
  {id="title_spore_bane",name="Spore Bane",achievement="raid_naxx_loatheb",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_CallofBone"},
  {id="title_frost_wyrm",name="Frost Wyrm Slayer",achievement="raid_naxx_sapphiron",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Blue"},
  {id="title_arachnid_slayer",name="Arachnid Slayer",achievement="raid_naxx_maexxna",prefix=false,category="Raids",icon="Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01"},
  {id="title_four_horsemen",name="of the Four Horsemen",achievement="raid_naxx_four_horsemen",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  {id="title_death_knight",name="Death Knight",achievement="raid_naxx_four_horsemen",prefix=false,category="Raids",icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  
  -- Elite Achievement Titles
  {id="title_epochbreaker",name="the Epochbreaker",achievement="elite_epochbreaker",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  {id="title_trophy_reaper",name="the Trophy Reaper",achievement="elite_100_unique_bosses",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black"},
  {id="title_endless",name="the Endless",achievement="kill_100000",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Sword_27"},
  {id="title_unfaltering",name="the Unfaltering",achievement="casual_quest_streak_200",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Misc_Book_09"},
  {id="title_farstrider",name="the Farstrider",achievement="explore_world_pathfinder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Misc_Map_01"},
  {id="title_goldbound",name="the Goldbound",achievement="gold_50000",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Misc_Coin_17"},
  {id="title_warbanner",name="the Warbanner",achievement="pvp_bg_all_100",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Banner_02"},
  {id="title_unbroken",name="the Unbroken",achievement="pvp_duel_streak_25",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Sword_62"},
  {id="title_grand_battlemaster",name="the Battlemaster",achievement="pvp_bg_win_250",prefix=false,category="Elite",icon="Interface\\Icons\\INV_BannerPVP_02"},
  {id="title_ironfoe",name="the Ironfoe",achievement="item_ironfoe_weilder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Hammer_11"},
  {id="title_flamebearer",name="the Flamebearer",achievement="item_sulfuras_weilder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Hammer_Unique_Sulfuras"},
  {id="title_windforged",name="the Windforged",achievement="item_thunderfury_weilder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Sword_39"},
  {id="title_guardians_successor",name="the Guardian's Successor",achievement="item_atiesh_weilder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Staff_Medivh"},
  {id="title_ashen",name="the Ashen",achievement="item_ashbringer_weilder",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Sword_2H_Ashbringer"},
  {id="title_mountains_heart",name="the Mountain's Heart",achievement="item_modragzan_heart_of_the_mountain",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Hammer_19"},
  {id="title_big_bonker",name="the Big Bonker",achievement="item_arms_of_thaurissan_big_bonkers",prefix=false,category="Elite",icon="Interface\\Icons\\INV_Hammer_25"},

  
  -- PvP Titles
  {id="title_warlord",name="Warlord",achievement="pvp_hk_5000",prefix=true,category="PvP",icon="Interface\\Icons\\INV_Sword_62"},
  {id="title_grand_marshal",name="Grand Marshal",achievement="elite_pvp_rank_14",prefix=true,category="PvP",icon="Interface\\Icons\\INV_Sword_39"},
  {id="title_bloodthirsty",name="the Bloodthirsty",achievement="pvp_hk_10000",prefix=false,category="PvP",icon="Interface\\Icons\\Spell_Shadow_ShadowWordPain"},
  {id="title_arena_master",name="Arena Master",achievement="pvp_duel_100",prefix=false,category="PvP",icon="Interface\\Icons\\INV_Sword_62"},
  {id="title_gladiator",name="Gladiator",achievement="pvp_hk_1000",prefix=false,category="PvP",icon="Interface\\Icons\\INV_Sword_48"},
  {id="title_duelist",name="the Duelist",achievement="pvp_duel_50",prefix=false,category="PvP",icon="Interface\\Icons\\INV_Sword_39"},
  {id="title_high_warlord",name="High Warlord",achievement="pvp_hk_10000",prefix=true,category="PvP",icon="Interface\\Icons\\INV_Sword_39"},
  
  -- Profession Titles
  {id="title_master_alchemist",name="Master Alchemist",achievement="prof_alchemy_300",prefix=false,category="Professions",icon="Interface\\Icons\\Trade_Alchemy"},
  {id="title_master_blacksmith",name="Master Blacksmith",achievement="prof_blacksmithing_300",prefix=false,category="Professions",icon="Interface\\Icons\\Trade_BlackSmithing"},
  {id="title_master_enchanter",name="Master Enchanter",achievement="prof_enchanting_300",prefix=false,category="Professions",icon="Interface\\Icons\\Trade_Engraving"},
  {id="title_master_engineer",name="Master Engineer",achievement="prof_engineering_300",prefix=false,category="Professions",icon="Interface\\Icons\\Trade_Engineering"},
  {id="title_artisan",name="the Artisan",achievement="prof_dual_artisan",prefix=false,category="Professions",icon="Interface\\Icons\\INV_Misc_Note_06"},
  
  -- Exploration Titles
  {id="title_explorer",name="the Explorer",achievement="explore_wanderer",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Map_01"},
  {id="title_world_explorer",name="the World Explorer",achievement="explore_world_explorer",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Map_02"},
  {id="title_kalimdor_cartographer",name="Cartographer of Kalimdor",achievement="explore_kalimdor",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Map_01"},
  {id="title_eastern_pathfinder",name="Pathfinder of the East",achievement="explore_eastern_kingdoms",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_BannerPVP_02"},
  {id="title_balor_wayfinder",name="Wayfinder of Balor",achievement="explore_tw_balor",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Platnumdisks"},
  {id="title_gilneas_trailblazer",name="Gilnean Trailblazer",achievement="explore_tw_gilneas",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Shield_06"},
  {id="title_northwind_scout",name="Northwind Scout",achievement="explore_tw_northwind",prefix=false,category="Exploration",icon="Interface\\Icons\\Spell_Frost_FrostShock"},
  {id="title_lapidis_navigator",name="Navigator of Lapidis",achievement="explore_tw_lapidis",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Gem_Sapphire_02"},
  {id="title_isle_rover",name="the Isle Rover",achievement="explore_tw_gillijim",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Gem_Pearl_01"},
  {id="title_hyjal_stargazer",name="Hyjal Stargazer",achievement="explore_tw_hyjal",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Green"},
  {id="title_grim_wanderer",name="the Grim Wanderer",achievement="explore_tw_grim_reaches",prefix=false,category="Exploration",icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  {id="title_telabim_horizons",name="of Tel'Abim Horizons",achievement="explore_tw_telabim",prefix=false,category="Exploration",icon="Interface\\Icons\\INV_Misc_Herb_BlackLotus"},
  {id="title_uplands_ranger",name="Tirisfal Ranger",achievement="explore_tw_tirisfal_uplands",prefix=false,category="Exploration",icon="Interface\\Icons\\Spell_Shadow_RagingScream"},  
  -- Casual Titles
  {id="title_loremaster",name="Loremaster",achievement="casual_quest_1000",prefix=false,category="Casual",icon="Interface\\Icons\\INV_Misc_Book_09"},
  {id="title_angler",name="the Master Angler",achievement="casual_fish_1000",prefix=false,category="Casual",icon="Interface\\Icons\\Trade_Fishing"},
  {id="title_pet_collector",name="the Pet Collector",achievement="casual_pet_fanatic",prefix=false,category="Casual",icon="Interface\\Icons\\INV_Misc_Toy_07"},
  {id="title_banker",name="the Banker",achievement="gold_5000",prefix=false,category="Casual",icon="Interface\\Icons\\INV_Misc_Coin_17"},
  {id="title_death_prone",name="Death-Prone",achievement="casual_deaths_100",prefix=false,category="Casual",icon="Interface\\Icons\\Spell_Shadow_DeathScream"},
  {id="title_clumsy",name="the Clumsy",achievement="casual_fall_death",prefix=false,category="Casual",icon="Interface\\Icons\\Ability_Rogue_FeintedStrike"},
  
  -- Gold Titles
  {id="title_wealthy",name="the Wealthy",achievement="gold_1000",prefix=false,category="Gold",icon="Interface\\Icons\\INV_Misc_Coin_06"},
  {id="title_fortune_builder",name="Fortune Builder",achievement="gold_5000",prefix=false,category="Gold",icon="Interface\\Icons\\INV_Misc_Coin_17"},
  {id="title_tycoon",name="the Tycoon",achievement="gold_5000",prefix=false,category="Gold",icon="Interface\\Icons\\INV_Misc_Coin_17"},
  
  -- Dungeon Titles (updated to new completion IDs)
  {id="title_dungeoneer",name="the Dungeoneer",achievement="dung_ubrs_complete",prefix=false,category="Dungeons",icon="Interface\\Icons\\INV_Misc_Head_Dragon_01"},
  {id="title_undead_slayer",name="Undead Slayer",achievement="dung_strat_complete",prefix=false,category="Dungeons",icon="Interface\\Icons\\Spell_Shadow_RaiseDead"},
  {id="title_shadow_hunter",name="Shadow Hunter",achievement="dung_scholo_complete",prefix=false,category="Dungeons",icon="Interface\\Icons\\Spell_Shadow_Charm"},
  {id="title_dungeon_master",name="Dungeon Master",achievement="dung_dmn_complete",prefix=false,category="Dungeons",icon="Interface\\Icons\\INV_Misc_Key_14"},

  -- Legendary Titles (RED - require officer approval)
  {id="title_the_unsupported",name="the Unsupported",achievement="legendary_solo_raid_boss",prefix=false,category="Legendary",icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength",legendary=true},
  {id="title_bare_bones",name="Bare Bones",achievement="legendary_naked_dungeon",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01",legendary=true},
  {id="title_undying",name="the Undying",achievement="legendary_ironman_60",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Helmet_74",legendary=true},
  {id="title_undefeated",name="the Undefeated",achievement="legendary_duel_streak_100",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Sword_62",legendary=true},
  {id="title_conqueror_of_all",name="Conqueror of All",achievement="legendary_full_clear_week",prefix=false,category="Legendary",icon="Interface\\Icons\\Spell_Shadow_SoulGem",legendary=true},
  {id="title_the_immortal_leg",name="the Immortal",achievement="legendary_flawless_naxx",prefix=false,category="Legendary",icon="Interface\\Icons\\Spell_Shadow_RaiseDead",legendary=true},
  {id="title_speed_demon",name="Speed Demon",achievement="legendary_speed_run_brd",prefix=false,category="Legendary",icon="Interface\\Icons\\Spell_Fire_LavaSpawn",legendary=true},
  {id="title_dragonslayer_leg",name="Dragonslayer",achievement="legendary_onyxia_10",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",legendary=true},
  {id="title_wyrmbane",name="Wyrmbane",achievement="legendary_onyxia_5",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Misc_Head_Dragon_Black",legendary=true},
  {id="title_one_man_army",name="the One-Man Army",achievement="legendary_solo_60_boss",prefix=false,category="Legendary",icon="Interface\\Icons\\Spell_Holy_BlessingOfStrength",legendary=true},
  {id="title_pure_mortal",name="the Pure Mortal",achievement="legendary_no_consumes_t2plus",prefix=false,category="Legendary",icon="Interface\\Icons\\INV_Potion_01",legendary=true},
}

-- ==========================================
-- BOSS CRITERIA DATA (from AtlasLoot)
-- ==========================================

local DUNGEON_BOSSES = {
  rfc    = {"Taragaman the Hungerer","Oggleflint","Jergosh the Invoker","Bazzalan"},
  wc     = {"Lord Cobrahn","Lady Anacondra","Kresh","Zandara Windhoof","Lord Pythas","Skum","Vangros","Lord Serpentis","Verdan the Everliving","Mutanus the Devourer"},
  dm     = {"Jared Voss","Rhahk'Zor","Sneed","Sneed's Shredder","Gilnid","Masterpiece Harvester","Mr. Smite","Cookie","Captain Greenskin","Edwin VanCleef"},
  sfk    = {"Rethilgore","Razorclaw the Butcher","Baron Silverlaine","Commander Springvale","Odo the Blindwatcher","Fenrus the Devourer","Wolf Master Nandos","Archmage Arugal","Prelate Ironmane"},
  bfd    = {"Ghamoo-ra","Lady Sarevess","Gelihast","Baron Aquanis","Velthelaxx the Defiler","Twilight Lord Kelris","Old Serra'kis","Aku'mai"},
  stocks = {"Targorr the Dread","Kam Deepfury","Hamhock","Dextren Ward","Bazil Thredd"},
  tcg    = {"Grovetender Engryss","Keeper Ranathos","High Priestess A'lathea","Fenektis the Deceiver","Master Raxxieth"},
  gnomer = {"Grubbis","Viscous Fallout","Electrocutioner 6000","Crowd Pummeler 9-60","Dark Iron Ambassador","Mekgineer Thermaplugg"},
  rfk    = {"Aggem Thorncurse","Death Speaker Jargba","Overlord Ramtusk","Agathelos the Raging","Charlga Razorflank","Rotthorn"},
  sm_gy  = {"Interrogator Vishas","Duke Dreadmoore","Bloodmage Thalnos"},
  sm_lib = {"Houndmaster Loksey","Brother Wystan","Arcanist Doan"},
  sm_arm = {"Herod","Armory Quartermaster Daghelm"},
  sm_cat = {"High Inquisitor Fairbanks","Scarlet Commander Mograine","High Inquisitor Whitemane"},
  swr    = {"Oronok Torn-Heart","Dagar the Glutton","Duke Balor the IV","Librarian Theodorus","Chieftain Stormsong","Deathlord Tidebane","Subjugator Halthas Shadecrest","Mycellakos","Eldermaw the Primordial","Lady Drazare","Mergothid"},
  rfdown = {"Tuten'kash","Plaguemaw the Rotting","Mordresh Fire Eye","Glutton","Death Prophet Rakameg","Amnennar the Coldbringer"},
  ulda   = {"Baelog","Olaf","Eric 'The Swift'","Revelosh","Ironaya","Ancient Stone Keeper","Galgann Firehammer","Grimlok","Archaedas"},
  gc     = {"Matthias Holtz","Packmaster Ragetooth","Judge Sutherland","Dustivan Blackcowl","Marshal Magnus Greystone","Horsemaster Levvin","Genn Greymane"},
  mara   = {"Noxxion","Razorlash","Lord Vyletongue","Celebras the Cursed","Landslide","Tinkerer Gizlock","Rotgrip","Princess Theradras"},
  zf     = {"Antu'sul","Witch Doctor Zum'rah","Shadowpriest Sezz'ziz","Gahz'rilla","Chief Ukorz Sandscalp","Zel'jeb the Ancient","Champion Razjal the Quick"},
  st     = {"Atal'alarion","Spawn of Hakkar","Avatar of Hakkar","Jammal'an the Prophet","Ogom the Wretched","Dreamscythe","Weaver","Morphaz","Hazzas","Shade of Eranikus"},
  hq     = {"High Foreman Bargul Blackhammer","Engineer Figgles","Corrosis","Hatereaver Annihilator","Har'gesh Doomcaller"},
  brd    = {"Lord Roccor","High Interrogator Gerstahn","Anub'shiah","Eviscerator","Gorosh the Dervish","Grizzle","Hedrum the Creeper","Ok'thor the Breaker","Theldren","Houndmaster Grebmar","Fineous Darkvire","Lord Incendius","Bael'Gar","General Angerforge","Golem Lord Argelmach","Ambassador Flamelash","Magmus","Emperor Dagran Thaurissan"},
  dme    = {"Pusillin","Zevrim Thornhoof","Hydrospawn","Lethtendris","Isalien","Alzzin the Wildshaper"},
  dmw    = {"Tendris Warpwood","Illyanna Ravenoak","Magister Kalendris","Immol'thar","Prince Tortheldrin"},
  dmn    = {"Guard Mol'dar","Stomper Kreeg","Guard Fengus","Guard Slip'kik","Captain Kromcrush","Cho'Rush the Observer","King Gordok"},
  scholo = {"Kirtonos the Herald","Jandice Barov","Rattlegore","Death Knight Darkreaver","Marduk Blackpool","Vectus","Ras Frostwhisper","Kormok","Instructor Malicia","Doctor Theolen Krastinov","Lorekeeper Polkelt","The Ravenian","Lord Alexei Barov","Lady Illucia Barov","Darkmaster Gandling"},
  strat  = {"Postmaster Malown","Fras Siabi","The Unforgiven","Timmy the Cruel","Cannon Master Willey","Archivist Galford","Balnazzar","Baroness Anastari","Nerub'enkan","Maleki the Pallid","Magistrate Barthilas","Ramstein the Gorger","Baron Rivendare"},
  lbrs   = {"Highlord Omokk","Shadow Hunter Vosh'gajin","War Master Voone","Mor Grayhoof","Mother Smolderweb","Urok Doomhowl","Quartermaster Zigris","Halycon","Gizrul the Slavener","Overlord Wyrmthalak"},
  ubrs   = {"Pyroguard Emberseer","Solakar Flamewreath","Father Flame","Warchief Rend Blackhand","Gyth","The Beast","Lord Valthalak","General Drakkisath"},
  kc     = {"Marrowspike","Hivaxxis","Corpsemuncher","Guard Captain Gort","Archlich Enkhraz","Commander Andreon","Alarus"},
  cotbm  = {"Chronar","Epidamu","Drifting Avatar of Sand","Time-Lord Epochronos","Mossheart","Rotmaw","Antnormi"},
  swv    = {"Aszosh Grimflame","Tham'Grarr","Black Bride","Damian","Volkan Cruelblade"},
  dmr    = {"Gowlfang","Cavernweb Broodmother","Web Master Torkon","Garlok Flamekeeper","Halgan Redbrand","Slagfist Destroyer","Overlord Blackheart","Elder Hollowblood","Searistrasz","Zuluhed the Whacked"},
}

local RAID_BOSSES = {
  zg     = {"High Priestess Jeklik","High Priest Venoxis","High Priestess Mar'li","Bloodlord Mandokir","Gri'lek","Hazza'rah","Renataki","Wushoolay","Gahz'ranka","High Priest Thekal","High Priestess Arlokk","Jin'do the Hexxer","Hakkar"},
  aq20   = {"Kurinnaxx","General Rajaxx","Moam","Buru the Gorger","Ayamiss the Hunter","Ossirian the Unscarred"},
  mc     = {"Incindis","Lucifron","Magmadar","Garr","Shazzrah","Baron Geddon","Golemagg the Incinerator","Basalthar","Sorcerer-Thane Thaurissan","Sulfuron Harbinger","Majordomo Executus","Ragnaros"},
  onyxia = {"Onyxia"},
  bwl    = {"Razorgore the Untamed","Vaelastrasz the Corrupt","Broodlord Lashlayer","Firemaw","Ebonroc","Flamegor","Chromaggus","Nefarian"},
  aq40   = {"The Prophet Skeram","Lord Kri","Princess Yauj","Vem","Battleguard Sartura","Fankriss the Unyielding","Viscidus","Princess Huhuran","Emperor Vek'lor","Ouro","C'Thun"},
  naxx   = {"Patchwerk","Grobbulus","Gluth","Thaddius","Anub'Rekhan","Grand Widow Faerlina","Maexxna","Noth the Plaguebringer","Heigan the Unclean","Loatheb","Instructor Razuvious","Gothik the Harvester","Highlord Mograine","Thane Korth'azz","Lady Blaumeux","Sir Zeliek","Sapphiron","Kel'Thuzad"},
  es     = {"Erennius","Solnius the Awakener"},
  lkh    = {"Master Blacksmith Rolfen","Brood Queen Araxxna","Grizikil","Clawlord Howlfang","Lord Blackwald II","Moroes"},
  ukh    = {"Keeper Gnarlmoon","Ley-Watcher Incantagos","Anomalus","Echo of Medivh","King","Sanv Tas'dal","Kruul","Rupturan the Broken","Mephistroth"},
}

-- Reverse lookup: boss name â†’ dungeon key
local BOSS_TO_DUNGEON = {}
for dungId, bossList in pairs(DUNGEON_BOSSES) do
  for _, bossName in ipairs(bossList) do
    BOSS_TO_DUNGEON[bossName] = dungId
  end
end

-- Reverse lookup: boss name â†’ raid key
local BOSS_TO_RAID = {}
for raidId, bossList in pairs(RAID_BOSSES) do
  for _, bossName in ipairs(bossList) do
    BOSS_TO_RAID[bossName] = raidId
  end
end

-- Boss name compatibility:
-- Atlas/Turtle/custom modules can use slightly different punctuation/spelling.
-- We resolve those variants to a canonical boss name before progress checks.
local BOSS_NAME_ALIASES = {
  ["Erik 'The Swift'"] = "Eric 'The Swift'",
  ["Erik the Swift"] = "Eric 'The Swift'",
  ["Erik \"The Swift\""] = "Eric 'The Swift'",
  ["Eric \"The Swift\""] = "Eric 'The Swift'",
  ["Cho'Rush Observer"] = "Cho'Rush the Observer",
  ["Rend Blackhand"] = "Warchief Rend Blackhand",
  ["Jindo the Hexxer"] = "Jin'do the Hexxer",
  ["Emperor Vek'nilash"] = "Emperor Vek'lor",
  ["Smoldaris"] = "Basalthar",
}

local function BossFuzzyKey(name)
  if not name then return nil end
  local key = string.lower(name)
  key = string.gsub(key, "[^%w]", "")
  return key
end

-- Atlas grouped raid labels that do not map 1:1 to your internal boss keys.
-- When one of these appears, all mapped internal bosses are credited.
local BOSS_GROUP_ALIASES = {
  ["The Bug Family"] = {"Lord Kri", "Princess Yauj", "Vem"},
  ["The Four Horsemen"] = {"Highlord Mograine", "Thane Korth'azz", "Lady Blaumeux", "Sir Zeliek"},
  ["Twin Emperors"] = {"Emperor Vek'lor"},
  ["Basalthar & Smoldaris"] = {"Basalthar"},
}
local BOSS_FUZZY_INDEX = {}
local BOSS_FUZZY_KEYS = {}
local BOSS_FUZZY_KEY_SEEN = {}
local function AddBossFuzzyName(canonical)
  local key = BossFuzzyKey(canonical)
  if not key or key == "" then return end
  if not BOSS_FUZZY_KEY_SEEN[key] then
    BOSS_FUZZY_KEY_SEEN[key] = true
    table.insert(BOSS_FUZZY_KEYS, {key = key, canonical = canonical})
  end
  if BOSS_FUZZY_INDEX[key] == nil then
    BOSS_FUZZY_INDEX[key] = canonical
  elseif BOSS_FUZZY_INDEX[key] ~= canonical then
    -- Mark ambiguous key as unusable for fuzzy matching.
    BOSS_FUZZY_INDEX[key] = false
  end
end

local function IsOneEditAway(a, b)
  local la = string.len(a)
  local lb = string.len(b)
  local diff = la - lb
  if diff < 0 then diff = -diff end
  if diff > 1 then return false end

  if la == lb then
    local mismatches = 0
    for i = 1, la do
      if string.sub(a, i, i) ~= string.sub(b, i, i) then
        mismatches = mismatches + 1
        if mismatches > 1 then return false end
      end
    end
    return true
  end

  local i, j, usedSkip = 1, 1, false
  while i <= la and j <= lb do
    if string.sub(a, i, i) == string.sub(b, j, j) then
      i = i + 1
      j = j + 1
    else
      if usedSkip then return false end
      usedSkip = true
      if la > lb then
        i = i + 1
      else
        j = j + 1
      end
    end
  end
  return true
end

local function ResolveOneEditBossName(bossName)
  local key = BossFuzzyKey(bossName)
  if not key or key == "" then return nil end

  local best = nil
  for _, e in ipairs(BOSS_FUZZY_KEYS) do
    local ck = e.key
    local ld = string.len(ck) - string.len(key)
    if ld < 0 then ld = -ld end
    if ld <= 1 and string.sub(ck, 1, 1) == string.sub(key, 1, 1) and IsOneEditAway(ck, key) then
      if best and best ~= e.canonical then
        return nil -- ambiguous typo match
      end
      best = e.canonical
    end
  end
  return best
end

for _, bossList in pairs(DUNGEON_BOSSES) do
  for _, bossName in ipairs(bossList) do
    AddBossFuzzyName(bossName)
  end
end
for _, bossList in pairs(RAID_BOSSES) do
  for _, bossName in ipairs(bossList) do
    AddBossFuzzyName(bossName)
  end
end

local function ResolveBossName(bossName)
  if not bossName or bossName == "" then return nil end

  local alias = BOSS_NAME_ALIASES[bossName]
  if alias then
    bossName = alias
  end

  if BOSS_TO_DUNGEON[bossName] or BOSS_TO_RAID[bossName] then
    return bossName
  end

  local fuzzy = BossFuzzyKey(bossName)
  local canonical = fuzzy and BOSS_FUZZY_INDEX[fuzzy] or nil
  if canonical and canonical ~= false then
    return canonical
  end

  return ResolveOneEditBossName(bossName)
end

-- ==========================================
-- PUBLIC API FOR OTHER ADDONS
-- ==========================================

local function GetAchievementIcon(achId)
  if not achId then return "Interface\\Icons\\INV_Misc_QuestionMark" end
  
  -- Check ACHIEVEMENTS table first
  local achData = ACHIEVEMENTS[achId]
  if achData and achData.icon then
    return achData.icon
  end
  
  -- Fallback icons based on achievement ID pattern
  local lowerAchId = string.lower(achId)
  
  -- Leveling icons
  if string.find(lowerAchId, "^lvl_") then
    return "Interface\\Icons\\INV_Helmet_08"
  end
  
  -- Profession icons
  if string.find(lowerAchId, "^prof_") then
    return "Interface\\Icons\\Trade_Engineering"
  end
  
  -- Gold icons
  if string.find(lowerAchId, "^gold_") then
    return "Interface\\Icons\\INV_Misc_Coin_01"
  end
  
  -- Dungeon icons
  if string.find(lowerAchId, "^dung_") then
    return "Interface\\Icons\\INV_Misc_Key_14"
  end
  
  -- Raid icons
  if string.find(lowerAchId, "^raid_") then
    return "Interface\\Icons\\INV_Misc_Head_Dragon_01"
  end
  
  -- PvP icons
  if string.find(lowerAchId, "^pvp_") then
    return "Interface\\Icons\\INV_Sword_48"
  end
  
  -- Elite icons
  if string.find(lowerAchId, "^elite_") then
    return "Interface\\Icons\\INV_Misc_Trophy_Gold"
  end
  
  -- Casual icons
  if string.find(lowerAchId, "^casual_") then
    return "Interface\\Icons\\INV_Misc_Toy_07"
  end
  
  -- Exploration icons
  if string.find(lowerAchId, "^explore_") then
    return "Interface\\Icons\\INV_Misc_Spyglass_03"
  end
  
  -- Default fallback
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

LeafVE_AchTest.API = {
  GetPlayerPoints = function(playerName)
    return LeafVE_AchTest:GetTotalAchievementPoints(playerName)
  end,
  
  GetRecentAchievements = function(playerName, count)
    if not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.achievements then return {} end
    playerName = ShortName(playerName)
    if not playerName then return {} end
    if not LeafVE_AchTest_DB.achievements[playerName] then return {} end
    
    local achievements = {}
    for achId, achData in pairs(LeafVE_AchTest_DB.achievements[playerName]) do
      if type(achData) == "table" and achData.points and achData.timestamp then
        local achievement = ACHIEVEMENTS[achId]
        if achievement then
          table.insert(achievements, {
            id = achId,
            name = achievement.name,
            icon = GetAchievementIcon(achId),
            points = achData.points,
            timestamp = achData.timestamp
          })
        end
      end
    end
    
    -- Sort by most recent
    table.sort(achievements, function(a, b) return a.timestamp > b.timestamp end)
    
    -- Return only the requested count
    local result = {}
    for i = 1, math.min(count or 5, table.getn(achievements)) do
      table.insert(result, achievements[i])
    end
    
    return result
  end
}

-- Cross-addon accessors used by LeafVillageLegends for tooltips
function LeafVE_AchTest.GetAchievementMeta(achId)
  return ACHIEVEMENTS[achId]
end

function LeafVE_AchTest.GetBossCriteria(criteriaKey, criteriaType)
  if criteriaType == "dungeon" then return DUNGEON_BOSSES[criteriaKey] end
  if criteriaType == "raid"    then return RAID_BOSSES[criteriaKey]    end
  return nil
end

function LeafVE_AchTest.GetBossProgress(playerName, criteriaKey, criteriaType)
  if not LeafVE_AchTest_DB then return nil end
  if criteriaType == "dungeon" then
    local dp = LeafVE_AchTest_DB.dungeonProgress
    return dp and dp[playerName] and dp[playerName][criteriaKey]
  end
  if criteriaType == "raid" then
    local rp = LeafVE_AchTest_DB.raidProgress
    return rp and rp[playerName] and rp[playerName][criteriaKey]
  end
  return nil
end

-- ==========================================
-- PROGRESS TRACKING HELPERS
-- ==========================================

-- Zone name (from GetRealZoneText) â†’ dungeon completion achievement ID
local ZONE_TO_DUNGEON_ACH = {
  ["Ragefire Chasm"]               = "dung_rfc_complete",
  ["Wailing Caverns"]              = "dung_wc_complete",
  ["The Deadmines"]                = "dung_dm_complete",
  ["Shadowfang Keep"]              = "dung_sfk_complete",
  ["Blackfathom Deeps"]            = "dung_bfd_complete",
  ["The Stockade"]                 = "dung_stocks_complete",
  ["The Crescent Grove"]           = "dung_tcg_complete",
  ["Gnomeregan"]                   = "dung_gnomer_complete",
  ["Razorfen Kraul"]               = "dung_rfk_complete",
  ["Scarlet Monastery"]            = nil, -- multiple wings; skip blanket grant
  ["Stormwrought Ruins"]           = "dung_swr_complete",
  ["Razorfen Downs"]               = "dung_rfdown_complete",
  ["Uldaman"]                      = "dung_ulda_complete",
  ["Gilneas City"]                 = "dung_gc_complete",
  ["Maraudon"]                     = "dung_mara_complete",
  ["Zul'Farrak"]                   = "dung_zf_complete",
  ["The Sunken Temple"]            = "dung_st_complete",
  ["Hateforge Quarry"]             = "dung_hq_complete",
  ["Blackrock Depths"]             = "dung_brd_complete",
  ["Dire Maul"]                    = nil, -- multiple wings; skip blanket grant
  ["Scholomance"]                  = "dung_scholo_complete",
  ["Stratholme"]                   = "dung_strat_complete",
  ["Lower Blackrock Spire"]        = "dung_lbrs_complete",
  ["Upper Blackrock Spire"]        = "dung_ubrs_complete",
  ["Karazhan Crypt"]               = "dung_kc_complete",
  ["Black Morass"]                 = "dung_cotbm_complete",
  ["Stormwind Vault"]              = "dung_swv_complete",
  ["Dragonmaw Retreat"]            = "dung_dmr_complete",
}

-- Per-achievement counter/goal definitions for tooltip progress lines
local ACHIEVEMENT_PROGRESS_DEF = {
  -- PvP HKs: read live from the API
  pvp_hk_50    = {api="hk", goal=50},
  pvp_hk_100   = {api="hk", goal=100},
  pvp_hk_1000  = {api="hk", goal=1000},
  pvp_hk_2500  = {api="hk", goal=2500},
  pvp_hk_5000  = {api="hk", goal=5000},
  pvp_hk_10000 = {api="hk", goal=10000},
  -- Duels tracked via CHAT_MSG_SYSTEM event
  pvp_duel_10  = {counter="duels", goal=10},
  pvp_duel_25  = {counter="duels", goal=25},
  pvp_duel_50  = {counter="duels", goal=50},
  pvp_duel_100 = {counter="duels", goal=100},
  pvp_duel_streak_25 = {counter="duelStreak", goal=25},
  pvp_bg_win_1  = {counter="bgWins", goal=1},
  pvp_bg_win_10 = {counter="bgWins", goal=10},
  pvp_bg_win_50 = {counter="bgWins", goal=50},
  pvp_bg_win_250 = {counter="bgWins", goal=250},
  pvp_wsg_win_10 = {counter="bgWinsWSG", goal=10},
  pvp_ab_win_10  = {counter="bgWinsAB", goal=10},
  pvp_av_win_10  = {counter="bgWinsAV", goal=10},
  -- Gold: read live from the API
  gold_10   = {api="gold", goal=10},
  gold_100  = {api="gold", goal=100},
  gold_500  = {api="gold", goal=500},
  gold_1000 = {api="gold", goal=1000},
  gold_5000 = {api="gold", goal=5000},
  gold_50000 = {api="gold", goal=50000},
  -- Quests: use the higher of GetNumQuestsCompleted() and tracked counter
  quest_25 = {api="quests", counter="quests", goal=25},
  casual_quest_100  = {api="quests", counter="quests", goal=100},
  quest_250 = {api="quests", counter="quests", goal=250},
  casual_quest_500  = {api="quests", counter="quests", goal=500},
  quest_750 = {api="quests", counter="quests", goal=750},
  casual_quest_1000 = {api="quests", counter="quests", goal=1000},
  quest_1500 = {api="quests", counter="quests", goal=1500},
  quest_2000 = {api="quests", counter="quests", goal=2000},
  casual_quest_streak_200 = {counter="questsSinceDeath", goal=200},
  -- Deaths tracked via PLAYER_DEAD event
  casual_deaths_50  = {counter="deaths", goal=50},
  casual_deaths_100 = {counter="deaths", goal=100},
  casual_fall_death = {counter="fallDeaths", goal=10},
  casual_drown      = {counter="drownings", goal=10},
  -- Hearthstone uses tracked via UNIT_SPELLCAST_SUCCEEDED
  casual_hearthstone_1   = {counter="hearthstones", goal=1},
  casual_hearthstone_use = {counter="hearthstones", goal=50},
  casual_hearthstone_100 = {counter="hearthstones", goal=100},
  -- Fish tracked via CHAT_MSG_LOOT (bobber loot)
  casual_fish_25   = {counter="fish", goal=25},
  casual_fish_100  = {counter="fish", goal=100},
  casual_fish_1000 = {counter="fish", goal=1000},
  -- Groups joined: PARTY_MEMBERS_CHANGED (0 â†’ >0)
  casual_party_join = {counter="groups", goal=50},
  -- Emotes tracked via CHAT_MSG_TEXT_EMOTE
  casual_emote_25  = {counter="emotes", goal=25},
  casual_emote_100 = {counter="emotes", goal=100},
  -- Boss kill counts tracked via CHAT_MSG_COMBAT_HOSTILE_DEATH
  elite_rag_5x        = {counter="boss_Ragnaros",    goal=5},
  elite_rag_10x       = {counter="boss_Ragnaros",    goal=10},
  elite_nef_5x        = {counter="boss_Nefarian",    goal=5},
  elite_nef_10x       = {counter="boss_Nefarian",    goal=10},
  elite_kt_3x         = {counter="boss_KelThuzad",   goal=3},
  elite_kt_5x         = {counter="boss_KelThuzad",   goal=5},
  elite_cthun_5x      = {counter="boss_CThun",       goal=5},
  elite_drakkisath_5x = {counter="boss_Drakkisath",  goal=5},
  elite_gandling_5x   = {counter="boss_Gandling",    goal=5},
  elite_baron_5x      = {counter="boss_BaronRiv",    goal=5},
  elite_onyxia_5x     = {counter="boss_Onyxia",      goal=5},
  elite_onyxia_10x    = {counter="boss_Onyxia",      goal=10},
  elite_hakkar_5x     = {counter="boss_Hakkar",      goal=5},
  -- Total and unique boss kills
  elite_100_bosses     = {counter="totalBossKills",  goal=100},
  elite_250_bosses     = {counter="totalBossKills",  goal=250},
  elite_500_bosses     = {counter="totalBossKills",  goal=500},
  elite_25_unique_bosses = {counter="uniqueBossKills", goal=25},
  elite_50_unique_bosses = {counter="uniqueBossKills", goal=50},
  elite_100_unique_bosses = {counter="uniqueBossKills", goal=100},
  -- Dungeon and raid run counts
  elite_50_dungeons  = {counter="dungeonRuns", goal=50},
  elite_100_dungeons = {counter="dungeonRuns", goal=100},
  elite_250_dungeons = {counter="dungeonRuns", goal=250},
  elite_500_dungeons = {counter="dungeonRuns", goal=500},
  elite_25_raids     = {counter="raidRuns",    goal=25},
  elite_50_raids     = {counter="raidRuns",    goal=50},
  elite_100_raids    = {counter="raidRuns",    goal=100},
  elite_250_raids    = {counter="raidRuns",    goal=250},
  -- Resurrections tracked via accepted player resurrection requests
  casual_resurrect_10 = {counter="resurrections", goal=10},
  casual_resurrect_50 = {counter="resurrections", goal=50},
  -- Flight paths tracked via TAXIMAP_CLOSED
  casual_flight_10 = {counter="flights", goal=10},
  casual_flight_50 = {counter="flights", goal=50},
  -- Bandages tracked via UNIT_SPELLCAST_SUCCEEDED
  casual_bandage_25  = {counter="bandages", goal=25},
  casual_bandage_100 = {counter="bandages", goal=100},
  -- Loots tracked via CHAT_MSG_LOOT
  casual_loot_100  = {counter="loots", goal=100},
  casual_loot_1000 = {counter="loots", goal=1000},
  casual_loot_5000 = {counter="loots", goal=5000},
  -- Trades tracked via TRADE_CLOSED
  casual_trade_10 = {counter="trades", goal=10},
  -- Reputation milestones (tracked via UPDATE_FACTION)
  reputation_exalted_1  = {counter="exaltedFactions", goal=1},
  reputation_exalted_5  = {counter="exaltedFactions", goal=5},
  reputation_exalted_10 = {counter="exaltedFactions", goal=10},
  -- Generic kill milestones tracked via CHAT_MSG_COMBAT_HOSTILE_DEATH (player or party/raid member kill)
  kill_01    = {counter="genericKills", goal=1},
  kill_100   = {counter="genericKills", goal=100},
  kill_500   = {counter="genericKills", goal=500},
  kill_1000  = {counter="genericKills", goal=1000},
  kill_10000 = {counter="genericKills", goal=10000},
  kill_50000 = {counter="genericKills", goal=50000},
  kill_100000 = {counter="genericKills", goal=100000},
}

-- Counter name -> list of achievement IDs that use that counter.
-- Used to immediately persist progress cache whenever counters change.
local PROGRESS_DEF_BY_COUNTER = {}
for achId, def in pairs(ACHIEVEMENT_PROGRESS_DEF) do
  if def.counter then
    if not PROGRESS_DEF_BY_COUNTER[def.counter] then
      PROGRESS_DEF_BY_COUNTER[def.counter] = {}
    end
    table.insert(PROGRESS_DEF_BY_COUNTER[def.counter], achId)
  end
end

-- Returns {current, goal} or nil if no progress data exists for this achievement.
local function GetCachedProgress(playerName, achId)
  if not playerName or not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.progressCache then return 0 end
  local p = LeafVE_AchTest_DB.progressCache[playerName]
  if not p then return 0 end
  return tonumber(p[achId]) or 0
end

local function CacheProgress(playerName, achId, value)
  if not playerName or not achId then return end
  local n = tonumber(value) or 0
  if n < 0 then n = 0 end
  EnsureDB()
  if not LeafVE_AchTest_DB.progressCache[playerName] then
    LeafVE_AchTest_DB.progressCache[playerName] = {}
  end
  local p = LeafVE_AchTest_DB.progressCache[playerName]
  local prev = tonumber(p[achId]) or 0
  if n > prev then
    p[achId] = n
  end
end

local function GetAchievementProgress(me, achId)
  local def = ACHIEVEMENT_PROGRESS_DEF[achId]
  if not def then return nil end
  EnsureDB()

  local current = 0

  if def.api == "hk" then
    current = (GetPVPLifetimeHonorableKills and GetPVPLifetimeHonorableKills()) or 0
  elseif def.api == "gold" then
    local cur = math.floor((GetMoney and GetMoney() or 0) / 10000)
    local total = (me and LeafVE_AchTest_DB and LeafVE_AchTest_DB.goldEarnedTotal and LeafVE_AchTest_DB.goldEarnedTotal[me]) or 0
    local last = (me and LeafVE_AchTest_DB and LeafVE_AchTest_DB.goldLastSeen and LeafVE_AchTest_DB.goldLastSeen[me])
    local peak = (me and LeafVE_AchTest_DB and LeafVE_AchTest_DB.peakGold and LeafVE_AchTest_DB.peakGold[me]) or 0
    if total < peak then total = peak end -- migrate old progress safely
    if total == 0 and cur > 0 then total = cur end -- initialize from current wallet
    if last and cur > last then total = total + (cur - last) end
    current = total
  elseif def.api == "quests" then
    -- Use the highest known value to tolerate API/client inconsistencies.
    local pc = LeafVE_AchTest_DB and LeafVE_AchTest_DB.progressCounters
    local pme = pc and pc[me]
    local tracked = (pme and pme[def.counter]) or 0
    local apiTotal = nil
    if GetNumQuestsCompleted then
      apiTotal = tonumber(GetNumQuestsCompleted())
    end
    if apiTotal and apiTotal > tracked then
      current = apiTotal
      if me then
        if not LeafVE_AchTest_DB.progressCounters[me] then
          LeafVE_AchTest_DB.progressCounters[me] = {}
        end
        LeafVE_AchTest_DB.progressCounters[me][def.counter] = apiTotal
      end
    else
      current = tracked
    end
  end

  if def.counter then
    local pc = LeafVE_AchTest_DB and LeafVE_AchTest_DB.progressCounters
    local pme = pc and pc[me]
    local tracked = (pme and pme[def.counter]) or 0
    -- For API-backed achievements the API value is more accurate; for others use counter
    if def.api ~= "hk" and def.api ~= "gold" and def.api ~= "quests" then
      current = tracked
    end
  end

  -- Use persisted max progress so temporary API failures never regress progress UI.
  local cached = GetCachedProgress(me, achId)
  if cached > current then
    current = cached
  end
  CacheProgress(me, achId, current)

  return {current = current, goal = def.goal}
end

-- Ensure a player's counter sub-table exists and increment a named counter
local function IncrCounter(playerName, counterName, amount)
  EnsureDB()
  if not LeafVE_AchTest_DB.progressCounters[playerName] then
    LeafVE_AchTest_DB.progressCounters[playerName] = {}
  end
  local c = LeafVE_AchTest_DB.progressCounters[playerName]
  c[counterName] = (c[counterName] or 0) + (amount or 1)
  local related = PROGRESS_DEF_BY_COUNTER[counterName]
  if related then
    for _, achId in ipairs(related) do
      CacheProgress(playerName, achId, c[counterName])
    end
  end
  return c[counterName]
end

local function SetCounter(playerName, counterName, value)
  EnsureDB()
  if not LeafVE_AchTest_DB.progressCounters[playerName] then
    LeafVE_AchTest_DB.progressCounters[playerName] = {}
  end
  local c = LeafVE_AchTest_DB.progressCounters[playerName]
  c[counterName] = value
  local related = PROGRESS_DEF_BY_COUNTER[counterName]
  if related then
    for _, achId in ipairs(related) do
      CacheProgress(playerName, achId, c[counterName])
    end
  end
  return c[counterName]
end

-- Expose helpers so separate achievement module files loaded after this file
-- can add achievements and interact with the DB without duplicating locals.
LeafVE_AchTest.ShortName     = ShortName
LeafVE_AchTest.IncrCounter   = IncrCounter
LeafVE_AchTest.SetCounter    = SetCounter
LeafVE_AchTest.IsPartyOrSelf = IsPartyOrSelf
function LeafVE_AchTest:AddAchievement(id, data)
  ACHIEVEMENTS[id] = data
end
-- Allow external modules to register tooltip progress definitions.
function LeafVE_AchTest:RegisterProgressDef(achId, def)
  ACHIEVEMENT_PROGRESS_DEF[achId] = def
  if def and def.counter then
    if not PROGRESS_DEF_BY_COUNTER[def.counter] then
      PROGRESS_DEF_BY_COUNTER[def.counter] = {}
    end
    local list = PROGRESS_DEF_BY_COUNTER[def.counter]
    local exists = false
    for _, existingId in ipairs(list) do
      if existingId == achId then
        exists = true
        break
      end
    end
    if not exists then
      table.insert(list, achId)
    end
  end
end
-- Allow external modules to add titles.
function LeafVE_AchTest:AddTitle(titleData)
  table.insert(TITLES, titleData)
end

-- Check and award quest-count achievements using the highest reliable known total.
function LeafVE_AchTest:CheckQuestAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  local pc = LeafVE_AchTest_DB.progressCounters[me]
  local streak = (pc and pc.questsSinceDeath) or 0
  local trackedTotal = (pc and pc.quests) or 0
  local total = trackedTotal
  local apiTotal = nil
  if GetNumQuestsCompleted then
    apiTotal = tonumber(GetNumQuestsCompleted())
  end
  if apiTotal and apiTotal > total then
    total = apiTotal
    SetCounter(me, "quests", apiTotal)
  end
  if total >= 25   then self:AwardAchievement("quest_25",   silent) end
  if total >= 100  then self:AwardAchievement("casual_quest_100",  silent) end
  if total >= 250  then self:AwardAchievement("quest_250",  silent) end
  if total >= 500  then self:AwardAchievement("casual_quest_500",  silent) end
  if total >= 750  then self:AwardAchievement("quest_750",  silent) end
  if total >= 1000 then self:AwardAchievement("casual_quest_1000", silent) end
  if total >= 1500 then self:AwardAchievement("quest_1500", silent) end
  if total >= 2000 then self:AwardAchievement("quest_2000", silent) end
  if streak >= 200 then self:AwardAchievement("casual_quest_streak_200", silent) end
end

-- Check PvP rank achievement
function LeafVE_AchTest:CheckPvPRankAchievements(silent)
  if not UnitPVPRank then return end
  local rank = UnitPVPRank("player") or 0
  if rank >= 14 then self:AwardAchievement("elite_pvp_rank_14", silent) end
end

local function CountExaltedFactions()
  if not GetNumFactions or not GetFactionInfo then return 0 end

  -- Expand collapsed headers so we can count all factions reliably.
  local safety = 0
  local changed = true
  while changed and safety < 20 do
    changed = false
    safety = safety + 1
    local n = GetNumFactions()
    for i = 1, n do
      local _, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
      if isHeader and isCollapsed and ExpandFactionHeader then
        ExpandFactionHeader(i)
        changed = true
      end
    end
  end

  local exalted = 0
  for i = 1, (GetNumFactions() or 0) do
    local _, _, standingID, _, _, _, _, _, isHeader = GetFactionInfo(i)
    if not isHeader and standingID and standingID >= 8 then
      exalted = exalted + 1
    end
  end
  return exalted
end

function LeafVE_AchTest:CheckReputationAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  if not LeafVE_AchTest_DB.progressCounters[me] then
    LeafVE_AchTest_DB.progressCounters[me] = {}
  end
  local exalted = CountExaltedFactions()
  LeafVE_AchTest_DB.progressCounters[me].exaltedFactions = exalted

  if exalted >= 1  then self:AwardAchievement("reputation_exalted_1", silent) end
  if exalted >= 5  then self:AwardAchievement("reputation_exalted_5", silent) end
  if exalted >= 10 then self:AwardAchievement("reputation_exalted_10", silent) end
end

local function CheckBattlegroundAchievementsForPlayer(me, silent)
  EnsureDB()
  local pc = LeafVE_AchTest_DB.progressCounters
  local p = pc[me] or {}

  local wins = p.bgWins or 0
  if wins >= 1  then LeafVE_AchTest:AwardAchievement("pvp_bg_win_1", silent) end
  if wins >= 10 then LeafVE_AchTest:AwardAchievement("pvp_bg_win_10", silent) end
  if wins >= 50 then LeafVE_AchTest:AwardAchievement("pvp_bg_win_50", silent) end
  if wins >= 250 then LeafVE_AchTest:AwardAchievement("pvp_bg_win_250", silent) end

  local wsgWins = p.bgWinsWSG or 0
  local abWins = p.bgWinsAB or 0
  local avWins = p.bgWinsAV or 0
  if wsgWins >= 10 then LeafVE_AchTest:AwardAchievement("pvp_wsg_win_10", silent) end
  if abWins  >= 10 then LeafVE_AchTest:AwardAchievement("pvp_ab_win_10", silent) end
  if avWins  >= 10 then LeafVE_AchTest:AwardAchievement("pvp_av_win_10", silent) end
  if wsgWins >= 100 and abWins >= 100 and avWins >= 100 then
    LeafVE_AchTest:AwardAchievement("pvp_bg_all_100", silent)
  end
end

function LeafVE_AchTest:CheckBattlegroundAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  CheckBattlegroundAchievementsForPlayer(me, silent)
end

local lastBattlegroundWinSignature = nil
local lastBattlegroundWinTime = 0
local BATTLEGROUND_WIN_DEDUPE_WINDOW = 5

local function MessageDeclaresFactionVictory(lowerMsg, factionKey)
  if not lowerMsg or lowerMsg == "" then return false end
  if factionKey == "alliance" then
    return string.find(lowerMsg, "the alliance wins", 1, true)
      or string.find(lowerMsg, "alliance wins", 1, true)
      or string.find(lowerMsg, "alliance victory", 1, true)
      or string.find(lowerMsg, "the alliance has won", 1, true)
      or string.find(lowerMsg, "alliance has won", 1, true)
      or string.find(lowerMsg, "the alliance is victorious", 1, true)
      or string.find(lowerMsg, "victory for the alliance", 1, true)
      or string.find(lowerMsg, "victory to the alliance", 1, true)
  elseif factionKey == "horde" then
    return string.find(lowerMsg, "the horde wins", 1, true)
      or string.find(lowerMsg, "horde wins", 1, true)
      or string.find(lowerMsg, "horde victory", 1, true)
      or string.find(lowerMsg, "the horde has won", 1, true)
      or string.find(lowerMsg, "horde has won", 1, true)
      or string.find(lowerMsg, "the horde is victorious", 1, true)
      or string.find(lowerMsg, "victory for the horde", 1, true)
      or string.find(lowerMsg, "victory to the horde", 1, true)
  end
  return false
end

local function ResolveBattlegroundType(msg)
  local lower = string.lower(msg or "")
  if string.find(lower, "warsong gulch", 1, true) then return "WSG" end
  if string.find(lower, "arathi basin", 1, true) then return "AB" end
  if string.find(lower, "alterac valley", 1, true) then return "AV" end

  local zone = ""
  if GetRealZoneText then
    zone = string.lower(GetRealZoneText() or "")
  elseif GetZoneText then
    zone = string.lower(GetZoneText() or "")
  end
  local subZone = string.lower((GetSubZoneText and GetSubZoneText()) or "")

  if string.find(zone, "warsong gulch", 1, true) or string.find(subZone, "warsong gulch", 1, true) then
    return "WSG"
  end
  if string.find(zone, "arathi basin", 1, true) or string.find(subZone, "arathi basin", 1, true) then
    return "AB"
  end
  if string.find(zone, "alterac valley", 1, true) or string.find(subZone, "alterac valley", 1, true) then
    return "AV"
  end
  return nil
end

function LeafVE_AchTest:HandleBattlegroundSystemMessage(evt, msg)
  local me = ShortName(UnitName("player"))
  if not me then return end
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  local lower = string.lower(msg or "")
  local isWin = false

  if evt == "CHAT_MSG_BG_SYSTEM_ALLIANCE" then
    isWin = (faction == "Alliance") and MessageDeclaresFactionVictory(lower, "alliance")
  elseif evt == "CHAT_MSG_BG_SYSTEM_HORDE" then
    isWin = (faction == "Horde") and MessageDeclaresFactionVictory(lower, "horde")
  elseif evt == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
    if faction == "Alliance" then
      isWin = MessageDeclaresFactionVictory(lower, "alliance")
    elseif faction == "Horde" then
      isWin = MessageDeclaresFactionVictory(lower, "horde")
    end
  end

  if not isWin then return end

  local bgType = ResolveBattlegroundType(msg)
  local now = GetTime and GetTime() or 0
  local signature = tostring(bgType or "BG") .. "|" .. lower
  if now > 0 and lastBattlegroundWinSignature == signature
     and (now - lastBattlegroundWinTime) <= BATTLEGROUND_WIN_DEDUPE_WINDOW then
    return
  end
  lastBattlegroundWinSignature = signature
  lastBattlegroundWinTime = now

  IncrCounter(me, "bgWins")
  if bgType == "WSG" then
    IncrCounter(me, "bgWinsWSG")
  elseif bgType == "AB" then
    IncrCounter(me, "bgWinsAB")
  elseif bgType == "AV" then
    IncrCounter(me, "bgWinsAV")
  end
  CheckBattlegroundAchievementsForPlayer(me)
end

-- ==========================================
-- GUILD SYNC SYSTEM
-- ==========================================

-- Broadcast your achievements to guild
function LeafVE_AchTest:BroadcastAchievements()
  if not IsInGuild() then return end
  
  local me = ShortName(UnitName("player"))
  if not me then return end
  
  local myAchievements = self:GetPlayerAchievements(me)
  
  -- Build compressed achievement list (just IDs and timestamps)
  local achData = {}
  for achID, data in pairs(myAchievements) do
    table.insert(achData, achID..":"..data.timestamp..":"..data.points)
  end
  
  local message = table.concat(achData, ",")
  
  -- Send via addon channel
  if table.getn(achData) > 0 then
    SendAddonMessage(ADDON_COMM_PREFIX, "SYNC:"..message, "GUILD")
    Debug("Broadcast "..table.getn(achData).." achievements to guild")
  else
    Debug("No achievements to broadcast")
  end

  self:BroadcastVersion()
end

function LeafVE_AchTest:BroadcastVersion(targetPlayer)
  local version = GetAddonVersion()
  if not version or version == "" then return end

  if not IsInGuild() then return end
  SendAddonMessage(ADDON_COMM_PREFIX, "VER:"..version, "GUILD")
end

function LeafVE_AchTest:RequestGuildVersions()
  if not IsInGuild() then return end
  SendAddonMessage(ADDON_COMM_PREFIX, "VERREQ", "GUILD")
end

-- Receive other players' achievements (FIXED for Vanilla WoW)
function LeafVE_AchTest:OnAddonMessage(prefix, message, channel, sender)
  if prefix ~= ADDON_COMM_PREFIX then return end
  if channel ~= "GUILD" then return end

  EnsureDB()
  sender = ShortName(sender)
  if not sender then return end

  -- Never overwrite our own achievements from a sync message â€” local data is authoritative
  local me = ShortName(UnitName("player"))
  if sender == me then return end

  Debug("Received addon message from "..sender)

  if message == "VERREQ" then
    self:BroadcastVersion()
    return
  end

  if string.sub(message, 1, 4) == "VER:" then
    local version = Trim(string.sub(message, 5))
    if version ~= "" then
      RecordKnownVersion(sender, version)
      Debug("Stored addon version "..version.." from "..sender)
    end
    return
  end
  -- Parse sync message
  if string.sub(message, 1, 5) == "SYNC:" then
    local achData = string.sub(message, 6)
    
    if not LeafVE_AchTest_DB.achievements[sender] then
      LeafVE_AchTest_DB.achievements[sender] = {}
    end
    
    -- Parse achievement data (Vanilla WoW compatible)
    local achievements = {}
    local startPos = 1
    
    while startPos <= string.len(achData) do
      local commaPos = string.find(achData, ",", startPos)
      local achEntry
      
      if commaPos then
        achEntry = string.sub(achData, startPos, commaPos - 1)
        startPos = commaPos + 1
      else
        achEntry = string.sub(achData, startPos)
        startPos = string.len(achData) + 1
      end
      
      -- Parse individual achievement: "achID:timestamp:points"
      local colonPos1 = string.find(achEntry, ":")
      if colonPos1 then
        local achID = string.sub(achEntry, 1, colonPos1 - 1)
        local colonPos2 = string.find(achEntry, ":", colonPos1 + 1)
        
        if colonPos2 then
          local timestamp = string.sub(achEntry, colonPos1 + 1, colonPos2 - 1)
          local points = string.sub(achEntry, colonPos2 + 1)
          
          achievements[achID] = {
            timestamp = tonumber(timestamp),
            points = tonumber(points)
          }
        end
      end
    end
    
    -- Update stored data for this player
    LeafVE_AchTest_DB.achievements[sender] = achievements
    
    local count = 0
    for _ in pairs(achievements) do count = count + 1 end
    Debug("Stored "..count.." achievements from "..sender)
    
    -- Refresh UI if viewing this player
    if LeafVE and LeafVE.UI and LeafVE.UI.cardCurrentPlayer == sender then
      LeafVE.UI:ShowPlayerCard(sender)
    end
  end
end

-- Register addon message listener
local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("CHAT_MSG_ADDON")
syncFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_ADDON" then
    LeafVE_AchTest:OnAddonMessage(arg1, arg2, arg3, arg4)
  end
end)

-- Auto-broadcast on login and every 5 minutes
local broadcastTimer = 0
local broadcastFrame = CreateFrame("Frame")
broadcastFrame:SetScript("OnUpdate", function()
  broadcastTimer = broadcastTimer + arg1
  if broadcastTimer >= 300 then -- 5 minutes
    broadcastTimer = 0
    LeafVE_AchTest:BroadcastAchievements()
  end
end)

-- Broadcast shortly after login (ONCE only, not on every zone change or addon load)
local loginBroadcast = CreateFrame("Frame")
loginBroadcast:RegisterEvent("PLAYER_ENTERING_WORLD")
loginBroadcast:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    -- Only broadcast on the very first login, not on zone transitions or reloads from other addons
    if LeafVE_AchTest.loginBroadcastDone then return end
    LeafVE_AchTest.loginBroadcastDone = true

    local waitTimer = 0
    this:SetScript("OnUpdate", function()
      waitTimer = waitTimer + arg1
      if waitTimer >= 5 then
        LeafVE_AchTest:BroadcastAchievements()
        this:SetScript("OnUpdate", nil)
        this:UnregisterEvent("PLAYER_ENTERING_WORLD")
      end
    end)
  end
end)

local versionReminderFrame = CreateFrame("Frame")
versionReminderFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
versionReminderFrame:SetScript("OnEvent", function()
  if event ~= "PLAYER_ENTERING_WORLD" then return end
  if LeafVE_AchTest.versionReminderLoginDone then return end
  LeafVE_AchTest.versionReminderLoginDone = true

  local waitTimer = 0
  local requestedVersions = false

  this:SetScript("OnUpdate", function()
    waitTimer = waitTimer + arg1

    if not requestedVersions and waitTimer >= 2 then
      requestedVersions = true
      LeafVE_AchTest:RequestGuildVersions()
    end

    if waitTimer >= 7 then
      LeafVE_AchTest:CheckVersionReminder(false)
      this:SetScript("OnUpdate", nil)
      this:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
  end)
end)

Print("Achievement sync system loaded!")

-- Store original SendChatMessage before hooking
local originalSendChatMessage = SendChatMessage
local originalSetItemRef = SetItemRef

function LeafVE_AchTest:GetPlayerAchievements(playerName)
  EnsureDB()
  playerName = ShortName(playerName or UnitName("player"))
  if not playerName then return {} end
  if not LeafVE_AchTest_DB.achievements[playerName] then
    LeafVE_AchTest_DB.achievements[playerName] = {}
  end
  return LeafVE_AchTest_DB.achievements[playerName]
end

function LeafVE_AchTest:HasAchievement(playerName, achievementID)
  local achievements = self:GetPlayerAchievements(playerName)
  return achievements[achievementID] ~= nil
end

function LeafVE_AchTest:CheckExplorationAchievements(silent, newlyDiscovered)
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  if not LeafVE_AchTest_DB.exploredZones[me] then return end

  local discovered = LeafVE_AchTest_DB.exploredZones[me]
  local soundPlayed = false

  for groupKey, zones in pairs(ZONE_GROUP_ZONES) do
    local achId = GetZoneGroupAchievementId(groupKey)
    local achMeta = ACHIEVEMENTS[achId]
    if achMeta then
      local total = table.getn(zones)
      local found = 0
      local hasNew = false
      for _, z in ipairs(zones) do
        if discovered[z] then
          found = found + 1
        end
        if newlyDiscovered and newlyDiscovered[z] then
          hasNew = true
        end
      end

      if hasNew and not silent then
        for _, z in ipairs(zones) do
          if newlyDiscovered[z] then
            Print('Discovered "'..z..'" - '..found..'/'..total..' Locations for '..achMeta.name)
          end
        end
        if not soundPlayed then
          PlaySound("QUESTCOMPLETED")
          soundPlayed = true
        end
      end

      if found == total and not self:HasAchievement(me, achId) then
        self:AwardAchievement(achId, silent)
      end
    end
  end
end

function LeafVE_AchTest:ShowAchievementPopup(achievementID)
  local achievement = ACHIEVEMENTS[achievementID]
  if not achievement then return end
  
  local popup = CreateFrame("Frame", nil, UIParent)
  popup:SetWidth(320)
  popup:SetHeight(90)
  popup:SetPoint("TOP", UIParent, "TOP", 0, -150)
  popup:SetFrameStrata("HIGH")
  popup:SetAlpha(0)
  
  popup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  popup:SetBackdropColor(0.02, 0.05, 0.07, 0.95)
  popup:SetBackdropBorderColor(0.42, 0.52, 0.30, 1)
  
  local earnedText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  earnedText:SetPoint("TOP", popup, "TOP", 0, -10)
  earnedText:SetText("|cFFFFD433Achievement Earned!|r")
  
  local icon = popup:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(48)
  icon:SetHeight(48)
  icon:SetPoint("LEFT", popup, "LEFT", 15, -5)
  icon:SetTexture(achievement.icon)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  
  local nameText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
  nameText:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
  nameText:SetJustifyH("LEFT")
  nameText:SetText("|cFF2DD35C"..achievement.name.."|r")
  
  local descText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  descText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
  descText:SetPoint("RIGHT", popup, "RIGHT", -10, 0)
  descText:SetJustifyH("LEFT")
  descText:SetText(achievement.desc)
  
  local pointsText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  pointsText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 0)
  pointsText:SetText("|cFFFF7F00+"..achievement.points.." points|r")
  
  local fadeIn = 0
  local stay = 0
  local fadeOut = 0
  
  popup:SetScript("OnUpdate", function()
    if fadeIn < 0.5 then
      fadeIn = fadeIn + arg1
      popup:SetAlpha(fadeIn / 0.5)
    elseif stay < 4 then
      stay = stay + arg1
      popup:SetAlpha(1)
    elseif fadeOut < 0.5 then
      fadeOut = fadeOut + arg1
      popup:SetAlpha(1 - (fadeOut / 0.5))
    else
      popup:SetScript("OnUpdate", nil)
      popup:Hide()
    end
  end)
  
  popup:Show()
  PlaySound("LevelUp")
end

local LEGENDARY_GUILD_MESSAGES = {
  legendary_naked_dungeon = function(name) return name .. " has conquered a dungeon wearing nothing but courage. Henceforth, they shall be known as |cFFFF0000Bare Bones|r!" end,
  legendary_speed_run_brd = function(name) return name .. " blazed through Blackrock Depths in under 30 minutes! The fires of the mountain could not slow them. They have earned the title |cFFFF0000Speed Demon|r!" end,
  legendary_flawless_naxx = function(name) return name .. " led a flawless raid through the halls of Naxxramas â€” not a single soul was lost. They are now |cFFFF0000the Immortal|r!" end,
  legendary_solo_raid_boss = function(name) return name .. " has defeated a raid boss entirely alone. Against all odds, they stand victorious as |cFFFF0000the Unsupported|r!" end,
  legendary_duel_streak_100 = function(name) return name .. " has won 100 consecutive duels without a single defeat. None can challenge them. They are |cFFFF0000the Undefeated|r!" end,
  legendary_full_clear_week = function(name) return name .. " cleared every raid in Azeroth within a single week. No boss was left standing. They are now |cFFFF0000Conqueror of All|r!" end,
  legendary_ironman_60 = function(name) return name .. " reached level 60 without dying a single time. Death itself could not claim them. They are |cFFFF0000the Undying|r!" end,
  legendary_onyxia_10 = function(name) return name .. " slew Onyxia with only 10 heroes at their side. The broodmother falls, and " .. name .. " rises as |cFFFF0000Dragonslayer|r!" end,
  legendary_onyxia_5 = function(name) return name .. " felled Onyxia with a mere 5 adventurers. A feat whispered of in legends. They have earned the title |cFFFF0000Wyrmbane|r!" end,
  legendary_solo_60_boss = function(name) return name .. " walked into a level 60 dungeon alone and walked out victorious. They are |cFFFF0000the One-Man Army|r!" end,
  legendary_no_consumes_t2plus = function(name) return name .. " completed a Tier 2+ raid without a single consumable used by anyone. Pure skill, no potions. They are |cFFFF0000the Pure Mortal|r!" end,
}

local EQUIPPED_ITEM_ACHIEVEMENTS = {
  [11684] = "item_ironfoe_weilder",
  [13262] = "item_ashbringer_weilder",
  [17182] = "item_sulfuras_weilder",
  [17802] = "item_thunderfury_weilder",
  [19019] = "item_thunderfury_weilder",
  [22589] = "item_atiesh_weilder",
  [22630] = "item_atiesh_weilder",
  [22631] = "item_atiesh_weilder",
  [22632] = "item_atiesh_weilder",
  [22737] = "item_atiesh_weilder",
}

local EQUIPPED_ITEM_ACHIEVEMENTS_BY_NAME = {
  ["modrag'zan, heart of the mountain"] = "item_modragzan_heart_of_the_mountain",
}

local EQUIPPED_ITEM_GUILD_MESSAGES = {
  item_ironfoe_weilder = function(name, achLink, titleText)
    return name .. " has defied the odds, walked the forgotten road beneath Blackrock Mountain, and claimed " .. achLink .. ". Henceforth, they shall forever be known as " .. titleText .. "!"
  end,
  item_sulfuras_weilder = function(name, achLink, titleText)
    return name .. " has braved fire, legend, and the will of a Firelord to claim " .. achLink .. ". From this day onward, they shall forever be known as " .. titleText .. "!"
  end,
  item_thunderfury_weilder = function(name, achLink, titleText)
    return name .. " has sought the path less traveled, bound storm to steel, and seized " .. achLink .. ". Let all who hear it know they shall forever be known as " .. titleText .. "!"
  end,
  item_atiesh_weilder = function(name, achLink, titleText)
    return name .. " has reclaimed " .. achLink .. ", a staff spoken of only in reverent whispers. By right of burden and brilliance, they shall forever be known as " .. titleText .. "!"
  end,
  item_ashbringer_weilder = function(name, achLink, titleText)
    return name .. " has stepped into holy myth itself and taken up " .. achLink .. ". The wicked tremble, for they shall forever be known as " .. titleText .. "!"
  end,
  item_modragzan_heart_of_the_mountain = function(name, achLink, titleText)
    return name .. " has wrested " .. achLink .. " from the deep wrath of the mountain and now bears Blackrock's fury in hand. They shall forever be known as " .. titleText .. "!"
  end,
  item_arms_of_thaurissan_big_bonkers = function(name, achLink, titleText)
    return name .. " has united Ironfoe and Modrag'zan, Heart of the Mountain, and claimed " .. achLink .. ". Dark Iron thunder answers both hands, and they shall forever be known as " .. titleText .. "!"
  end,
}

local function NormalizeGrantAchievementId(rawAchId)
  local achId = string.lower(Trim(rawAchId))
  if achId == "" then return "" end
  if ACHIEVEMENTS[achId] then return achId end
  local prefixes = {
    "dung_","raid_","explore_","casual_","elite_",
    "pvp_","gold_","prof_","legendary_","lvl_","item_","quest_","rp_",
  }
  for _, prefix in ipairs(prefixes) do
    local candidate = prefix..achId
    if ACHIEVEMENTS[candidate] then
      return candidate
    end
  end
  return achId
end

local function BuildAdminAchievementOptions()
  local options = {}
  for achId, achData in pairs(ACHIEVEMENTS) do
    table.insert(options, {
      id = achId,
      name = achData and achData.name or achId,
      category = achData and achData.category or "Misc",
    })
  end
  table.sort(options, function(a, b)
    local ac = string.lower(a.category or "")
    local bc = string.lower(b.category or "")
    if ac ~= bc then return ac < bc end
    local an = string.lower(a.name or "")
    local bn = string.lower(b.name or "")
    if an ~= bn then return an < bn end
    return a.id < b.id
  end)
  return options
end

local function GetAchievementRewardTitle(achId)
  for _, titleData in ipairs(TITLES) do
    if titleData.achievement == achId then
      return titleData
    end
  end
  return nil
end

local announcementTitleLookupBuilt = false
local announcementTitlesByName = {}
local announcementAchievementsByName = {}

local function NormalizeAnnouncementLabel(label)
  return string.lower(Trim(tostring(label or "")))
end

local function EnsureAnnouncementLookups()
  if announcementTitleLookupBuilt then return end

  announcementTitlesByName = {}
  for _, titleData in ipairs(TITLES) do
    local key = NormalizeAnnouncementLabel(titleData.name)
    if key ~= "" then
      announcementTitlesByName[key] = titleData
    end
  end

  announcementAchievementsByName = {}
  for achId, achData in pairs(ACHIEVEMENTS) do
    local key = NormalizeAnnouncementLabel(achData and achData.name)
    if key ~= "" then
      announcementAchievementsByName[key] = {id = achId, data = achData}
    end
  end

  announcementTitleLookupBuilt = true
end

local function GetAnnouncementTitleColorHex(titleData)
  if titleData and titleData.legendary then return "ffff0000" end
  if titleData and titleData.guild then return "ff8b4513" end
  return "ffff7f00"
end

local function BuildAnnouncementItemLink(displayText, colorHex)
  if not displayText or displayText == "" then return nil end
  return "|c"..colorHex.."|Hitem:"..LEAFVE_ANNOUNCEMENT_ITEM_ID..":0:0:0|h"..displayText.."|h|r"
end

local function BuildAnnouncementTitleLink(titleData)
  if not titleData then return nil end
  return BuildAnnouncementItemLink(titleData.name, GetAnnouncementTitleColorHex(titleData))
end

local function BuildAnnouncementAchievementLink(achievement)
  if not achievement or not achievement.name then return nil end
  return BuildAnnouncementItemLink("["..achievement.name.."]", "ffffd700")
end

local function ExtractAnnouncementLinkText(text)
  local cleaned = tostring(text or "")
  cleaned = string.gsub(cleaned, "|c%x%x%x%x%x%x%x%x", "")
  cleaned = string.gsub(cleaned, "|r", "")
  local linked = smatch(cleaned, "|H.-|h(.+)|h")
  return linked or cleaned
end

local function ResolveAnnouncementLink(text)
  EnsureAnnouncementLookups()

  local displayText = ExtractAnnouncementLinkText(text)
  if not displayText or displayText == "" then return nil end

  local bracketed = smatch(displayText, "^%[(.+)%]$")
  if bracketed then
    return "achievement", announcementAchievementsByName[NormalizeAnnouncementLabel(bracketed)]
  end

  return "title", announcementTitlesByName[NormalizeAnnouncementLabel(displayText)]
end

local function ShowAnnouncementTooltip(linkText)
  local kind, payload = ResolveAnnouncementLink(linkText)
  if not kind or not payload then return false end

  local tooltip = ItemRefTooltip or GameTooltip
  if not tooltip or not tooltip.AddLine then return false end

  if tooltip.SetOwner then
    if tooltip == GameTooltip then
      tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    else
      tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    end
  end

  tooltip:ClearLines()

  if kind == "title" then
    tooltip:AddLine("|c"..GetAnnouncementTitleColorHex(payload)..payload.name.."|r")
    tooltip:AddLine("LeafVE title", 1.0, 0.82, 0.0)
    tooltip:AddLine("Category: "..(payload.category or "Unknown"), 0.75, 0.75, 0.75)
    tooltip:AddLine(payload.prefix and "Format: Prefix title" or "Format: Suffix title", 0.75, 0.75, 0.75)
    local sourceAchievement = payload.achievement and ACHIEVEMENTS[payload.achievement]
    if sourceAchievement then
      tooltip:AddLine("Unlocked by: "..sourceAchievement.name, 0.5, 1.0, 0.5)
    end
  elseif kind == "achievement" then
    local achData = payload.data
    tooltip:AddLine("|cffffd700["..achData.name.."]|r")
    tooltip:AddLine((achData.category or "Achievement").." achievement", 1.0, 0.82, 0.0)
    if achData.desc and achData.desc ~= "" then
      tooltip:AddLine(achData.desc, 0.95, 0.95, 0.95, 1)
    end
    tooltip:AddLine("Points: "..tostring(achData.points or 0), 0.5, 1.0, 0.5)
    local rewardTitle = GetAchievementRewardTitle(payload.id)
    if rewardTitle then
      tooltip:AddLine("Awards title: "..rewardTitle.name, 1.0, 0.5, 0.0)
    end
  else
    return false
  end

  tooltip:Show()
  return true
end

local function FormatAchievementTitleText(playerName, titleData)
  local titleLink = BuildAnnouncementTitleLink(titleData)
  if titleLink then return titleLink end
  return playerName
end

local function BuildGuildAchievementMessage(playerName, achId, ach)
  local rewardTitle = GetAchievementRewardTitle(achId)
  local currentTitle = LeafVE_AchTest and LeafVE_AchTest.GetCurrentTitle and LeafVE_AchTest:GetCurrentTitle(playerName)
  local titleLink = BuildAnnouncementTitleLink(rewardTitle or currentTitle)
  local achLink = BuildAnnouncementAchievementLink(ach) or ("["..ach.name.."]")

  local me = ShortName(UnitName("player"))
  local earnedByOtherPlayer = ShortName(playerName) ~= me

  if titleLink and earnedByOtherPlayer then
    return playerName.." "..titleLink.." has earned the achievement "..achLink
  end
  if titleLink then
    return titleLink.." has earned the achievement "..achLink
  end
  if earnedByOtherPlayer then
    return playerName.." has earned the achievement "..achLink
  end
  return "has earned the achievement "..achLink
end

function LeafVE_AchTest:AdminGrantAchievement(targetInput, achInput, requireGuildMember)
  local targetText = Trim(targetInput)
  local achId = NormalizeGrantAchievementId(achInput)
  if targetText == "" or achId == "" then
    return false, "Enter a player name and achievement ID."
  end
  local target = ResolveGuildMemberName(targetText)
  if not target then
    if requireGuildMember then
      return false, "Guild member not found: "..targetText
    end
    target = ShortName(targetText)
  end
  if not target or target == "" then
    return false, "Invalid player name."
  end
  local ach = ACHIEVEMENTS[achId]
  if not ach then
    return false, "Unknown achievement ID: "..achId
  end

  local achievements = self:GetPlayerAchievements(target)
  if achievements[achId] then
    return false, target.." already has: "..ach.name
  end
  achievements[achId] = {timestamp = Now(), points = ach.points}

  if IsInGuild and IsInGuild() then
    local guildMsg = BuildGuildAchievementMessage(target, achId, ach)
    if originalSendChatMessage then
      originalSendChatMessage(guildMsg, "GUILD")
    else
      SendChatMessage(guildMsg, "GUILD")
    end
  end

  if LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then
    LeafVE_AchTest.UI:Refresh()
  end

  return true, target, ach
end

function LeafVE_AchTest:AwardAchievement(achievementID, silent)
  local playerName = UnitName("player")
  if not playerName or playerName == "" then return end
  local me = ShortName(playerName)
  if not me or me == "" then return end
  if self:HasAchievement(me, achievementID) then
    return
  end
  local achievement = ACHIEVEMENTS[achievementID]
  if not achievement then return end
  local achievements = self:GetPlayerAchievements(me)
  achievements[achievementID] = {timestamp = Now(), points = achievement.points}
  
  if not silent then
    self:ShowAchievementPopup(achievementID)
    Print("Achievement earned: "..achievement.name.." (+"..achievement.points.." pts)")

    -- Guild announcement â€” achievement name is a clickable hyperlink
    if IsInGuild() then
      local guildMsg = BuildGuildAchievementMessage(me, achievementID, achievement)

      -- Use original SendChatMessage to avoid adding title twice
      if originalSendChatMessage then
        originalSendChatMessage(guildMsg, "GUILD")
      else
        SendChatMessage(guildMsg, "GUILD")
      end

      Debug("Sent guild achievement: "..guildMsg)
    end
  end
  
  if LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then
    LeafVE_AchTest.UI:Refresh()
  end
  
  -- Check if any ach_meta achievements are now fulfilled
  for metaId, metaData in pairs(ACHIEVEMENTS) do
    if metaData.criteria_type == "ach_meta" and metaData.criteria_ids then
      if not self:HasAchievement(me, metaId) then
        local allDone = true
        for _, reqId in ipairs(metaData.criteria_ids) do
          if not self:HasAchievement(me, reqId) then
            allDone = false
            break
          end
        end
        if allDone then
          -- Preserve the caller's notification mode: backlog/login scans must stay silent.
          self:AwardAchievement(metaId, silent)
        end
      end
    end
  end

  -- Notify LeafLegends to refresh if it's open
  if LeafVE and LeafVE.UI and LeafVE.UI.ShowPlayerCard and LeafVE.UI.cardCurrentPlayer then
    LeafVE.UI:ShowPlayerCard(LeafVE.UI.cardCurrentPlayer)
  end

  -- Immediately sync to guild so others see the new achievement without waiting for the 5-minute timer
  -- Silent (backlog) awards on login are already covered by the 5-second login broadcast
  if not silent then
    LeafVE_AchTest:BroadcastAchievements()
  end
end

function LeafVE_AchTest:GetTotalAchievementPoints(playerName)
  local achievements = self:GetPlayerAchievements(playerName)
  local total = 0
  for achID, data in pairs(achievements) do
    local ach = ACHIEVEMENTS[achID]
    if ach then total = total + ach.points end
  end
  return total
end

function LeafVE_AchTest:GetCurrentTitle(playerName)
  EnsureDB()
  playerName = ShortName(playerName or UnitName("player"))
  if not playerName then return nil end
  local titleData = LeafVE_AchTest_DB.selectedTitles[playerName]
  if not titleData then return nil end
  local titleID = titleData
  local asPrefix = false
  if type(titleData) == "table" then
    titleID = titleData.id
    asPrefix = titleData.asPrefix or false
  end
  for _, title in ipairs(TITLES) do
    if title.id == titleID then
      return {id=title.id,name=title.name,achievement=title.achievement,prefix=asPrefix,legendary=title.legendary,guild=title.guild}
    end
  end
  return nil
end

function LeafVE_AchTest:SetTitle(playerName, titleID, usePrefix)
  EnsureDB()
  playerName = ShortName(playerName or UnitName("player"))
  if not playerName then return end
  if not titleID or titleID == "" then return end
  local titleData = nil
  for _, title in ipairs(TITLES) do
    if title.id == titleID then titleData = title break end
  end
  if not titleData then return end
  if self:HasAchievement(playerName, titleData.achievement) then
    LeafVE_AchTest_DB.selectedTitles[playerName] = {id=titleID,asPrefix=usePrefix or false}
    local displayText = usePrefix and (titleData.name.." "..playerName) or (playerName.." "..titleData.name)
    Print("Title set to: |cFFFF7F00"..displayText.."|r")
    if LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then
      LeafVE_AchTest.UI:Refresh()
    end
  else
    Print("You haven't earned that title yet!")
  end
end

function LeafVE_AchTest:RemoveTitle(playerName)
  EnsureDB()
  playerName = ShortName(playerName or UnitName("player"))
  if not playerName then return end
  LeafVE_AchTest_DB.selectedTitles[playerName] = nil
  Print("Title removed.")
  if LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then
    LeafVE_AchTest.UI:Refresh()
  end
end

local LEVEL_MILESTONE_IDS = {
  [10] = "lvl_10",
  [20] = "lvl_20",
  [30] = "lvl_30",
  [40] = "lvl_40",
  [50] = "lvl_50",
  [60] = "lvl_60",
}

local LEVEL_MILESTONE_ORDER = {10, 20, 30, 40, 50, 60}

function LeafVE_AchTest:CheckLevelAchievements(silent, levelOverride, exactOnly)
  local level = tonumber(levelOverride) or UnitLevel("player") or 0
  if exactOnly then
    local achId = LEVEL_MILESTONE_IDS[level]
    if achId then
      self:AwardAchievement(achId, silent)
    end
    return
  end

  for _, milestone in ipairs(LEVEL_MILESTONE_ORDER) do
    if level >= milestone then
      self:AwardAchievement(LEVEL_MILESTONE_IDS[milestone], silent)
    end
  end
end

-- Award all level milestone achievements crossed in the inclusive [fromLevel, toLevel] range.
function LeafVE_AchTest:AwardLevelMilestonesBetween(fromLevel, toLevel, silent)
  local a = tonumber(fromLevel) or 0
  local b = tonumber(toLevel) or 0
  if b < a then return end
  for _, milestone in ipairs(LEVEL_MILESTONE_ORDER) do
    if milestone >= a and milestone <= b then
      local achId = LEVEL_MILESTONE_IDS[milestone]
      if achId then
        self:AwardAchievement(achId, silent)
      end
    end
  end
end

local function UpdateLifetimeGoldForPlayer(me)
  EnsureDB()
  if not me then return 0 end

  local current = math.floor((GetMoney and GetMoney() or 0) / 10000)
  local total = LeafVE_AchTest_DB.goldEarnedTotal[me] or 0
  local last = LeafVE_AchTest_DB.goldLastSeen[me]
  local peak = LeafVE_AchTest_DB.peakGold[me] or 0

  -- Backward compatibility with old peak-wallet tracking.
  if total < peak then total = peak end
  if total == 0 and current > 0 then total = current end

  -- Lifetime accumulation: only add positive deltas from last seen wallet value.
  if last ~= nil and current > last then
    total = total + (current - last)
  end

  LeafVE_AchTest_DB.goldLastSeen[me] = current
  LeafVE_AchTest_DB.goldEarnedTotal[me] = total

  if current > peak then
    LeafVE_AchTest_DB.peakGold[me] = current
  end

  return total
end

function LeafVE_AchTest:CheckGoldAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  local earned = UpdateLifetimeGoldForPlayer(me)
  if earned >= 10   then self:AwardAchievement("gold_10",   silent) end
  if earned >= 100  then self:AwardAchievement("gold_100",  silent) end
  if earned >= 500  then self:AwardAchievement("gold_500",  silent) end
  if earned >= 1000 then self:AwardAchievement("gold_1000", silent) end
  if earned >= 5000 then self:AwardAchievement("gold_5000", silent) end
  if earned >= 50000 then self:AwardAchievement("gold_50000", silent) end
end

function LeafVE_AchTest:CheckRunMilestoneAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  local p = LeafVE_AchTest_DB.progressCounters[me] or {}
  local dungeonRuns = p.dungeonRuns or 0
  local raidRuns = p.raidRuns or 0

  if dungeonRuns >= 50  then self:AwardAchievement("elite_50_dungeons", silent) end
  if dungeonRuns >= 100 then self:AwardAchievement("elite_100_dungeons", silent) end
  if dungeonRuns >= 250 then self:AwardAchievement("elite_250_dungeons", silent) end
  if dungeonRuns >= 500 then self:AwardAchievement("elite_500_dungeons", silent) end

  if raidRuns >= 25  then self:AwardAchievement("elite_25_raids", silent) end
  if raidRuns >= 50  then self:AwardAchievement("elite_50_raids", silent) end
  if raidRuns >= 100 then self:AwardAchievement("elite_100_raids", silent) end
  if raidRuns >= 250 then self:AwardAchievement("elite_250_raids", silent) end
end

-- Re-evaluate all progress-based achievements from persisted counters/API values.
-- This catches achievements that should have been awarded in prior sessions even
-- if a specific live event was missed.
function LeafVE_AchTest:CheckCachedProgressAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  for achId in pairs(ACHIEVEMENT_PROGRESS_DEF) do
    local p = GetAchievementProgress(me, achId)
    if p and p.current and p.goal and p.current >= p.goal then
      self:AwardAchievement(achId, silent)
    end
  end
end

local function GetItemIdFromLink(link)
  local itemId = smatch(link or "", "item:(%d+)")
  if itemId then return tonumber(itemId) end
  return nil
end

local function GetItemNameFromLink(link)
  return smatch(link or "", "%[(.-)%]")
end

function LeafVE_AchTest:CheckEquipmentAchievements(silent)
  if not GetInventoryItemLink then return end
  local awarded = {}
  for slot = 1, 19 do
    local link = GetInventoryItemLink("player", slot)
    local itemId = GetItemIdFromLink(link)
    local achId = itemId and EQUIPPED_ITEM_ACHIEVEMENTS[itemId]
    if not achId then
      local itemName = GetItemNameFromLink(link)
      achId = itemName and EQUIPPED_ITEM_ACHIEVEMENTS_BY_NAME[string.lower(itemName)]
    end
    if achId and not awarded[achId] then
      awarded[achId] = true
      self:AwardAchievement(achId, silent)
    end
  end
end

LeafVE_AchTest.UI = {}
LeafVE_AchTest.UI.currentView = "achievements"
LeafVE_AchTest.UI.selectedCategory = "All"
LeafVE_AchTest.UI.searchText = ""
LeafVE_AchTest.UI.titleSearchText = ""
LeafVE_AchTest.UI.titleCategoryFilter = "All"

-- Boss kill tracking: raid bosses only â€” dungeon bosses are tracked via BOSS_TO_DUNGEON
local BOSS_ACHIEVEMENTS = {
  -- Dungeon bosses with standalone achievements
  ["Princess Theradras"] = "dung_mara_princess",
  -- Molten Core
  ["Incindis"] = "raid_mc_incindis",
  ["Lucifron"] = "raid_mc_lucifron",
  ["Magmadar"] = "raid_mc_magmadar",
  ["Gehennas"] = "raid_mc_gehennas",
  ["Garr"] = "raid_mc_garr",
  ["Baron Geddon"] = "raid_mc_geddon",
  ["Shazzrah"] = "raid_mc_shazzrah",
  ["Sulfuron Harbinger"] = "raid_mc_sulfuron",
  ["Golemagg the Incinerator"] = "raid_mc_golemagg",
  ["Basalthar"] = "raid_mc_twins",
  ["Sorcerer-Thane Thaurissan"] = "raid_mc_sorcerer",
  ["Majordomo Executus"] = "raid_mc_majordomo",
  ["Ragnaros"] = "raid_mc_ragnaros",
  -- Onyxia
  ["Onyxia"] = "raid_onyxia",
  -- Blackwing Lair
  ["Razorgore the Untamed"] = "raid_bwl_razorgore",
  ["Vaelastrasz the Corrupt"] = "raid_bwl_vaelastrasz",
  ["Broodlord Lashlayer"] = "raid_bwl_broodlord",
  ["Firemaw"] = "raid_bwl_firemaw",
  ["Ebonroc"] = "raid_bwl_ebonroc",
  ["Flamegor"] = "raid_bwl_flamegor",
  ["Chromaggus"] = "raid_bwl_chromaggus",
  ["Nefarian"] = "raid_bwl_nefarian",
  -- Zul'Gurub
  ["High Priest Venoxis"] = "raid_zg_venoxis",
  ["High Priestess Jeklik"] = "raid_zg_jeklik",
  ["High Priestess Mar'li"] = "raid_zg_marli",
  ["Bloodlord Mandokir"] = "raid_zg_mandokir",
  ["Gri'lek"] = "raid_zg_grilek",
  ["Hazza'rah"] = "raid_zg_hazzarah",
  ["Renataki"] = "raid_zg_renataki",
  ["Wushoolay"] = "raid_zg_wushoolay",
  ["Gahz'ranka"] = "raid_zg_gahzranka",
  ["High Priest Thekal"] = "raid_zg_thekal",
  ["High Priestess Arlokk"] = "raid_zg_arlokk",
  ["Jin'do the Hexxer"] = "raid_zg_jindo",
  ["Hakkar"] = "raid_zg_hakkar",
  -- AQ20
  ["Kurinnaxx"] = "raid_aq20_kurinnaxx",
  ["General Rajaxx"] = "raid_aq20_rajaxx",
  ["Moam"] = "raid_aq20_moam",
  ["Buru the Gorger"] = "raid_aq20_buru",
  ["Ayamiss the Hunter"] = "raid_aq20_ayamiss",
  ["Ossirian the Unscarred"] = "raid_aq20_ossirian",
  -- AQ40
  ["The Prophet Skeram"] = "raid_aq40_skeram",
  ["Lord Kri"] = "raid_aq40_bug_trio",
  ["Princess Yauj"] = "raid_aq40_bug_trio",
  ["Vem"] = "raid_aq40_bug_trio",
  ["Battleguard Sartura"] = "raid_aq40_sartura",
  ["Fankriss the Unyielding"] = "raid_aq40_fankriss",
  ["Viscidus"] = "raid_aq40_viscidus",
  ["Princess Huhuran"] = "raid_aq40_huhuran",
  ["Emperor Vek'lor"] = "raid_aq40_twins",
  ["Ouro"] = "raid_aq40_ouro",
  ["C'Thun"] = "raid_aq40_cthun",
  -- Naxxramas
  ["Anub'Rekhan"] = "raid_naxx_anubrekhan",
  ["Grand Widow Faerlina"] = "raid_naxx_faerlina",
  ["Maexxna"] = "raid_naxx_maexxna",
  ["Noth the Plaguebringer"] = "raid_naxx_noth",
  ["Heigan the Unclean"] = "raid_naxx_heigan",
  ["Loatheb"] = "raid_naxx_loatheb",
  ["Instructor Razuvious"] = "raid_naxx_razuvious",
  ["Gothik the Harvester"] = "raid_naxx_gothik",
  ["Highlord Mograine"] = "raid_naxx_four_horsemen",
  ["Thane Korth'azz"] = "raid_naxx_four_horsemen",
  ["Lady Blaumeux"] = "raid_naxx_four_horsemen",
  ["Sir Zeliek"] = "raid_naxx_four_horsemen",
  ["Patchwerk"] = "raid_naxx_patchwerk",
  ["Grobbulus"] = "raid_naxx_grobbulus",
  ["Gluth"] = "raid_naxx_gluth",
  ["Thaddius"] = "raid_naxx_thaddius",
  ["Sapphiron"] = "raid_naxx_sapphiron",
  ["Kel'Thuzad"] = "raid_naxx_kelthuzad",
  -- Emerald Sanctum (Turtle WoW)
  ["Erennius"] = "raid_es_erennius",
  ["Solnius the Awakener"] = "raid_es_solnius",
  -- Lower Karazhan Halls (Turtle WoW)
  ["Master Blacksmith Rolfen"] = "raid_lkh_rolfen",
  ["Brood Queen Araxxna"] = "raid_lkh_araxxna",
  ["Grizikil"] = "raid_lkh_grizikil",
  ["Clawlord Howlfang"] = "raid_lkh_howlfang",
  ["Lord Blackwald II"] = "raid_lkh_blackwald",
  ["Moroes"] = "raid_lkh_moroes",
  -- Upper Karazhan Halls (Turtle WoW)
  ["Keeper Gnarlmoon"] = "raid_ukh_gnarlmoon",
  ["Ley-Watcher Incantagos"] = "raid_ukh_incantagos",
  ["Anomalus"] = "raid_ukh_anomalus",
  ["Echo of Medivh"] = "raid_ukh_echo",
  ["King"] = "raid_ukh_king",
  ["Sanv Tas'dal"] = "raid_ukh_sanvtas",
  ["Kruul"] = "raid_ukh_kruul",
  ["Rupturan the Broken"] = "raid_ukh_rupturan",
  ["Mephistroth"] = "raid_ukh_mephistroth",
}

-- ==========================================
-- BOSS TRACKING & BACKLOG LOGIC
-- ==========================================

-- Record a dungeon boss kill and award completion if all bosses done
function LeafVE_AchTest:RecordDungeonBoss(bossName)
  local dungId = BOSS_TO_DUNGEON[bossName]
  if not dungId then return end
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  local dp = LeafVE_AchTest_DB.dungeonProgress
  if not dp[me] then dp[me] = {} end
  if not dp[me][dungId] then dp[me][dungId] = {} end
  if not dp[me][dungId][bossName] then
    dp[me][dungId][bossName] = Now()
    Debug("Dungeon boss: "..bossName.." ("..dungId..")")
    local achId = "dung_"..dungId.."_complete"
    if ACHIEVEMENTS[achId] and not self:HasAchievement(me, achId) then
      local allDone = true
      for _, req in ipairs(DUNGEON_BOSSES[dungId]) do
        if not dp[me][dungId][req] then allDone = false; break end
      end
      if allDone then
        self:AwardAchievement(achId)
        -- Count completed dungeon runs for run-count achievements
    local runTotal = IncrCounter(me, "dungeonRuns")
    if runTotal >= 50  then self:AwardAchievement("elite_50_dungeons")  end
    if runTotal >= 100 then self:AwardAchievement("elite_100_dungeons") end
    if runTotal >= 250 then self:AwardAchievement("elite_250_dungeons") end
    if runTotal >= 500 then self:AwardAchievement("elite_500_dungeons") end
    self:CheckMetaAchievements()
      end
    end
  end
end

-- Record a raid boss kill and award completion if all bosses done
function LeafVE_AchTest:RecordRaidBoss(bossName)
  local raidId = BOSS_TO_RAID[bossName]
  if not raidId then return end
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  local rp = LeafVE_AchTest_DB.raidProgress
  if not rp[me] then rp[me] = {} end
  if not rp[me][raidId] then rp[me][raidId] = {} end
  if not rp[me][raidId][bossName] then
    rp[me][raidId][bossName] = Now()
    local achId = "raid_"..raidId.."_complete"
    if ACHIEVEMENTS[achId] and not self:HasAchievement(me, achId) then
      local allDone = true
      for _, req in ipairs(RAID_BOSSES[raidId]) do
        if not rp[me][raidId][req] then allDone = false; break end
      end
      if allDone then
        self:AwardAchievement(achId)
        -- Count completed raid runs for run-count achievements
    local runTotal = IncrCounter(me, "raidRuns")
    if runTotal >= 25 then self:AwardAchievement("elite_25_raids") end
    if runTotal >= 50 then self:AwardAchievement("elite_50_raids") end
    if runTotal >= 100 then self:AwardAchievement("elite_100_raids") end
    if runTotal >= 250 then self:AwardAchievement("elite_250_raids") end
    self:CheckMetaAchievements()
      end
    end
  end
end

-- Backlog: check all stored kill progress on login and award any completions earned.
-- Also scans LeafVE_DB.pointHistory for "Instance completion: <Zone>" entries so that
-- dungeons cleared before the achievement addon was installed are retroactively credited.
function LeafVE_AchTest:CheckBacklogAchievements()
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  local dp = LeafVE_AchTest_DB.dungeonProgress
  local rp = LeafVE_AchTest_DB.raidProgress
  if dp and dp[me] then
    for dungId, killed in pairs(dp[me]) do
      local achId = "dung_"..dungId.."_complete"
      if ACHIEVEMENTS[achId] and not self:HasAchievement(me, achId) then
        local bossList = DUNGEON_BOSSES[dungId]
        if bossList then
          local allDone = true
          for _, b in ipairs(bossList) do
            if not killed[b] then allDone = false; break end
          end
          if allDone then self:AwardAchievement(achId, true) end
        end
      end
    end
  end
  if rp and rp[me] then
    for raidId, killed in pairs(rp[me]) do
      local achId = "raid_"..raidId.."_complete"
      if ACHIEVEMENTS[achId] and not self:HasAchievement(me, achId) then
        local bossList = RAID_BOSSES[raidId]
        if bossList then
          local allDone = true
          for _, b in ipairs(bossList) do
            if not killed[b] then allDone = false; break end
          end
          if allDone then self:AwardAchievement(achId, true) end
        end
      end
    end
  end

  -- Re-check meta achievements based on what has been awarded so far
  self:CheckMetaAchievements(true)

  -- Scan LeafVE_DB point history for previously tracked instance completions.
  -- If LeafVillageLegends recorded "Instance completion: <Zone>", credit the
  -- corresponding dungeon clear achievement (the run was validated by that addon).
  if LeafVE_DB and LeafVE_DB.pointHistory and LeafVE_DB.pointHistory[me] then
    for _, entry in ipairs(LeafVE_DB.pointHistory[me]) do
      local zone = entry.reason and smatch(entry.reason, "^Instance completion: (.+)$")
      if zone then
        local achId = ZONE_TO_DUNGEON_ACH[zone]
        if achId and ACHIEVEMENTS[achId] and not self:HasAchievement(me, achId) then
          self:AwardAchievement(achId, true)
          Debug("Backlog from history: "..achId.." ("..zone..")")
        end
      end
    end
  end
end

-- Backlog: check profession skill levels via API and award any earned achievements
function LeafVE_AchTest:CheckProfessionAchievements(silent)
  local profMap = {
    ["Alchemy"]       = "prof_alchemy_300",
    ["Blacksmithing"] = "prof_blacksmithing_300",
    ["Enchanting"]    = "prof_enchanting_300",
    ["Engineering"]   = "prof_engineering_300",
    ["Herbalism"]     = "prof_herbalism_300",
    ["Leatherworking"]= "prof_leatherworking_300",
    ["Mining"]        = "prof_mining_300",
    ["Skinning"]      = "prof_skinning_300",
    ["Tailoring"]     = "prof_tailoring_300",
    ["Fishing"]       = "prof_fishing_300",
    ["Cooking"]       = "prof_cooking_300",
    ["First Aid"]     = "prof_firstaid_300",
  }
  local artisanCount = 0
  local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
  for i = 1, numSkills do
    local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
    if skillName and not isHeader then
      local achId = profMap[skillName]
      if achId then
        Debug("Found profession: "..skillName.." at rank "..tostring(skillRank))
        if skillRank and skillRank >= 300 then
          self:AwardAchievement(achId, silent)
          artisanCount = artisanCount + 1
        end
      end
    end
  end
  if artisanCount >= 2 then
    self:AwardAchievement("prof_dual_artisan", silent)
  end
end

-- Maps boss name to a safe counter key used in progressCounters
local BOSS_KILL_COUNTER = {
  ["Ragnaros"]            = "boss_Ragnaros",
  ["Nefarian"]            = "boss_Nefarian",
  ["Kel'Thuzad"]          = "boss_KelThuzad",
  ["C'Thun"]              = "boss_CThun",
  ["General Drakkisath"]  = "boss_Drakkisath",
  ["Darkmaster Gandling"] = "boss_Gandling",
  ["Baron Rivendare"]     = "boss_BaronRiv",
  ["Onyxia"]              = "boss_Onyxia",
  ["Hakkar"]              = "boss_Hakkar",
}

-- All raid completion achievement IDs â€” used by the meta achievement check
local ALL_RAID_COMPLETE_IDS = {
  "raid_zg_complete","raid_aq20_complete","raid_mc_complete","raid_onyxia_complete",
  "raid_bwl_complete","raid_aq40_complete","raid_naxx_complete",
  "raid_es_complete","raid_lkh_complete","raid_ukh_complete",
}
-- All dungeon completion achievement IDs â€” used by the meta achievement check
local ALL_DUNGEON_COMPLETE_IDS = {
  "dung_rfc_complete","dung_wc_complete","dung_dm_complete","dung_sfk_complete",
  "dung_bfd_complete","dung_stocks_complete","dung_tcg_complete","dung_gnomer_complete",
  "dung_rfk_complete","dung_sm_gy_complete","dung_sm_lib_complete","dung_sm_arm_complete",
  "dung_sm_cat_complete","dung_swr_complete","dung_rfdown_complete","dung_ulda_complete",
  "dung_gc_complete","dung_mara_complete","dung_zf_complete","dung_st_complete",
  "dung_hq_complete","dung_brd_complete","dung_dme_complete","dung_dmw_complete",
  "dung_dmn_complete","dung_scholo_complete","dung_strat_complete","dung_lbrs_complete",
  "dung_ubrs_complete","dung_kc_complete","dung_cotbm_complete","dung_swv_complete",
  "dung_dmr_complete",
}

function LeafVE_AchTest:CheckMetaAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end
  local allRaids = true
  for _, id in ipairs(ALL_RAID_COMPLETE_IDS) do
    if not self:HasAchievement(me, id) then allRaids = false; break end
  end
  if allRaids then self:AwardAchievement("elite_all_raids_complete", silent) end
  local allDungeons = true
  for _, id in ipairs(ALL_DUNGEON_COMPLETE_IDS) do
    if not self:HasAchievement(me, id) then allDungeons = false; break end
  end
  if allDungeons then self:AwardAchievement("elite_all_dungeons_complete", silent) end
end

-- Re-check all achievement-meta chains (criteria_type="ach_meta") from persisted data.
-- This ensures newly added meta achievements award immediately on login when requirements
-- were completed in earlier sessions.
function LeafVE_AchTest:CheckAchievementMetaAchievements(silent)
  local me = ShortName(UnitName("player"))
  if not me then return end

  for achId, achData in pairs(ACHIEVEMENTS) do
    if achData.criteria_type == "ach_meta" and achData.criteria_ids and not self:HasAchievement(me, achId) then
      local allDone = true
      for _, reqId in ipairs(achData.criteria_ids) do
        if not self:HasAchievement(me, reqId) then
          allDone = false
          break
        end
      end
      if allDone then
        self:AwardAchievement(achId, silent)
      end
    end
  end
end

function LeafVE_AchTest:CheckBossKill(bossName)
  local group = BOSS_GROUP_ALIASES[bossName]
  if group then
    for _, groupedBossName in ipairs(group) do
      self:CheckBossKill(groupedBossName)
    end
    return
  end

  local resolvedBossName = ResolveBossName(bossName)
  -- Ignore regular elite mobs that are not tracked bosses
  if not resolvedBossName then return end
  -- Award individual raid boss achievement if mapped
  if BOSS_ACHIEVEMENTS[resolvedBossName] then
    Debug("Raid boss kill: "..resolvedBossName)
    self:AwardAchievement(BOSS_ACHIEVEMENTS[resolvedBossName])
  end
  -- Track dungeon progress (awards completion when all bosses done)
  self:RecordDungeonBoss(resolvedBossName)
  -- Track raid progress (awards completion when all bosses done)
  self:RecordRaidBoss(resolvedBossName)
  -- Track per-boss, total, and unique kill counts
  local me = ShortName(UnitName("player"))
  if me then
    -- Per-boss counter for repeat-kill achievements
    local bossCounter = BOSS_KILL_COUNTER[resolvedBossName]
    if bossCounter then
      local n = IncrCounter(me, bossCounter)
      if bossCounter == "boss_Ragnaros" then
        if n >= 5  then self:AwardAchievement("elite_rag_5x")  end
        if n >= 10 then self:AwardAchievement("elite_rag_10x") end
      elseif bossCounter == "boss_Nefarian" then
        if n >= 5  then self:AwardAchievement("elite_nef_5x")  end
        if n >= 10 then self:AwardAchievement("elite_nef_10x") end
      elseif bossCounter == "boss_KelThuzad" then
        if n >= 3 then self:AwardAchievement("elite_kt_3x") end
        if n >= 5 then self:AwardAchievement("elite_kt_5x") end
      elseif bossCounter == "boss_CThun" then
        if n >= 5 then self:AwardAchievement("elite_cthun_5x") end
      elseif bossCounter == "boss_Drakkisath" then
        if n >= 5 then self:AwardAchievement("elite_drakkisath_5x") end
      elseif bossCounter == "boss_Gandling" then
        if n >= 5 then self:AwardAchievement("elite_gandling_5x") end
      elseif bossCounter == "boss_BaronRiv" then
        if n >= 5 then self:AwardAchievement("elite_baron_5x") end
      elseif bossCounter == "boss_Onyxia" then
        if n >= 5  then self:AwardAchievement("elite_onyxia_5x")  end
        if n >= 10 then self:AwardAchievement("elite_onyxia_10x") end
      elseif bossCounter == "boss_Hakkar" then
        if n >= 5 then self:AwardAchievement("elite_hakkar_5x") end
      end
    end
    -- Total boss kills
    local total = IncrCounter(me, "totalBossKills")
    if total >= 100 then self:AwardAchievement("elite_100_bosses") end
    if total >= 250 then self:AwardAchievement("elite_250_bosses") end
    if total >= 500 then self:AwardAchievement("elite_500_bosses") end
    -- Unique boss kills (first kill of each boss name)
    EnsureDB()
    local pc = LeafVE_AchTest_DB.progressCounters
    if not pc[me] then pc[me] = {} end
    local killedKey = "killed_"..string.gsub(resolvedBossName, "[^%w]", "_")
    if not pc[me][killedKey] then
      pc[me][killedKey] = true
      local unique = IncrCounter(me, "uniqueBossKills")
      if unique >= 25 then self:AwardAchievement("elite_25_unique_bosses") end
      if unique >= 50 then self:AwardAchievement("elite_50_unique_bosses") end
      if unique >= 100 then self:AwardAchievement("elite_100_unique_bosses") end
    end
  end
end

-- Virtual-scroll constants for the achievement list.
-- ACH_ROW_H: pixel height of each achievement row.
-- ACH_POOL:  number of recycled frame slots (covers visible area + buffer).
local ACH_ROW_H = 85
local ACH_POOL  = 14

-- Create one unstyled achievement row frame attached to `parent`.
local function CreateAchievementRow(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetWidth(690)
  frame:SetHeight(80)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2}
  })
  frame:SetBackdropColor(0.08, 0.07, 0.06, 0.96)
  frame:SetBackdropBorderColor(0.34, 0.28, 0.20, 0.92)
  local rowBg = frame:CreateTexture(nil, "BACKGROUND")
  rowBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
  rowBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
  rowBg:SetTexture(TEX.parchmentH)
  rowBg:SetVertexColor(0.92, 0.90, 0.86, 0.94)
  frame.rowBg = rowBg
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(48)
  icon:SetHeight(48)
  icon:SetPoint("LEFT", frame, "LEFT", 8, 0)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  frame.icon = icon
  local iconFrame = frame:CreateTexture(nil, "OVERLAY")
  iconFrame:SetWidth(56)
  iconFrame:SetHeight(56)
  iconFrame:SetPoint("CENTER", icon, "CENTER", 0, 0)
  iconFrame:SetTexture(TEX.iconFrame)
  iconFrame:SetVertexColor(1, 1, 1, 0.95)
  frame.iconFrame = iconFrame
  local checkmark = frame:CreateTexture(nil, "OVERLAY")
  checkmark:SetWidth(20)
  checkmark:SetHeight(20)
  checkmark:SetPoint("CENTER", icon, "TOPRIGHT", -2, -2)
  checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  frame.checkmark = checkmark
  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -5)
  name:SetWidth(490)
  name:SetJustifyH("LEFT")
  frame.name = name
  local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
  desc:SetWidth(490)
  desc:SetJustifyH("LEFT")
  frame.desc = desc
  local emblem = frame:CreateTexture(nil, "ARTWORK")
  emblem:SetWidth(56)
  emblem:SetHeight(56)
  emblem:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
  emblem:SetTexture("Interface\\Icons\\Spell_Nature_ResistNature")
  emblem:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  frame.emblem = emblem
  local points = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  points:SetPoint("CENTER", emblem, "CENTER", 0, 0)
  frame.points = points
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function()
    local ad = this.achData
    local me = this.achPlayerName
    if not ad then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if this.achCompleted then
      GameTooltip:SetText(ad.name, THEME.leaf[1], THEME.leaf[2], THEME.leaf[3], 1, true)
      GameTooltip:AddLine("|cFF888888"..ad.category.."|r", 1, 1, 1)
      GameTooltip:AddLine(ad.desc, 1, 1, 1, true)
      GameTooltip:AddLine(" ", 1, 1, 1)
      GameTooltip:AddLine("Earned: "..date("%m/%d/%Y", this.achTimestamp), 0.5, 0.8, 0.5)
    else
      GameTooltip:SetText(ad.name, 0.6, 0.6, 0.6, 1, true)
      GameTooltip:AddLine("|cFF888888"..ad.category.."|r", 1, 1, 1)
      GameTooltip:AddLine(ad.desc, 0.7, 0.7, 0.7, true)
      GameTooltip:AddLine(" ", 1, 1, 1)
      local prog = GetAchievementProgress(me, ad.id)
      if prog then
        GameTooltip:AddLine(string.format("Progress: %d / %d", prog.current, prog.goal), 0.6, 0.8, 1.0)
      end
      if ad.manual then
        GameTooltip:AddLine("|cFFFF8800Requires officer grant: /achgrant <name> "..ad.id.."|r", 1, 1, 1, true)
      else
        GameTooltip:AddLine("Not yet earned", 0.8, 0.4, 0.4)
      end
    end
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine(ad.points.." Achievement Points", 1.0, 0.5, 0.0)
    -- â”€â”€ Dungeon / Raid boss criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad.criteria_key and (ad.criteria_type == "dungeon" or ad.criteria_type == "raid") then
      local bossList, progress
      if ad.criteria_type == "dungeon" then
        bossList = DUNGEON_BOSSES[ad.criteria_key]
        local dp = LeafVE_AchTest_DB and LeafVE_AchTest_DB.dungeonProgress
        progress = dp and dp[me] and dp[me][ad.criteria_key]
      elseif ad.criteria_type == "raid" then
        bossList = RAID_BOSSES[ad.criteria_key]
        local rp = LeafVE_AchTest_DB and LeafVE_AchTest_DB.raidProgress
        progress = rp and rp[me] and rp[me][ad.criteria_key]
      end
      if bossList then
        local killed, total = 0, table.getn(bossList)
        GameTooltip:AddLine(" ", 1, 1, 1)
        for _, bossName in ipairs(bossList) do
          if progress and progress[bossName] then
            killed = killed + 1
            GameTooltip:AddLine("|cFF00CC00[x]|r "..bossName, 0.9, 0.9, 0.9)
          else
            GameTooltip:AddLine("|cFF666666[ ]|r "..bossName, 0.5, 0.5, 0.5)
          end
        end
        GameTooltip:AddLine(string.format("Criteria: %d / %d bosses", killed, total), 1.0, 0.82, 0.2)
      end
    end
    -- â”€â”€ Dungeon Completionist meta criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad.criteria_type == "dungeon_meta" then
      local done, total = 0, table.getn(ALL_DUNGEON_COMPLETE_IDS)
      GameTooltip:AddLine(" ", 1, 1, 1)
      for _, dachId in ipairs(ALL_DUNGEON_COMPLETE_IDS) do
        local dach = ACHIEVEMENTS[dachId]
        if dach then
          if LeafVE_AchTest:HasAchievement(me, dachId) then
            done = done + 1
            GameTooltip:AddLine("|cFF00CC00[x]|r "..dach.name, 0.9, 0.9, 0.9)
          else
            GameTooltip:AddLine("|cFF666666[ ]|r "..dach.name, 0.5, 0.5, 0.5)
          end
        end
      end
      GameTooltip:AddLine(string.format("Criteria: %d / %d dungeons", done, total), 1.0, 0.82, 0.2)
    end
    -- â”€â”€ Raid Completionist meta criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad.criteria_type == "raid_meta" then
      local done, total = 0, table.getn(ALL_RAID_COMPLETE_IDS)
      GameTooltip:AddLine(" ", 1, 1, 1)
      for _, rachId in ipairs(ALL_RAID_COMPLETE_IDS) do
        local rach = ACHIEVEMENTS[rachId]
        if rach then
          if LeafVE_AchTest:HasAchievement(me, rachId) then
            done = done + 1
            GameTooltip:AddLine("|cFF00CC00[x]|r "..rach.name, 0.9, 0.9, 0.9)
          else
            GameTooltip:AddLine("|cFF666666[ ]|r "..rach.name, 0.5, 0.5, 0.5)
          end
        end
      end
      GameTooltip:AddLine(string.format("Criteria: %d / %d raids", done, total), 1.0, 0.82, 0.2)
    end
    -- â”€â”€ Zone-group exploration criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad.criteria_type == "zone_group" and ad.criteria_key then
      local zones = ZONE_GROUP_ZONES[ad.criteria_key]
      if zones then
        local pz = LeafVE_AchTest_DB and LeafVE_AchTest_DB.exploredZones
        local myZones = pz and pz[me]
        local found, total = 0, table.getn(zones)
        GameTooltip:AddLine(" ", 1, 1, 1)
        for _, z in ipairs(zones) do
          if myZones and myZones[z] then
            found = found + 1
            GameTooltip:AddLine("|cFF00CC00[x]|r "..z, 0.9, 0.9, 0.9)
          else
            GameTooltip:AddLine("|cFF666666[ ]|r "..z, 0.5, 0.5, 0.5)
          end
        end
        GameTooltip:AddLine(string.format("Discovered: %d / %d locations", found, total), 1.0, 0.82, 0.2)
      end
    end
    -- â”€â”€ Quest chain step criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad._questSteps then
      local cq = LeafVE_AchTest_DB and LeafVE_AchTest_DB.completedQuests
      local myQ = cq and cq[me]
      local done, total = 0, 0
      local normalizeQuestKey = LeafVE_AchTest and LeafVE_AchTest.NormalizeQuestStepKey
      GameTooltip:AddLine(" ", 1, 1, 1)
      for _, step in ipairs(ad._questSteps) do
        local stepName = step
        local needed = 1
        if type(step) == "table" then
          stepName = step.name or step[1]
          needed = tonumber(step.count) or tonumber(step.required) or 1
          if needed < 1 then needed = 1 end
        end
        if type(stepName) == "string" and stepName ~= "" then
          local key = normalizeQuestKey and normalizeQuestKey(stepName) or string.lower(stepName)
          local stepDone = 0
          local v = myQ and key and myQ[key]
          if type(v) == "number" then
            stepDone = v
          elseif v then
            stepDone = 1
          end
          if stepDone <= 0 and myQ then
            -- Backward compatibility for pre-normalized quest keys.
            local legacy = myQ[string.lower(stepName)]
            if type(legacy) == "number" then
              stepDone = legacy
            elseif legacy then
              stepDone = 1
            end
          end

          local contribution = stepDone
          if contribution > needed then contribution = needed end
          done = done + contribution
          total = total + needed

          local label = stepName
          if needed > 1 then
            label = string.format("%s (%d/%d)", stepName, contribution, needed)
          end

          if stepDone >= needed then
            GameTooltip:AddLine("|cFF00CC00[x]|r "..label, 0.9, 0.9, 0.9)
          else
            GameTooltip:AddLine("|cFF666666[ ]|r "..label, 0.5, 0.5, 0.5)
          end
        end
      end
      GameTooltip:AddLine(string.format("Progress: %d / %d quests", done, total), 1.0, 0.82, 0.2)
    end
    -- â”€â”€ Achievement meta criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if ad.criteria_type == "ach_meta" and ad.criteria_ids then
      local done, total = 0, table.getn(ad.criteria_ids)
      GameTooltip:AddLine(" ", 1, 1, 1)
      for _, reqId in ipairs(ad.criteria_ids) do
        local reqAch = ACHIEVEMENTS[reqId]
        local reqName = reqAch and reqAch.name or reqId
        if LeafVE_AchTest:HasAchievement(me, reqId) then
          done = done + 1
          GameTooltip:AddLine("|cFF00CC00[x]|r "..reqName, 0.9, 0.9, 0.9)
        else
          GameTooltip:AddLine("|cFF666666[ ]|r "..reqName, 0.5, 0.5, 0.5)
        end
      end
      GameTooltip:AddLine(string.format("Criteria: %d / %d achievements", done, total), 1.0, 0.82, 0.2)
    end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  return frame
end

function LeafVE_AchTest.UI:Build()
  if self.frame then
    self.frame:Show()
    self:Refresh()
    return
  end
  
  local f = CreateFrame("Frame", "LeafVE_AchTestFrame", UIParent)
  self.frame = f
  f:SetPoint("CENTER", 0, 0)
  f:SetWidth(930)
  f:SetHeight(640)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() f:StartMoving() end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
  f:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

  -- Warm wood-toned backdrop.
  local grad = f:CreateTexture(nil, "BACKGROUND")
  grad:SetAllPoints(f)
  grad:SetTexture(TEX.bankBg)
  grad:SetVertexColor(1, 1, 1, 0.72)
  
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
  header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  header:SetHeight(46)
  header:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2}
  })
  header:SetBackdropColor(0.10, 0.10, 0.10, 0.96)
  header:SetBackdropBorderColor(0.42, 0.42, 0.42, 0.95)
  local headerArt = header:CreateTexture(nil, "BACKGROUND")
  headerArt:SetAllPoints(header)
  headerArt:SetTexture(TEX.bankBg)
  headerArt:SetVertexColor(1, 1, 1, 0.35)

  local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("CENTER", header, "CENTER", 0, 0)
  title:SetText("LeafVillageAchievements")
  title:SetTextColor(THEME.gold[1], THEME.gold[2], THEME.gold[3])
  
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
  
  self.pointsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.pointsLabel:SetPoint("TOP", f, "TOP", 0, -52)
  local pointsFrame = CreateFrame("Frame", nil, f)
  pointsFrame:SetPoint("TOP", f, "TOP", 0, -52)
  pointsFrame:SetWidth(230)
  pointsFrame:SetHeight(24)
  pointsFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2}
  })
  pointsFrame:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
  pointsFrame:SetBackdropBorderColor(0.40, 0.40, 0.40, 0.95)
  pointsFrame:SetFrameLevel(f:GetFrameLevel() + 2)
  self.pointsLabel:SetParent(pointsFrame)
  self.pointsLabel:ClearAllPoints()
  self.pointsLabel:SetPoint("CENTER", pointsFrame, "CENTER", 0, 0)
  
  local achTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  achTab:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -82)
  achTab:SetWidth(100)
  achTab:SetHeight(25)
  achTab:SetText("Achievements")
  achTab:SetScript("OnClick", function()
    LeafVE_AchTest.UI.currentView = "achievements"
    LeafVE_AchTest.UI:Refresh()
  end)
  self.achTab = achTab
  
  local titlesTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  titlesTab:SetPoint("LEFT", achTab, "RIGHT", 5, 0)
  titlesTab:SetWidth(80)
  titlesTab:SetHeight(25)
  titlesTab:SetText("Titles")
  titlesTab:SetScript("OnClick", function()
    LeafVE_AchTest.UI.currentView = "titles"
    LeafVE_AchTest.UI:Refresh()
  end)
  self.titlesTab = titlesTab

  local adminTab = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  adminTab:SetPoint("LEFT", titlesTab, "RIGHT", 5, 0)
  adminTab:SetWidth(60)
  adminTab:SetHeight(25)
  adminTab:SetText("Admin")
  adminTab:SetScript("OnClick", function()
    local _, rankName = GetGuildInfo("player")
    if not IsOfficerRank(rankName) then
      Print("Only Anbu, Sannin, or Hokage may access the Admin panel.")
      return
    end
    LeafVE_AchTest.UI.currentView = "admin"
    LeafVE_AchTest.UI:Refresh()
  end)
  self.adminTab = adminTab

  -- Award / Reset buttons (placed directly after the Admin tab)
  local awardBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  awardBtn:SetPoint("LEFT", adminTab, "RIGHT", 15, 0)
  awardBtn:SetWidth(60)
  awardBtn:SetHeight(25)
  awardBtn:SetText("Award")
  awardBtn:SetScript("OnClick", function()
    local _, rankName = GetGuildInfo("player")
    if not IsOfficerRank(rankName) then
      Print("Only Anbu, Sannin, or Hokage may use the Award button.")
      return
    end
    local me = ShortName(UnitName("player") or "")
    local playerAchievements = LeafVE_AchTest:GetPlayerAchievements(me)
    local availableAchievements = {}
    for achID, achData in pairs(ACHIEVEMENTS) do
      if not playerAchievements[achID] then
        table.insert(availableAchievements, achID)
      end
    end
    if table.getn(availableAchievements) > 0 then
      local randomIndex = math.random(1, table.getn(availableAchievements))
      local randomAchID = availableAchievements[randomIndex]
      LeafVE_AchTest:AwardAchievement(randomAchID, false)
    else
      Print("You already have all achievements!")
    end
  end)
  self.awardBtn = awardBtn

  local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  resetBtn:SetPoint("LEFT", awardBtn, "RIGHT", 5, 0)
  resetBtn:SetWidth(60)
  resetBtn:SetHeight(25)
  resetBtn:SetText("Reset")
  resetBtn:SetScript("OnClick", function()
    local _, rankName = GetGuildInfo("player")
    if not IsOfficerRank(rankName) then
      Print("Only Anbu, Sannin, or Hokage may reset achievements.")
      return
    end
    LeafVE_AchTest_DB.achievements    = {}
    LeafVE_AchTest_DB.selectedTitles  = {}
    LeafVE_AchTest_DB.progressCounters = {}
    LeafVE_AchTest_DB.progressCache    = {}
    LeafVE_AchTest_DB.exploredZones   = {}
    LeafVE_AchTest_DB.dungeonProgress = {}
    LeafVE_AchTest_DB.raidProgress    = {}
    LeafVE_AchTest_DB.completedQuests = {}
    LeafVE_AchTest_DB.peakGold        = {}
    LeafVE_AchTest_DB.goldEarnedTotal = {}
    LeafVE_AchTest_DB.goldLastSeen    = {}
    Print("Reset complete!")
    LeafVE_AchTest.UI:Refresh()
  end)
  self.resetBtn = resetBtn

  -- â”€â”€ Admin Panel (hidden by default) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  local adminFrame = CreateFrame("Frame", nil, f)
  adminFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -110)
  adminFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 10)
  adminFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=2, right=2, top=2, bottom=2},
  })
  adminFrame:SetBackdropColor(0.04, 0.05, 0.07, 0.94)
  adminFrame:SetBackdropBorderColor(0.46, 0.16, 0.12, 0.82)
  adminFrame:Hide()
  self.adminFrame = adminFrame

  local adminTitle = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  adminTitle:SetPoint("TOP", adminFrame, "TOP", 0, -14)
  adminTitle:SetText("|cFFFF0000Admin Panel|r â€” Grant Achievements to Players")

  local adminNote = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  adminNote:SetPoint("TOP", adminTitle, "BOTTOM", 0, -4)
  adminNote:SetText("|cFFFFCC00Officers only â€” use /achgrant <player> <id> in chat as well|r")

  local adminPlayerLabel = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  adminPlayerLabel:SetPoint("TOPLEFT", adminFrame, "TOPLEFT", 20, -70)
  adminPlayerLabel:SetText("Player Name:")

  local adminPlayerBox = CreateFrame("EditBox", nil, adminFrame)
  adminPlayerBox:SetPoint("LEFT", adminPlayerLabel, "RIGHT", 8, 0)
  adminPlayerBox:SetWidth(180)
  adminPlayerBox:SetHeight(24)
  adminPlayerBox:SetAutoFocus(false)
  adminPlayerBox:SetFontObject("GameFontHighlight")
  adminPlayerBox:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = {left=4, right=4, top=4, bottom=4}
  })
  adminPlayerBox:SetBackdropColor(0.01, 0.02, 0.03, 0.86)
  adminPlayerBox:SetBackdropBorderColor(0.32, 0.28, 0.24, 1)
  adminPlayerBox:SetTextInsets(6, 6, 0, 0)
  adminPlayerBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  adminPlayerBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  self.adminPlayerBox = adminPlayerBox

  local adminAchLabel = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  adminAchLabel:SetPoint("TOPLEFT", adminPlayerLabel, "BOTTOMLEFT", 0, -16)
  adminAchLabel:SetText("Achievement ID:")

  local adminAchBox = CreateFrame("EditBox", nil, adminFrame)
  adminAchBox:SetPoint("LEFT", adminAchLabel, "RIGHT", 8, 0)
  adminAchBox:SetWidth(280)
  adminAchBox:SetHeight(24)
  adminAchBox:SetAutoFocus(false)
  adminAchBox:SetFontObject("GameFontHighlight")
  adminAchBox:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = {left=4, right=4, top=4, bottom=4}
  })
  adminAchBox:SetBackdropColor(0.01, 0.02, 0.03, 0.86)
  adminAchBox:SetBackdropBorderColor(0.32, 0.28, 0.24, 1)
  adminAchBox:SetTextInsets(6, 6, 0, 0)
  adminAchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  adminAchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  self.adminAchBox = adminAchBox

  local adminDropdownLabel = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  adminDropdownLabel:SetPoint("TOPLEFT", adminAchLabel, "BOTTOMLEFT", 0, -18)
  adminDropdownLabel:SetText("Select Achievement:")

  local adminAchOptions = BuildAdminAchievementOptions()
  local adminAchLookup = {}
  local adminAchCategories = {}
  local adminAchByCategory = {}
  for _, option in ipairs(adminAchOptions) do
    option.display = "["..option.category.."] "..option.name.." ("..option.id..")"
    adminAchLookup[string.lower(option.id)] = option
    if not adminAchByCategory[option.category] then
      adminAchByCategory[option.category] = {}
      table.insert(adminAchCategories, option.category)
    end
    table.insert(adminAchByCategory[option.category], option)
  end
  table.sort(adminAchCategories, function(a, b)
    return string.lower(a) < string.lower(b)
  end)
  self.adminAchLookup = adminAchLookup

  local adminAchDropdown = CreateFrame("Frame", "LeafVE_AchTestAdminAchDropdown", adminFrame, "UIDropDownMenuTemplate")
  adminAchDropdown:SetPoint("TOPLEFT", adminDropdownLabel, "BOTTOMLEFT", -16, 4)
  UIDropDownMenu_SetWidth(440, adminAchDropdown)
  UIDropDownMenu_JustifyText("LEFT", adminAchDropdown)
  UIDropDownMenu_SetText("Select an achievement...", adminAchDropdown)
  local ACH_DROPDOWN_PAGE_SIZE = 24
  UIDropDownMenu_Initialize(adminAchDropdown, function(arg1, arg2, arg3)
    -- Vanilla dropdown callbacks vary by caller: either (level, menuList)
    -- or (self, level, menuList). Normalize both forms.
    local level, menuValue
    if type(arg1) == "number" then
      level = arg1
      menuValue = arg2
    else
      level = arg2
      menuValue = arg3
    end
    level = tonumber(level) or UIDROPDOWNMENU_MENU_LEVEL or 1
    if menuValue == nil and level > 1 then
      menuValue = UIDROPDOWNMENU_MENU_VALUE
    end
    local selectedAch = string.lower(Trim(adminAchBox:GetText() or ""))

    local function AddAchievementOption(option)
      local achId = option.id
      local display = option.display
      local info = {}
      info.text = display
      info.checked = (selectedAch == string.lower(achId))
      info.func = function()
        UIDropDownMenu_SetText(display, adminAchDropdown)
        adminAchBox:SetText(achId)
        if CloseDropDownMenus then CloseDropDownMenus() end
      end
      UIDropDownMenu_AddButton(info, level)
    end

    if level == 1 then
      for catIndex, category in ipairs(adminAchCategories) do
        local list = adminAchByCategory[category]
        local info = {}
        info.text = category.." ("..table.getn(list)..")"
        info.hasArrow = 1
        info.notCheckable = 1
        info.value = "CAT:"..catIndex
        UIDropDownMenu_AddButton(info, level)
      end
      return
    end

    local tokenKind, tokenCatIndex, tokenPage = nil, nil, nil
    if type(menuValue) == "string" then
      tokenKind, tokenCatIndex, tokenPage = string.match(menuValue, "^(%u+):(%d+):?(%d*)$")
    end
    local catIndex = tonumber(tokenCatIndex or "")
    local category = catIndex and adminAchCategories[catIndex]
    local list = category and adminAchByCategory[category] or nil
    if not list then return end

    if level == 2 and tokenKind == "CAT" then
      local total = table.getn(list)
      if total <= ACH_DROPDOWN_PAGE_SIZE then
        for i = 1, total do
          AddAchievementOption(list[i])
        end
      else
        local pageCount = math.ceil(total / ACH_DROPDOWN_PAGE_SIZE)
        for page = 1, pageCount do
          local firstIndex = ((page - 1) * ACH_DROPDOWN_PAGE_SIZE) + 1
          local lastIndex = page * ACH_DROPDOWN_PAGE_SIZE
          if lastIndex > total then lastIndex = total end
          local info = {}
          info.text = string.format("Page %d (%d-%d)", page, firstIndex, lastIndex)
          info.hasArrow = 1
          info.notCheckable = 1
          info.value = "PAGE:"..catIndex..":"..page
          UIDropDownMenu_AddButton(info, level)
        end
      end
      return
    end

    if level == 3 and tokenKind == "PAGE" then
      local page = tonumber(tokenPage or "") or 1
      local firstIndex = ((page - 1) * ACH_DROPDOWN_PAGE_SIZE) + 1
      local lastIndex = page * ACH_DROPDOWN_PAGE_SIZE
      local total = table.getn(list)
      if lastIndex > total then lastIndex = total end
      for i = firstIndex, lastIndex do
        AddAchievementOption(list[i])
      end
    end
  end)
  self.adminAchDropdown = adminAchDropdown

  local function SyncAdminDropdownFromInput()
    local key = string.lower(Trim(adminAchBox:GetText() or ""))
    local match = key ~= "" and adminAchLookup[key] or nil
    if match then
      UIDropDownMenu_SetText(match.display, adminAchDropdown)
    else
      UIDropDownMenu_SetText("Select an achievement...", adminAchDropdown)
    end
  end
  adminAchBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
    SyncAdminDropdownFromInput()
  end)
  adminAchBox:SetScript("OnEnterPressed", function()
    this:ClearFocus()
    SyncAdminDropdownFromInput()
  end)
  adminAchBox:SetScript("OnTextChanged", function()
    SyncAdminDropdownFromInput()
  end)

  local adminGrantBtn = CreateFrame("Button", nil, adminFrame, "UIPanelButtonTemplate")
  adminGrantBtn:SetPoint("LEFT", adminAchBox, "RIGHT", 10, 0)
  adminGrantBtn:SetWidth(80)
  adminGrantBtn:SetHeight(24)
  adminGrantBtn:SetText("Grant")
  adminGrantBtn:SetScript("OnClick", function()
    local _, rankName = GetGuildInfo("player")
    if not IsOfficerRank(rankName) then
      Print("Only Anbu, Sannin, or Hokage may grant achievements.")
      return
    end
    local playerName = LeafVE_AchTest.UI.adminPlayerBox and LeafVE_AchTest.UI.adminPlayerBox:GetText() or ""
    local achId = LeafVE_AchTest.UI.adminAchBox and LeafVE_AchTest.UI.adminAchBox:GetText() or ""
    local ok, targetOrError, achOrNil = LeafVE_AchTest:AdminGrantAchievement(playerName, achId, false)
    if not ok then
      Print("|cFFFF4444Admin: "..targetOrError.."|r")
      return
    end
    Print("|cFFFF0000[Admin Grant]|r "..targetOrError.." awarded: |cFF2DD35C"..achOrNil.name.."|r (+"..achOrNil.points.." pts)")
  end)

  local adminGrantGuildBtn = CreateFrame("Button", nil, adminFrame, "UIPanelButtonTemplate")
  adminGrantGuildBtn:SetPoint("TOPLEFT", adminGrantBtn, "BOTTOMLEFT", 0, -6)
  adminGrantGuildBtn:SetWidth(110)
  adminGrantGuildBtn:SetHeight(22)
  adminGrantGuildBtn:SetText("Grant Guildie")
  adminGrantGuildBtn:SetScript("OnClick", function()
    local _, rankName = GetGuildInfo("player")
    if not IsOfficerRank(rankName) then
      Print("Only Anbu, Sannin, or Hokage may grant achievements.")
      return
    end
    local playerName = LeafVE_AchTest.UI.adminPlayerBox and LeafVE_AchTest.UI.adminPlayerBox:GetText() or ""
    local achId = LeafVE_AchTest.UI.adminAchBox and LeafVE_AchTest.UI.adminAchBox:GetText() or ""
    local ok, targetOrError, achOrNil = LeafVE_AchTest:AdminGrantAchievement(playerName, achId, true)
    if not ok then
      Print("|cFFFF4444Admin: "..targetOrError.."|r")
      return
    end
    Print("|cFFFF0000[Admin Guild Grant]|r "..targetOrError.." awarded: |cFF2DD35C"..achOrNil.name.."|r (+"..achOrNil.points.." pts)")
  end)

  local adminStatusLabel = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  adminStatusLabel:SetPoint("TOPLEFT", adminAchDropdown, "BOTTOMLEFT", 16, -8)
  adminStatusLabel:SetWidth(700)
  adminStatusLabel:SetJustifyH("LEFT")
  adminStatusLabel:SetText("|cFF888888Hint: Dropdown is grouped by category (and pages for large categories). /achgrant <name> <id> and /achgrantguild <name> <id> still work.|r")
  self.adminStatusLabel = adminStatusLabel

  -- Legendary achievements quick-reference list
  local adminLegHeader = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  adminLegHeader:SetPoint("TOPLEFT", adminStatusLabel, "BOTTOMLEFT", 0, -12)
  adminLegHeader:SetText("|cFFFF0000Legendary Achievement IDs (require streaming/recording + officer approval):|r")

  local LEGENDARY_IDS = {
    "legendary_solo_raid_boss","legendary_naked_dungeon","legendary_ironman_60",
    "legendary_duel_streak_100","legendary_full_clear_week",
    "legendary_flawless_naxx","legendary_speed_run_brd",
    "legendary_onyxia_10","legendary_onyxia_5",
    "legendary_solo_60_boss","legendary_no_consumes_t2plus",
  }
  local yLeg = -14
  for _, lid in ipairs(LEGENDARY_IDS) do
    local ach = ACHIEVEMENTS[lid]
    if ach then
      local row = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      row:SetPoint("TOPLEFT", adminLegHeader, "BOTTOMLEFT", 0, yLeg)
      row:SetWidth(820)
      row:SetJustifyH("LEFT")
      row:SetText("|cFFFF8800"..lid.."|r â€” "..ach.name)
      yLeg = yLeg - 16
    end
  end

  -- â”€â”€ Left sidebar: category navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  local sidebarFrame = CreateFrame("Frame", nil, f)
  sidebarFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -110)
  sidebarFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 10)
  sidebarFrame:SetWidth(140)
  sidebarFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=2, right=2, top=2, bottom=2},
  })
  sidebarFrame:SetBackdropColor(0.10, 0.10, 0.10, 0.95)
  sidebarFrame:SetBackdropBorderColor(0.40, 0.40, 0.40, 0.90)
  self.sidebarFrame = sidebarFrame

  -- Ordered list of categories shown in the sidebar
  local SIDEBAR_CATS = {
    {display="All",            filter="All"},
    {display="Leveling",       filter="Leveling"},
    {display="Quests",         filter="Quests"},
    {display="Professions",    filter="Professions"},
    {display="Skills",         filter="Skills"},
    {display="Dungeons",       filter="Dungeons"},
    {display="Raids",          filter="Raids"},
    {display="Exploration",    filter="Exploration"},
    {display="PvP",            filter="PvP"},
    {display="Gold",           filter="Gold"},
    {display="Elite",          filter="Elite"},
    {display="Casual",         filter="Casual"},
    {display="Roleplay",       filter="Roleplay"},
    {display="Kills",          filter="Kills"},
    {display="Identity",       filter="Identity"},
    {display="Reputation",     filter="Reputation"},
    {display="Legendary",      filter="Legendary"},
  }
  self.categoryButtons = {}
  for i, cat in ipairs(SIDEBAR_CATS) do
    local filterVal = cat.filter
    local btn = CreateFrame("Frame", nil, sidebarFrame)
    btn:SetPoint("TOPLEFT", sidebarFrame, "TOPLEFT", 4, -(i-1)*27 - 4)
    btn:SetWidth(132)
    btn:SetHeight(24)
    btn:EnableMouse(true)
    btn:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      tile = true, tileSize = 8,
      insets = {left=2, right=2, top=2, bottom=2},
    })
    btn:SetBackdropColor(0, 0, 0, 0)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    lbl:SetText(cat.display)
    lbl:SetTextColor(0.92, 0.78, 0.26)
    btn.label     = lbl
    btn.filterValue = filterVal
    local hi = btn:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints(btn)
    hi:SetTexture(TEX.categoryHi)
    hi:SetVertexColor(1, 1, 1, 0.70)
    hi:Hide()
    btn.highlight = hi
    btn:SetScript("OnMouseDown", function()
      LeafVE_AchTest.UI.selectedCategory = this.filterValue
      LeafVE_AchTest.UI:Refresh()
    end)
    btn:SetScript("OnEnter", function()
      if this.filterValue ~= LeafVE_AchTest.UI.selectedCategory then
        if this.highlight then
          this.highlight:SetVertexColor(1, 1, 1, 0.55)
          this.highlight:Show()
        end
      end
    end)
    btn:SetScript("OnLeave", function()
      if this.filterValue ~= LeafVE_AchTest.UI.selectedCategory then
        if this.highlight then this.highlight:Hide() end
      end
    end)
    table.insert(self.categoryButtons, btn)
  end
  
  -- Achievement Search Bar
  local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  searchLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 155, -110)
  searchLabel:SetText("Search:")
  self.searchLabel = searchLabel
  
  local searchBox = CreateFrame("EditBox", nil, f)
  searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
  searchBox:SetWidth(230)
  searchBox:SetHeight(25)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject("GameFontHighlight")
  searchBox:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  searchBox:SetBackdropColor(0.10, 0.10, 0.10, 0.92)
  searchBox:SetBackdropBorderColor(0.38, 0.38, 0.38, 1)
  searchBox:SetTextInsets(8, 8, 0, 0)
  searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  searchBox:SetScript("OnTextChanged", function()
    LeafVE_AchTest.UI.searchText = this:GetText()
    LeafVE_AchTest.UI:Refresh()
  end)
  self.searchBox = searchBox
  
  local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  clearBtn:SetPoint("LEFT", searchBox, "RIGHT", 5, 0)
  clearBtn:SetWidth(50)
  clearBtn:SetHeight(25)
  clearBtn:SetText("Clear")
  clearBtn:SetScript("OnClick", function()
    searchBox:SetText("")
    LeafVE_AchTest.UI.searchText = ""
    LeafVE_AchTest.UI:Refresh()
  end)
  self.clearBtn = clearBtn
  
  -- Title Search Bar (hidden by default)
  local titleSearchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  titleSearchLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 155, -110)
  titleSearchLabel:SetText("Search:")
  titleSearchLabel:Hide()
  self.titleSearchLabel = titleSearchLabel
  
  local titleSearchBox = CreateFrame("EditBox", nil, f)
  titleSearchBox:SetPoint("LEFT", titleSearchLabel, "RIGHT", 5, 0)
  titleSearchBox:SetWidth(230)
  titleSearchBox:SetHeight(25)
  titleSearchBox:SetAutoFocus(false)
  titleSearchBox:SetFontObject("GameFontHighlight")
  titleSearchBox:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  titleSearchBox:SetBackdropColor(0.10, 0.10, 0.10, 0.92)
  titleSearchBox:SetBackdropBorderColor(0.38, 0.38, 0.38, 1)
  titleSearchBox:SetTextInsets(8, 8, 0, 0)
  titleSearchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  titleSearchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  titleSearchBox:SetScript("OnTextChanged", function()
    LeafVE_AchTest.UI.titleSearchText = this:GetText()
    LeafVE_AchTest.UI:Refresh()
  end)
  titleSearchBox:Hide()
  self.titleSearchBox = titleSearchBox
  
  local titleClearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  titleClearBtn:SetPoint("LEFT", titleSearchBox, "RIGHT", 5, 0)
  titleClearBtn:SetWidth(50)
  titleClearBtn:SetHeight(25)
  titleClearBtn:SetText("Clear")
  titleClearBtn:SetScript("OnClick", function()
    titleSearchBox:SetText("")
    LeafVE_AchTest.UI.titleSearchText = ""
    LeafVE_AchTest.UI:Refresh()
  end)
  titleClearBtn:Hide()
  self.titleClearBtn = titleClearBtn

  -- â”€â”€ Left sidebar for title category navigation (same layout as achievement sidebar) â”€â”€
  local titleSidebarFrame = CreateFrame("Frame", nil, f)
  titleSidebarFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -110)
  titleSidebarFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 10)
  titleSidebarFrame:SetWidth(140)
  titleSidebarFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left=2, right=2, top=2, bottom=2},
  })
  titleSidebarFrame:SetBackdropColor(0.10, 0.10, 0.10, 0.95)
  titleSidebarFrame:SetBackdropBorderColor(0.40, 0.40, 0.40, 0.90)
  titleSidebarFrame:Hide()
  self.titleSidebarFrame = titleSidebarFrame

  local TITLE_SIDEBAR_CATS = {
    {display="All",          filter="All"},
    {display="Obtained",     filter="Obtained"},
    {display="Leveling",     filter="Leveling"},
    {display="Raids",        filter="Raids"},
    {display="Dungeons",     filter="Dungeons"},
    {display="PvP",          filter="PvP"},
    {display="Professions",  filter="Professions"},
    {display="Elite",        filter="Elite"},
    {display="Gold",         filter="Gold"},
    {display="Exploration",  filter="Exploration"},
    {display="Casual",       filter="Casual"},
    {display="Roleplay",     filter="Roleplay"},
    {display="Quests",       filter="Quests"},
    {display="Legendary",    filter="Legendary"},
  }
  self.titleCategoryButtons = {}
  for i, cat in ipairs(TITLE_SIDEBAR_CATS) do
    local filterVal = cat.filter
    local btn = CreateFrame("Frame", nil, titleSidebarFrame)
    btn:SetPoint("TOPLEFT", titleSidebarFrame, "TOPLEFT", 4, -(i-1)*27 - 4)
    btn:SetWidth(132)
    btn:SetHeight(24)
    btn:EnableMouse(true)
    btn:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      tile = true, tileSize = 8,
      insets = {left=2, right=2, top=2, bottom=2},
    })
    btn:SetBackdropColor(0, 0, 0, 0)
    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetAllPoints(btn)
    lbl:SetJustifyH("CENTER")
    lbl:SetText(cat.display)
    lbl:SetTextColor(0.92, 0.78, 0.26)
    btn.label = lbl
    btn.filterValue = filterVal
    local hi = btn:CreateTexture(nil, "BACKGROUND")
    hi:SetAllPoints(btn)
    hi:SetTexture(TEX.categoryHi)
    hi:SetVertexColor(1, 1, 1, 0.70)
    hi:Hide()
    btn.highlight = hi
    btn:SetScript("OnMouseDown", function()
      LeafVE_AchTest.UI.titleCategoryFilter = this.filterValue
      LeafVE_AchTest.UI:Refresh()
    end)
    btn:SetScript("OnEnter", function()
      if this.filterValue ~= LeafVE_AchTest.UI.titleCategoryFilter then
        if this.highlight then
          this.highlight:SetVertexColor(1, 1, 1, 0.55)
          this.highlight:Show()
        end
      end
    end)
    btn:SetScript("OnLeave", function()
      if this.filterValue ~= LeafVE_AchTest.UI.titleCategoryFilter then
        if this.highlight then this.highlight:Hide() end
      end
    end)
    table.insert(self.titleCategoryButtons, btn)
  end
  
  local scrollFrame = CreateFrame("ScrollFrame", nil, f)
  scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 158, -152)
  scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 12)
  scrollFrame:EnableMouseWheel(true)
  self.scrollFrame = scrollFrame

  local contentArt = f:CreateTexture(nil, "BACKGROUND")
  contentArt:SetPoint("TOPLEFT", f, "TOPLEFT", 158, -152)
  contentArt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, 12)
  contentArt:SetTexture(TEX.bankBg)
  contentArt:SetVertexColor(1, 1, 1, 0.55)
  self.contentArt = contentArt
  
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(710)
  scrollChild:SetHeight(1)
  scrollFrame:SetScrollChild(scrollChild)
  self.scrollChild = scrollChild
  
  local scrollbar = CreateFrame("Slider", nil, f)
  scrollbar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -152)
  scrollbar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 15)
  scrollbar:SetWidth(16)
  scrollbar:SetOrientation("VERTICAL")
  scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  scrollbar:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  scrollbar:SetBackdropColor(0.10, 0.10, 0.10, 0.90)
  scrollbar:SetMinMaxValues(0, 1)
  scrollbar:SetValue(0)
  scrollbar:SetValueStep(20)
  self.scrollbar = scrollbar
  
  scrollbar:SetScript("OnValueChanged", function()
    if LeafVE_AchTest.UI and LeafVE_AchTest.UI.scrollFrame then
      LeafVE_AchTest.UI.scrollFrame:SetVerticalScroll(this:GetValue())
      if LeafVE_AchTest.UI.currentView == "achievements" then
        LeafVE_AchTest.UI:UpdateVisibleAchievements()
      end
    end
  end)
  
  scrollFrame:SetScript("OnMouseWheel", function()
    local current = this:GetVerticalScroll()
    local maxScroll = this:GetVerticalScrollRange()
    local newScroll = current - (arg1 * 20)
    if newScroll < 0 then newScroll = 0 end
    if newScroll > maxScroll then newScroll = maxScroll end
    this:SetVerticalScroll(newScroll)
    if LeafVE_AchTest.UI and LeafVE_AchTest.UI.scrollbar then
      LeafVE_AchTest.UI.scrollbar:SetValue(newScroll)
    end
  end)
  
  self:Refresh()
end

function LeafVE_AchTest.UI:Refresh()
  if not self.frame or not self.scrollChild then return end
  
  local me = ShortName(UnitName("player") or "")
  local totalPoints = LeafVE_AchTest:GetTotalAchievementPoints(me)
  local currentTitle = LeafVE_AchTest:GetCurrentTitle(me)
  local _, rankName = GetGuildInfo("player")
  local hasAdminAccess = IsOfficerRank(rankName)

  if not hasAdminAccess and self.currentView == "admin" then
    self.currentView = "achievements"
  end

  if self.adminTab then
    if hasAdminAccess then
      self.adminTab:Show()
    else
      self.adminTab:Hide()
    end
  end

  if self.resetBtn then
    if hasAdminAccess then
      self.resetBtn:Show()
    else
      self.resetBtn:Hide()
    end
  end
  
  if self.pointsLabel then
    if currentTitle then
      local titleText = currentTitle.prefix and (currentTitle.name.." "..me) or (me.." "..currentTitle.name)
      local titleColor = currentTitle.legendary and "|cFFFF0000" or "|cFFFF7F00"
      self.pointsLabel:SetText(titleColor..titleText.."|r | Points: |cFFFF7F00"..totalPoints.."|r")
    else
      self.pointsLabel:SetText(me.." | Points: |cFFFF7F00"..totalPoints.."|r")
    end
  end
  
  if self.achievementFrames then
    for i = 1, table.getn(self.achievementFrames) do
      if self.achievementFrames[i] then self.achievementFrames[i]:Hide() end
    end
  end
  
  if self.titleFrames then
    for i = 1, table.getn(self.titleFrames) do
      if self.titleFrames[i] then self.titleFrames[i]:Hide() end
    end
  end
  
  if self.scrollFrame then self.scrollFrame:SetVerticalScroll(0) end
  if self.scrollbar then self.scrollbar:SetValue(0) end
  
  if self.currentView == "achievements" then
    if self.achTab then self.achTab:Disable() end
    if self.titlesTab then self.titlesTab:Enable() end
    if self.adminTab and hasAdminAccess then self.adminTab:Enable() end
    if self.awardBtn then
      if hasAdminAccess then
        self.awardBtn:Show()
      else
        self.awardBtn:Hide()
      end
    end
    if self.searchLabel then self.searchLabel:Show() end
    if self.searchBox then self.searchBox:Show() end
    if self.clearBtn then self.clearBtn:Show() end
    if self.titleSearchLabel then self.titleSearchLabel:Hide() end
    if self.titleSearchBox then self.titleSearchBox:Hide() end
    if self.titleClearBtn then self.titleClearBtn:Hide() end
    -- Show achievement sidebar, hide title sidebar and admin panel
    if self.sidebarFrame then self.sidebarFrame:Show() end
    if self.titleSidebarFrame then self.titleSidebarFrame:Hide() end
    if self.adminFrame then self.adminFrame:Hide() end
    if self.scrollFrame then self.scrollFrame:Show() end
    if self.scrollbar then self.scrollbar:Show() end
    if self.categoryButtons then
      for _, btn in ipairs(self.categoryButtons) do
        if btn.filterValue == self.selectedCategory then
          if btn.highlight then
            btn.highlight:SetVertexColor(1, 1, 1, 0.88)
            btn.highlight:Show()
          end
          btn.label:SetTextColor(THEME.leaf[1], THEME.leaf[2], THEME.leaf[3])
        else
          if btn.highlight then btn.highlight:Hide() end
          btn.label:SetTextColor(0.92, 0.78, 0.26)
        end
      end
    end
    self:RefreshAchievements()
  elseif self.currentView == "admin" then
    if self.achTab then self.achTab:Enable() end
    if self.titlesTab then self.titlesTab:Enable() end
    if self.adminTab and hasAdminAccess then self.adminTab:Disable() end
    if self.awardBtn then self.awardBtn:Hide() end
    if self.searchLabel then self.searchLabel:Hide() end
    if self.searchBox then self.searchBox:Hide() end
    if self.clearBtn then self.clearBtn:Hide() end
    if self.titleSearchLabel then self.titleSearchLabel:Hide() end
    if self.titleSearchBox then self.titleSearchBox:Hide() end
    if self.titleClearBtn then self.titleClearBtn:Hide() end
    if self.sidebarFrame then self.sidebarFrame:Hide() end
    if self.titleSidebarFrame then self.titleSidebarFrame:Hide() end
    if self.adminFrame then self.adminFrame:Show() end
    if self.scrollFrame then self.scrollFrame:Hide() end
    if self.scrollbar then self.scrollbar:Hide() end
  else
    if self.achTab then self.achTab:Enable() end
    if self.titlesTab then self.titlesTab:Disable() end
    if self.adminTab and hasAdminAccess then self.adminTab:Enable() end
    if self.awardBtn then self.awardBtn:Hide() end
    if self.searchLabel then self.searchLabel:Hide() end
    if self.searchBox then self.searchBox:Hide() end
    if self.clearBtn then self.clearBtn:Hide() end
    if self.titleSearchLabel then self.titleSearchLabel:Show() end
    if self.titleSearchBox then self.titleSearchBox:Show() end
    if self.titleClearBtn then self.titleClearBtn:Show() end
    -- Show title sidebar, hide achievement sidebar and admin panel
    if self.sidebarFrame then self.sidebarFrame:Hide() end
    if self.titleSidebarFrame then self.titleSidebarFrame:Show() end
    if self.adminFrame then self.adminFrame:Hide() end
    if self.scrollFrame then self.scrollFrame:Show() end
    if self.scrollbar then self.scrollbar:Show() end
    if self.titleCategoryButtons then
      for _, btn in ipairs(self.titleCategoryButtons) do
        if btn.filterValue == self.titleCategoryFilter then
          if btn.highlight then
            btn.highlight:SetVertexColor(1, 1, 1, 0.88)
            btn.highlight:Show()
          end
          btn.label:SetTextColor(THEME.leaf[1], THEME.leaf[2], THEME.leaf[3])
        else
          if btn.highlight then btn.highlight:Hide() end
          btn.label:SetTextColor(0.92, 0.78, 0.26)
        end
      end
    end
    self:RefreshTitles()
  end
  
  if self.scrollFrame and self.scrollbar then
    local maxScroll = self.scrollFrame:GetVerticalScrollRange()
    self.scrollbar:SetMinMaxValues(0, maxScroll > 0 and maxScroll or 1)
  end
end

function LeafVE_AchTest.UI:RefreshAchievements()
  if not self.scrollChild then return end
  local me = ShortName(UnitName("player") or "")
  local playerAchievements = LeafVE_AchTest:GetPlayerAchievements(me)
  if not self.achievementFrames then self.achievementFrames = {} end

  -- Build filtered & sorted achievement list.
  local achievementList = {}
  for achID, achData in pairs(ACHIEVEMENTS) do
    local matchesCategory = self.selectedCategory == "All" or achData.category == self.selectedCategory
    local matchesSearch = true
    if self.searchText and self.searchText ~= "" then
      local searchLower = string.lower(self.searchText)
      local nameLower = string.lower(achData.name)
      local descLower = string.lower(achData.desc)
      matchesSearch = string.find(nameLower, searchLower) or string.find(descLower, searchLower)
    end
    if matchesCategory and matchesSearch then
      local completed = playerAchievements[achID] ~= nil
      local timestamp = completed and playerAchievements[achID].timestamp or 0
      table.insert(achievementList, {id=achID, data=achData, completed=completed, timestamp=timestamp})
    end
  end

  table.sort(achievementList, function(a, b)
    if a.completed and not b.completed then return true end
    if not a.completed and b.completed then return false end
    if a.completed and b.completed then return a.timestamp > b.timestamp end
    return a.data.points > b.data.points
  end)

  -- Store the sorted list for virtual-scroll updates.
  self.currentAchList  = achievementList
  self.currentAchOwner = me

  -- Set the scrollChild virtual height so the scrollbar range is correct.
  local totalHeight = math.max(10, table.getn(achievementList) * ACH_ROW_H + 10)
  self.scrollChild:SetHeight(totalHeight)

  if self.scrollFrame and self.scrollbar then
    local maxScroll = self.scrollFrame:GetVerticalScrollRange()
    self.scrollbar:SetMinMaxValues(0, maxScroll > 0 and maxScroll or 1)
  end

  -- Ensure the recycled frame pool exists (created once, reused forever).
  while table.getn(self.achievementFrames) < ACH_POOL do
    local frame = CreateAchievementRow(self.scrollChild)
    frame:Hide()
    table.insert(self.achievementFrames, frame)
  end

  self:UpdateVisibleAchievements()
end

-- Reposition and repopulate only the pool frames that fall inside the current
-- scroll viewport.  Called by RefreshAchievements and by scroll events.
function LeafVE_AchTest.UI:UpdateVisibleAchievements()
  local list = self.currentAchList
  if not list or not self.scrollFrame then return end
  local me    = self.currentAchOwner or ""
  local total = table.getn(list)

  -- Hide all pooled frames before re-assigning.
  for i = 1, table.getn(self.achievementFrames) do
    if self.achievementFrames[i] then self.achievementFrames[i]:Hide() end
  end

  if total == 0 then return end

  local scrollOff = self.scrollFrame:GetVerticalScroll() or 0
  -- First row index (1-based) that is at least partially visible.
  local firstRow  = math.max(1, math.floor(scrollOff / ACH_ROW_H) + 1)
  local poolSize  = table.getn(self.achievementFrames)

  for pi = 1, poolSize do
    local rowIdx = firstRow + pi - 1
    if rowIdx > total then break end
    local ach   = list[rowIdx]
    local frame = self.achievementFrames[pi]
    if not frame then break end

    local yOff = (rowIdx - 1) * ACH_ROW_H
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -yOff)

    frame.achData       = ach.data
    frame.achCompleted  = ach.completed
    frame.achTimestamp  = ach.timestamp
    frame.achPlayerName = me

    frame.icon:SetTexture(ach.data.icon)
    if ach.completed then
      if frame.rowBg then frame.rowBg:SetVertexColor(1.0, 1.0, 1.0, 0.96) end
      frame.icon:SetDesaturated(false)
      frame.icon:SetAlpha(1)
      frame.checkmark:Show()
      local isLeg = ach.data.category == "Legendary"
      if isLeg then
        frame:SetBackdropBorderColor(0.9, 0.1, 0.1, 0.9)
        frame.name:SetTextColor(1, 0, 0)
      else
        frame:SetBackdropBorderColor(0.56, 0.46, 0.28, 0.92)
        frame.name:SetTextColor(0.90, 0.88, 0.84)
      end
      frame.name:SetText(ach.data.name)
      frame.desc:SetText(ach.data.desc)
      frame.desc:SetTextColor(0.80, 0.78, 0.74)
      frame.emblem:SetTexture("Interface\\Icons\\Spell_Nature_ResistNature")
      frame.emblem:SetVertexColor(1.0, 0.82, 0.20)
      frame.emblem:SetAlpha(1)
      frame.points:SetText("|cFFFFD433"..ach.data.points.."|r")
    else
      if frame.rowBg then frame.rowBg:SetVertexColor(0.70, 0.70, 0.70, 0.78) end
      frame.icon:SetDesaturated(true)
      frame.icon:SetAlpha(0.5)
      frame.checkmark:Hide()
      frame:SetBackdropBorderColor(0.32, 0.27, 0.20, 0.82)
      frame.name:SetText(ach.data.name)
      frame.name:SetTextColor(0.67, 0.65, 0.62)
      frame.desc:SetText(ach.data.desc)
      frame.desc:SetTextColor(0.52, 0.50, 0.48)
      frame.emblem:SetTexture("Interface\\Icons\\Spell_Nature_ResistNature")
      frame.emblem:SetVertexColor(0.5, 0.5, 0.5)
      frame.emblem:SetAlpha(0.4)
      frame.points:SetText("|cFF888888"..ach.data.points.."|r")
    end
    frame:Show()
  end
end

function LeafVE_AchTest.UI:RefreshTitles()
  if not self.scrollChild then return end
  local me = ShortName(UnitName("player") or "")
  if not self.titleFrames then self.titleFrames = {} end
  
  -- Build filtered title list
  local filteredTitles = {}
  for i, titleData in ipairs(TITLES) do
    local matchesSearch = true
    
    -- Search filter
    if self.titleSearchText and self.titleSearchText ~= "" then
      local searchLower = string.lower(self.titleSearchText)
      local nameLower = string.lower(titleData.name)
      local achData = ACHIEVEMENTS[titleData.achievement]
      local achNameLower = achData and string.lower(achData.name) or ""
      matchesSearch = string.find(nameLower, searchLower) or string.find(achNameLower, searchLower)
    end
    
    if matchesSearch then
      local matchesCategory = true
      local cat = self.titleCategoryFilter or "All"
      if cat == "Obtained" then
        matchesCategory = LeafVE_AchTest:HasAchievement(me, titleData.achievement)
      elseif cat ~= "All" then
        matchesCategory = (titleData.category == cat)
      end
      if matchesCategory then
        table.insert(filteredTitles, titleData)
      end
    end
  end
  
  local yOffset = 0
  for i, titleData in ipairs(filteredTitles) do
    local frame = self.titleFrames[i]
    local earned = LeafVE_AchTest:HasAchievement(me, titleData.achievement)
    if not frame then
      frame = CreateFrame("Frame", nil, self.scrollChild)
      frame:SetWidth(690)
      frame:SetHeight(55)
      frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
      })
      frame:SetBackdropColor(0.08, 0.07, 0.06, 0.96)
      frame:SetBackdropBorderColor(0.34, 0.28, 0.20, 0.92)
      local rowBg = frame:CreateTexture(nil, "BACKGROUND")
      rowBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
      rowBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
      rowBg:SetTexture(TEX.parchmentH)
      rowBg:SetVertexColor(0.92, 0.90, 0.86, 0.94)
      frame.rowBg = rowBg
      local icon = frame:CreateTexture(nil, "ARTWORK")
      icon:SetWidth(32)
      icon:SetHeight(32)
      icon:SetPoint("LEFT", frame, "LEFT", 10, 0)
      icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      frame.icon = icon
      local iconFrame = frame:CreateTexture(nil, "OVERLAY")
      iconFrame:SetWidth(40)
      iconFrame:SetHeight(40)
      iconFrame:SetPoint("CENTER", icon, "CENTER", 0, 0)
      iconFrame:SetTexture(TEX.iconFrame)
      iconFrame:SetVertexColor(1, 1, 1, 0.95)
      frame.iconFrame = iconFrame
      local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      name:SetPoint("LEFT", icon, "RIGHT", 10, 8)
      name:SetWidth(430)
      name:SetJustifyH("LEFT")
      frame.name = name
      local requirement = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      requirement:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
      requirement:SetWidth(430)
      requirement:SetJustifyH("LEFT")
      frame.requirement = requirement
      local equipBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
      equipBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -12)
      equipBtn:SetWidth(70)
      equipBtn:SetHeight(24)
      equipBtn:SetText("Equip")
      frame.equipBtn = equipBtn
      -- Tooltip
      frame:EnableMouse(true)
      frame:SetScript("OnEnter", function()
        if not this.titleData then return end
        local td = this.titleData
        local achData = ACHIEVEMENTS[td.achievement]
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if this.titleEarned then
          GameTooltip:SetText(td.name, THEME.leaf[1], THEME.leaf[2], THEME.leaf[3], 1, true)
          GameTooltip:AddLine("|cFF888888Title|r", 1, 1, 1)
          if achData then
            GameTooltip:AddLine("Requires: "..achData.name, 1, 1, 1, true)
          end
          GameTooltip:AddLine(" ", 1, 1, 1)
          GameTooltip:AddLine("Earned", 0.5, 0.8, 0.5)
        else
          GameTooltip:SetText(td.name, 0.6, 0.6, 0.6, 1, true)
          GameTooltip:AddLine("|cFF888888Title|r", 1, 1, 1)
          if achData then
            GameTooltip:AddLine("Requires: "..achData.name, 0.7, 0.7, 0.7, true)
          end
          GameTooltip:AddLine(" ", 1, 1, 1)
          GameTooltip:AddLine("Not yet earned", 0.8, 0.4, 0.4)
        end
        GameTooltip:Show()
      end)
      frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
      table.insert(self.titleFrames, frame)
    end
    -- Store per-frame data for the tooltip
    frame.titleData = titleData
    frame.titleEarned = earned
    frame:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -yOffset)
    local achData = ACHIEVEMENTS[titleData.achievement]
    frame.icon:SetTexture(titleData.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    if earned then
      if frame.rowBg then frame.rowBg:SetVertexColor(1.0, 1.0, 1.0, 0.96) end
      local isLeg = titleData.legendary
      local br = isLeg and {1,0,0} or {THEME.leaf[1],THEME.leaf[2],THEME.leaf[3]}
      frame:SetBackdropBorderColor(br[1], br[2], br[3], 0.84)
      frame.icon:SetDesaturated(false)
      frame.icon:SetAlpha(1)
      frame.name:SetText(titleData.name)
      if isLeg then
        frame.name:SetTextColor(1, 0, 0)
      else
        frame.name:SetTextColor(0.90, 0.88, 0.84)
      end
      frame.requirement:SetText("From: "..(achData and achData.name or "Unknown"))
      frame.requirement:SetTextColor(0.80, 0.78, 0.74)
      local currentTitle = LeafVE_AchTest_DB and LeafVE_AchTest_DB.selectedTitles and LeafVE_AchTest_DB.selectedTitles[me]
      local isEquipped = currentTitle and currentTitle.id == titleData.id
      frame.equipBtn:Enable()
      frame.equipBtn.titleID = titleData.id
      frame.equipBtn.titlePrefix = titleData.prefix
      if isEquipped then
        frame.equipBtn:SetText("Remove")
        frame.equipBtn:SetScript("OnClick", function()
          LeafVE_AchTest:RemoveTitle(me)
        end)
      else
        frame.equipBtn:SetText("Equip")
        frame.equipBtn:SetScript("OnClick", function()
          LeafVE_AchTest:SetTitle(me, this.titleID, this.titlePrefix)
          LeafVE_AchTest.UI:Refresh()
        end)
      end
    else
      if frame.rowBg then frame.rowBg:SetVertexColor(0.70, 0.70, 0.70, 0.78) end
      frame:SetBackdropBorderColor(0.32, 0.27, 0.20, 0.82)
      frame.icon:SetDesaturated(true)
      frame.icon:SetAlpha(0.3)
      frame.name:SetText(titleData.name)
      frame.name:SetTextColor(0.67, 0.65, 0.62)
      frame.requirement:SetText("Requires: "..(achData and achData.name or "Unknown"))
      frame.requirement:SetTextColor(0.52, 0.50, 0.48)
      frame.equipBtn:Disable()
    end
    frame:Show()
    yOffset = yOffset + 60
  end
  
  -- Hide unused frames
  for i = table.getn(filteredTitles) + 1, table.getn(self.titleFrames) do
    if self.titleFrames[i] then
      self.titleFrames[i]:Hide()
    end
  end
  
  if self.scrollChild then self.scrollChild:SetHeight(yOffset + 10) end
  if self.scrollFrame and self.scrollbar then
    local maxScroll = self.scrollFrame:GetVerticalScrollRange()
    self.scrollbar:SetMinMaxValues(0, maxScroll > 0 and maxScroll or 1)
  end
end

-- Timestamps of the most recent fall and drowning damage; used to classify the cause of death.
local lastFallDamageTime  = 0
local lastDrownDamageTime = 0
-- Trade state machine: only count a trade when both parties accept and the window closes.
local tradeArmed      = false
local tradeCandidate  = false
local firedThisTrade  = false
-- Maximum seconds between environmental damage and PLAYER_DEAD to classify cause of death.
local DEATH_CLASSIFY_WINDOW = 3
-- Track whether player was dead, to count only genuine resurrections.
local playerWasDead = false
-- Resurrection request state: only accepted player-cast resurrects should count.
local pendingAcceptedPlayerRes = false
local lastResurrectRequester = nil
local lastResurrectRequestTime = 0
local RESURRECT_REQUEST_WINDOW = 30
-- Recent target tracking for fallback boss kill validation ("X dies." / "X has been slain.")
local BOSS_TARGET_WINDOW = 30  -- seconds
local recentTargets = {}       -- lowercase mob name -> last-targeted timestamp
-- Quest log snapshot: used to diff on QUEST_FINISHED to detect actual turn-ins.
local questLogSnapshot = {}
local lastQuestTurnInTime = 0
local lastQuestTurnInName = nil
local QUEST_TURNIN_DEDUPE_WINDOW = 0.75
local QUEST_TURNIN_ANY_WINDOW = 0.20
-- Manual taxi state tracking (UnitOnTaxi does not exist in vanilla 1.12).
local isOnTaxi = false
local taxiMapJustClosed = false

local function ExtractCompletedQuestName(msg)
  if type(msg) ~= "string" then return nil end
  local name = smatch(msg, 'Quest "([^"]+)" completed%.')
           or smatch(msg, "Quest '([^']+)' completed%.")
  if name and name ~= "" then return Trim(name) end
  if string.find(msg, " completed%.") then
    local stripped = string.gsub(msg, " completed%.", "")
    stripped = string.gsub(stripped, '^Quest%s*["\']', "")
    stripped = string.gsub(stripped, '["\']%s*$', "")
    stripped = string.gsub(stripped, "^%s+", "")
    stripped = string.gsub(stripped, "%s+$", "")
    if stripped ~= "" then return stripped end
  end
  return nil
end

local function RecordQuestTurnIn(me, questName)
  if not me then return false end
  local now = GetTime and GetTime() or 0
  local lname = ""
  if type(questName) == "string" and questName ~= "" then
    lname = string.lower(Trim(questName))
  end

  if now > 0 then
    local sinceLast = now - lastQuestTurnInTime
    local sameName = (lname ~= "" and lastQuestTurnInName == lname)
    if lname == "" and sinceLast <= QUEST_TURNIN_ANY_WINDOW then
      return false
    end
    if sameName and sinceLast <= QUEST_TURNIN_DEDUPE_WINDOW then
      return false
    end
    lastQuestTurnInTime = now
    if lname ~= "" then
      lastQuestTurnInName = lname
    end
  end

  IncrCounter(me, "quests")
  if type(questName) == "string" and questName ~= "" and LeafVE_AchTest and LeafVE_AchTest.RecordQuestCompletion then
    LeafVE_AchTest.RecordQuestCompletion(me, questName)
  end
  local streak = IncrCounter(me, "questsSinceDeath")
  if streak >= 200 then
    LeafVE_AchTest:AwardAchievement("casual_quest_streak_200")
  end
  LeafVE_AchTest:CheckQuestAchievements()
  return true
end

local questRewardHooksInstalled = false
local function InstallQuestRewardHooks()
  if questRewardHooksInstalled then return end
  if not GetQuestReward then return end
  questRewardHooksInstalled = true

  local oldGetQuestReward = GetQuestReward
  GetQuestReward = function(choice)
    local me = ShortName(UnitName("player"))
    local questName = GetTitleText and GetTitleText() or nil
    if LeafVE_AchTest and LeafVE_AchTest.initialized and me and questName and questName ~= "" then
      RecordQuestTurnIn(me, questName)
    end
    return oldGetQuestReward(choice)
  end
end

-- Taxi state frame: tracks TAXIMAP_CLOSED + control events to detect flight paths.
local taxiFrame = CreateFrame("Frame")
taxiFrame:RegisterEvent("TAXIMAP_CLOSED")
taxiFrame:RegisterEvent("PLAYER_CONTROL_LOST")
taxiFrame:RegisterEvent("PLAYER_CONTROL_GAINED")
taxiFrame:SetScript("OnEvent", function()
  if event == "TAXIMAP_CLOSED" then
    taxiMapJustClosed = true
  elseif event == "PLAYER_CONTROL_LOST" then
    if taxiMapJustClosed then
      isOnTaxi = true
      taxiMapJustClosed = false
    end
  elseif event == "PLAYER_CONTROL_GAINED" then
    isOnTaxi = false
    taxiMapJustClosed = false
  end
end)

local resurrectHookInstalled = false
local function IsLikelyPlayerResurrecter(name)
  local short = ShortName(name)
  if not short or short == "" then return false end
  if string.find(short, " ") then return false end
  local low = string.lower(short)
  if string.find(low, "spirit", 1, true) and string.find(low, "healer", 1, true) then
    return false
  end
  return true
end

local function InstallResurrectionHooks()
  if resurrectHookInstalled then return end
  resurrectHookInstalled = true
  if AcceptResurrect then
    local oldAcceptResurrect = AcceptResurrect
    AcceptResurrect = function()
      local recent = (GetTime() - lastResurrectRequestTime) <= RESURRECT_REQUEST_WINDOW
      pendingAcceptedPlayerRes = recent and IsLikelyPlayerResurrecter(lastResurrectRequester)
      oldAcceptResurrect()
    end
  end
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("ADDON_LOADED")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_LEVEL_UP")
ef:RegisterEvent("PLAYER_MONEY")
ef:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
ef:RegisterEvent("PLAYER_TARGET_CHANGED")
ef:RegisterEvent("PLAYER_DEAD")
ef:RegisterEvent("PLAYER_ALIVE")
ef:RegisterEvent("PLAYER_UNGHOST")
ef:RegisterEvent("RESURRECT_REQUEST")
ef:RegisterEvent("TAXIMAP_CLOSED")
ef:RegisterEvent("TRADE_CLOSED")
ef:RegisterEvent("TRADE_SHOW")
ef:RegisterEvent("TRADE_ACCEPT_UPDATE")
ef:RegisterEvent("QUEST_FINISHED")
ef:RegisterEvent("QUEST_LOG_UPDATE")
ef:RegisterEvent("PARTY_MEMBERS_CHANGED")
ef:RegisterEvent("CHAT_MSG_SYSTEM")
ef:RegisterEvent("UPDATE_FACTION")
ef:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
ef:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
ef:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
ef:RegisterEvent("UNIT_INVENTORY_CHANGED")

ef:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == LeafVE_AchTest.name then
    EnsureDB()
    InstallResurrectionHooks()
    InstallQuestRewardHooks()
    -- Backlog: award completions from previously stored boss kill progress + history
    LeafVE_AchTest:CheckBacklogAchievements()
    Print("Achievement System Loaded! Type /achtest")
    Debug("Debug mode is: "..tostring(LeafVE_AchTest.DEBUG))
  end
  if event == "PLAYER_ENTERING_WORLD" then
    -- Re-run silent backlog checks now that live player data is available
    EnsureDB()
    InstallQuestRewardHooks()
    LeafVE_AchTest:CheckLevelAchievements(true)
    LeafVE_AchTest:CheckGoldAchievements(true)
    LeafVE_AchTest:CheckProfessionAchievements(true)
    LeafVE_AchTest:CheckQuestAchievements(true)
    LeafVE_AchTest:CheckPvPRankAchievements(true)
    LeafVE_AchTest:CheckReputationAchievements(true)
    LeafVE_AchTest:CheckBattlegroundAchievements(true)
    LeafVE_AchTest:CheckRunMilestoneAchievements(true)
    LeafVE_AchTest:CheckCachedProgressAchievements(true)
    LeafVE_AchTest:CheckExplorationAchievements(true)
    LeafVE_AchTest:CheckEquipmentAchievements(true)
    LeafVE_AchTest:CheckBacklogAchievements()
    LeafVE_AchTest:CheckAchievementMetaAchievements(true)
    do
      local me = ShortName(UnitName("player"))
      if me then
        SetCounter(me, "lastSeenLevel", UnitLevel("player") or 0)
      end
    end
    pendingAcceptedPlayerRes = false
    lastResurrectRequester = nil
    lastResurrectRequestTime = 0
    LeafVE_AchTest.initialized = true
  end
  if event == "PLAYER_TARGET_CHANGED" then
    local tname = UnitName("target")
    if tname then recentTargets[string.lower(tname)] = time() end
  end
  if event == "PLAYER_LEVEL_UP" and LeafVE_AchTest.initialized then
    local me = ShortName(UnitName("player"))
    if me then
      EnsureDB()
      local pc = LeafVE_AchTest_DB.progressCounters
      if not pc[me] then pc[me] = {} end

      local oldLevel = tonumber(pc[me].lastSeenLevel) or 0
      local eventLevel = tonumber(arg1) or 0
      local liveLevel = UnitLevel("player") or 0
      local newLevel = eventLevel

      if newLevel < 1 then newLevel = liveLevel end
      if liveLevel > newLevel then newLevel = liveLevel end
      -- This event means at least one level was gained; guard against stale payloads.
      if newLevel <= oldLevel then newLevel = oldLevel + 1 end

      LeafVE_AchTest:AwardLevelMilestonesBetween(oldLevel + 1, newLevel, false)
      SetCounter(me, "lastSeenLevel", newLevel)
    end
  end
  if event == "PLAYER_MONEY" and LeafVE_AchTest.initialized then LeafVE_AchTest:CheckGoldAchievements() end
  if event == "UPDATE_FACTION" and LeafVE_AchTest.initialized then LeafVE_AchTest:CheckReputationAchievements() end
  if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" and LeafVE_AchTest.initialized then
    LeafVE_AchTest:CheckEquipmentAchievements()
  end
  if (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL")
    and LeafVE_AchTest.initialized then
    LeafVE_AchTest:HandleBattlegroundSystemMessage(event, arg1 or "")
  end
  if event == "RESURRECT_REQUEST" then
    lastResurrectRequester = arg1
    lastResurrectRequestTime = GetTime()
  end
  if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
    -- Boss kill tracking only; generic kills are handled by LeafVE_Ach_Kills.lua.
    local msg = arg1 or ""
    local mobName
    -- Scenarios 1-3: explicit "You/Your party/Your raid has slain X!"
    mobName = smatch(msg, "^You have slain (.+)!$")
      or smatch(msg, "^Your party has slain (.+)!$")
      or smatch(msg, "^Your raid has slain (.+)!$")
    -- Scenarios 4-6: "X is slain by Y.", "X slain by Y.", "X has been slain by Y." (dot or excl)
    if not mobName then
      local slainTarget, killerName = smatch(msg, "^(.+) is slain by (.-)[%.!]?$")
      if not slainTarget then
        slainTarget, killerName = smatch(msg, "^(.+) slain by (.-)[%.!]?$")
      end
      if not slainTarget then
        slainTarget, killerName = smatch(msg, "^(.+) has been slain by (.-)[%.!]?$")
      end
      if slainTarget and killerName and IsPartyOrSelf(killerName) then
        mobName = slainTarget
      end
    end
    -- Fallback: "X dies." or "X has been slain." â€” validate via recent target / party / combat
    if not mobName then
      local fallbackName = smatch(msg, "^(.+) dies%.$")
        or smatch(msg, "^(.+) has been slain%.$")
      if fallbackName then
        local lname = string.lower(fallbackName)
        local recentlyTargeted = recentTargets[lname]
          and (time() - recentTargets[lname]) < BOSS_TARGET_WINDOW
        local partyTargeting = false
        if not recentlyTargeted then
          local numRaid = GetNumRaidMembers()
          local numParty = GetNumPartyMembers()
          if numRaid > 0 then
            for i = 1, numRaid do
              if UnitName("raid"..i.."target") == fallbackName then
                partyTargeting = true; break
              end
            end
          elseif numParty > 0 then
            for i = 1, numParty do
              if UnitName("party"..i.."target") == fallbackName then
                partyTargeting = true; break
              end
            end
          end
        end
        if recentlyTargeted or partyTargeting then
          mobName = fallbackName
        end
      end
    end
    if mobName then LeafVE_AchTest:CheckBossKill(mobName) end
  end
  if event == "PLAYER_DEAD" then
    playerWasDead = true
    pendingAcceptedPlayerRes = false
    local me = ShortName(UnitName("player"))
    if me then
      local total = IncrCounter(me, "deaths")
      SetCounter(me, "questsSinceDeath", 0)
      if total >= 50  then LeafVE_AchTest:AwardAchievement("casual_deaths_50")  end
      if total >= 100 then LeafVE_AchTest:AwardAchievement("casual_deaths_100") end
      -- Check if death was caused by falling (fall damage fired just before death)
      if GetTime() - lastFallDamageTime < DEATH_CLASSIFY_WINDOW then
        local fallTotal = IncrCounter(me, "fallDeaths")
        if fallTotal >= 10 then LeafVE_AchTest:AwardAchievement("casual_fall_death") end
        lastFallDamageTime = 0  -- prevent double-count if PLAYER_DEAD fires again
      end
      -- Check if death was caused by drowning (suffocation damage fired just before death)
      if GetTime() - lastDrownDamageTime < DEATH_CLASSIFY_WINDOW then
        local drownTotal = IncrCounter(me, "drownings")
        if drownTotal >= 10 then LeafVE_AchTest:AwardAchievement("casual_drown") end
        lastDrownDamageTime = 0  -- prevent double-count if PLAYER_DEAD fires again
      end
    end
  end
  if event == "QUEST_LOG_UPDATE" then
    -- Snapshot the quest log so we can diff on QUEST_FINISHED.
    questLogSnapshot = {}
    local numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
    for i = 1, numEntries do
      local title = GetQuestLogTitle and GetQuestLogTitle(i)
      if title and title ~= "" then
        questLogSnapshot[title] = true
      end
    end
  end
  if event == "QUEST_FINISHED" then
    -- Diff the current quest log against the snapshot; a missing title means turn-in.
    local me = ShortName(UnitName("player"))
    if me then
      local numEntries = GetNumQuestLogEntries and GetNumQuestLogEntries() or 0
      local currentLog = {}
      for i = 1, numEntries do
        local title = GetQuestLogTitle and GetQuestLogTitle(i)
        if title and title ~= "" then
          currentLog[title] = true
        end
      end
      local questTurnedIn = false
      local turnedInTitle = nil
      for title in pairs(questLogSnapshot) do
        if not currentLog[title] then
          questTurnedIn = true
          turnedInTitle = title
          break
        end
      end
      if questTurnedIn then
        RecordQuestTurnIn(me, turnedInTitle)
      end
      questLogSnapshot = currentLog
    end
  end
  if event == "PARTY_MEMBERS_CHANGED" then
    -- Award when first joining a group (party goes from 0 to 1+ members)
    local me = ShortName(UnitName("player"))
    local partySize = GetNumPartyMembers and GetNumPartyMembers() or 0
    if me then
      local pc = LeafVE_AchTest_DB and LeafVE_AchTest_DB.progressCounters
      if partySize >= 1 then
        local prev = pc and pc[me] and pc[me].lastPartySize or 0
        if prev == 0 then
          local total = IncrCounter(me, "groups")
          if total >= 50 then LeafVE_AchTest:AwardAchievement("casual_party_join") end
        end
        -- Refresh cached size for this player
        if pc and pc[me] then pc[me].lastPartySize = partySize end
      elseif partySize == 0 then
        if pc and pc[me] then pc[me].lastPartySize = 0 end
      end
    end
  end
  if event == "CHAT_MSG_SYSTEM" then
    local msg = arg1 or ""
    local completedQuestName = ExtractCompletedQuestName(msg)
    if completedQuestName then
      local me = ShortName(UnitName("player"))
      if me then
        RecordQuestTurnIn(me, completedQuestName)
      end
    end
    local winner, loser = smatch(msg, "^(.-) has defeated (.+) in a duel$")
    if winner then
      local me = ShortName(UnitName("player"))
      local winnerShort = ShortName(winner)
      local loserShort = ShortName(loser)
      if me and ShortName(winner) == me then
        Debug("Duel won against: "..tostring(loser))
        local total = IncrCounter(me, "duels")
        local streak = IncrCounter(me, "duelStreak")
        if total >= 10  then LeafVE_AchTest:AwardAchievement("pvp_duel_10")  end
        if total >= 25  then LeafVE_AchTest:AwardAchievement("pvp_duel_25")  end
        if total >= 50  then LeafVE_AchTest:AwardAchievement("pvp_duel_50")  end
        if total >= 100 then LeafVE_AchTest:AwardAchievement("pvp_duel_100") end
        if streak >= 25 then LeafVE_AchTest:AwardAchievement("pvp_duel_streak_25") end
      elseif me and loserShort == me and winnerShort ~= me then
        SetCounter(me, "duelStreak", 0)
      end
    end
  end
  if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    -- Only count resurrections when coming back from a previous death
    if playerWasDead then
      local shouldCountRes = pendingAcceptedPlayerRes
      playerWasDead = false
      pendingAcceptedPlayerRes = false
      lastResurrectRequester = nil
      if shouldCountRes then
        local me = ShortName(UnitName("player"))
        if me then
          local total = IncrCounter(me, "resurrections")
          if total >= 10 then LeafVE_AchTest:AwardAchievement("casual_resurrect_10") end
          if total >= 50 then LeafVE_AchTest:AwardAchievement("casual_resurrect_50") end
        end
      end
    end
  end
  if event == "TAXIMAP_CLOSED" then
    -- Use a short delay to allow PLAYER_CONTROL_LOST to fire and set isOnTaxi.
    local me = ShortName(UnitName("player"))
    if me then
      local elapsed = 0
      ef:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 0.5 then
          ef:SetScript("OnUpdate", nil)
          if isOnTaxi or (UnitOnTaxi and UnitOnTaxi("player")) then
            local total = IncrCounter(me, "flights")
            if total >= 10 then LeafVE_AchTest:AwardAchievement("casual_flight_10") end
            if total >= 50 then LeafVE_AchTest:AwardAchievement("casual_flight_50") end
          end
        end
      end)
    end
  end
  if event == "TRADE_SHOW" then
    tradeArmed     = true
    tradeCandidate = false
    firedThisTrade = false
    Debug("TRADE_SHOW: trade state reset")
  end
  if event == "TRADE_ACCEPT_UPDATE" then
    -- arg1 = player accept (1/0), arg2 = target accept (1/0)
    if arg1 == 1 and arg2 == 1 then
      tradeCandidate = true
      Debug("TRADE_ACCEPT_UPDATE: both accepted, candidate=true")
    else
      tradeCandidate = false
      Debug("TRADE_ACCEPT_UPDATE: accept retracted, candidate=false")
    end
  end
  if event == "TRADE_CLOSED" then
    if tradeArmed and tradeCandidate and not firedThisTrade then
      local me = ShortName(UnitName("player"))
      if me then
        local total = IncrCounter(me, "trades")
        Debug("TRADE_CLOSED: completed trade #"..total)
        if total >= 10 then LeafVE_AchTest:AwardAchievement("casual_trade_10") end
      end
      firedThisTrade = true
    else
      Debug("TRADE_CLOSED: not a completed trade (armed="..tostring(tradeArmed).." candidate="..tostring(tradeCandidate).." fired="..tostring(firedThisTrade)..")")
    end
    tradeArmed = false
  end
end)

-- Track environmental damage timestamps to classify the cause of death in PLAYER_DEAD.
-- Fall damage fires through CHAT_MSG_COMBAT_SELF_HITS ("You fall for X damage.").
-- Drowning (suffocation) fires through CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE ("You suffocate for X damage.").
local envFrame = CreateFrame("Frame")
envFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
envFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
envFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_COMBAT_SELF_HITS" then
    if string.find(arg1 or "", "You fall for") then
      lastFallDamageTime = GetTime()
    end
  elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
    if string.find(arg1 or "", "suffocate") then
      lastDrownDamageTime = GetTime()
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Bank-full tracking
-- ---------------------------------------------------------------------------

local bankFrameOpen = false

local function IsBankFull()
  -- Main bank bag (-1); if it has 0 slots the bank is not accessible
  local mainSlots = GetContainerNumSlots(-1)
  if mainSlots == 0 then return false end
  for slot = 1, mainSlots do
    if not GetContainerItemInfo(-1, slot) then return false end
  end
  -- Bank bag containers 5-10 (only purchased bags will have slots > 0)
  for bag = 5, 10 do
    local bagSlots = GetContainerNumSlots(bag)
    for slot = 1, bagSlots do
      if not GetContainerItemInfo(bag, slot) then return false end
    end
  end
  return true
end

local bankFrame = CreateFrame("Frame")
bankFrame:RegisterEvent("BANKFRAME_OPENED")
bankFrame:RegisterEvent("BANKFRAME_CLOSED")
bankFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
bankFrame:RegisterEvent("BAG_UPDATE")
bankFrame:SetScript("OnEvent", function()
  if event == "BANKFRAME_OPENED" then
    bankFrameOpen = true
    if IsBankFull() then
      local me = ShortName(UnitName("player"))
      if me then LeafVE_AchTest:AwardAchievement("casual_bank_full") end
    end
  elseif event == "BANKFRAME_CLOSED" then
    bankFrameOpen = false
  elseif (event == "PLAYERBANKSLOTS_CHANGED" or event == "BAG_UPDATE") and bankFrameOpen then
    if IsBankFull() then
      local me = ShortName(UnitName("player"))
      if me then LeafVE_AchTest:AwardAchievement("casual_bank_full") end
    end
  end
end)



-- Time a Hearthstone cast started (0 = not casting); used by the Vanilla 1.12
-- SPELLCAST_START / SPELLCAST_STOP path.
local pendingHearthstoneStart = 0

-- Mount cast pending state for casual_mount_60 / casual_epic_mount.
local mountCastPending      = false
local mountCastPendingTime  = 0
local mountAwardedThisCast  = false
local pendingMountIsEpic    = false
local pendingMountSpellName = nil
-- Maximum seconds between a mount SPELLCAST_START and SPELLCAST_STOP to count as a successful cast.
local MOUNT_CAST_WINDOW = 5

-- Fishing cast state: set when the player casts "Fishing"; cleared on interruption.
local fishingCastPending  = false
local fishingBobberActive = false
local MOUNT_PATTERNS = {
  "horse", "charger", "ram", "mechanostrider", "raptor", "wolf",
  "kodo", "tiger", "saber", "skeletal", "frostwolf", "nightsaber",
  "hawkstrider", "warhorse", "wyvern", "gryphon",
}
local MOUNT_EXACT_NAMES = {
  ["dire wolf"] = true,
}
-- Epic mount spell name patterns (lowercase).
local EPIC_MOUNT_PATTERNS = {
  "swift", "dreadsteed", "epic",
}
-- Paladin/Warlock class mounts that are always considered epic.
local EPIC_MOUNT_FULL = {
  "summon dreadsteed", "summon charger",
}

local function IsMountSpell(nameLower)
  if MOUNT_EXACT_NAMES[nameLower] then return true end
  if not string.find(nameLower, "summon") then return false end
  for _, p in ipairs(MOUNT_PATTERNS) do
    if string.find(nameLower, p, 1, true) then return true end
  end
  return false
end

local function IsEpicMountSpell(nameLower)
  for _, p in ipairs(EPIC_MOUNT_FULL) do
    if string.find(nameLower, p, 1, true) then return true end
  end
  for _, p in ipairs(EPIC_MOUNT_PATTERNS) do
    if string.find(nameLower, p, 1, true) then
      -- Must also look like a mount (contain summon or be a known class mount name)
      if string.find(nameLower, "summon") or string.find(nameLower, "mount") then
        return true
      end
    end
  end
  return false
end

local CLASS_MOUNT_QUEST_BACKFILL = {
  ["summon dreadsteed"] = "Dreadsteed of Xoroth",
  ["summon charger"] = "Charger",
}

local function BackfillClassMountQuest(spellName, silent)
  if not spellName or spellName == "" then return end
  if not LeafVE_AchTest or not LeafVE_AchTest.EnsureQuestCompletion then return end
  local me = ShortName(UnitName("player"))
  if not me then return end
  local questName = CLASS_MOUNT_QUEST_BACKFILL[string.lower(spellName)]
  if questName then
    LeafVE_AchTest.EnsureQuestCompletion(me, questName, silent)
  end
end

local spellFrame = CreateFrame("Frame")
spellFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
-- Vanilla 1.12 cast events (fire for the local player only; no unit ID in arg1).
spellFrame:RegisterEvent("SPELLCAST_START")
spellFrame:RegisterEvent("SPELLCAST_STOP")
spellFrame:RegisterEvent("SPELLCAST_INTERRUPTED")
spellFrame:RegisterEvent("SPELLCAST_FAILED")
spellFrame:SetScript("OnEvent", function()
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    if arg1 ~= "player" then return end
    local spellName = arg2 or ""
    BackfillClassMountQuest(spellName, false)
    if string.find(spellName, "^Hearthstone") then
      local me = ShortName(UnitName("player"))
      if me then
        local total = IncrCounter(me, "hearthstones")
        if total >= 1   then LeafVE_AchTest:AwardAchievement("casual_hearthstone_1")   end
        if total >= 50  then LeafVE_AchTest:AwardAchievement("casual_hearthstone_use") end
        if total >= 100 then LeafVE_AchTest:AwardAchievement("casual_hearthstone_100") end
      end
    end
    -- Bandage tracking (First Aid spells contain "Bandage" in the name)
    if string.find(spellName, "Bandage") then
      local me = ShortName(UnitName("player"))
      if me then
        local total = IncrCounter(me, "bandages")
        if total >= 25  then LeafVE_AchTest:AwardAchievement("casual_bandage_25")  end
        if total >= 100 then LeafVE_AchTest:AwardAchievement("casual_bandage_100") end
      end
    end

  elseif event == "SPELLCAST_START" then
    local spellName = string.lower(arg1 or "")
    if string.find(spellName, "^hearthstone") then
      pendingHearthstoneStart = GetTime()
    end
    -- Fishing detection
    if string.find(spellName, "^fishing") then
      fishingCastPending  = true
      fishingBobberActive = false
    end
    -- Mount detection
    local isEpicMount = IsEpicMountSpell(spellName)
    if IsMountSpell(spellName) or isEpicMount then
      mountCastPending     = true
      mountCastPendingTime = GetTime()
      mountAwardedThisCast = false
      pendingMountIsEpic   = isEpicMount
      pendingMountSpellName = spellName
      Debug("SPELLCAST_START: mount spell detected: "..(arg1 or ""))
    end

  elseif event == "SPELLCAST_STOP" then
    if pendingHearthstoneStart > 0 then
      local me = ShortName(UnitName("player"))
      if me then
        local total = IncrCounter(me, "hearthstones")
        if total >= 1   then LeafVE_AchTest:AwardAchievement("casual_hearthstone_1")   end
        if total >= 50  then LeafVE_AchTest:AwardAchievement("casual_hearthstone_use") end
        if total >= 100 then LeafVE_AchTest:AwardAchievement("casual_hearthstone_100") end
      end
      pendingHearthstoneStart = 0
    end
    -- Fishing cast completed: bobber has been placed in water.
    if fishingCastPending then
      fishingBobberActive = true
      fishingCastPending  = false
    end
    -- Mount cast completed (SPELLCAST_STOP fires on success in Vanilla 1.12)
    if mountCastPending and not mountAwardedThisCast and (GetTime() - mountCastPendingTime) <= MOUNT_CAST_WINDOW then
      local me = ShortName(UnitName("player"))
      if me then
        LeafVE_AchTest:AwardAchievement("casual_mount_60")
        if pendingMountIsEpic then
          LeafVE_AchTest:AwardAchievement("casual_epic_mount")
        end
        BackfillClassMountQuest(pendingMountSpellName, false)
        Debug("SPELLCAST_STOP: mount awarded")
      end
      mountAwardedThisCast = true
      mountCastPending     = false
      pendingMountSpellName = nil
    end

  elseif event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_FAILED" then
    pendingHearthstoneStart = 0
    mountCastPending        = false
    pendingMountIsEpic      = false
    pendingMountSpellName   = nil
    fishingCastPending      = false
    fishingBobberActive     = false
    Debug("SPELLCAST_INTERRUPTED/FAILED: mount cast cancelled")
  end
end)

-- Track fish catches via loot messages
local lootFrame = CreateFrame("Frame")
lootFrame:RegisterEvent("CHAT_MSG_LOOT")
lootFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- Keywords (lowercase) for matching fish item names in loot messages.
local FISH_KEYWORDS = {
  "fish", "snapper", "catfish", "smallfish", "grudgeon", "mightfish",
  "pufferfish", "swordfish", "tuna", "salmon", "trout", "eel",
  "whitefish", "mackere", "perch", "lobster", "craw", "shrimp",
  "oyster", "crab", "clam", "squid", "gourami",
}

lootFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_LOOT" then
    -- Only count fish looted while fishing (message says "receive loot")
    local msg = string.lower(arg1 or "")
    if not string.find(msg, "you receive loot") then return end
    local isFish = false
    for _, kw in ipairs(FISH_KEYWORDS) do
      if string.find(msg, kw, 1, true) then isFish = true; break end
    end
    if isFish and fishingBobberActive then
      fishingBobberActive = false
      local me = ShortName(UnitName("player"))
      if me then
        local total = IncrCounter(me, "fish")
        if total >= 25   then LeafVE_AchTest:AwardAchievement("casual_fish_25")   end
        if total >= 100  then LeafVE_AchTest:AwardAchievement("casual_fish_100")  end
        if total >= 1000 then LeafVE_AchTest:AwardAchievement("casual_fish_1000") end
      end
    end
    -- Count all looted items for casual_loot_* achievements
    local me = ShortName(UnitName("player"))
    if me and string.find(string.lower(arg1 or ""), "you receive loot") then
      local lootTotal = IncrCounter(me, "loots")
      if lootTotal >= 100  then LeafVE_AchTest:AwardAchievement("casual_loot_100")  end
      if lootTotal >= 1000 then LeafVE_AchTest:AwardAchievement("casual_loot_1000") end
      if lootTotal >= 5000 then LeafVE_AchTest:AwardAchievement("casual_loot_5000") end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Entering combat; can't be fishing, so clear the bobber/cast flags.
    fishingBobberActive = false
    fishingCastPending  = false
  end
end)

-- Track player emotes via CHAT_MSG_TEXT_EMOTE (fires when the local player uses an emote)
local emoteFrame = CreateFrame("Frame")
emoteFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
emoteFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_TEXT_EMOTE" then
    -- arg2 is the sender name; only count emotes from the local player
    local senderName = arg2 and smatch(arg2, "^([^%-]+)") or ""
    local me = ShortName(UnitName("player"))
    if me and ShortName(senderName) == me then
      local total = IncrCounter(me, "emotes")
      if total >= 25  then LeafVE_AchTest:AwardAchievement("casual_emote_25")  end
      if total >= 100 then LeafVE_AchTest:AwardAchievement("casual_emote_100") end
    end
  end
end)

SLASH_ACHTEST1 = "/achtest"
SlashCmdList["ACHTEST"] = function(msg)
  LeafVE_AchTest.UI:Build()
end

SLASH_LEAFACH1 = "/leafach"
SlashCmdList["LEAFACH"] = function()
  LeafVE_AchTest.UI:Build()
end

SLASH_ACHTESTDEBUG1 = "/achtestdebug"
SlashCmdList["ACHTESTDEBUG"] = function(msg)
  LeafVE_AchTest.DEBUG = not LeafVE_AchTest.DEBUG
  Print("Debug mode: "..tostring(LeafVE_AchTest.DEBUG))
end

SLASH_ACHSYNC1 = "/achsync"
SlashCmdList["ACHSYNC"] = function()
  LeafVE_AchTest:BroadcastAchievements()
  Print("Broadcasting achievements to guild...")
end

-- /achgrant <player> <achId>  â€” lets officers credit a player for pre-addon completions
-- Example: /achgrant Naruto rfc_complete    or    /achgrant Naruto raid_mc_complete
SLASH_ACHGRANT1 = "/achgrant"
SlashCmdList["ACHGRANT"] = function(msg)
  local _, rankName = GetGuildInfo("player")
  if not IsOfficerRank(rankName) then
    Print("Only Anbu, Sannin, or Hokage may grant achievements.")
    return
  end
  local target, achId = smatch(msg, "^(%S+)%s+(%S+)$")
  if not target or not achId then
    Print("Usage: /achgrant <PlayerName> <achievementId>")
    Print("Example: /achgrant Naruto dung_rfc_complete")
    return
  end
  local ok, targetOrError, achOrNil = LeafVE_AchTest:AdminGrantAchievement(target, achId, false)
  if not ok then
    Print(targetOrError)
    return
  end
  Print("|cFFFF7F00[Admin Grant]|r "..targetOrError.." awarded: |cFF2DD35C"..achOrNil.name.."|r (+"..achOrNil.points.." pts)")
end

SLASH_ACHGRANTGUILD1 = "/achgrantguild"
SlashCmdList["ACHGRANTGUILD"] = function(msg)
  local _, rankName = GetGuildInfo("player")
  if not IsOfficerRank(rankName) then
    Print("Only Anbu, Sannin, or Hokage may grant achievements.")
    return
  end
  local target, achId = smatch(msg, "^(%S+)%s+(%S+)$")
  if not target or not achId then
    Print("Usage: /achgrantguild <GuildieName> <achievementId>")
    Print("Example: /achgrantguild Naruto explore_tw_balor")
    return
  end
  local ok, targetOrError, achOrNil = LeafVE_AchTest:AdminGrantAchievement(target, achId, true)
  if not ok then
    Print(targetOrError)
    return
  end
  Print("|cFFFF7F00[Admin Guild Grant]|r "..targetOrError.." awarded: |cFF2DD35C"..achOrNil.name.."|r (+"..achOrNil.points.." pts)")
end

-- Chat Title Integration with Orange Color (Vanilla WoW Compatible)
local chatHooked = false

local function HookChatWithTitles()
  if chatHooked then 
    Debug("Chat already hooked")
    return 
  end
  
  Debug("Installing chat title hooks...")
  
  if type(originalSendChatMessage) == "function" then
    SendChatMessage = function(msg, chatType, language, channel)
      if chatType == "GUILD" and type(msg) == "string" and msg ~= "" then
        local hasLeafLink = string.find(msg, "|Hitem:"..LEAFVE_ANNOUNCEMENT_ITEM_ID..":0:0:0|h", 1, true)
        local hasLeafVillageBadge = string.find(msg, "|Hleafve_badge:", 1, true)
        local hasLeafVillageTitle = string.find(msg, "|Hleafve_title:", 1, true)
        local me = ShortName(UnitName("player"))
        local title = me and LeafVE_AchTest and LeafVE_AchTest.GetCurrentTitle and LeafVE_AchTest:GetCurrentTitle(me)
        local hasExistingTitle = hasLeafLink or hasLeafVillageBadge or hasLeafVillageTitle
        if not hasExistingTitle and me and LeafVE and LeafVE.GetEquippedTitleNameForPlayer then
          local leafVillageTitle = LeafVE:GetEquippedTitleNameForPlayer(me)
          if leafVillageTitle and leafVillageTitle ~= "" then
            local leafVillagePlainPrefix = tostring(leafVillageTitle).." "
            local leafVillageBracketedPrefix = "["..tostring(leafVillageTitle).."] "
            hasExistingTitle = string.sub(msg, 1, string.len(leafVillagePlainPrefix)) == leafVillagePlainPrefix
              or string.sub(msg, 1, string.len(leafVillageBracketedPrefix)) == leafVillageBracketedPrefix
          end
        end
        if not hasExistingTitle and title and title.name and title.name ~= "" then
          local ownPlainPrefix = tostring(title.name).." "
          local ownBracketedPrefix = "["..tostring(title.name).."] "
          hasExistingTitle = string.sub(msg, 1, string.len(ownPlainPrefix)) == ownPlainPrefix
            or string.sub(msg, 1, string.len(ownBracketedPrefix)) == ownBracketedPrefix
        end
        if not hasExistingTitle and not string.find(msg, "^/") and not string.find(msg, " has earned the achievement ", 1, true) then
          local titleLink = BuildAnnouncementTitleLink(title)
          if titleLink then
            msg = titleLink.." "..msg
          end
        end
      end
      return originalSendChatMessage(msg, chatType, language, channel)
    end
  end

  if type(originalSetItemRef) == "function" then
    SetItemRef = function(link, text, button, chatFrame)
      local itemId = tonumber(smatch(link or "", "item:(%d+)"))
      if itemId == LEAFVE_ANNOUNCEMENT_ITEM_ID and ShowAnnouncementTooltip(text) then
        return
      end
      return originalSetItemRef(link, text, button, chatFrame)
    end
  end
  
  chatHooked = true
  Print("Clickable guild title links enabled!")
  Debug("Chat hook complete")
end

-- Minimap Button
local minimapButton = CreateFrame("Button", "LeafVE_AchTestMinimapButton", Minimap)
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local MINIMAP_ICON_CANDIDATES = {
  "Interface\\Icons\\Spell_Nature_ResistNature",
  "Interface\\Icons\\INV_Misc_Book_09",
  "Interface\\Icons\\INV_Misc_QuestionMark",
}

local function ApplyMinimapIcon(tex)
  for _, path in ipairs(MINIMAP_ICON_CANDIDATES) do
    tex:SetTexture(path)
    if tex:GetTexture() then
      return
    end
  end
end

-- Icon
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetWidth(20)
icon:SetHeight(20)
ApplyMinimapIcon(icon)
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
icon:SetVertexColor(1, 1, 1, 1)
icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapButton.icon = icon

-- Border
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(52)
overlay:SetHeight(52)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", 0, 0)

-- Position on minimap
local function UpdateMinimapPosition()
  EnsureDB()
  if not LeafVE_AchTest_DB.minimapAngle then LeafVE_AchTest_DB.minimapAngle = 45 end
  local angle = math.rad(LeafVE_AchTest_DB.minimapAngle)
  local x = math.cos(angle) * 80
  local y = math.sin(angle) * 80
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

UpdateMinimapPosition()

-- Dragging functionality
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function()
  this:StartMoving()
end)

minimapButton:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local centerX, centerY = Minimap:GetCenter()
  local buttonX, buttonY = this:GetCenter()
  local angle = math.deg(math.atan2(buttonY - centerY, buttonX - centerX))
  if angle < 0 then angle = angle + 360 end
  EnsureDB()
  LeafVE_AchTest_DB.minimapAngle = angle
  UpdateMinimapPosition()
end)

-- Click to open
minimapButton:SetScript("OnClick", function()
  LeafVE_AchTest.UI:Build()
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:SetText("|cFF2DD35CLeafVillageAchievements|r", 1, 1, 1)
  GameTooltip:AddLine("Click to open", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Drag to move", 0.6, 0.6, 0.6)
  GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

Print("Minimap button loaded!")

-- ---------------------------------------------------------------------------
-- Zone discovery tracking for exploration achievements
-- Records both the major zone name (GetZoneText) and the subzone name
-- (GetSubZoneText) so that both continent-level (Kalimdor/Eastern Kingdoms)
-- and fine-grained (Elwynn Forest/Barrens) tracking work correctly.
-- ---------------------------------------------------------------------------
local zoneDiscFrame = CreateFrame("Frame")
zoneDiscFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneDiscFrame:RegisterEvent("ZONE_CHANGED")
zoneDiscFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneDiscFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneDiscFrame:SetScript("OnEvent", function()
  -- Skip discovery while on a taxi/flight path; subzone transitions during
  -- flight should not count as explored for achievement purposes.
  if isOnTaxi or (UnitOnTaxi and UnitOnTaxi("player")) then return end
  local me = ShortName(UnitName("player"))
  if not me then return end
  EnsureDB()
  if not LeafVE_AchTest_DB.exploredZones[me] then
    LeafVE_AchTest_DB.exploredZones[me] = {}
  end
  local zoneName  = GetZoneText and GetZoneText() or ""
  local subzone   = GetSubZoneText and GetSubZoneText() or ""
  -- Normalize names to match canonical entries in ZONE_GROUP_ZONES
  zoneName = NormalizeZoneName(zoneName)
  subzone  = NormalizeZoneName(subzone)
  -- Record new zone/subzone names and re-check all zone-group achievements
  local anyNew = false
  local newlyDiscovered = {}
  if zoneName ~= "" and not LeafVE_AchTest_DB.exploredZones[me][zoneName] then
    LeafVE_AchTest_DB.exploredZones[me][zoneName] = true
    anyNew = true
    newlyDiscovered[zoneName] = true
  end
  if subzone ~= "" and not LeafVE_AchTest_DB.exploredZones[me][subzone] then
    LeafVE_AchTest_DB.exploredZones[me][subzone] = true
    anyNew = true
    newlyDiscovered[subzone] = true
  end
  if not anyNew then
    LeafVE_AchTest:CheckExplorationAchievements(true)
    return
  end
  LeafVE_AchTest:CheckExplorationAchievements(false, newlyDiscovered)
end)

local hookTimer = 0
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hookFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    Debug("Player entering world - starting hook timer")
    hookTimer = 0
    hookFrame:SetScript("OnUpdate", function()
      hookTimer = hookTimer + arg1
      if hookTimer >= 3 then
        HookChatWithTitles()
        hookFrame:SetScript("OnUpdate", nil)
      end
    end)
  end
end)

Print("LeafVillageAchievements loaded successfully!")











