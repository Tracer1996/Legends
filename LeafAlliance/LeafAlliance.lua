-- LeafAlliance
-- WoW 1.12 / Lua 5.0 addon
-- Joins the custom "Alliance" channel on login, suppresses all
-- join/leave notices for that channel, and locally restyles chat lines
-- from that channel with a yellow "[Alliance]" tag and yellow linked text.
-- Automatically joins the passworded Alliance channel.

local ADDON_NAME  = "LeafAlliance"
local CHANNEL_NAME = "Alliance"
local CHANNEL_PASSWORD = "Turtleboys"
local MAX_CHANNEL_SCAN = 50
local ALLIANCE_CHAT_R = 1.00
local ALLIANCE_CHAT_G = 0.82
local ALLIANCE_CHAT_B = 0.05
local ALLIANCE_TEXT_HEX = "FFFFD10D"
local ALLIANCE_LINK_PREFIX = "leafalliance:"
local ALLIANCE_TEXT_LINK_PREFIX = "leafalliancetext:"
local ALLIANCE_WORD_LINK_PREFIX = "leafallianceword:"

-- Frames & state
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
frame:RegisterEvent("CHANNEL_UI_UPDATE")

local allianceChannelId = nil
local handlerGuard      = false
local pratAllianceChannelKey = nil
local pratAllianceSavedShortname = nil
local pratAllianceSavedReplace = nil
local pendingAllianceChannelSetup = false

-- Keep references to the active handlers so we can re-hook after
-- later-loading chat addons install their own wrappers.
local originalSetItemRef          = nil
local originalMessageEventHandler = nil
local wrappedSetItemRef           = nil
local wrappedMessageEventHandler  = nil

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

local function AreDefaultChannelSlotsReady()
    if not GetChannelName then
        return false
    end

    local id, name = GetChannelName(1)
    if not id or id == 0 or not name then
        return false
    end

    if SafeLower(name) == SafeLower(CHANNEL_NAME) then
        return false
    end

    return IsGeneralChannelName(name)
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

    prat.db.profile.shortnames[desiredKey] = "[Alliance]"
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
        local chatFrame = _G["ChatFrame" .. tostring(i)]
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

    EnsureAllianceChannelVisible()
    EnsureAllianceChannelPassword()
    ApplyAllianceChannelColor()
    FinalizeNewAllianceChannelSetup()
    return true
end

local function BuildAllianceTooltipLink(linkTarget, displayText)
    local safeLink = tostring(linkTarget or "")
    local safeText = tostring(displayText or "")
    if safeLink == "" or safeText == "" then
        return safeText
    end

    return "|c" .. ALLIANCE_TEXT_HEX .. "|H" .. safeLink .. "|h" .. safeText .. "|h|r"
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
end

-- ------------------------------------------------------------------ --
-- Styled link helpers
-- ------------------------------------------------------------------ --

local function AllianceChannelLink(text)
    return BuildAllianceTooltipLink(ALLIANCE_LINK_PREFIX .. "channel", text)
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
        local linkStart, linkEnd = string.find(remaining, "|H.-|h.-|h")
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

local function ShowAllianceTooltip()
    if ItemRefTooltip then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        ItemRefTooltip:ClearLines()
        ItemRefTooltip:AddLine("Alliance Chat", 1, 1, 0)
        ItemRefTooltip:Show()
    end
end

local function BuildAllianceChatLine(author, msg)
    local displayAuthor = author or "Unknown"
    local displayBody   = msg or ""
    return AllianceChannelLink("[Alliance]") .. " "
        .. BuildLinkedAllianceText(displayAuthor .. ": " .. displayBody)
end

-- ------------------------------------------------------------------ --
-- Hyperlink click handler (replaces global SetItemRef)
-- ------------------------------------------------------------------ --

wrappedSetItemRef = function(link, text, button)
    if string.sub(link, 1, string.len(ALLIANCE_LINK_PREFIX)) == ALLIANCE_LINK_PREFIX then
        ShowAllianceTooltip()
        return
    end

    if string.sub(link, 1, string.len(ALLIANCE_TEXT_LINK_PREFIX)) == ALLIANCE_TEXT_LINK_PREFIX then
        ShowAllianceTooltip()
        return
    end

    if string.sub(link, 1, string.len(ALLIANCE_WORD_LINK_PREFIX)) == ALLIANCE_WORD_LINK_PREFIX then
        ShowAllianceTooltip()
        return
    end

    if originalSetItemRef then
        originalSetItemRef(link, text, button)
    end
end

-- ------------------------------------------------------------------ --
-- Chat-frame message-event handler override (suppresses notices)
-- ------------------------------------------------------------------ --

wrappedMessageEventHandler = function(chatFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    -- Guard against re-entrancy: in some WoW 1.12 builds the original handler
    -- calls back into the global ChatFrame_MessageEventHandler for sub-events.
    -- pcall is used so that a Lua error inside the original handler can never
    -- leave handlerGuard stuck at true (which would break all future events).
    if handlerGuard then
        if originalMessageEventHandler then
            pcall(originalMessageEventHandler, chatFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
        return
    end

    -- In WoW 1.12 the event arguments are globals: arg1 … arg9
    local noticeType    = _G.arg1  -- e.g. "JOIN", "LEAVE", "YOU_JOINED", "YOU_LEFT"
    local channelName   = _G.arg7  -- channel name string
    local channelNumber = _G.arg8  -- channel slot number

    if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_NOTICE_USER" then
        if IsSuppressedNoticeType(noticeType)
                and IsAllianceChannel(channelName, channelNumber) then
            -- Drop this notice entirely
            return
        end
    end

    -- In WoW 1.12, CHAT_MSG_CHANNEL args:
    --   arg1 = message text
    --   arg2 = sender name
    --   arg4 = channel name, sometimes prefixed with number (e.g. "4. Alliance")
    --   arg8 = channel slot number (integer)
    --   arg9 = channel base name (e.g. "Alliance"), may be absent on some builds
    if event == "CHAT_MSG_CHANNEL" then
        local msg        = _G.arg1
        local author     = _G.arg2
        local chanFull   = _G.arg4   -- may be "4. Alliance" or just "Alliance"
        local chanNum    = _G.arg8
        local chanBase   = _G.arg9

        -- Derive the plain channel name from arg4 if arg9 is not populated.
        -- arg4 format in 1.12 is typically "N. ChannelName".
        local derivedBase = chanBase
        if (not derivedBase or derivedBase == "") and chanFull then
            derivedBase = string.gsub(chanFull, "^%d+%.%s*", "")
        end

        if IsAllianceChannel(derivedBase, chanNum) then
            -- Suppress the default rendered line and print a styled replacement
            -- to the same chat frame that received this event.
            local targetFrame = chatFrame or DEFAULT_CHAT_FRAME
            if targetFrame and targetFrame.AddMessage then
                targetFrame:AddMessage(BuildAllianceChatLine(author, msg))
                return
            end
        end
    end

    if originalMessageEventHandler then
        handlerGuard = true
        pcall(originalMessageEventHandler, chatFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        handlerGuard = false
    end
end

local function InstallItemRefHook()
    if SetItemRef ~= wrappedSetItemRef then
        originalSetItemRef = SetItemRef
        SetItemRef = wrappedSetItemRef
    end
end

local function InstallMessageEventHook()
    if ChatFrame_MessageEventHandler ~= wrappedMessageEventHandler then
        originalMessageEventHandler = ChatFrame_MessageEventHandler
        ChatFrame_MessageEventHandler = wrappedMessageEventHandler
    end
end

local function InstallHooks()
    InstallItemRefHook()
    InstallMessageEventHook()
end

-- ------------------------------------------------------------------ --
-- Join helper (passworded auto-join)
-- ------------------------------------------------------------------ --

local function JoinAllianceChannel()
    RefreshAllianceChannelId()
    if allianceChannelId then
        FinalizeAllianceChannelJoin()
        return
    end

    -- Wait until default channels are in place so we do not occupy /1.
    if not AreDefaultChannelSlotsReady() then
        return
    end

    -- JoinChannelByName is the vanilla 1.12 API and accepts an optional
    -- password for custom channels.
    if JoinChannelByName then
        pendingAllianceChannelSetup = true
        JoinChannelByName(CHANNEL_NAME, CHANNEL_PASSWORD)
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
    end
end

-- ------------------------------------------------------------------ --
-- Main event handler
-- ------------------------------------------------------------------ --

frame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        pendingAllianceChannelSetup = true
        InstallHooks()
        JoinAllianceChannel()
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()

        Print("Loaded for " .. AllianceChannelLink(CHANNEL_NAME) .. ".")
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(BuildYellowLinkedMessage("Alliance Chat Ready"))
        end

    elseif event == "CHANNEL_UI_UPDATE" then
        InstallHooks()
        JoinAllianceChannel()
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
        -- Keep our channel-id cache up to date as the channel roster changes
        RefreshAllianceChannelId()
        FinalizeAllianceChannelJoin()
    end
end)
