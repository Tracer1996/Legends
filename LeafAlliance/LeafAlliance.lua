-- LeafAlliance
-- WoW 1.12 / Lua 5.0 addon
-- Joins the custom "Alliance" channel on login, suppresses all
-- join/leave notices for that channel, and locally restyles chat lines
-- from that channel with a yellow [Alliance] tag and yellow linked text.
-- Automatically joins the passworded Alliance channel.

local ADDON_NAME  = "LeafAlliance"
local CHANNEL_NAME = "Alliance"
local CHANNEL_PASSWORD = "Turtleboys"
local MAX_CHANNEL_SCAN = 50
local JOIN_RETRY_INITIAL_DELAY = 6.0
local JOIN_RETRY_INTERVAL = 0.8
local JOIN_RETRY_MAX_ATTEMPTS = 18
local JOIN_RETRY_FORCE_THRESHOLD = 3
local WHO_QUERY_INTERVAL = 2.0
local WHO_QUERY_TIMEOUT = 5.0
local WHO_QUERY_RETRY_DELAY = 30.0
local ALLIANCE_CHAT_R = 1.00
local ALLIANCE_CHAT_G = 0.82
local ALLIANCE_CHAT_B = 0.05
local ALLIANCE_PREFIX_HEX = "FF73C8FF"
local ALLIANCE_TEXT_HEX = "FFFFD10D"
local ALLIANCE_LINK_PREFIX = "leafalliance:"
local ALLIANCE_GUILD_LINK_PREFIX = "leafallianceguild:"
local ALLIANCE_TEXT_LINK_PREFIX = "leafalliancetext:"
local ALLIANCE_WORD_LINK_PREFIX = "leafallianceword:"
local ALLIANCE_WIRE_PREFIX = "~LAA1~TAG:"
local ALLIANCE_WIRE_BODY_PREFIX = "~LAA1~MSG:"
local HOOK_WATCHDOG_INTERVAL = 1.0

-- Frames & state
local frame = CreateFrame("Frame")
local hookWatchdogFrame = CreateFrame("Frame")
local whoQueryFrame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
frame:RegisterEvent("CHANNEL_UI_UPDATE")
frame:RegisterEvent("WHO_LIST_UPDATE")

local allianceChannelId = nil
local handlerGuard      = false
local setItemRefGuard   = false
local pratAllianceChannelKey = nil
local pratAllianceSavedShortname = nil
local pratAllianceSavedReplace = nil
local pendingAllianceChannelSetup = false
local joinRetryActive = false
local joinRetryDelay = 0
local joinRetryAttemptsRemaining = 0
local joinRetryWaitingForConfirmation = false
local lastAllianceAuthorRaw = ""
local lastAllianceAuthorNormalized = ""
local lastAllianceGuildTitle = ""
local lastAllianceMessageBody = ""
local lastAllianceRenderedLine = ""
local lastAllianceRenderedInput = ""
local lastAllianceRenderedPlain = ""
local lastAllianceRenderedMatched = false
local lastAllianceRenderedChannelTag = ""
local lastAllianceRenderedAuthorText = ""
local lastAllianceRenderedBodyText = ""
local hookWatchdogElapsed = 0
local pendingAllianceAuthor = nil
local pendingAllianceMessageBody = nil
local pendingAllianceMessageExpiresAt = 0
local pendingAllianceGuildTitle = nil
local playerGuildNameCache = ""
local authorGuildCache = {}
local authorGuildRetryAt = {}
local whoQueryQueue = {}
local queuedWhoLookups = {}
local activeWhoLookupName = nil
local activeWhoLookupElapsed = 0
local whoQueryCooldown = 0
local lastAllianceIncomingAuthor = ""
local lastAllianceIncomingRawMessage = ""
local lastAllianceIncomingParsedGuild = ""
local lastAllianceIncomingParsedBody = ""
local lastAllianceIncomingSource = ""
local lastAllianceOutgoingOriginalMessage = ""
local lastAllianceOutgoingWireMessage = ""
local lastAllianceOutgoingGuild = ""
local lastAllianceOutgoingChatType = ""
local lastAllianceOutgoingChannel = ""

-- Keep references to the active handlers so we can re-hook after
-- later-loading chat addons install their own wrappers.
local originalSetItemRef          = nil
local originalMessageEventHandler = nil
local originalSendChatMessage     = nil
local wrappedSetItemRef           = nil
local wrappedMessageEventHandler  = nil
local wrappedSendChatMessage      = nil
local IsAllianceRenderedChannelTag = nil
local GetAllianceGuildTitleForAuthor = nil
local BuildAllianceChatLine = nil

-- ------------------------------------------------------------------ --
-- Utility
-- ------------------------------------------------------------------ --

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[LeafAlliance]|r " .. (msg or ""))
    end
end

local function SafeLower(value)
    if value then
        return string.lower(value)
    end
    return ""
end

local function Trim(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function GetNamedGlobal(name)
    if type(getglobal) == "function" then
        return getglobal(name)
    end
    if _G then
        return _G[name]
    end
    return nil
end

local function EscapeAllianceLinkToken(text)
    local token = Trim(text or "")
    token = string.gsub(token, "%s+", "_")
    token = string.gsub(token, "[^%w_%-]", "")
    if token == "" then
        token = "guild"
    end
    return token
end

local function EscapeAllianceDisplayText(text)
    local displayText = tostring(text or "")
    displayText = string.gsub(displayText, "|", "||")
    return displayText
end

local function NormalizePlayerName(name)
    local text = Trim(name or "")
    local linkedName = string.match(text, "|Hplayer:([^:|]+)")
    if linkedName and linkedName ~= "" then
        text = linkedName
    else
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|r", "")
        text = string.gsub(text, "|H.-|h", "")
        text = string.gsub(text, "|h", "")
    end

    local bracketedLevelName = string.match(text, "^<%d+:(.-)>$")
    if bracketedLevelName and bracketedLevelName ~= "" then
        text = bracketedLevelName
    end

    local bracketedName = string.match(text, "^<(.-)>$")
    if bracketedName and bracketedName ~= "" then
        text = bracketedName
    end

    text = Trim(text)
    text = string.gsub(text, "%-.+$", "")
    return text
end

local function StripAllianceRenderedMarkup(text)
    local cleaned = tostring(text or "")
    cleaned = string.gsub(cleaned, "|c%x%x%x%x%x%x%x%x", "")
    cleaned = string.gsub(cleaned, "|r", "")
    cleaned = string.gsub(cleaned, "|H.-|h", "")
    cleaned = string.gsub(cleaned, "|h", "")
    return cleaned
end

local function StripLeadingAllianceRenderedPrefixes(text)
    local cleaned = tostring(text or "")

    cleaned = string.gsub(cleaned, "^%[%d%d?:%d%d:%d%d%]%s*", "")
    cleaned = string.gsub(cleaned, "^%[%d%d?:%d%d%]%s*", "")
    cleaned = string.gsub(cleaned, "^%d%d?:%d%d:%d%d%s+", "")
    cleaned = string.gsub(cleaned, "^%d%d?:%d%d%s+", "")

    return cleaned
end

local function SamePlayerName(leftName, rightName)
    local left = SafeLower(NormalizePlayerName(leftName))
    local right = SafeLower(NormalizePlayerName(rightName))
    return left ~= "" and left == right
end

local function GetPlayerGuildName()
    local guildName = ""

    if type(GetGuildInfo) ~= "function" then
        return playerGuildNameCache or ""
    end

    guildName = Trim((GetGuildInfo("player")) or "")
    if guildName ~= "" then
        playerGuildNameCache = guildName
        return guildName
    end

    return playerGuildNameCache or ""
end

local function GetAllianceChannelDisplayName()
    return CHANNEL_NAME
end

local function GetAllianceChannelTagText()
    return "[" .. GetAllianceChannelDisplayName() .. "]"
end

local function GetTimeSeconds()
    if type(GetTime) == "function" then
        return tonumber(GetTime()) or 0
    end

    return 0
end

local function EncodeAllianceWireField(value)
    local text = tostring(value or "")
    text = string.gsub(text, "%%", "%%25")
    text = string.gsub(text, "~", "%%7E")
    return text
end

local function DecodeAllianceWireField(value)
    local text = tostring(value or "")
    text = string.gsub(text, "%%7E", "~")
    text = string.gsub(text, "%%25", "%%")
    return text
end

local function ParseAllianceWireMessage(message)
    local text = tostring(message or "")
    local payload = ""
    local bodyStart = nil
    local bodyEnd = nil
    local guildField = ""
    local bodyText = ""

    if string.sub(text, 1, string.len(ALLIANCE_WIRE_PREFIX)) ~= ALLIANCE_WIRE_PREFIX then
        return "", text, false
    end

    payload = string.sub(text, string.len(ALLIANCE_WIRE_PREFIX) + 1)
    bodyStart, bodyEnd = string.find(payload, ALLIANCE_WIRE_BODY_PREFIX, 1, true)
    if not bodyStart then
        return "", text, false
    end

    guildField = string.sub(payload, 1, bodyStart - 1)
    bodyText = string.sub(payload, bodyEnd + 1)
    return Trim(DecodeAllianceWireField(guildField)), bodyText, true
end

local function BuildAllianceWireMessage(message, guildName)
    local cleanGuild = Trim(guildName or "")
    local cleanBody = tostring(message or "")
    return ALLIANCE_WIRE_PREFIX .. EncodeAllianceWireField(cleanGuild) .. ALLIANCE_WIRE_BODY_PREFIX .. cleanBody
end

local function StripAllianceWirePayloadInline(text)
    local rendered = tostring(text or "")
    local prefixStart = nil
    local leadingText = ""
    local payloadText = ""
    local guildName = ""
    local bodyText = ""
    local hadWirePayload = false

    prefixStart = string.find(rendered, ALLIANCE_WIRE_PREFIX, 1, true)
    if not prefixStart then
        return rendered, "", false
    end

    leadingText = string.sub(rendered, 1, prefixStart - 1)
    payloadText = string.sub(rendered, prefixStart)
    guildName, bodyText, hadWirePayload = ParseAllianceWireMessage(payloadText)
    if not hadWirePayload then
        return rendered, "", false
    end

    return leadingText .. tostring(bodyText or ""), guildName, true
end

local function CapturePendingAllianceMessage(author, message, guildName)
    pendingAllianceAuthor = tostring(author or "")
    pendingAllianceMessageBody = tostring(message or "")
    pendingAllianceGuildTitle = Trim(guildName or "")
    pendingAllianceMessageExpiresAt = GetTimeSeconds() + 2.0
end

local function ClearPendingAllianceMessage()
    pendingAllianceAuthor = nil
    pendingAllianceMessageBody = nil
    pendingAllianceGuildTitle = nil
    pendingAllianceMessageExpiresAt = 0
end

local function TryFormatPendingAllianceMessage(text)
    local rendered = tostring(text or "")
    local renderedPlain = ""
    local channelTag = nil
    local authorText = nil
    local bodyText = nil
    local effectiveAuthor = nil
    local effectiveBody = nil
    local effectiveGuild = nil

    if rendered == "" then
        return nil
    end
    if string.find(rendered, ALLIANCE_LINK_PREFIX, 1, true) ~= nil then
        return nil
    end
    if not pendingAllianceAuthor or pendingAllianceAuthor == "" then
        return nil
    end
    if pendingAllianceMessageExpiresAt > 0 and GetTimeSeconds() > pendingAllianceMessageExpiresAt then
        ClearPendingAllianceMessage()
        return nil
    end

    renderedPlain = StripAllianceRenderedMarkup(rendered)
    renderedPlain = StripLeadingAllianceRenderedPrefixes(renderedPlain)
    channelTag, authorText, bodyText = string.match(renderedPlain, "^%[([^%]]+)%]%s*(.-):%s*(.*)$")
    if not channelTag or not IsAllianceRenderedChannelTag(channelTag) then
        return nil
    end
    if authorText and Trim(authorText) ~= ""
            and not SamePlayerName(authorText, pendingAllianceAuthor) then
        return nil
    end

    effectiveAuthor = pendingAllianceAuthor
    if not effectiveAuthor or Trim(effectiveAuthor) == "" then
        effectiveAuthor = authorText or ""
    end

    effectiveBody = bodyText or ""
    if Trim(effectiveBody) == "" and pendingAllianceMessageBody ~= nil then
        effectiveBody = pendingAllianceMessageBody or ""
    end

    effectiveGuild = pendingAllianceGuildTitle or ""

    local formatted = BuildAllianceChatLine(
        effectiveAuthor,
        effectiveBody,
        effectiveGuild
    )
    ClearPendingAllianceMessage()
    return formatted
end

local function CacheAllianceGuildForPlayer(playerName, guildName)
    local normalized = NormalizePlayerName(playerName)
    if normalized == "" then
        return
    end

    authorGuildCache[normalized] = Trim(guildName or "")
    authorGuildRetryAt[normalized] = nil
end

local function MarkAllianceGuildLookupMiss(playerName)
    local normalized = NormalizePlayerName(playerName)
    if normalized == "" then
        return
    end

    authorGuildRetryAt[normalized] = GetTimeSeconds() + WHO_QUERY_RETRY_DELAY
end

local function CanRetryAllianceGuildLookup(playerName)
    local normalized = NormalizePlayerName(playerName)
    local retryAt = authorGuildRetryAt[normalized]

    if not retryAt then
        return true
    end

    if GetTimeSeconds() >= retryAt then
        authorGuildRetryAt[normalized] = nil
        return true
    end

    return false
end

local function QueueAllianceGuildLookup(playerName)
    local normalized = NormalizePlayerName(playerName)
    local playerNameText = UnitName and UnitName("player") or ""

    if normalized == "" then
        return
    end
    if authorGuildCache[normalized] ~= nil then
        return
    end
    if not CanRetryAllianceGuildLookup(normalized) then
        return
    end
    if playerNameText ~= "" and SamePlayerName(normalized, playerNameText) then
        CacheAllianceGuildForPlayer(normalized, GetPlayerGuildName())
        return
    end
    if activeWhoLookupName and SamePlayerName(activeWhoLookupName, normalized) then
        return
    end
    if queuedWhoLookups[normalized] then
        return
    end
    if type(SendWho) ~= "function" then
        return
    end

    table.insert(whoQueryQueue, normalized)
    queuedWhoLookups[normalized] = true
end

local function SendAllianceGuildWhoQuery(playerName)
    local normalized = NormalizePlayerName(playerName)

    if normalized == "" or type(SendWho) ~= "function" then
        return false
    end

    if type(SetWhoToUI) == "function" then
        pcall(SetWhoToUI, 1)
    end

    SendWho('n-"' .. normalized .. '"')
    activeWhoLookupName = normalized
    activeWhoLookupElapsed = 0
    whoQueryCooldown = WHO_QUERY_INTERVAL
    return true
end

local function ProcessAllianceGuildLookupQueue()
    local nextName = nil

    if activeWhoLookupName or whoQueryCooldown > 0 then
        return
    end
    if table.getn(whoQueryQueue) == 0 then
        return
    end

    nextName = table.remove(whoQueryQueue, 1)
    queuedWhoLookups[nextName] = nil
    if nextName and nextName ~= "" then
        SendAllianceGuildWhoQuery(nextName)
    end
end

local function CompleteAllianceGuildWhoQuery()
    local lookupName = activeWhoLookupName
    local totalResults = 0
    local matchedGuildName = nil
    local whoName = nil
    local whoGuildName = nil
    local i = 0

    if not lookupName then
        return
    end

    if type(GetNumWhoResults) == "function" then
        totalResults = tonumber(GetNumWhoResults()) or 0
    end

    if type(GetWhoInfo) == "function" then
        for i = 1, totalResults do
            whoName, whoGuildName = GetWhoInfo(i)
            if SamePlayerName(whoName, lookupName) then
                matchedGuildName = Trim(whoGuildName or "")
                break
            end
        end
    end

    if matchedGuildName ~= nil then
        CacheAllianceGuildForPlayer(lookupName, matchedGuildName)
    else
        MarkAllianceGuildLookupMiss(lookupName)
    end

    activeWhoLookupName = nil
    activeWhoLookupElapsed = 0
end

whoQueryFrame:SetScript("OnUpdate", function()
    local elapsed = tonumber(arg1) or 0

    if whoQueryCooldown > 0 then
        whoQueryCooldown = whoQueryCooldown - elapsed
        if whoQueryCooldown < 0 then
            whoQueryCooldown = 0
        end
    end

    if activeWhoLookupName then
        activeWhoLookupElapsed = activeWhoLookupElapsed + elapsed
        if activeWhoLookupElapsed >= WHO_QUERY_TIMEOUT then
            MarkAllianceGuildLookupMiss(activeWhoLookupName)
            activeWhoLookupName = nil
            activeWhoLookupElapsed = 0
        end
    end

    ProcessAllianceGuildLookupQueue()
end)

IsAllianceRenderedChannelTag = function(channelTag)
    local cleaned = Trim(channelTag or "")
    local rightSide = ""

    if cleaned == "" then
        return false
    end
    if SafeLower(cleaned) == SafeLower(CHANNEL_NAME) then
        return true
    end

    rightSide = string.match(cleaned, "^.-|%s*(.-)$") or ""
    return SafeLower(Trim(rightSide)) == SafeLower(CHANNEL_NAME)
end

local function DumpAlliancePlayerDebug(playerName, normalizedPlayerName)
    local guildName = nil
    local rankName = nil
    local rankIndex = nil
    local resolvedGuildTitle = ""

    if type(GetGuildInfo) == "function" then
        guildName, rankName, rankIndex = GetGuildInfo("player")
    end

    resolvedGuildTitle = GetAllianceGuildTitleForAuthor(normalizedPlayerName) or ""

    Print("playerName = [" .. tostring(playerName or "") .. "]")
    Print("normalizedPlayerName = [" .. tostring(normalizedPlayerName or "") .. "]")
    Print("GetGuildInfo(player).guildName = [" .. tostring(guildName or "") .. "]")
    Print("GetGuildInfo(player).rankName = [" .. tostring(rankName or "") .. "]")
    Print("GetGuildInfo(player).rankIndex = [" .. tostring(rankIndex or "") .. "]")
    Print("playerGuildNameCache = [" .. tostring(playerGuildNameCache or "") .. "]")
    Print("GetPlayerGuildName() = [" .. tostring(GetPlayerGuildName() or "") .. "]")
    Print("resolvedGuildTitle = [" .. tostring(resolvedGuildTitle or "") .. "]")
    Print("lastAllianceAuthorRaw = [" .. tostring(lastAllianceAuthorRaw or "") .. "]")
    Print("lastAllianceAuthorNormalized = [" .. tostring(lastAllianceAuthorNormalized or "") .. "]")
    Print("lastAllianceGuildTitle = [" .. tostring(lastAllianceGuildTitle or "") .. "]")
    Print("cachedGuildForLastAuthor = [" .. tostring(authorGuildCache[lastAllianceAuthorNormalized] or "") .. "]")
    Print("activeWhoLookupName = [" .. tostring(activeWhoLookupName or "") .. "]")
    Print("queuedWhoLookupCount = [" .. tostring(table.getn(whoQueryQueue)) .. "]")
    Print("pendingAllianceAuthor = [" .. tostring(pendingAllianceAuthor or "") .. "]")
    Print("pendingAllianceGuildTitle = [" .. tostring(pendingAllianceGuildTitle or "") .. "]")
    Print("pendingAllianceMessageBody = [" .. tostring(pendingAllianceMessageBody or "") .. "]")
end

local function DumpAllianceTrafficDebug()
    Print("lastIncomingAuthor = [" .. tostring(lastAllianceIncomingAuthor or "") .. "]")
    Print("lastIncomingRawMessage = [" .. tostring(lastAllianceIncomingRawMessage or "") .. "]")
    Print("lastIncomingParsedGuild = [" .. tostring(lastAllianceIncomingParsedGuild or "") .. "]")
    Print("lastIncomingParsedBody = [" .. tostring(lastAllianceIncomingParsedBody or "") .. "]")
    Print("lastIncomingSource = [" .. tostring(lastAllianceIncomingSource or "") .. "]")
    Print("lastOutgoingChatType = [" .. tostring(lastAllianceOutgoingChatType or "") .. "]")
    Print("lastOutgoingChannel = [" .. tostring(lastAllianceOutgoingChannel or "") .. "]")
    Print("lastOutgoingGuild = [" .. tostring(lastAllianceOutgoingGuild or "") .. "]")
    Print("lastOutgoingOriginalMessage = [" .. tostring(lastAllianceOutgoingOriginalMessage or "") .. "]")
    Print("lastOutgoingWireMessage = [" .. tostring(lastAllianceOutgoingWireMessage or "") .. "]")
    Print("sendChatWrapped = [" .. tostring(SendChatMessage == wrappedSendChatMessage) .. "]")
end

local function DumpAllianceRenderDebug(normalizedPlayerName)
    Print("lastAllianceMessageBody = [" .. tostring(lastAllianceMessageBody or "") .. "]")
    Print("authorMatchesPlayer = [" .. tostring(SamePlayerName(lastAllianceAuthorNormalized, normalizedPlayerName)) .. "]")
    Print("messageHandlerWrapped = [" .. tostring(ChatFrame_MessageEventHandler == wrappedMessageEventHandler) .. "]")
    Print("defaultFrameWrapped = [" .. tostring(DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage == DEFAULT_CHAT_FRAME.leafAllianceWrappedAddMessage) .. "]")
    Print("chatFrame1Wrapped = [" .. tostring(ChatFrame1 and ChatFrame1.AddMessage == ChatFrame1.leafAllianceWrappedAddMessage) .. "]")
    Print("lastRenderedMatched = [" .. tostring(lastAllianceRenderedMatched) .. "]")
    Print("lastRenderedChannelTag = [" .. tostring(lastAllianceRenderedChannelTag or "") .. "]")
    Print("lastRenderedAuthorText = [" .. tostring(lastAllianceRenderedAuthorText or "") .. "]")
    Print("lastRenderedBodyText = [" .. tostring(lastAllianceRenderedBodyText or "") .. "]")
    Print("lastRenderedPlain = [" .. tostring(lastAllianceRenderedPlain or "") .. "]")
end

local function DumpGuildDebugState()
    local playerName = UnitName and UnitName("player") or ""
    local normalizedPlayerName = NormalizePlayerName(playerName or "")

    Print("Guild debug:")
    DumpAlliancePlayerDebug(playerName, normalizedPlayerName)
    DumpAllianceTrafficDebug()
    DumpAllianceRenderDebug(normalizedPlayerName)
end

-- ------------------------------------------------------------------ --
-- Channel-id tracking
-- ------------------------------------------------------------------ --

local function RefreshAllianceChannelId()
    if not GetChannelName then
        allianceChannelId = nil
        return
    end

    allianceChannelId = nil
    for i = 1, MAX_CHANNEL_SCAN do
        local id, name = GetChannelName(i)
        if id and id > 0 and name and SafeLower(name) == SafeLower(CHANNEL_NAME) then
            allianceChannelId = id
            return
        end
    end
end

local function IsGeneralChannelName(name)
    local lowered = SafeLower(name)
    return string.find(lowered, "general", 1, true) ~= nil
end

local function IsDefaultPublicChannelName(name)
    local lowered = SafeLower(name)

    if lowered == "" then
        return false
    end

    return string.find(lowered, "general", 1, true) ~= nil
        or string.find(lowered, "trade", 1, true) ~= nil
        or string.find(lowered, "defense", 1, true) ~= nil
        or string.find(lowered, "guildrecruitment", 1, true) ~= nil
        or string.find(lowered, "lookingforgroup", 1, true) ~= nil
end

local function AreDefaultChannelSlotsReady()
    local id, name = nil, nil
    local activeChannelCount = 0
    local i = 0

    if not GetChannelName then
        return false
    end

    id, name = GetChannelName(1)
    if not id or id == 0 or not name then
        return false
    end

    if SafeLower(name) == SafeLower(CHANNEL_NAME) then
        return false
    end

    if IsDefaultPublicChannelName(name) or IsGeneralChannelName(name) then
        return true
    end

    for i = 1, 5 do
        id, name = GetChannelName(i)
        if id and id > 0 and name and name ~= "" then
            activeChannelCount = activeChannelCount + 1
            if SafeLower(name) ~= SafeLower(CHANNEL_NAME)
                    and IsDefaultPublicChannelName(name) then
                return true
            end
        end
    end

    return activeChannelCount >= 2
end

local function IsAllianceChannel(channelName, channelNumber)
    if channelName and SafeLower(channelName) == SafeLower(CHANNEL_NAME) then
        return true
    end

    if allianceChannelId and channelNumber
            and tonumber(channelNumber) == tonumber(allianceChannelId) then
        return true
    end

    return false
end

local function IsAllianceSystemNoticeText(text)
    text = SafeLower(Trim(text))
    if text == "" then
        return false
    end

    return string.find(text, "owner changed to", 1, true) ~= nil
        or string.find(text, "changed owner to", 1, true) ~= nil
        or string.find(text, "channel owner", 1, true) ~= nil
        or string.find(text, "joined channel", 1, true) ~= nil
        or string.find(text, "joined the channel", 1, true) ~= nil
        or string.find(text, "has joined", 1, true) ~= nil
        or string.find(text, "left channel", 1, true) ~= nil
        or string.find(text, "left the channel", 1, true) ~= nil
        or string.find(text, "has left", 1, true) ~= nil
end

local function MessageTargetsAllianceChannel(text)
    text = SafeLower(Trim(text))
    local desiredName = SafeLower(CHANNEL_NAME)

    if text == "" then
        return false
    end
    if desiredName ~= "" and string.find(text, desiredName, 1, true) ~= nil then
        return true
    end
    if allianceChannelId and allianceChannelId > 0 then
        local idText = tostring(allianceChannelId)
        if string.find(text, "[" .. idText .. "]", 1, true) ~= nil
                or string.find(text, idText .. ".", 1, true) ~= nil then
            return true
        end
    end

    return false
end

local function IsAllianceOutgoingChannel(channel)
    local numericChannel = tonumber(channel)
    local derivedChannelText = ""
    local bracketedChannelTag = ""
    local leadingChannelNumber = nil

    if numericChannel and allianceChannelId and numericChannel == tonumber(allianceChannelId) then
        return true
    end

    if type(channel) == "string" then
        local channelText = Trim(channel)
        derivedChannelText = string.gsub(channelText, "^%d+%.%s*", "")
        bracketedChannelTag = string.match(derivedChannelText, "^%[(.+)%]$") or ""
        leadingChannelNumber = tonumber(string.match(channelText, "^(%d+)%."))
        if SafeLower(channelText) == SafeLower(CHANNEL_NAME) then
            return true
        end
        if SafeLower(derivedChannelText) == SafeLower(CHANNEL_NAME) then
            return true
        end
        if bracketedChannelTag ~= "" and IsAllianceRenderedChannelTag(bracketedChannelTag) then
            return true
        end
        if derivedChannelText ~= "" and IsAllianceRenderedChannelTag(derivedChannelText) then
            return true
        end
        if numericChannel and allianceChannelId and numericChannel == tonumber(allianceChannelId) then
            return true
        end
        if leadingChannelNumber and allianceChannelId and leadingChannelNumber == tonumber(allianceChannelId) then
            return true
        end
    end

    return false
end

local function ShouldSuppressAllianceSystemMessage(message)
    local text = SafeLower(Trim(message))
    if not IsAllianceSystemNoticeText(text) then
        return false
    end

    return MessageTargetsAllianceChannel(text)
end

local function ShouldSuppressAllianceNoticeEvent(...)
    local parts = {}
    local message = arg and arg[1]
    local channelString = arg and arg[4]
    local channelNumber = arg and arg[8]
    local channelName = arg and arg[9]
    local derivedChannelName = channelName
    local targetsAlliance = false

    for i = 1, table.getn(arg) do
        local value = arg[i]
        if value ~= nil and value ~= "" then
            table.insert(parts, SafeLower(tostring(value)))
        end
    end

    local combined = table.concat(parts, " ")
    if combined == "" then
        return false
    end

    if not (
        string.find(combined, "join", 1, true) ~= nil
        or string.find(combined, "left", 1, true) ~= nil
        or string.find(combined, "leave", 1, true) ~= nil
        or string.find(combined, "logout", 1, true) ~= nil
        or string.find(combined, "log out", 1, true) ~= nil
        or string.find(combined, "owner", 1, true) ~= nil
    ) then
        return false
    end

    if (not derivedChannelName or derivedChannelName == "") and channelString then
        derivedChannelName = string.gsub(channelString, "^%d+%.%s*", "")
    end

    targetsAlliance = IsAllianceChannel(derivedChannelName, channelNumber)
        or MessageTargetsAllianceChannel(combined)
        or MessageTargetsAllianceChannel(message or "")

    return targetsAlliance
end

local function GetPratChannelNamesModule()
    if Prat_ChannelNames
            and Prat_ChannelNames.db
            and Prat_ChannelNames.db.profile
            and Prat_ChannelNames.db.profile.shortnames
            and Prat_ChannelNames.db.profile.replace then
        return Prat_ChannelNames
    end

    return nil
end

local function RestorePratAllianceChannelName()
    local prat = GetPratChannelNamesModule()
    if not prat or not pratAllianceChannelKey then
        pratAllianceChannelKey = nil
        pratAllianceSavedShortname = nil
        pratAllianceSavedReplace = nil
        return
    end

    prat.db.profile.shortnames[pratAllianceChannelKey] = pratAllianceSavedShortname
    prat.db.profile.replace[pratAllianceChannelKey] = pratAllianceSavedReplace

    pratAllianceChannelKey = nil
    pratAllianceSavedShortname = nil
    pratAllianceSavedReplace = nil

    if prat.doReplacement then
        prat:doReplacement()
    end
end

local function ApplyPratAllianceChannelName()
    local prat = GetPratChannelNamesModule()
    local desiredKey = nil

    if allianceChannelId and allianceChannelId > 0 then
        desiredKey = "channel" .. tostring(allianceChannelId)
    end

    if pratAllianceChannelKey and pratAllianceChannelKey ~= desiredKey then
        RestorePratAllianceChannelName()
    end

    if not prat or not desiredKey then
        return
    end

    if pratAllianceChannelKey ~= desiredKey then
        pratAllianceSavedShortname = prat.db.profile.shortnames[desiredKey]
        pratAllianceSavedReplace = prat.db.profile.replace[desiredKey]
        pratAllianceChannelKey = desiredKey
    end

    prat.db.profile.shortnames[desiredKey] = GetAllianceChannelTagText()
    prat.db.profile.replace[desiredKey] = true

    if prat.doReplacement then
        prat:doReplacement()
    end
end

local function ApplyAllianceChannelColor()
    if not allianceChannelId or allianceChannelId <= 0 then
        return
    end

    local channelKey = "CHANNEL" .. tostring(allianceChannelId)
    if ChatTypeInfo and ChatTypeInfo[channelKey] then
        ChatTypeInfo[channelKey].r = ALLIANCE_CHAT_R
        ChatTypeInfo[channelKey].g = ALLIANCE_CHAT_G
        ChatTypeInfo[channelKey].b = ALLIANCE_CHAT_B
    end

    if ChangeChatColor then
        pcall(ChangeChatColor, channelKey, ALLIANCE_CHAT_R, ALLIANCE_CHAT_G, ALLIANCE_CHAT_B)
    end
    if ChangeChatColorByID then
        pcall(ChangeChatColorByID, allianceChannelId, ALLIANCE_CHAT_R, ALLIANCE_CHAT_G, ALLIANCE_CHAT_B)
    end

    ApplyPratAllianceChannelName()
end

local function GetAllianceDisplayChannelInfo()
    if not GetNumDisplayChannels or not GetChannelDisplayInfo then
        return nil, nil
    end

    local totalChannels = tonumber(GetNumDisplayChannels()) or 0
    for i = 1, totalChannels do
        local name, header, collapsed, channelNumber, count = GetChannelDisplayInfo(i)
        if not header and name and SafeLower(name) == SafeLower(CHANNEL_NAME) then
            return i, tonumber(count)
        end
    end

    return nil, nil
end

local function IsAllianceDisplayChannelOwner()
    local displayIndex, memberCount = GetAllianceDisplayChannelInfo()
    if not displayIndex then
        return nil
    end

    if memberCount == 1 then
        return true
    end

    if not SetSelectedDisplayChannel or not IsDisplayChannelOwner then
        return nil
    end

    local previousDisplayIndex = nil
    if GetSelectedDisplayChannel then
        previousDisplayIndex = GetSelectedDisplayChannel()
    end

    pcall(SetSelectedDisplayChannel, displayIndex)
    local isOwner = IsDisplayChannelOwner() and true or false

    if previousDisplayIndex and previousDisplayIndex ~= displayIndex then
        pcall(SetSelectedDisplayChannel, previousDisplayIndex)
    end

    return isOwner
end

local function EnsureAllianceChannelVisible()
    if not ChatFrame_AddChannel then
        return
    end

    local totalFrames = tonumber(NUM_CHAT_WINDOWS) or 7
    for i = 1, totalFrames do
        local chatFrame = GetNamedGlobal("ChatFrame" .. tostring(i))
        if chatFrame then
            pcall(ChatFrame_AddChannel, chatFrame, CHANNEL_NAME)
        end
    end

    if DEFAULT_CHAT_FRAME then
        pcall(ChatFrame_AddChannel, DEFAULT_CHAT_FRAME, CHANNEL_NAME)
    end
    if SELECTED_CHAT_FRAME then
        pcall(ChatFrame_AddChannel, SELECTED_CHAT_FRAME, CHANNEL_NAME)
    end
end

local function EnsureAllianceChannelPassword()
    if not allianceChannelId or allianceChannelId <= 0 then
        return
    end

    if SetChannelPassword and IsAllianceDisplayChannelOwner() then
        pcall(SetChannelPassword, CHANNEL_NAME, CHANNEL_PASSWORD)
    end
end

local function FinalizeNewAllianceChannelSetup()
    if not pendingAllianceChannelSetup then
        return true
    end

    local displayIndex, memberCount = GetAllianceDisplayChannelInfo()
    if not displayIndex or memberCount == nil then
        return false
    end

    -- Player-created channels are created when the first member joins. If we
    -- are the only member right after login/join, we can safely toggle
    -- announcements off for everyone in the channel.
    if memberCount == 1 and ChannelToggleAnnouncements then
        pcall(ChannelToggleAnnouncements, CHANNEL_NAME, CHANNEL_NAME)
    end

    pendingAllianceChannelSetup = false
    return true
end

local function FinalizeAllianceChannelJoin()
    if not allianceChannelId or allianceChannelId <= 0 then
        return false
    end

    joinRetryWaitingForConfirmation = false
    EnsureAllianceChannelVisible()
    EnsureAllianceChannelPassword()
    ApplyAllianceChannelColor()
    FinalizeNewAllianceChannelSetup()
    return true
end

local function BuildAllianceTooltipLink(linkTarget, displayText, colorHex)
    local safeLink = tostring(linkTarget or "")
    local safeText = EscapeAllianceDisplayText(displayText or "")
    local safeColor = tostring(colorHex or ALLIANCE_TEXT_HEX)
    if safeLink == "" or safeText == "" then
        return safeText
    end

    return "|c" .. safeColor .. "|H" .. safeLink .. "|h" .. safeText .. "|h|r"
end

-- ------------------------------------------------------------------ --
-- Notice-type detection
-- ------------------------------------------------------------------ --

local function IsSuppressedNoticeType(noticeType)
    local v = SafeLower(noticeType)
    -- We manually add Alliance to the visible chat frames after join, so we
    -- can suppress both other-player and self join/leave notices locally.
    return v == "join"
        or v == "leave"
        or v == "you_joined"
        or v == "you_left"
        or v == "owner_changed"
        or v == "owner change"
end

-- ------------------------------------------------------------------ --
-- Styled link helpers
-- ------------------------------------------------------------------ --

local function AllianceChannelLink(text)
    return BuildAllianceTooltipLink(ALLIANCE_LINK_PREFIX .. "channel", text)
end

local function BuildAllianceChannelTag()
    return AllianceChannelLink("[Alliance]")
end

local function AllianceGuildLink(guildName)
    local displayGuild = Trim(guildName or "")
    if displayGuild == "" then
        return ""
    end

    return BuildAllianceTooltipLink(
        ALLIANCE_GUILD_LINK_PREFIX .. EscapeAllianceLinkToken(displayGuild),
        displayGuild,
        ALLIANCE_PREFIX_HEX
    )
end

local function AllianceTextLink(text)
    return BuildAllianceTooltipLink(ALLIANCE_TEXT_LINK_PREFIX .. "text", text)
end

local function YellowWordLink(word)
    return BuildAllianceTooltipLink(ALLIANCE_WORD_LINK_PREFIX .. "word", word)
end

local function BuildYellowLinkedMessage(text)
    local result = ""
    local first  = true

    for word in string.gfind(text or "", "%S+") do
        if first then
            result = YellowWordLink(word)
            first  = false
        else
            result = result .. " " .. YellowWordLink(word)
        end
    end

    return result
end

local function BuildLinkedAllianceText(text)
    local remaining = tostring(text or "")
    local result = ""

    while remaining ~= "" do
        local linkStart, linkEnd = string.find(remaining, "|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r")
        if not linkStart then
            linkStart, linkEnd = string.find(remaining, "|H.-|h.-|h")
        end
        if not linkStart then
            result = result .. AllianceTextLink(remaining)
            break
        end

        local plainChunk = string.sub(remaining, 1, linkStart - 1)
        if plainChunk ~= "" then
            result = result .. AllianceTextLink(plainChunk)
        end

        result = result .. string.sub(remaining, linkStart, linkEnd)
        remaining = string.sub(remaining, linkEnd + 1)
    end

    return result
end

local function TryFormatAllianceRenderedText(text)
    local rendered = tostring(text or "")
    local renderedPlain
    local channelTag
    local authorText
    local bodyText
    local transmittedGuild = ""

    lastAllianceRenderedInput = rendered
    lastAllianceRenderedPlain = ""
    lastAllianceRenderedMatched = false
    lastAllianceRenderedChannelTag = ""
    lastAllianceRenderedAuthorText = ""
    lastAllianceRenderedBodyText = ""

    if rendered == "" then
        return nil
    end
    if string.find(rendered, ALLIANCE_LINK_PREFIX, 1, true) ~= nil then
        return nil
    end

    renderedPlain = StripAllianceRenderedMarkup(rendered)
    renderedPlain = StripLeadingAllianceRenderedPrefixes(renderedPlain)
    lastAllianceRenderedPlain = renderedPlain
    channelTag, authorText, bodyText = string.match(renderedPlain, "^%[([^%]]+)%]%s*(.-):%s*(.*)$")
    lastAllianceRenderedChannelTag = tostring(channelTag or "")
    lastAllianceRenderedAuthorText = tostring(authorText or "")
    lastAllianceRenderedBodyText = tostring(bodyText or "")
    if not channelTag or not IsAllianceRenderedChannelTag(channelTag) then
        return nil
    end
    if not authorText or Trim(authorText) == "" then
        return nil
    end

    lastAllianceRenderedMatched = true

    if pendingAllianceAuthor and pendingAllianceAuthor ~= ""
            and SamePlayerName(authorText, pendingAllianceAuthor) then
        transmittedGuild = Trim(pendingAllianceGuildTitle or "")
    end

    return BuildAllianceChatLine(authorText, bodyText or "", transmittedGuild)
end

local function WrapAllianceChatFrame(frameToWrap)
    if not frameToWrap or type(frameToWrap.AddMessage) ~= "function" then
        return false
    end
    if frameToWrap.leafAllianceWrapped and frameToWrap.AddMessage == frameToWrap.leafAllianceWrappedAddMessage then
        return true
    end

    frameToWrap.leafAllianceOriginalAddMessage = frameToWrap.AddMessage
    frameToWrap.leafAllianceWrappedAddMessage = function(selfFrame, text, r, g, b, chatTypeID, holdTime, accessID, lineID)
        local strippedText, transmittedGuild, hadInlineWirePayload = StripAllianceWirePayloadInline(text)

        if hadInlineWirePayload then
            text = strippedText
            if pendingAllianceGuildTitle == nil or pendingAllianceGuildTitle == "" then
                pendingAllianceGuildTitle = Trim(transmittedGuild or "")
            end
        end

        local pendingFormatted = TryFormatPendingAllianceMessage(text)
        if pendingFormatted then
            return selfFrame.leafAllianceOriginalAddMessage(selfFrame, pendingFormatted, r, g, b, chatTypeID, holdTime, accessID, lineID)
        end

        local formatted = TryFormatAllianceRenderedText(text)
        if formatted then
            return selfFrame.leafAllianceOriginalAddMessage(selfFrame, formatted, r, g, b, chatTypeID, holdTime, accessID, lineID)
        end

        return selfFrame.leafAllianceOriginalAddMessage(selfFrame, text, r, g, b, chatTypeID, holdTime, accessID, lineID)
    end

    frameToWrap.AddMessage = frameToWrap.leafAllianceWrappedAddMessage
    frameToWrap.leafAllianceWrapped = true
    return true
end

local function InstallAllianceRenderedMessageWrapping()
    local totalFrames = tonumber(NUM_CHAT_WINDOWS) or 7
    local chatFrame

    for i = 1, totalFrames do
        chatFrame = GetNamedGlobal("ChatFrame" .. tostring(i))
        if chatFrame then
            WrapAllianceChatFrame(chatFrame)
        end
    end

    WrapAllianceChatFrame(DEFAULT_CHAT_FRAME)
    WrapAllianceChatFrame(SELECTED_CHAT_FRAME)
end

local function ShowAllianceTooltip(titleText, red, green, blue, detailText)
    if ItemRefTooltip then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        ItemRefTooltip:ClearLines()
        ItemRefTooltip:AddLine(titleText or "Alliance Chat", red or 1, green or 1, blue or 0)
        if detailText and detailText ~= "" then
            ItemRefTooltip:AddLine(detailText, 0.9, 0.9, 0.9, 1)
        end
        ItemRefTooltip:Show()
    end
end

GetAllianceGuildTitleForAuthor = function(author)
    local normalizedAuthor = NormalizePlayerName(author or "")
    local playerName = UnitName and UnitName("player") or ""

    if normalizedAuthor == "" then
        return ""
    end
    if playerName ~= "" and SamePlayerName(normalizedAuthor, playerName) then
        return GetPlayerGuildName()
    end
    if authorGuildCache[normalizedAuthor] ~= nil then
        return authorGuildCache[normalizedAuthor] or ""
    end

    return ""
end

BuildAllianceChatLine = function(author, msg, transmittedGuildName)
    local displayAuthor = Trim(author or "")
    local normalizedAuthor = NormalizePlayerName(author or "")
    local parsedGuildName, parsedBody, hadWirePayload = ParseAllianceWireMessage(msg or "")
    local displayBody   = msg or ""
    local guildName = Trim(transmittedGuildName or "")

    if displayAuthor == "" then
        displayAuthor = normalizedAuthor
    end
    if displayAuthor == "" then
        displayAuthor = "Unknown"
    end
    if hadWirePayload then
        displayBody = parsedBody or ""
        if guildName == "" then
            guildName = Trim(parsedGuildName or "")
        end
    end
    if guildName ~= "" then
        CacheAllianceGuildForPlayer(normalizedAuthor, guildName)
    else
        guildName = GetAllianceGuildTitleForAuthor(normalizedAuthor)
    end

    lastAllianceAuthorRaw = tostring(author or "")
    lastAllianceAuthorNormalized = tostring(normalizedAuthor or "")
    lastAllianceGuildTitle = tostring(guildName or "")
    lastAllianceMessageBody = tostring(displayBody or "")
    lastAllianceRenderedLine = BuildAllianceChannelTag() .. " "
        .. BuildLinkedAllianceText(displayAuthor .. ": " .. displayBody)

    return lastAllianceRenderedLine
end

-- ------------------------------------------------------------------ --
-- Hyperlink click handler (replaces global SetItemRef)
-- ------------------------------------------------------------------ --

wrappedSetItemRef = function(link, text, button, chatFrame)
    link = tostring(link or "")

    if string.sub(link, 1, string.len(ALLIANCE_LINK_PREFIX)) == ALLIANCE_LINK_PREFIX then
        ShowAllianceTooltip("Alliance Chat", 1, 1, 0)
        return
    end

    if string.sub(link, 1, string.len(ALLIANCE_GUILD_LINK_PREFIX)) == ALLIANCE_GUILD_LINK_PREFIX then
        local guildName = Trim(tostring(text or ""))
        guildName = string.gsub(guildName, "|c%x%x%x%x%x%x%x%x", "")
        guildName = string.gsub(guildName, "|r", "")
        guildName = string.gsub(guildName, "|H.-|h", "")
        guildName = string.gsub(guildName, "|h", "")
        ShowAllianceTooltip(guildName ~= "" and guildName or "Guild", 0.45, 0.78, 1.0, "Alliance guild title")
        return
    end

    if string.sub(link, 1, string.len(ALLIANCE_TEXT_LINK_PREFIX)) == ALLIANCE_TEXT_LINK_PREFIX then
        ShowAllianceTooltip("Alliance Chat", 1, 1, 0)
        return
    end

    if string.sub(link, 1, string.len(ALLIANCE_WORD_LINK_PREFIX)) == ALLIANCE_WORD_LINK_PREFIX then
        ShowAllianceTooltip("Alliance Chat", 1, 1, 0)
        return
    end

    if not originalSetItemRef or originalSetItemRef == wrappedSetItemRef then
        return
    end

    if setItemRefGuard then
        return originalSetItemRef(link, text, button, chatFrame)
    end

    setItemRefGuard = true
    local ok, err = pcall(originalSetItemRef, link, text, button, chatFrame)
    setItemRefGuard = false

    if not ok then
        error(err)
    end
end

-- ------------------------------------------------------------------ --
-- Chat-frame message-event handler override (suppresses notices)
-- ------------------------------------------------------------------ --

wrappedMessageEventHandler = function(...)
    local args = arg or {}
    args.n = args.n or table.getn(args)

    local chatFrame
    local eventName
    local message
    local author
    local languageName
    local channelString
    local target
    local flags
    local unknown1
    local channelNumber
    local channelName
    local unknown2
    local counter

    if type(args[1]) == "table" and args[1].AddMessage then
        chatFrame = args[1]
        eventName = args[2]
        message = args[3]
        author = args[4]
        languageName = args[5]
        channelString = args[6]
        target = args[7]
        flags = args[8]
        unknown1 = args[9]
        channelNumber = args[10]
        channelName = args[11]
        unknown2 = args[12]
        counter = args[13]
    else
        chatFrame = (type(this) == "table" and this.AddMessage and this) or DEFAULT_CHAT_FRAME
        eventName = args[1]
        message = args[2]
        author = args[3]
        languageName = args[4]
        channelString = args[5]
        target = args[6]
        flags = args[7]
        unknown1 = args[8]
        channelNumber = args[9]
        channelName = args[10]
        unknown2 = args[11]
        counter = args[12]
    end

    if chatFrame then
        pcall(WrapAllianceChatFrame, chatFrame)
    end

    local function CallOriginalHandler()
        if originalMessageEventHandler then
            pcall(function()
                originalMessageEventHandler(unpack(args, 1, args.n))
            end)
        end
    end

    -- Guard against re-entrancy: in some WoW 1.12 builds the original handler
    -- calls back into the global ChatFrame_MessageEventHandler for sub-events.
    if handlerGuard then
        CallOriginalHandler()
        return
    end

    local noticeType        = message       -- e.g. "JOIN", "LEAVE", "YOU_JOINED", "YOU_LEFT"
    local noticeLongName    = channelString -- e.g. "6. Alliance"
    local noticeChannelNum  = channelNumber
    local noticeChannelName = channelName

    if eventName == "CHAT_MSG_CHANNEL_NOTICE" or eventName == "CHAT_MSG_CHANNEL_NOTICE_USER" then
        local derivedNoticeName = noticeChannelName
        if (not derivedNoticeName or derivedNoticeName == "") and noticeLongName then
            derivedNoticeName = string.gsub(noticeLongName, "^%d+%.%s*", "")
        end

        if (IsSuppressedNoticeType(noticeType)
                and IsAllianceChannel(derivedNoticeName, noticeChannelNum))
                or ShouldSuppressAllianceNoticeEvent(
                    message, author, languageName, channelString, target,
                    flags, unknown1, channelNumber, channelName, unknown2, counter
                ) then
            return
        end
    end

    if eventName == "CHAT_MSG_SYSTEM" and ShouldSuppressAllianceSystemMessage(message) then
        return
    end

    if eventName == "CHAT_MSG_CHANNEL" then
        local msg      = message
        local chanFull = channelString
        local chanNum  = channelNumber
        local chanBase = channelName
        local transmittedGuild = ""
        local hadWirePayload = false

        local derivedBase = chanBase
        if (not derivedBase or derivedBase == "") and chanFull then
            derivedBase = string.gsub(chanFull, "^%d+%.%s*", "")
        end

        if IsAllianceChannel(derivedBase, chanNum) then
            local targetFrame = chatFrame or DEFAULT_CHAT_FRAME
            lastAllianceIncomingAuthor = tostring(author or "")
            lastAllianceIncomingRawMessage = tostring(msg or "")
            lastAllianceIncomingSource = "handler"
            transmittedGuild, msg, hadWirePayload = ParseAllianceWireMessage(msg)
            lastAllianceIncomingParsedGuild = tostring(transmittedGuild or "")
            lastAllianceIncomingParsedBody = tostring(msg or "")
            if hadWirePayload and transmittedGuild ~= "" then
                CacheAllianceGuildForPlayer(author, transmittedGuild)
            end
            CapturePendingAllianceMessage(author, msg, transmittedGuild)
            if targetFrame and targetFrame.AddMessage then
                targetFrame:AddMessage(BuildAllianceChatLine(author, msg, transmittedGuild))
                ClearPendingAllianceMessage()
                return
            end
        end
    end

    handlerGuard = true
    CallOriginalHandler()
    handlerGuard = false
end

local function InstallItemRefHook()
    if SetItemRef == wrappedSetItemRef then
        return
    end
    if type(SetItemRef) ~= "function" then
        return
    end

    originalSetItemRef = SetItemRef
    SetItemRef = wrappedSetItemRef
end

local function InstallMessageEventHook()
    if ChatFrame_MessageEventHandler ~= wrappedMessageEventHandler then
        originalMessageEventHandler = ChatFrame_MessageEventHandler
        ChatFrame_MessageEventHandler = wrappedMessageEventHandler
    end
end

local function InstallSendChatHook()
    if wrappedSendChatMessage and SendChatMessage == wrappedSendChatMessage then
        return
    end
    if type(SendChatMessage) ~= "function" then
        return
    end

    originalSendChatMessage = SendChatMessage
    wrappedSendChatMessage = function(msg, chatType, language, channel)
        local outgoing = msg

        if chatType == "CHANNEL" and IsAllianceOutgoingChannel(channel) and type(outgoing) == "string" then
            local transmittedGuild, strippedMessage, hadWirePayload = ParseAllianceWireMessage(outgoing)
            local effectiveGuild = GetPlayerGuildName()

            if hadWirePayload then
                outgoing = BuildAllianceWireMessage(strippedMessage or "", transmittedGuild or "")
            else
                outgoing = BuildAllianceWireMessage(outgoing or "", effectiveGuild or "")
            end

            lastAllianceOutgoingOriginalMessage = tostring(msg or "")
            lastAllianceOutgoingWireMessage = tostring(outgoing or "")
            lastAllianceOutgoingGuild = tostring(effectiveGuild or "")
            lastAllianceOutgoingChatType = tostring(chatType or "")
            lastAllianceOutgoingChannel = tostring(channel or "")
        end

        return originalSendChatMessage(outgoing, chatType, language, channel)
    end

    SendChatMessage = wrappedSendChatMessage
end

local function InstallHooks()
    InstallItemRefHook()
    InstallMessageEventHook()
    InstallSendChatHook()
    InstallAllianceRenderedMessageWrapping()
end

hookWatchdogFrame:SetScript("OnUpdate", function()
    local elapsed = tonumber(arg1) or 0
    hookWatchdogElapsed = hookWatchdogElapsed + elapsed
    if hookWatchdogElapsed >= HOOK_WATCHDOG_INTERVAL then
        hookWatchdogElapsed = 0
        InstallHooks()
    end
end)

SLASH_LEAFALLIANCEDEBUG1 = "/ladebug"
SLASH_LEAFALLIANCEDEBUG2 = "/leafalliancedebug"
SlashCmdList["LEAFALLIANCEDEBUG"] = function()
    DumpGuildDebugState()
end

local function StopAllianceJoinRetry()
    joinRetryActive = false
    joinRetryDelay = 0
    joinRetryAttemptsRemaining = 0
    joinRetryWaitingForConfirmation = false
    frame:SetScript("OnUpdate", nil)
end

-- ------------------------------------------------------------------ --
-- Join helper (passworded auto-join)
-- ------------------------------------------------------------------ --

local function JoinAllianceChannel(allowUnsafeJoin)
    RefreshAllianceChannelId()
    if allianceChannelId then
        FinalizeAllianceChannelJoin()
        return true
    end

    -- Wait until default channels are in place so we do not occupy /1.
    if not allowUnsafeJoin and not AreDefaultChannelSlotsReady() then
        return false
    end

    -- JoinChannelByName is the vanilla 1.12 API and accepts an optional
    -- password for custom channels.
    if JoinChannelByName then
        pendingAllianceChannelSetup = true
        joinRetryWaitingForConfirmation = true
        JoinChannelByName(CHANNEL_NAME, CHANNEL_PASSWORD)
        RefreshAllianceChannelId()
        if FinalizeAllianceChannelJoin() then
            return true
        end
    end

    return false
end

local function StartAllianceJoinRetry(initialDelay, maxAttempts)
    if allianceChannelId and allianceChannelId > 0 then
        StopAllianceJoinRetry()
        return
    end

    joinRetryActive = true
    joinRetryDelay = tonumber(initialDelay) or JOIN_RETRY_INITIAL_DELAY
    joinRetryAttemptsRemaining = tonumber(maxAttempts) or JOIN_RETRY_MAX_ATTEMPTS
    joinRetryWaitingForConfirmation = false

    frame:SetScript("OnUpdate", function()
        local elapsed = tonumber(arg1) or 0

        if not joinRetryActive then
            frame:SetScript("OnUpdate", nil)
            return
        end

        RefreshAllianceChannelId()
        if allianceChannelId and allianceChannelId > 0 then
            FinalizeAllianceChannelJoin()
            StopAllianceJoinRetry()
            return
        end

        joinRetryDelay = joinRetryDelay - elapsed
        if joinRetryDelay > 0 then
            return
        end

        if joinRetryWaitingForConfirmation then
            joinRetryWaitingForConfirmation = false
            joinRetryDelay = JOIN_RETRY_INTERVAL
            return
        end

        if joinRetryAttemptsRemaining <= 0 then
            StopAllianceJoinRetry()
            return
        end

        joinRetryAttemptsRemaining = joinRetryAttemptsRemaining - 1
        if JoinAllianceChannel(joinRetryAttemptsRemaining <= JOIN_RETRY_FORCE_THRESHOLD) then
            StopAllianceJoinRetry()
            return
        end

        joinRetryDelay = JOIN_RETRY_INTERVAL
    end)
end

-- ------------------------------------------------------------------ --
-- Main event handler
-- ------------------------------------------------------------------ --

frame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        GetPlayerGuildName()
        InstallHooks()
        JoinAllianceChannel()
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
        StartAllianceJoinRetry(JOIN_RETRY_INITIAL_DELAY, JOIN_RETRY_MAX_ATTEMPTS)
        local playerName = UnitName and UnitName("player") or ""
        if playerName ~= "" then
            CacheAllianceGuildForPlayer(playerName, GetPlayerGuildName())
        end

        Print("Loaded for " .. AllianceChannelLink(CHANNEL_NAME) .. ".")
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(BuildYellowLinkedMessage("Alliance Chat Ready"))
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        GetPlayerGuildName()
        InstallHooks()
        JoinAllianceChannel()
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
        if not allianceChannelId or allianceChannelId <= 0 then
            StartAllianceJoinRetry(JOIN_RETRY_INTERVAL, JOIN_RETRY_MAX_ATTEMPTS)
        else
            StopAllianceJoinRetry()
        end

    elseif event == "PLAYER_GUILD_UPDATE" then
        GetPlayerGuildName()
        ApplyPratAllianceChannelName()

    elseif event == "CHAT_MSG_CHANNEL" then
        local message = arg1
        local author = arg2
        local channelString = arg4
        local channelNumber = arg8
        local channelName = arg9
        local derivedBase = channelName
        local transmittedGuild = ""
        local hadWirePayload = false

        if (not derivedBase or derivedBase == "") and channelString then
            derivedBase = string.gsub(channelString, "^%d+%.%s*", "")
        end

        if IsAllianceChannel(derivedBase, channelNumber) then
            lastAllianceIncomingAuthor = tostring(author or "")
            lastAllianceIncomingRawMessage = tostring(message or "")
            lastAllianceIncomingSource = "event"
            transmittedGuild, message, hadWirePayload = ParseAllianceWireMessage(message)
            lastAllianceIncomingParsedGuild = tostring(transmittedGuild or "")
            lastAllianceIncomingParsedBody = tostring(message or "")
            if hadWirePayload and transmittedGuild ~= "" then
                CacheAllianceGuildForPlayer(author, transmittedGuild)
            end
            CapturePendingAllianceMessage(author, message, transmittedGuild)
        end

    elseif event == "CHANNEL_UI_UPDATE" then
        InstallHooks()
        JoinAllianceChannel()
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
        if not allianceChannelId or allianceChannelId <= 0 then
            StartAllianceJoinRetry(JOIN_RETRY_INTERVAL, JOIN_RETRY_MAX_ATTEMPTS)
        else
            StopAllianceJoinRetry()
        end
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        -- Keep our channel-id cache up to date as the channel roster changes
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
        if allianceChannelId and allianceChannelId > 0 then
            StopAllianceJoinRetry()
        end
    elseif event == "WHO_LIST_UPDATE" then
        CompleteAllianceGuildWhoQuery()
    end
end)
