-- Relationships Achievements Core
-- Handles SavedVariables initialization, unlocking, and progress lookup.

RelationshipsAchievements = {}

local function EnsureDBs()
    if not RelationshipsAchievementsDB then
        RelationshipsAchievementsDB = { unlocked = {}, points = 0, stats = {} }
    end
    if not RelationshipsAchievementsDB.unlocked then RelationshipsAchievementsDB.unlocked = {} end
    if not RelationshipsAchievementsDB.points   then RelationshipsAchievementsDB.points = 0 end
    if not RelationshipsAchievementsDB.stats    then RelationshipsAchievementsDB.stats = {} end

    if not RelationshipsAchievementsCharDB then
        RelationshipsAchievementsCharDB = {
            unlocked = {},
            points = 0,
            stats = {},
            zones = {},
            factionsExalted = {},
            dungeonBosses = {},
            raidBosses = {},
        }
    end
    local d = RelationshipsAchievementsCharDB
    if not d.unlocked        then d.unlocked = {} end
    if not d.points          then d.points = 0 end
    if not d.stats           then d.stats = {} end
    if not d.zones           then d.zones = {} end
    if not d.factionsExalted then d.factionsExalted = {} end
    if not d.dungeonBosses   then d.dungeonBosses = {} end
    if not d.raidBosses      then d.raidBosses = {} end

    local legacy = { "questCount", "goldLooted", "honorKills", "deaths",
                     "killCount", "duelWins", "wsgWins", "avWins", "abWins",
                      "bgWins", "pvpKills", "zoneCount", "profSkill", "weaponSkill",
                      "exaltedCount", "dungeonsCleared", "raidsCleared", "friendCount",
                      "chatCount", "fishCount", "cookingSkill", "fishingSkill",
                      "recipesLearned", "petCount", "mountCount", "auctionsListed",
                      "auctionsWon", "vendorSales", "silithystTurnIns" }
    for i = 1, table.getn(legacy) do
        local k = legacy[i]
        if d[k] and not d.stats[k] then
            d.stats[k] = d[k]
            d[k] = nil
        end
    end
end

function RelationshipsAchievements:Init()
    EnsureDBs()
    -- Older versions could record a high counter without awarding every lower
    -- milestone. Reconcile all saved counters every login so progression can
    -- never contain (for example) 1,000 HKs without the 100 HK achievement.
    for i = 1, table.getn(RelationshipsAchievements_List) do
        local a = RelationshipsAchievements_List[i]
        if a.progress and not self:IsUnlocked(a.id) then
            local cur = self:GetStat(a.progress.stat, a.progress.accountStat)
            if cur >= a.progress.max then self:Unlock(a.id) end
        end
    end
end

function RelationshipsAchievements:IsUnlocked(id)
    local ach = RelationshipsAchievements_ById[id]
    if not ach then return false end
    if ach.account then
        return RelationshipsAchievementsDB.unlocked[id] ~= nil
    else
        return RelationshipsAchievementsCharDB.unlocked[id] ~= nil
    end
end

function RelationshipsAchievements:GetUnlockTime(id)
    local ach = RelationshipsAchievements_ById[id]
    if not ach then return nil end
    if ach.account then
        return RelationshipsAchievementsDB.unlocked[id]
    else
        return RelationshipsAchievementsCharDB.unlocked[id]
    end
end

function RelationshipsAchievements:GetStat(key, accountStat)
    if accountStat then
        return (RelationshipsAchievementsDB.stats and RelationshipsAchievementsDB.stats[key]) or 0
    end
    return (RelationshipsAchievementsCharDB.stats and RelationshipsAchievementsCharDB.stats[key]) or 0
end

function RelationshipsAchievements:SetStat(key, value, accountStat)
    if accountStat then
        if not RelationshipsAchievementsDB.stats then RelationshipsAchievementsDB.stats = {} end
        RelationshipsAchievementsDB.stats[key] = value
    else
        if not RelationshipsAchievementsCharDB.stats then RelationshipsAchievementsCharDB.stats = {} end
        RelationshipsAchievementsCharDB.stats[key] = value
    end
end

function RelationshipsAchievements:AddStat(key, delta, accountStat)
    delta = delta or 1
    local cur = self:GetStat(key, accountStat) + delta
    self:SetStat(key, cur, accountStat)
    for i = 1, table.getn(RelationshipsAchievements_List) do
        local a = RelationshipsAchievements_List[i]
        if a.progress and a.progress.stat == key and not self:IsUnlocked(a.id) then
            if cur >= a.progress.max then
                self:Unlock(a.id)
            end
        end
    end
    if RelationshipsAchievementFrame and RelationshipsAchievementFrame:IsVisible() and RelationshipsAchievements_RefreshUI then
        RelationshipsAchievements_RefreshUI()
    end
end

function RelationshipsAchievements:UpdateStat(key, value, accountStat)
    local cur = self:GetStat(key, accountStat)
    if value <= cur then return end
    self:SetStat(key, value, accountStat)
    for i = 1, table.getn(RelationshipsAchievements_List) do
        local a = RelationshipsAchievements_List[i]
        if a.progress and a.progress.stat == key and not self:IsUnlocked(a.id) then
            if value >= a.progress.max then
                self:Unlock(a.id)
            end
        end
    end
end

function RelationshipsAchievements:GetProgress(id)
    local ach = RelationshipsAchievements_ById[id]
    if not ach or not ach.progress then return nil end
    local cur = self:GetStat(ach.progress.stat, ach.progress.accountStat)
    if cur > ach.progress.max then cur = ach.progress.max end
    return cur, ach.progress.max
end

function RelationshipsAchievements:Unlock(id)
    local ach = RelationshipsAchievements_ById[id]
    if not ach then return end
    if self:IsUnlocked(id) then return end

    local now = time()
    if ach.account then
        RelationshipsAchievementsDB.unlocked[id] = now
        RelationshipsAchievementsDB.points = (RelationshipsAchievementsDB.points or 0) + (ach.points or 0)
    else
        RelationshipsAchievementsCharDB.unlocked[id] = now
        RelationshipsAchievementsCharDB.points = (RelationshipsAchievementsCharDB.points or 0) + (ach.points or 0)
    end

    if RelationshipsAchievements_ShowToast then
        RelationshipsAchievements_ShowToast(ach)
    end

    local link = "|cffffd200|Hrelach:"..ach.id.."|h["..ach.name.."]|h|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Achievement Earned:|r "..link)

    if RelationshipsAchievementFrame and RelationshipsAchievementFrame:IsVisible() and RelationshipsAchievements_RefreshUI then
        RelationshipsAchievements_RefreshUI()
    end
end

function RelationshipsAchievements:TotalPoints()
    return (RelationshipsAchievementsDB.points or 0) + (RelationshipsAchievementsCharDB.points or 0)
end

function RelationshipsAchievements:TotalUnlocked()
    local n = 0
    for _ in pairs(RelationshipsAchievementsDB.unlocked) do n = n + 1 end
    for _ in pairs(RelationshipsAchievementsCharDB.unlocked) do n = n + 1 end
    return n
end

function RelationshipsAchievements:TotalAvailable()
    return table.getn(RelationshipsAchievements_List)
end

function RelationshipsAchievements:CategoryProgress(catId)
    local total, done = 0, 0
    for i = 1, table.getn(RelationshipsAchievements_List) do
        local a = RelationshipsAchievements_List[i]
        if a.cat == catId then
            total = total + 1
            if self:IsUnlocked(a.id) then done = done + 1 end
        end
    end
    return done, total
end

-- Slash commands
SLASH_RELATIONSHIPSACHIEVEMENTS1 = "/rach"
SLASH_RELATIONSHIPSACHIEVEMENTS2 = "/relach"
SLASH_RELATIONSHIPSACHIEVEMENTS3 = "/relationshipsachievements"
SlashCmdList["RELATIONSHIPSACHIEVEMENTS"] = function(msg)
    if not msg then msg = "" end
    local _, _, cmd, rest = string.find(msg, "^(%S+)%s*(.-)$")
    if not cmd or cmd == "" then
        RelationshipsAchievements_Toggle()
        return
    end
    cmd = string.lower(cmd)
    if cmd == "unlock" then
        local id = tonumber(rest)
        if id then
            RelationshipsAchievements:Unlock(id)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Usage:|r /rach unlock <id>")
        end
    elseif cmd == "reset" then
        RelationshipsAchievementsDB = nil
        RelationshipsAchievementsCharDB = nil
        EnsureDBs()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Relationships Achievements reset.|r")
        if RelationshipsAchievementFrame and RelationshipsAchievementFrame:IsVisible() and RelationshipsAchievements_RefreshUI then
            RelationshipsAchievements_RefreshUI()
        end
    elseif cmd == "points" then
        DEFAULT_CHAT_FRAME:AddMessage("Achievement Points: "..RelationshipsAchievements:TotalPoints())
    elseif cmd == "scan" then
        if RelationshipsAchievements_ScanCharacter then RelationshipsAchievements_ScanCharacter() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Relationships Achievements: character rescanned.|r")
    elseif cmd == "test" then
        if RelationshipsAchievements_ShowToast and RelationshipsAchievements_ById[206] then
            RelationshipsAchievements_ShowToast(RelationshipsAchievements_ById[206])
        end
    elseif cmd == "minimap" then
        local sub = string.lower(rest or "")
        if sub == "show" then
            if RelationshipsAchievements_Minimap_Show then RelationshipsAchievements_Minimap_Show() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Minimap button shown.|r")
        elseif sub == "hide" then
            if RelationshipsAchievements_Minimap_Hide then RelationshipsAchievements_Minimap_Hide() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Minimap button hidden.|r")
        elseif sub == "reset" then
            if RelationshipsAchievements_Minimap_Reset then RelationshipsAchievements_Minimap_Reset() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Minimap button position reset.|r")
        else
            if RelationshipsAchievements_Minimap_Toggle then RelationshipsAchievements_Minimap_Toggle() end
        end
    elseif cmd == "played" then
        if RequestTimePlayed then RequestTimePlayed() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Relationships Achievements:|r reading /played for quest count...")
    elseif cmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Relationships Achievements commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach                - toggle window")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach unlock <id>    - unlock achievement by id")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach reset          - wipe all progress")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach points         - show total points")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach minimap [show|hide|reset] - control minimap button")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach played         - sync quest count from /played")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach scan           - rescan character stats")
        DEFAULT_CHAT_FRAME:AddMessage("  /rach test           - show a test toast")
    else
        RelationshipsAchievements_Toggle()
    end
end
