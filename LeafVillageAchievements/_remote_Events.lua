-- Event-driven achievement tracking, character scan, and hotkey binding.

local frame = CreateFrame("Frame", "RelationshipsAchievementsEventFrame", UIParent)

-- Turtle/OctoWoW builds expose slightly different event sets. Registering an
-- unknown event can abort an entire Lua file on some 1.12 clients, so optional
-- events are protected. The standard Vanilla events remain the primary path.
local function SafeRegister(name)
    pcall(frame.RegisterEvent, frame, name)
end
local trackedEvents = {
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "PLAYER_DEAD",
    "QUEST_COMPLETE", "QUEST_TURNED_IN", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS", "CHAT_MSG_COMBAT_HONOR_GAIN",
    "CHAT_MSG_COMBAT_FACTION_CHANGE", "SKILL_LINES_CHANGED", "CHAT_MSG_LOOT",
    "CHAT_MSG_MONEY", "CHAT_MSG_COMBAT_HOSTILE_DEATH", "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_SYSTEM", "UPDATE_FACTION", "PARTY_MEMBERS_CHANGED", "FRIENDLIST_UPDATE",
    "GUILD_ROSTER_UPDATE", "PLAYER_UNGHOST", "PLAYER_ALIVE", "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_EMOTE", "PLAYER_PVP_RANK_CHANGED", "PLAYER_PVP_KILLS_CHANGED",
    "PLAYER_PVPKILLS_CHANGED", "HONOR_CURRENCY_UPDATE", "HEARTHSTONE_BOUND",
    "BANKFRAME_OPENED", "TRAINER_SHOW", "MAIL_SEND_SUCCESS", "PLAYER_EQUIPMENT_CHANGED",
    "BAG_UPDATE", "CHARACTER_POINTS_CHANGED", "SPELLS_CHANGED", "UNIT_HEALTH", "PLAYER_MONEY",
    -- Vanilla 1.12 event names (PLAYER_EQUIPMENT_CHANGED does not exist here).
    "UNIT_INVENTORY_CHANGED", "ADDON_LOADED", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "TIME_PLAYED_MSG", "UNIT_PET", "UNIT_MODEL_CHANGED", "LEARNED_SPELL_IN_TAB",
    -- OctoWoW / Turtle backported Companion API (Pet menu "P" -> Companions tab)
    "COMPANION_LEARNED", "COMPANION_UPDATE", "COMPANION_UNLEARNED", "PET_UI_UPDATE"
}
for i = 1, table.getn(trackedEvents) do SafeRegister(trackedEvents[i]) end

-- ============ PvP rank scanning ============
-- Vanilla UnitPVPRank("player") returns 0 (no rank) or 5..19 where the
-- lowest ranked player is Private/Scout = 5. Subtract 4 to get 1..14.
local function ScanPvPRank()
    if not UnitPVPRank then return end
    local raw = UnitPVPRank("player") or 0
    -- Lifetime stats preserve the highest rank ever earned, even after weekly
    -- decay. Use whichever is higher so installing later still grants every
    -- lower title in the chain.
    if GetPVPLifetimeStats then
        local _, _, highest = GetPVPLifetimeStats()
        if highest and highest > raw then raw = highest end
    end
    if raw == 0 then return end
    local rank = raw
    if rank >= 5 then rank = rank - 4 end
    if rank < 1 then return end

    if rank >= 1  then RelationshipsAchievements:Unlock(2001) end -- Private / Scout
    if rank >= 3  then RelationshipsAchievements:Unlock(2002) end -- Sergeant / Senior Sergeant
    if rank >= 6  then RelationshipsAchievements:Unlock(2003) end -- Knight / Stone Guard
    if rank >= 9  then RelationshipsAchievements:Unlock(2004) end -- Champion / Centurion
    if rank >= 12 then RelationshipsAchievements:Unlock(2005) end -- Marshal / Legionnaire
    if rank >= 13 then RelationshipsAchievements:Unlock(2006) end -- Field Marshal / Warlord
    if rank >= 14 then
        local _, faction = UnitFactionGroup("player")
        if faction == "Horde" then
            RelationshipsAchievements:Unlock(1003) -- High Warlord
        else
            RelationshipsAchievements:Unlock(1002) -- Grand Marshal
        end
    end
end

local function ScanPvPKills()
    if not GetPVPLifetimeStats then return end
    local honorable = GetPVPLifetimeStats() or 0
    RelationshipsAchievements:UpdateStat("honorKills", honorable)
    if honorable >= 1 then RelationshipsAchievements:Unlock(501) end
end

local function ScanTalents()
    if not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo then return end
    local spent = 0
    for tab = 1, GetNumTalentTabs() do
        for talent = 1, GetNumTalents(tab) do
            local _, _, _, _, rank = GetTalentInfo(tab, talent)
            spent = spent + (rank or 0)
        end
    end
    if spent >= 1 then RelationshipsAchievements:Unlock(1111) end
    if spent >= 51 then RelationshipsAchievements:Unlock(1112) end
end

local previousTalentSpent
local function ScanTalentChange()
    if not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo then return end
    local spent = 0
    for tab = 1, GetNumTalentTabs() do
        for talent = 1, GetNumTalents(tab) do
            local _, _, _, _, rank = GetTalentInfo(tab, talent)
            spent = spent + (rank or 0)
        end
    end
    if previousTalentSpent and previousTalentSpent > 0 and spent == 0 then RelationshipsAchievements:Unlock(1113) end
    previousTalentSpent = spent
    ScanTalents()
end

-- Extract item quality from a link's color code. Robust when GetItemInfo has
-- not cached the item yet (common in 1.12 right after login or equip).
local QUALITY_BY_COLOR = {
    ["ff9d9d9d"] = 0, ["ffffffff"] = 1, ["ff1eff00"] = 2,
    ["ff0070dd"] = 3, ["ffa335ee"] = 4, ["ffff8000"] = 5,
}
local function QualityFromLink(link)
    if not link then return nil end
    local _, _, color = string.find(link, "|c(%x%x%x%x%x%x%x%x)")
    if not color then return nil end
    return QUALITY_BY_COLOR[string.lower(color)]
end

local function ScanEquipmentAndBags()
    if GetInventoryItemLink then
        if GetInventoryItemLink("player", 4) then RelationshipsAchievements:Unlock(1203) end
        if GetInventoryItemLink("player", 19) then RelationshipsAchievements:Unlock(109) end
        -- Well Equipped: every equipped armor/weapon slot must be Rare+.
        -- Slots that are legitimately optional on a spec (shirt, tabard,
        -- ranged, off-hand on 2H users) are skipped from the "all filled"
        -- check but still count when present.
        local requiredSlots = { 1,2,3,5,6,7,8,9,10,11,12,13,14,15,16 }
        local optionalSlots = { 17, 18 } -- off-hand, ranged
        local allRare, missing, epic = true, false, false
        local function eval(slot, required)
            local link = GetInventoryItemLink("player", slot)
            if not link then
                if required then missing = true end
                return
            end
            local _, _, q = GetItemInfo(link)
            local quality = q or QualityFromLink(link)
            if quality and quality >= 4 then epic = true end
            if required and (not quality or quality < 3) then allRare = false end
            local itemName = GetItemInfo(link)
            if itemName == "Atiesh, Greatstaff of the Guardian" then RelationshipsAchievements:Unlock(1004) end
            if itemName == "Thunderfury, Blessed Blade of the Windseeker" then RelationshipsAchievements:Unlock(1005) end
            if itemName == "Sulfuras, Hand of Ragnaros" then RelationshipsAchievements:Unlock(1006) end
        end
        for i = 1, table.getn(requiredSlots) do eval(requiredSlots[i], true) end
        for i = 1, table.getn(optionalSlots) do eval(optionalSlots[i], false) end
        if not missing and allRare then RelationshipsAchievements:Unlock(1208) end
        if epic then RelationshipsAchievements:Unlock(1209) end
    end
    if GetContainerNumSlots then
        local bags, has16 = 0, false
        for bag = 1, 4 do
            local slots = GetContainerNumSlots(bag) or 0
            if slots > 0 then bags = bags + 1 end
            if slots >= 16 then has16 = true end
        end
        if bags >= 4 then RelationshipsAchievements:Unlock(1202) end
        if has16 then RelationshipsAchievements:Unlock(1201) end
    end
end

-- Hidden tooltip used for spellbook scanning. Vanilla 1.12 does not expose
-- mount / non-combat-pet flags on spells, so we read the tooltip text — it
-- reliably distinguishes them across every locale-agnostic edge case we care
-- about because the mount / pet tooltip prefixes are stable in enUS clients.
local RA_ScanTip = CreateFrame("GameTooltip", "RelationshipsAchievementsScanTip", UIParent, "GameTooltipTemplate")
RA_ScanTip:SetOwner(UIParent, "ANCHOR_NONE")

-- ============ Known companion names (Vanilla + TurtleWoW / OctoWoW) ============
-- Any spell whose name matches one of these entries is credited as a
-- non-combat pet even when its tooltip doesn't contain the standard
-- keywords. Extend this list as new companions are added to the server.
local RA_KNOWN_COMPANIONS_LIST = {
    -- Vanilla non-combat pets
    "Ancona Chicken", "Azure Whelpling", "Bombay Cat", "Black Kingsnake",
    "Black Tabby", "Blue Dragonhawk Hatchling", "Brown Prairie Dog",
    "Brown Rabbit", "Brown Snake", "Calico Cat", "Cat Carrier (Bombay)",
    "Cat Carrier (Black Tabby)", "Cat Carrier (Cornish Rex)",
    "Cat Carrier (Orange Tabby)", "Cat Carrier (Siamese)",
    "Cat Carrier (Silver Tabby)", "Cat Carrier (White Kitten)",
    "Chicken Egg", "Cockroach", "Cornish Rex", "Crimson Whelpling",
    "Dark Whelpling", "Disgusting Oozeling", "Emerald Whelpling",
    "Firefly", "Frog", "Golden Dragonhawk Hatchling", "Great Horned Owl",
    "Green Wing Macaw", "Hawk Owl", "Hyacinth Macaw", "Island Frog",
    "Jubling", "Lifelike Mechanical Toad", "Lifelike Toad",
    "Little Fawn", "Mana Wyrmling", "Mechanical Squirrel Box",
    "Mini Diablo", "Mulgore Hatchling", "Orange Tabby",
    "Panda Cub", "Parrot Cage (Green Wing Macaw)",
    "Parrot Cage (Hyacinth Macaw)", "Parrot Cage (Senegal)",
    "Peddlefeet", "Personal World Destroyer", "Prairie Dog Whistle",
    "Red Dragonhawk Hatchling", "Sprite Darter Hatchling",
    "Senegal", "Siamese", "Silver Tabby", "Smolderweb Hatchling",
    "Snowshoe Rabbit", "Snowy Owl", "Speedy", "Stinker",
    "Tiny Green Dragon", "Tiny Red Dragon", "Tranquil Mechanical Yeti",
    "Tree Frog Box", "Turquoise Turtle", "Wanderer's Companion",
    "Westfall Chicken", "White Kitten", "Whiskers the Rat",
    "Winter Reindeer", "Winter's Little Helper", "Worg Carrier",
    "Worg Pup", "Wolpertinger", "Zergling",
    -- Turtle WoW / OctoWoW additions (community-known companions)
    "Baby Blizzard Bear", "Baby Crocolisk", "Baby Murloc",
    "Baby Ogre", "Baby Shark", "Baby Tallstrider", "Baby Turtle",
    "Bat Cub", "Bloodsail Cannonball", "Blue Moth", "Bronze Whelpling",
    "Captured Firefly", "Clockwork Rocket Bot", "Cobra Hatchling",
    "Coral Whelpling", "Corrupt Whelpling", "Deviate Hatchling",
    "Elekk Plushie", "Ethereal Soul-Trader", "Fel Whelpling",
    "Forest Frog", "Fox Kit", "Ghost Cat", "Ghostly Skull",
    "Gorilla Hatchling", "Grunty", "Hippogryph Hatchling",
    "Ivory Raptor", "Jade Whelpling", "Lil' Alexstrasza",
    "Lil' Deathwing", "Lil' K.T.", "Lil' Ragnaros", "Lil' Smoky",
    "Lil' Tarecgosa", "Lil' Timmy", "Lil' Wickerman", "Lil' XT",
    "Lucky Cricket", "Magical Crawdad", "Mechanical Chicken",
    "Micro Sentry", "Mini Tyrael", "Moonkin Hatchling",
    "Murky", "Naga Hatchling", "Netherwhelp", "Nightsaber Cub",
    "Onyx Whelpling", "Pandaren Monk", "Peanut", "Perky Pug",
    "Piglet's Collar", "Pink Elekk", "Plague Rat", "Polar Bear Cub",
    "Purple Turtle", "Quilen Cub", "Raptor Hatchling", "Red Panda",
    "Reef Wanderer", "Riding Turtle Hatchling", "Sand Kitten",
    "Sandbox Tiger", "Sandstone Drake", "Sea Pony", "Shore Crab",
    "Silithid Hatchling", "Snowball", "Snowy Rabbit",
    "Spectral Tiger Cub", "Stormwind Rat", "Swamp Frog",
    "Tiny Emerald Whelpling", "Tiny Sporebat", "Tricorne",
    "Turkey", "Undercity Cockroach", "Wisp", "Withers",
    "Ziggy the Sifaka",
    -- OctoWoW Companions tab (as shown in the "P" menu)
    "Green Steam Tonk", "Purple Steam Tonk", "Blue Steam Tonk",
    "Red Steam Tonk", "Yellow Steam Tonk", "Steam Tonk",
    "Steam Tonk Controller", "Control Console",
    "Lulu", "Mr. Wiggles", "Pet Bombling", "Lifelike Mechanical Toad",
    "Tranquil Mechanical Yeti", "Mechanical Squirrel",
    "Green Kitten", "Black Kitten", "Orange Kitten", "Cornish Rex Cat",
    "Bombay Cat", "Siamese Cat", "Silver Tabby Cat",
}
local RA_KNOWN_COMPANIONS_SET = {}
for _, n in ipairs(RA_KNOWN_COMPANIONS_LIST) do
    RA_KNOWN_COMPANIONS_SET[string.lower(n)] = true
end

-- Substring patterns that identify a companion regardless of colour / prefix.
-- Any spellbook or summoned pet name containing one of these (case-insensitive)
-- is treated as a known companion. Covers the OctoWoW / Turtle families where
-- every colour variant shares the same base name (e.g. "Green Steam Tonk",
-- "Purple Steam Tonk", "White Steam Tonk" all match "steam tonk").
local RA_COMPANION_PATTERNS = {
    "steam tonk", "kitten", "whelpling", "hatchling", "cub",
    "prairie dog", "rabbit", "squirrel", "toad", "frog",
    "cockroach", "cat carrier", "mechanical squirrel",
    "lil'", "lil ", "mini ", "tiny ", "baby ",
    "companion", "critter",
}

function RA_IsKnownCompanionName(name)
    if type(name) ~= "string" or name == "" then return false end
    local lower = string.lower(name)
    if RA_KNOWN_COMPANIONS_SET[lower] == true then return true end
    for _, pat in ipairs(RA_COMPANION_PATTERNS) do
        if string.find(lower, pat, 1, true) then return true end
    end
    return false
end

function RA_AddKnownCompanion(name)
    if type(name) == "string" and name ~= "" then
        RA_KNOWN_COMPANIONS_SET[string.lower(name)] = true
    end
end

-- Credit a companion by name into the same store the tooltip path uses so
-- the total petCount stays consistent no matter which detection path found it.
function RA_CreditCompanionByName(name)
    if not RA_IsKnownCompanionName(name) then return end
    if not RelationshipsAchievementsCharDB then return end
    if not RelationshipsAchievementsCharDB.countedPets then
        RelationshipsAchievementsCharDB.countedPets = {}
    end
    RelationshipsAchievementsCharDB.countedPets[name] = true
    local n = 0
    for _ in pairs(RelationshipsAchievementsCharDB.countedPets) do n = n + 1 end
    local companionPets = 0
    if RelationshipsAchievementsCharDB.countedCompanions then
        for _ in pairs(RelationshipsAchievementsCharDB.countedCompanions) do
            companionPets = companionPets + 1
        end
    end
    local total = n
    if companionPets > total then total = companionPets end
    RelationshipsAchievements:UpdateStat("petCount", total)
    if total >= 1  then RelationshipsAchievements:Unlock(1204) end
    if total >= 10 then RelationshipsAchievements:Unlock(1205) end
end

local function TooltipText(index, book)
    RA_ScanTip:ClearLines()
    RA_ScanTip:SetSpell(index, book)
    local text = ""
    for line = 1, RA_ScanTip:NumLines() do
        local fs = getglobal("RelationshipsAchievementsScanTipTextLeft"..line)
        if fs then
            local t = fs:GetText()
            if t then text = text .. "\n" .. t end
        end
    end
    return string.lower(text)
end

-- ============ Known mount names (Vanilla + TurtleWoW / OctoWoW) ============
-- Same rationale as the companion list: some private-server mounts (e.g. the
-- OctoWoW "Zebra") have tooltips that don't include the classic "mount speed"
-- / "rideable" phrasing, so tooltip scanning misses them. A name whitelist
-- guarantees credit whenever such a spell appears in the spellbook or is
-- summoned by the player.
local RA_KNOWN_MOUNTS_LIST = {
    -- Horde racial ground mounts (Vanilla)
    "Brown Wolf", "Dire Wolf", "Timber Wolf", "Red Wolf", "Winter Wolf",
    "Frostwolf", "Black Wolf", "Arctic Wolf", "Swift Brown Wolf",
    "Swift Timber Wolf", "Swift Gray Wolf", "Swift Frostwolf",
    "Black Skeletal Horse", "Blue Skeletal Horse", "Brown Skeletal Horse",
    "Red Skeletal Horse", "Green Skeletal Warhorse", "Purple Skeletal Warhorse",
    "Red Skeletal Warhorse", "Grey Kodo", "Brown Kodo", "Green Kodo",
    "Teal Kodo", "Great White Kodo", "Great Grey Kodo", "Great Brown Kodo",
    "Great Green Kodo", "Ivory Raptor", "Emerald Raptor", "Turquoise Raptor",
    "Violet Raptor", "Obsidian Raptor", "Swift Blue Raptor", "Swift Olive Raptor",
    "Swift Orange Raptor", "Whistle of the Emerald Raptor",
    "Whistle of the Ivory Raptor", "Whistle of the Turquoise Raptor",
    "Whistle of the Violet Raptor", "Whistle of the Mottled Red Raptor",
    -- Alliance racial ground mounts (Vanilla)
    "Pinto", "Palomino", "Chestnut Mare", "Brown Horse", "White Stallion",
    "Black Stallion", "Swift Brown Steed", "Swift Palomino", "Swift White Steed",
    "Gray Ram", "Brown Ram", "White Ram", "Black Ram", "Frost Ram",
    "Swift Gray Ram", "Swift Brown Ram", "Swift White Ram",
    "Mechanostrider", "Blue Mechanostrider", "Green Mechanostrider",
    "Red Mechanostrider", "White Mechanostrider", "Yellow Mechanostrider",
    "Unpainted Mechanostrider", "Swift Green Mechanostrider",
    "Swift White Mechanostrider", "Swift Yellow Mechanostrider",
    "Striped Frostsaber", "Striped Nightsaber", "Spotted Frostsaber",
    "Striped Dawnsaber", "Swift Frostsaber", "Swift Mistsaber",
    "Swift Stormsaber", "Reins of the Striped Frostsaber",
    "Reins of the Striped Nightsaber", "Reins of the Spotted Frostsaber",
    -- Class mounts (Vanilla)
    "Summon Warhorse", "Summon Charger", "Summon Felsteed", "Summon Dreadsteed",
    "Warhorse", "Charger", "Felsteed", "Dreadsteed",
    -- PvP / faction / reputation / rare mounts (Vanilla)
    "Black Battlestrider", "Black War Kodo", "Black War Ram", "Black War Raptor",
    "Black War Steed", "Black War Tiger", "Black War Wolf", "Horn of the Black War Wolf",
    "Horn of the Black Wolf", "Horn of the Brown Wolf", "Horn of the Dire Wolf",
    "Horn of the Red Wolf", "Horn of the Timber Wolf", "Horn of the Arctic Wolf",
    "Horn of the Frostwolf", "Horn of the Swift Brown Wolf",
    "Horn of the Swift Gray Wolf", "Horn of the Swift Timber Wolf",
    "Rivendare's Deathcharger", "Deathcharger's Reins", "Reins of the Rivendare's Deathcharger",
    "Winterspring Frostsaber", "Reins of the Winterspring Frostsaber",
    "Swift Zulian Tiger", "Reins of the Swift Zulian Tiger",
    "Swift Razzashi Raptor", "Reins of the Swift Razzashi Raptor",
    "Qiraji Battle Tank", "Reins of the Blue Qiraji Battle Tank",
    "Reins of the Green Qiraji Battle Tank", "Reins of the Red Qiraji Battle Tank",
    "Reins of the Yellow Qiraji Battle Tank",
    "Tawny Sabercat", "Reins of the Tawny Sabercat",
    "Cenarion War Hippogryph", "Reins of the Cenarion War Hippogryph",
    -- Turtle WoW / OctoWoW custom mounts (community-known)
    "Zebra", "Reins of the Zebra", "Whistle of the Zebra",
    "Zhevra", "Reins of the Zhevra",
    "Silver Riding Turtle", "Reins of the Silver Riding Turtle",
    "Riding Turtle", "Reins of the Riding Turtle",
    "Sea Turtle", "Reins of the Sea Turtle",
    "Brown Ostrich", "White Ostrich", "Black Ostrich", "Reins of the Ostrich",
    "Swift Ostrich", "Reins of the Swift Ostrich",
    "Camel", "Brown Camel", "Tan Camel", "White Camel", "Reins of the Camel",
    "Swift Camel", "Reins of the Swift Camel",
    "Reindeer", "Winter Reindeer", "Reins of the Reindeer",
    "Great Elk", "Reins of the Great Elk",
    "Moose", "Reins of the Moose", "Swift Moose",
    "Boar", "War Boar", "Reins of the War Boar", "Swift War Boar",
    "Bear Mount", "Riding Bear", "Reins of the Riding Bear",
    "Swift Bear", "Polar Bear", "Reins of the Polar Bear",
    "Cheetah", "Reins of the Cheetah", "Swift Cheetah",
    "Lion", "White Lion", "Reins of the White Lion",
    "Steam Tank Mount", "Steamscale", "Mechano-Hog",
    "Goblin Trike", "Trike", "Reins of the Trike",
    "Snow Leopard", "Reins of the Snow Leopard",
    "Ochre Skeletal Warhorse", "Ancona Chicken Mount",
    "Turtle Mount", "Great Sea Turtle",
    "Black Panther", "Reins of the Black Panther",
    "Giraffe", "Reins of the Giraffe",
    "Hyena", "Reins of the Hyena",
    "Ram of Ironforge", "Kodo of Thunder Bluff",
}
local RA_KNOWN_MOUNTS_SET = {}
for _, n in ipairs(RA_KNOWN_MOUNTS_LIST) do
    RA_KNOWN_MOUNTS_SET[string.lower(n)] = true
end

function RA_IsKnownMountName(name)
    if type(name) ~= "string" or name == "" then return false end
    return RA_KNOWN_MOUNTS_SET[string.lower(name)] == true
end

function RA_AddKnownMount(name)
    if type(name) == "string" and name ~= "" then
        RA_KNOWN_MOUNTS_SET[string.lower(name)] = true
    end
end

-- Persistent per-character store so name-detected mounts survive reloads and
-- merge with tooltip-detected ones without double counting.
function RA_CreditMountByName(name)
    if not RA_IsKnownMountName(name) then return end
    if not RelationshipsAchievementsCharDB then return end
    if not RelationshipsAchievementsCharDB.countedMounts then
        RelationshipsAchievementsCharDB.countedMounts = {}
    end
    RelationshipsAchievementsCharDB.countedMounts[string.lower(name)] = true
end

local function CountStoredMounts()
    if not RelationshipsAchievementsCharDB
       or not RelationshipsAchievementsCharDB.countedMounts then
        return 0
    end
    local n = 0
    for _ in pairs(RelationshipsAchievementsCharDB.countedMounts) do n = n + 1 end
    return n
end

local function ScanSpellbook()
    if not GetSpellName then return end
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
            local tip = TooltipText(i, book)
            -- Mounts: tooltip includes "mount speed" or "riding" descriptor.
            -- We match both the classic "increases speed by X%" line and the
            -- explicit "summons and dismisses a rideable" phrasing.
            local isMount = string.find(tip, "mount speed", 1, true)
                or string.find(tip, "rideable", 1, true)
                or string.find(tip, "summons and dismisses a rideable", 1, true)
            -- Non-combat pets: tooltip contains "right click to dismiss"
            -- or the classic "companion" descriptor. Explicitly exclude
            -- combat pets (hunter/warlock), which say "summons your pet".
            -- Non-combat pets: several tooltip phrasings exist across
            -- Vanilla / TurtleWoW / OctoWoW. Match any of them, then filter
            -- out combat pets (hunter/warlock) which say "summons your pet".
            local isPet = (
                string.find(tip, "companion", 1, true)
                or string.find(tip, "right click to dismiss", 1, true)
                or string.find(tip, "small pet", 1, true)
                or string.find(tip, "critter", 1, true)
                or string.find(tip, "summons and dismisses a", 1, true)
                or string.find(tip, "summons and dismisses your", 1, true)
                or string.find(tip, "summon a small", 1, true)
                or string.find(tip, "vanity pet", 1, true)
                or string.find(tip, "non-combat pet", 1, true)
            )
                and not string.find(tip, "summons your pet", 1, true)
                and not string.find(tip, "combat pet", 1, true)
                and not isMount
            if isMount then
                mounts = mounts + 1
                -- Epic ground mounts grant +100% speed in vanilla.
                if string.find(tip, "100%", 1, true) or string.find(tip, "epic", 1, true) then
                    hasEpicMount = true
                end
                if RA_CreditMountByName then RA_CreditMountByName(name) end
            elseif isPet then
                pets = pets + 1
            end
            -- Name-based fast path: known vanilla + Turtle/Octo companions.
            -- Ensures custom pets whose tooltips don't match keywords still count.
            if (not isPet) and (not isMount)
               and RA_IsKnownCompanionName and RA_IsKnownCompanionName(name) then
                pets = pets + 1
                if RA_CreditCompanionByName then RA_CreditCompanionByName(name) end
            end
            -- Name-based fast path: known vanilla + Turtle/Octo mounts.
            -- Catches custom mounts (e.g. Zebra) whose tooltips omit the
            -- classic "mount speed" / "rideable" keywords.
            if (not isMount) and (not isPet)
               and RA_IsKnownMountName and RA_IsKnownMountName(name) then
                mounts = mounts + 1
                if RA_CreditMountByName then RA_CreditMountByName(name) end
            end
        end
        i = i + 1
    end

    -- Fallback: Riding skill unambiguously proves mount ownership even if
    -- tooltip scanning missed a custom mount (Turtle/OctoWoW variants).
    if GetNumSkillLines then
        for s = 1, GetNumSkillLines() do
            local skill, header, _, rank = GetSkillLineInfo(s)
            if not header and skill == "Riding" and rank and rank > 0 then
                if mounts < 1 then mounts = 1 end
                if rank >= 150 then hasEpicMount = true end
            end
        end
    end

    -- Merge with the persistent name-detected mount store so counts never
    -- regress if a mount was seen previously but is currently unavailable
    -- from the spellbook scan (e.g. server API hiccup).
    local storedMounts = CountStoredMounts()
    if storedMounts > mounts then mounts = storedMounts end

    RelationshipsAchievements:UpdateStat("mountCount", mounts)
    RelationshipsAchievements:UpdateStat("petCount", pets)
    if mounts >= 1 then RelationshipsAchievements:Unlock(211) end
    if hasEpicMount and (UnitLevel("player") or 1) >= 60 then
        RelationshipsAchievements:Unlock(212)
    end
    if pets >= 1 then RelationshipsAchievements:Unlock(1204) end
end

-- Expose so slash command / minimap can force a rescan.
RelationshipsAchievements_ScanSpellbook = ScanSpellbook

-- ============ Companion API scanning (OctoWoW / Turtle) ============
-- OctoWoW's Pet menu ("P") has a Companions tab powered by the backported
-- Companion API (GetNumCompanions/GetCompanionInfo/CallCompanion). This is
-- the authoritative source for non-combat pet ownership on those clients
-- and is far more reliable than tooltip scanning the spellbook.
local function EnsureCountedCompanions()
    if not RelationshipsAchievementsCharDB then return nil end
    if not RelationshipsAchievementsCharDB.countedCompanions then
        RelationshipsAchievementsCharDB.countedCompanions = {}
    end
    return RelationshipsAchievementsCharDB.countedCompanions
end

local function CountTable(t)
    local n = 0
    if t then for _ in pairs(t) do n = n + 1 end end
    return n
end

local function ScanCompanions()
    if not GetNumCompanions then return end
    local counted = EnsureCountedCompanions()
    if not counted then return end
    -- Different builds/servers register the companion tab under different
    -- type strings. Try each so we always sync with the "P" menu Companions
    -- tab regardless of which naming OctoWoW / Turtle uses.
    local types = { "CRITTER", "COMPANION", "COMPANIONS", "PET", "MINIPET" }
    for _, ctype in ipairs(types) do
        local ok, num = pcall(GetNumCompanions, ctype)
        if ok and num and num > 0 then
            for i = 1, num do
                local ok2, _, name = pcall(GetCompanionInfo, ctype, i)
                if ok2 and name and name ~= "" then
                    counted[name] = true
                else
                    counted[ctype.."_"..i] = true
                end
            end
        end
    end
    local total = CountTable(counted)
    -- Merge with tooltip-scanned pets so we always report the higher value.
    local spellPets = (RelationshipsAchievementsCharDB.stats and RelationshipsAchievementsCharDB.stats.petCount) or 0
    if total < spellPets then total = spellPets end
    RelationshipsAchievements:UpdateStat("petCount", total)
    if total >= 1  then RelationshipsAchievements:Unlock(1204) end
    if total >= 10 then RelationshipsAchievements:Unlock(1205) end
end
RelationshipsAchievements_ScanCompanions = ScanCompanions

-- Backup path: hook CallCompanion so a summon always credits the pet, even
-- if the addon loaded before the Companion API populated.
if CallCompanion then
    local _origCallCompanion = CallCompanion
    CallCompanion = function(ctype, index)
        _origCallCompanion(ctype, index)
        if ctype == "CRITTER" then
            local counted = EnsureCountedCompanions()
            if counted then
                local ok, _, name = pcall(GetCompanionInfo, "CRITTER", index)
                local key = (ok and name and name ~= "") and name or ("companion_"..index)
                counted[key] = true
                local n = CountTable(counted)
                RelationshipsAchievements:UpdateStat("petCount", n)
                RelationshipsAchievements:Unlock(1204)
                if n >= 10 then RelationshipsAchievements:Unlock(1205) end
            end
        end
    end
end

-- Backup pet-count tracking: if a player casts a spell whose tooltip matches
-- pet criteria, ensure it counts. This catches Turtle/Octo custom companions
-- whose tooltips ScanSpellbook may not have visited yet.
local function EnsureCountedPets()
    if not RelationshipsAchievementsCharDB then return nil end
    if not RelationshipsAchievementsCharDB.countedPets then
        RelationshipsAchievementsCharDB.countedPets = {}
    end
    return RelationshipsAchievementsCharDB.countedPets
end

local function TooltipTextByName(spellName)
    if not spellName or spellName == "" then return "" end
    RA_ScanTip:ClearLines()
    -- SetSpell by index only; iterate spellbook once to find the name.
    if not GetSpellName then return "" end
    local book = BOOKTYPE_SPELL or "spell"
    local i = 1
    while true do
        local name = GetSpellName(i, book)
        if not name then break end
        if name == spellName then
            return TooltipText(i, book)
        end
        i = i + 1
    end
    return ""
end

local function CreditPetSpell(spellName)
    if not spellName or spellName == "" then return end
    local counted = EnsureCountedPets()
    if not counted then return end
    if counted[spellName] then return end
    -- Known-companion fast path (no tooltip required).
    if RA_IsKnownCompanionName and RA_IsKnownCompanionName(spellName) then
        counted[spellName] = true
        local n = 0
        for _ in pairs(counted) do n = n + 1 end
        local companionPets = 0
        if RelationshipsAchievementsCharDB and RelationshipsAchievementsCharDB.countedCompanions then
            for _ in pairs(RelationshipsAchievementsCharDB.countedCompanions) do
                companionPets = companionPets + 1
            end
        end
        local total = n
        if companionPets > total then total = companionPets end
        RelationshipsAchievements:UpdateStat("petCount", total)
        RelationshipsAchievements:Unlock(1204)
        if total >= 10 then RelationshipsAchievements:Unlock(1205) end
        return
    end
    local tip = TooltipTextByName(spellName)
    if tip == "" then return end
    local isPet = (
        string.find(tip, "companion", 1, true)
        or string.find(tip, "right click to dismiss", 1, true)
        or string.find(tip, "small pet", 1, true)
        or string.find(tip, "critter", 1, true)
        or string.find(tip, "summons and dismisses a", 1, true)
        or string.find(tip, "summons and dismisses your", 1, true)
        or string.find(tip, "vanity pet", 1, true)
        or string.find(tip, "non-combat pet", 1, true)
    )
        and not string.find(tip, "summons your pet", 1, true)
        and not string.find(tip, "mount speed", 1, true)
        and not string.find(tip, "rideable", 1, true)
    if isPet then
        counted[spellName] = true
        local n = 0
        for _ in pairs(counted) do n = n + 1 end
        RelationshipsAchievements:UpdateStat("petCount", n)
        RelationshipsAchievements:Unlock(1204)
    end
end

-- Credit a mount cast by name. Mirrors CreditPetSpell but for mounts,
-- using the known-mount whitelist so custom Turtle/OctoWoW mounts (e.g.
-- "Zebra") count the moment the player summons them, even if the client's
-- spellbook scan hadn't picked them up yet.
local function CreditMountSpell(spellName)
    if not spellName or spellName == "" then return end
    if not RA_IsKnownMountName or not RA_IsKnownMountName(spellName) then return end
    if not RelationshipsAchievementsCharDB then return end
    if not RelationshipsAchievementsCharDB.countedMounts then
        RelationshipsAchievementsCharDB.countedMounts = {}
    end
    local key = string.lower(spellName)
    if RelationshipsAchievementsCharDB.countedMounts[key] then return end
    RelationshipsAchievementsCharDB.countedMounts[key] = true
    local n = 0
    for _ in pairs(RelationshipsAchievementsCharDB.countedMounts) do n = n + 1 end
    -- Never regress the stat: prefer whichever count is higher.
    local prev = 0
    if RelationshipsAchievementsCharDB.stats
       and RelationshipsAchievementsCharDB.stats.mountCount then
        prev = RelationshipsAchievementsCharDB.stats.mountCount
    end
    if n < prev then n = prev end
    RelationshipsAchievements:UpdateStat("mountCount", n)
    RelationshipsAchievements:Unlock(211)
end

local _origCastSpellByName = CastSpellByName
if _origCastSpellByName then CastSpellByName = function(name, onSelf)
    _origCastSpellByName(name, onSelf)
    CreditPetSpell(name)
    CreditMountSpell(name)
end end

local _origCastSpell = CastSpell
if _origCastSpell then CastSpell = function(spellId, bookType)
    _origCastSpell(spellId, bookType)
    if GetSpellName then
        local n = GetSpellName(spellId, bookType or BOOKTYPE_SPELL or "spell")
        CreditPetSpell(n)
        CreditMountSpell(n)
    end
end end

local _origUseAction = UseAction
if _origUseAction then UseAction = function(slot, checkCursor, onSelf)
    _origUseAction(slot, checkCursor, onSelf)
    if GetActionText then
        local txt = GetActionText(slot)
        if txt then
            CreditPetSpell(txt)
            CreditMountSpell(txt)
        end
    end
end end


function RelationshipsAchievements_ScanCharacter()
    RelationshipsAchievements:Init()

    local lvl = UnitLevel("player") or 1
    if lvl >= 5  then RelationshipsAchievements:Unlock(216) end
    if lvl >= 10 then RelationshipsAchievements:Unlock(201) end
    if lvl >= 15 then RelationshipsAchievements:Unlock(218) end
    if lvl >= 20 then RelationshipsAchievements:Unlock(202) end
    if lvl >= 25 then RelationshipsAchievements:Unlock(219) end
    if lvl >= 30 then RelationshipsAchievements:Unlock(203) end
    if lvl >= 35 then RelationshipsAchievements:Unlock(220) end
    if lvl >= 40 then RelationshipsAchievements:Unlock(204) end
    if lvl >= 45 then RelationshipsAchievements:Unlock(221) end
    if lvl >= 50 then RelationshipsAchievements:Unlock(205) end
    if lvl >= 55 then RelationshipsAchievements:Unlock(222) end
    if lvl >= 60 then RelationshipsAchievements:Unlock(206) end

    -- Custom races and OctoWoW level milestone.
    local race = UnitRace("player")
    if race == "High Elf" or race == "HighElf" then RelationshipsAchievements:Unlock(1302) end
    if race == "Goblin" then RelationshipsAchievements:Unlock(1303) end
    if lvl >= 60 then RelationshipsAchievements:Unlock(1307) end

    -- Class-at-60 achievements
    if lvl >= 60 then
        local _, class = UnitClass("player")
        if     class == "WARRIOR" then RelationshipsAchievements:Unlock(1101)
        elseif class == "PALADIN" then RelationshipsAchievements:Unlock(1102)
        elseif class == "HUNTER"  then RelationshipsAchievements:Unlock(1103)
        elseif class == "ROGUE"   then RelationshipsAchievements:Unlock(1104)
        elseif class == "PRIEST"  then RelationshipsAchievements:Unlock(1105)
        elseif class == "SHAMAN"  then RelationshipsAchievements:Unlock(1106)
        elseif class == "MAGE"    then RelationshipsAchievements:Unlock(1107)
        elseif class == "WARLOCK" then RelationshipsAchievements:Unlock(1108)
        elseif class == "DRUID"   then RelationshipsAchievements:Unlock(1109)
        end
    end

    if GetGuildInfo and GetGuildInfo("player") then
        RelationshipsAchievements:Unlock(103)
        if GetNumGuildMembers and GetNumGuildMembers() >= 10 then RelationshipsAchievements:Unlock(1703) end
    end

    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        RelationshipsAchievements:Unlock(105)
    end

    if GetNumFriends and GetNumFriends() > 0 then
        RelationshipsAchievements:Unlock(102)
        RelationshipsAchievements:UpdateStat("friendCount", GetNumFriends())
    end

    if GetInventoryItemLink and GetInventoryItemLink("player", 19) then
        RelationshipsAchievements:Unlock(109)
    end

    -- Gold-in-bag achievements (retroactive on scan)
    if GetMoney then
        local copper = GetMoney() or 0
        if copper >= 100         then RelationshipsAchievements:Unlock(1901) end -- 1 silver
        if copper >= 10000       then RelationshipsAchievements:Unlock(1902) end -- 1 gold
        if copper >= 5000000     then RelationshipsAchievements:Unlock(223)  end -- 500g
        if copper >= 10000000    then RelationshipsAchievements:Unlock(1903) end -- 1000g
        if copper >= 50000000    then RelationshipsAchievements:Unlock(224)  end -- 5000g
        if copper >= 100000000   then RelationshipsAchievements:Unlock(1904) end -- 10000g
    end

    local zc = 0
    for _ in pairs(RelationshipsAchievementsCharDB.zones) do zc = zc + 1 end
    RelationshipsAchievements:UpdateStat("zoneCount", zc)

    if GetNumSkillLines then
        local highestProf = 0
        local highestWeapon = 0
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            if not isHeader and rank and rank > 0 then
                if name == "Swords" or name == "Two-Handed Swords"
                or name == "Axes"   or name == "Two-Handed Axes"
                or name == "Maces"  or name == "Two-Handed Maces"
                or name == "Daggers" or name == "Fist Weapons"
                or name == "Polearms" or name == "Staves"
                or name == "Bows" or name == "Crossbows" or name == "Guns"
                or name == "Wands" or name == "Thrown" then
                    if rank > highestWeapon then highestWeapon = rank end
                elseif name == "Cooking" then
                    RelationshipsAchievements:UpdateStat("cookingSkill", rank)
                elseif name == "Fishing" then
                    RelationshipsAchievements:UpdateStat("fishingSkill", rank)
                elseif name == "First Aid" then
                    if rank >= 300 then RelationshipsAchievements:Unlock(707) end
                else
                    if rank > highestProf then highestProf = rank end
                    if rank >= 300 then
                        if name == "Alchemy"       then RelationshipsAchievements:Unlock(708) end
                        if name == "Blacksmithing" then RelationshipsAchievements:Unlock(709) end
                        if name == "Enchanting"    then RelationshipsAchievements:Unlock(710) end
                        if name == "Engineering"   then RelationshipsAchievements:Unlock(711) end
                        if name == "Herbalism"     then RelationshipsAchievements:Unlock(712) end
                        if name == "Leatherworking"then RelationshipsAchievements:Unlock(713) end
                        if name == "Mining"        then RelationshipsAchievements:Unlock(714) end
                        if name == "Skinning"      then RelationshipsAchievements:Unlock(715) end
                        if name == "Tailoring"     then RelationshipsAchievements:Unlock(716) end
                    end
                end
            end
        end
        RelationshipsAchievements:UpdateStat("profSkill",   highestProf)
        RelationshipsAchievements:UpdateStat("weaponSkill", highestWeapon)
    end

    if GetNumFactions then
        local exalted = 0
        local hasFriendly, hasHonored, hasRevered, hasExalted = false, false, false, false
        for i = 1, GetNumFactions() do
            local name, _, standing = GetFactionInfo(i)
            if standing then
                if standing >= 5 then hasFriendly = true end
                if standing >= 6 then hasHonored  = true end
                if standing >= 7 then hasRevered  = true end
                if standing >= 8 then
                    hasExalted = true
                    exalted = exalted + 1
                    if name and RelationshipsAchievements_FactionMap[name] then
                        RelationshipsAchievements:Unlock(RelationshipsAchievements_FactionMap[name])
                    end
                    RelationshipsAchievementsCharDB.factionsExalted[name or "?"] = true
                end
            end
        end
        if hasFriendly then RelationshipsAchievements:Unlock(801) end
        if hasHonored  then RelationshipsAchievements:Unlock(802) end
        if hasRevered  then RelationshipsAchievements:Unlock(803) end
        if hasExalted  then RelationshipsAchievements:Unlock(804) end
        RelationshipsAchievements:UpdateStat("exaltedCount", exalted)
    end

    ScanPvPRank()
    ScanPvPKills()
    ScanTalents()
    ScanEquipmentAndBags()
    ScanSpellbook()
    if RelationshipsAchievements_ScanCompanions then
        RelationshipsAchievements_ScanCompanions()
    end

    RelationshipsAchievements_RefreshUI = RelationshipsAchievements_RefreshUI or function() end
    if RelationshipsAchievementFrame and RelationshipsAchievementFrame:IsVisible() then
        RelationshipsAchievements_RefreshUI()
    end
end

local function BindHotkey()
    if not SetBinding then return end
    local existing = GetBindingAction and GetBindingAction("Y")
    if existing and existing ~= "" and existing ~= "TOGGLERELATIONSHIPSACHIEVEMENT" then
        return
    end
    SetBinding("Y", "TOGGLERELATIONSHIPSACHIEVEMENT")
end

-- ============ SendChatMessage hook (Chatty achievement) ============
-- Wrapping SendChatMessage is more reliable than reading CHAT_MSG_SAY back,
-- because whispers, guild chat, and channels each fire different events and
-- some don't echo the sender field consistently on Turtle / Vanilla.
local _origSendChatMessage = SendChatMessage
if _origSendChatMessage then SendChatMessage = function(msg, chatType, language, target)
    _origSendChatMessage(msg, chatType, language, target)
    if msg and msg ~= "" and RelationshipsAchievements and RelationshipsAchievements.AddStat then
        RelationshipsAchievements:AddStat("chatCount", 1)
    end
end end

local _origSendMail = SendMail
if _origSendMail then SendMail = function(name, subject, body)
    _origSendMail(name, subject, body)
    RelationshipsAchievements:Unlock(110)
end end

-- Auction House API is provided by Blizzard_AuctionUI, which is Load-on-Demand
-- in 1.12. Hooking at file-load time silently no-ops because the globals are
-- still nil. HookAuctionHouse() runs again on ADDON_LOADED "Blizzard_AuctionUI"
-- so the hooks attach as soon as the AH frame is opened for the first time.
local auctionHooked = false
local function HookAuctionHouse()
    if auctionHooked then return end
    -- Vanilla 1.12 uses StartAuction(minBid, buyoutPrice, runTime) to list the
    -- item currently in the auction sell slot. PostAuction is a TBC+ API and
    -- does not exist on Turtle/Octowow, which is why listings were never
    -- being counted. Hook both so the addon keeps working if Turtle ever
    -- back-ports PostAuction.
    if not StartAuction and not PostAuction and not BuyoutAuction and not PlaceAuctionBid then return end
    auctionHooked = true
    if StartAuction then
        local _orig = StartAuction
        StartAuction = function(minBid, buyoutPrice, runTime)
            _orig(minBid, buyoutPrice, runTime)
            -- GetAuctionSellItemInfo returns (name, texture, count, ...); count is the stack size.
            local count = 1
            if GetAuctionSellItemInfo then
                local _, _, c = GetAuctionSellItemInfo()
                if c and c > 0 then count = c end
            end
            RelationshipsAchievements:AddStat("auctionsListed", 1)
            -- (We count one auction per listing action; `count` is stack size, not # of auctions.)
            local _ = count
        end
    end
    if PostAuction then
        local _orig = PostAuction
        PostAuction = function(minBid, buyoutPrice, runTime, stackSize, numStacks)
            _orig(minBid, buyoutPrice, runTime, stackSize, numStacks)
            RelationshipsAchievements:AddStat("auctionsListed", numStacks or 1)
        end
    end
    if BuyoutAuction then
        local _orig = BuyoutAuction
        BuyoutAuction = function(index)
            _orig(index)
            RelationshipsAchievements:Unlock(107)
            RelationshipsAchievements:AddStat("auctionsWon", 1)
        end
    end
    -- Many AH addons (and the default UI in some 1.12 builds) route the
    -- Buyout button through PlaceAuctionBid(list, index, bid) with bid ==
    -- buyout price. Hook it too so wins are always counted.
    if PlaceAuctionBid then
        local _orig = PlaceAuctionBid
        PlaceAuctionBid = function(listType, index, bid)
            _orig(listType, index, bid)
            local _, _, _, _, _, _, _, _, buyout = GetAuctionItemInfo(listType, index)
            if buyout and bid and bid >= buyout and buyout > 0 then
                RelationshipsAchievements:Unlock(107)
                RelationshipsAchievements:AddStat("auctionsWon", 1)
            end
        end
    end
end
HookAuctionHouse() -- attempt immediately in case the UI is already loaded.

-- ============ Vendor sales tracking ============
-- The merchant window is always the default UI; hooks are safe to install at
-- file-load time. Two vectors cover every sell path:
--   * UseContainerItem while MerchantFrame is visible = shift-click / right-
--     click sell from the bag.
--   * Drag-and-drop onto the merchant → PickupContainerItem then a click on
--     the merchant, which resolves via UseContainerItem too, so one hook
--     catches both cases.
local function MerchantOpen()
    return MerchantFrame and MerchantFrame:IsVisible()
end
local _origUseContainerItem = UseContainerItem
if _origUseContainerItem then UseContainerItem = function(bag, slot, target)
    local sellable = false
    if MerchantOpen() and GetContainerItemLink then
        local link = GetContainerItemLink(bag, slot)
        -- Skip if slot is empty or item is bound-cannot-sell? A no-op sell is
        -- harmless — the vendor simply refuses — so we count only when the
        -- API had something to act on.
        if link then sellable = true end
    end
    _origUseContainerItem(bag, slot, target)
    if sellable then
        RelationshipsAchievements:AddStat("vendorSales", 1)
    end
end end

local _origStaticPopupShow = StaticPopup_Show
if _origStaticPopupShow then StaticPopup_Show = function(which, text_arg1, text_arg2, data)
    local popup = _origStaticPopupShow(which, text_arg1, text_arg2, data)
    if which == "CONFIRM_BINDER" then RelationshipsAchievementsCharDB.pendingInnBind = true end
    return popup
end end

-- ============ DoEmote hook (Say Hello / Dance Off) ============
-- Hooking DoEmote is the cleanest way: the token is stable ("wave", "dance")
-- across all locales, unlike the CHAT_MSG_TEXT_EMOTE text which is localized.
local _origDoEmote = DoEmote
if _origDoEmote then
    DoEmote = function(token, target)
        _origDoEmote(token, target)
        if not token then return end
        local t = string.lower(token)
        if t == "wave" then
            RelationshipsAchievements:Unlock(1701)
        elseif t == "dance" then
            RelationshipsAchievements:Unlock(1702)
        end
    end
end

local loginScanDone = false

local function OnLogin()
    RelationshipsAchievements:Init()
    RelationshipsAchievements:Unlock(101)
    RelationshipsAchievements:Unlock(1301)
    BindHotkey()
    if not loginScanDone then
        loginScanDone = true
        local scanner = CreateFrame("Frame")
        local acc = 0
        scanner:SetScript("OnUpdate", function()
            acc = acc + (arg1 or 0)
            if acc >= 2 then
                RelationshipsAchievements_ScanCharacter()
                if ShowFriends then ShowFriends() end
                if GuildRoster  then GuildRoster()  end
                this:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local function OnLevelUp()
    RelationshipsAchievements_ScanCharacter()
end

local function OnQuestComplete()
    -- QUEST_COMPLETE is the reliable 1.12 turn-in event. Custom clients that
    -- also emit QUEST_TURNED_IN are de-duplicated by time stamp below.
    local now = time()
    if RelationshipsAchievementsCharDB.lastQuestCredit == now then return end
    RelationshipsAchievementsCharDB.lastQuestCredit = now
    RelationshipsAchievements:AddStat("questCount", 1)
    local title = GetTitleText and GetTitleText() or ""
    local low = string.lower(title or "")
    if string.find(low, "attunement to the core") then RelationshipsAchievements:Unlock(683) end
    if string.find(low, "blackhand's command") then RelationshipsAchievements:Unlock(682) end
    if string.find(low, "onyxia") or string.find(low, "great masquerade") then RelationshipsAchievements:Unlock(684) end
    if string.find(low, "head of onyxia") or string.find(low, "victory for the alliance") or string.find(low, "victory for the horde") then RelationshipsAchievements:Unlock(2104) end
    if string.find(low, "silithyst") then RelationshipsAchievements:AddStat("silithystTurnIns", 1) end
    if string.find(low, "class") then RelationshipsAchievements:Unlock(312) end
end

local function OnZoneChanged()
    local zone = GetRealZoneText() or GetZoneText()
    if not zone or zone == "" then return end

    if RelationshipsAchievements_CityMap and RelationshipsAchievements_CityMap[zone] then
        RelationshipsAchievements:Unlock(RelationshipsAchievements_CityMap[zone])
        RelationshipsAchievementsCharDB.cities = RelationshipsAchievementsCharDB.cities or {}
        if not RelationshipsAchievementsCharDB.cities[zone] then
            RelationshipsAchievementsCharDB.cities[zone] = true
            local a, h = 0, 0
            for c in pairs(RelationshipsAchievementsCharDB.cities) do
                if RelationshipsAchievements_AllianceCities[c] then a = a + 1 end
                if RelationshipsAchievements_HordeCities[c]    then h = h + 1 end
            end
            RelationshipsAchievements:UpdateStat("allianceCitiesVisited", a)
            RelationshipsAchievements:UpdateStat("hordeCitiesVisited",    h)
            if a >= 3 then RelationshipsAchievements:Unlock(1807) end
            if h >= 3 then RelationshipsAchievements:Unlock(1808) end
        end
    end
    local lowZone = string.lower(zone)
    if string.find(lowZone, "karazhan crypt") then RelationshipsAchievements:Unlock(1305) end
    if string.find(lowZone, "emerald sanctum") then RelationshipsAchievements:Unlock(1308) end

    if not RelationshipsAchievementsCharDB.zones[zone] then
        RelationshipsAchievementsCharDB.zones[zone] = true
        local id = RelationshipsAchievements_ZoneMap[zone]
        if id then RelationshipsAchievements:Unlock(id) end
        local count = 0
        for _ in pairs(RelationshipsAchievementsCharDB.zones) do count = count + 1 end
        RelationshipsAchievements:UpdateStat("zoneCount", count)
    end
end

local function OnHonorGain(msg)
    -- Objective/bonus honor uses this event too, so never increment blindly.
    -- Lifetime stats give the authoritative HK total and cannot double-count.
    if GetPVPLifetimeStats then
        local before = RelationshipsAchievements:GetStat("honorKills")
        ScanPvPKills()
        local after = RelationshipsAchievements:GetStat("honorKills")
        if after > before then
            RelationshipsAchievements:Unlock(501)
            RelationshipsAchievements:UpdateStat("pvpKills", after)
        end
    elseif msg and string.find(string.lower(msg), "honorable kill") then
        RelationshipsAchievements:Unlock(501)
        RelationshipsAchievements:AddStat("honorKills", 1)
        RelationshipsAchievements:AddStat("pvpKills", 1)
    end
end

local function OnFactionChange(msg)
    if not msg then return end
    -- Recompute from the faction table. Incrementing from chat inflated the
    -- count when duplicate messages fired and could award 5/10 Exalted early.
    RelationshipsAchievements_ScanCharacter()
end

local function OnSkillLinesChanged()
    RelationshipsAchievements_ScanCharacter()
end

local function OnLootMessage(msg)
    if not msg then return end
    local clean = string.gsub(msg, ",", "")
    local _, _, g = string.find(clean, "(%d+) Gold")
    if g then
        RelationshipsAchievements:AddStat("goldLooted", tonumber(g))
    end
    local low = string.lower(msg)
    if string.find(low, "fish") or string.find(low, "snapper") or string.find(low, "trout")
    or string.find(low, "salmon") or string.find(low, "catfish") or string.find(low, "eel") then
        RelationshipsAchievements:Unlock(1401)
        RelationshipsAchievements:AddStat("fishCount", 1)
    end
    if string.find(low, "you create") and (string.find(low, "food") or string.find(low, "meal")
    or string.find(low, "roast") or string.find(low, "stew")) then RelationshipsAchievements:Unlock(1501) end
end

local function OnEnemyDeath(msg)
    if not msg then return end
    if string.find(msg, "You have slain") or string.find(msg, "slain by you") then
        RelationshipsAchievements:AddStat("killCount", 1)
    end
    local bossMap = RelationshipsAchievements_BossMap or {}
    for boss, info in pairs(bossMap) do
        if string.find(msg, boss, 1, true) then
            RelationshipsAchievements:Unlock(info.id)
            local seen = info.raid and RelationshipsAchievementsCharDB.raidBosses or RelationshipsAchievementsCharDB.dungeonBosses
            if not seen[boss] then
                seen[boss] = true
                RelationshipsAchievements:AddStat(info.raid and "raidsCleared" or "dungeonsCleared", 1)
            end
        end
    end
end

-- Match Turtle/Octo /played extension lines that expose the character's
-- completed-quest total. Multiple phrasings observed across custom builds.
local function TryParseQuestCount(msg)
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
                RelationshipsAchievements:UpdateStat("questCount", n)
                return true
            end
        end
    end
end

local function OnSystemMessage(msg)
    if not msg then return end
    TryParseQuestCount(msg)
    local _, _, winner = string.find(msg, "^(.-) has defeated ")
    if winner and winner == UnitName("player") then
        RelationshipsAchievements:AddStat("duelWins", 1)
    end
    if string.find(msg, "home is now") or string.find(msg, "bound to") then
        RelationshipsAchievements:Unlock(108)
        RelationshipsAchievementsCharDB.pendingInnBind = nil
    end
    local low = string.lower(msg)
    if string.find(low, "learned a new") or string.find(low, "you have learned") then RelationshipsAchievements:Unlock(1110) end
    if string.find(low, "darkmoon faire") then RelationshipsAchievements:Unlock(911) end
    if string.find(low, "trick or treat") then RelationshipsAchievements:Unlock(903) end
    if string.find(low, "lunar festival") then RelationshipsAchievements:Unlock(909) end
    if string.find(low, "winter veil") then RelationshipsAchievements:Unlock(901) end
    -- Battleground victories (system messages contain "Warsong Gulch", etc.)
    if string.find(msg, "[Vv]ictory") or string.find(msg, "wins!") then
        if string.find(msg, "Warsong Gulch") then
            RelationshipsAchievements:Unlock(505)
            RelationshipsAchievements:AddStat("wsgWins", 1)
            RelationshipsAchievements:AddStat("bgWins", 1)
        elseif string.find(msg, "Alterac Valley") then
            RelationshipsAchievements:Unlock(506)
            RelationshipsAchievements:AddStat("avWins", 1)
            RelationshipsAchievements:AddStat("bgWins", 1)
        elseif string.find(msg, "Arathi Basin") then
            RelationshipsAchievements:Unlock(507)
            RelationshipsAchievements:AddStat("abWins", 1)
            RelationshipsAchievements:AddStat("bgWins", 1)
        end
    end
end

-- Emote handler: catch /wave and /dance in every locale by matching the
-- token via DoEmote hook AND as a fallback matching the English text here.
local function OnTextEmote(msg, sender)
    if not msg then return end
    local me = UnitName("player")
    -- vanilla emote text always begins with "You " when it's the local player,
    -- or the player's name otherwise.
    local mine = (sender and sender == me) or string.find(msg, "^You ")
    if not mine then return end
    if string.find(string.lower(msg), "wave") then
        RelationshipsAchievements:Unlock(1701)
    end
    if string.find(string.lower(msg), "dance") then
        RelationshipsAchievements:Unlock(1702)
    end
end

frame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        OnLogin()
    elseif event == "PLAYER_ENTERING_WORLD" then
        RelationshipsAchievements:Init()
        BindHotkey()
        OnZoneChanged()
        ScanPvPRank()
    elseif event == "PLAYER_LEVEL_UP" then
        OnLevelUp()
    elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
        if event == "PLAYER_DEAD" then
            RelationshipsAchievements:Unlock(207)
            RelationshipsAchievements:AddStat("deaths", 1)
        end
    elseif event == "QUEST_COMPLETE" or event == "QUEST_TURNED_IN" then
        OnQuestComplete()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        OnZoneChanged()
    elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        OnHonorGain(arg1)
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        OnFactionChange(arg1)
    elseif event == "SKILL_LINES_CHANGED" then
        OnSkillLinesChanged()
    elseif event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_MONEY" then
        OnLootMessage(arg1)
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "CHAT_MSG_COMBAT_XP_GAIN" then
        OnEnemyDeath(arg1)
    elseif event == "CHAT_MSG_SYSTEM" then
        OnSystemMessage(arg1)
    elseif event == "CHAT_MSG_TEXT_EMOTE" or event == "CHAT_MSG_EMOTE" then
        OnTextEmote(arg1, arg2)
    elseif event == "PLAYER_PVP_RANK_CHANGED"
        or event == "HONOR_CURRENCY_UPDATE"
        or event == "PLAYER_PVPKILLS_CHANGED" or event == "PLAYER_PVP_KILLS_CHANGED" then
        ScanPvPRank()
        ScanPvPKills()
    elseif event == "HEARTHSTONE_BOUND" then
        RelationshipsAchievements:Unlock(108)
        RelationshipsAchievementsCharDB.pendingInnBind = nil
    elseif event == "BANKFRAME_OPENED" then
        RelationshipsAchievements:Unlock(106)
    elseif event == "TRAINER_SHOW" then
        RelationshipsAchievements:Unlock(111)
    elseif event == "MAIL_SEND_SUCCESS" then
        RelationshipsAchievements:Unlock(110)
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or event == "UNIT_INVENTORY_CHANGED"
        or event == "BAG_UPDATE" then
        if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
        ScanEquipmentAndBags()
    elseif event == "ADDON_LOADED" then
        if arg1 == "Blizzard_AuctionUI" then HookAuctionHouse() end
    elseif event == "MERCHANT_SHOW" then
        -- Rescan equipment when opening a vendor — buying gear or repairs
        -- often coincides with equipping the item immediately after.
        ScanEquipmentAndBags()
        ScanSpellbook()
    elseif event == "CHARACTER_POINTS_CHANGED" then
        ScanTalentChange()
    elseif event == "SPELLS_CHANGED" then
        ScanSpellbook()
    elseif event == "PLAYER_MONEY" then
        if GetMoney then
            local copper = GetMoney() or 0
            if copper >= 100 then RelationshipsAchievements:Unlock(1901) end
            if copper >= 10000 then RelationshipsAchievements:Unlock(1902) end
            if copper >= 5000000 then RelationshipsAchievements:Unlock(223) end
            if copper >= 10000000 then RelationshipsAchievements:Unlock(1903) end
            if copper >= 50000000 then RelationshipsAchievements:Unlock(224) end
            if copper >= 100000000 then RelationshipsAchievements:Unlock(1904) end
        end
    elseif event == "UNIT_HEALTH" and arg1 == "player" then
        local maxHealth = UnitHealthMax("player") or 0
        if maxHealth > 0 and UnitHealth("player") > 0 and UnitHealth("player") * 10 < maxHealth then
            RelationshipsAchievements:Unlock(1605)
        end
    elseif event == "UPDATE_FACTION" then
        RelationshipsAchievements_ScanCharacter()
    elseif event == "PARTY_MEMBERS_CHANGED" then
        if GetNumPartyMembers and GetNumPartyMembers() > 0 then
            RelationshipsAchievements:Unlock(105)
        end
    elseif event == "FRIENDLIST_UPDATE" then
        if GetNumFriends and GetNumFriends() > 0 then
            RelationshipsAchievements:Unlock(102)
            RelationshipsAchievements:UpdateStat("friendCount", GetNumFriends())
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if GetGuildInfo and GetGuildInfo("player") then
            RelationshipsAchievements:Unlock(103)
            if GetNumGuildMembers and GetNumGuildMembers() >= 10 then RelationshipsAchievements:Unlock(1703) end
        end
    elseif event == "TIME_PLAYED_MSG" then
        -- Some /played variants (Turtle/Octo) also emit "Quests completed: N"
        -- as separate CHAT_MSG_SYSTEM lines around this event. Rescan the
        -- spellbook too so any pets learned since last scan are counted.
        if RelationshipsAchievements_ScanSpellbook then
            RelationshipsAchievements_ScanSpellbook()
        end
    elseif event == "UNIT_PET" or event == "UNIT_MODEL_CHANGED" then
        -- A pet/companion just spawned or despawned. Rescan the spellbook so
        -- newly-learned companion spells count immediately.
        if arg1 == "player" and RelationshipsAchievements_ScanSpellbook then
            RelationshipsAchievements_ScanSpellbook()
            if RelationshipsAchievements_ScanCompanions then
                RelationshipsAchievements_ScanCompanions()
            end
            -- Name-based fallback: if the summoned pet's unit name matches a
            -- known companion, credit it directly.
            if UnitName and RA_CreditCompanionByName then
                local petName = UnitName("pet")
                if petName then RA_CreditCompanionByName(petName) end
            end
        end
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UPDATE"
        or event == "COMPANION_UNLEARNED" or event == "PET_UI_UPDATE" then
        if RelationshipsAchievements_ScanCompanions then
            RelationshipsAchievements_ScanCompanions()
        end
    elseif event == "LEARNED_SPELL_IN_TAB" then
        if RelationshipsAchievements_ScanSpellbook then
            RelationshipsAchievements_ScanSpellbook()
        end
        if RelationshipsAchievements_ScanCompanions then
            RelationshipsAchievements_ScanCompanions()
        end
    end
end)
