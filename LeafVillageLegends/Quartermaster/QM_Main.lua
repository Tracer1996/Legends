-- The Ashen Banner's Quartermaster wiring: events, login HELLO, the AE signature at login / logout and the player
-- and officer slash commands (/qm). The Keeper-only parts (trades, stock, ledger, weekly report, AH relay) are only
-- in AshenKeeper (AshenKeeper_Main.lua). Stands down when AshenKeeper is loaded (QM_Host.lua).
-- Lua 5.0 / WoW 1.12: no '#', no '%'.
if ASHEN_QM_STANDDOWN then return end

local AK = AshenKeeper
local P = AK.Protocol
local PL = AK.Player

local function Init()
  if AK.initialized then return end
  AK.initialized = true
  AK.InitDB()
  P.Init()
  math.randomseed(AK.Now())
  -- Before the Banner's own PLAYER_LOGIN (its daily login reward): is the AE data still what was signed at the
  -- last logout? (These files load before Core\Core.lua, so this handler runs first.)
  local ok, res = pcall(AK.Integrity.VerifyBanner)
  if ok and res == false then AK.Debug("Ashen Banner AE data changed since the last logout") end
  if AK.IsKeeper() then
    AK.Print("This character is the Quartermaster: the Keeper side needs the AshenKeeper addon (the Banner only has the player window).")
  else
    AK.After("abk-hello", 12, PL.SendHello)
  end
end

local frame = CreateFrame("Frame", "LeafVE_QuartermasterEventFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "LeafVillageLegends" then
    AK.InitDB()
  elseif event == "PLAYER_LOGIN" then
    Init()
  elseif event == "CHAT_MSG_ADDON" then
    if arg1 ~= "LeafVE" then P.OnAddon(arg1, arg2, arg3, arg4) end
  elseif event == "PLAYER_TARGET_CHANGED" then
    if AK.UI and AK.UI.OnTargetChanged then AK.UI.OnTargetChanged() end
  elseif event == "PLAYER_LOGOUT" then
    -- signs the Banner's AE rows as the game is about to save them (checked again at the next login)
    if AK.initialized then pcall(AK.Integrity.SignBanner) end
  end
end)

local function Words(msg)
  local w = {}
  local pos = 1
  msg = AK.Trim(msg or "")
  while pos <= string.len(msg) do
    local a, b = string.find(msg, "%S+", pos)
    if not a then break end
    table.insert(w, string.sub(msg, a, b))
    pos = b + 1
  end
  return w
end

function AK.BannerCommand(msg)
  if not AK.db then AK.InitDB() end
  local w = Words(msg)
  local cmd = string.lower(w[1] or "")
  if cmd == "" or cmd == "shop" or cmd == "qm" then
    if AK.UI and AK.UI.TogglePlayer then AK.UI.TogglePlayer() end
  elseif cmd == "setkeeper" then
    AK.db.config.keeperName = w[2] or ""
    AK.cache.keeperName = nil
    AK.Print("Keeper character set to '" .. tostring(w[2] or "") .. "'. /reload to apply.")
  elseif cmd == "status" then
    AK.Print("Quartermaster v" .. AK.VERSION .. " in The Ashen Banner v" .. tostring(AK.HostVersion()) .. "  me=" .. tostring(AK.MyName()) ..
             " keeper=" .. tostring(AK.KeeperName()) .. " online=" .. tostring(PL.IsKeeperOnline()) ..
             (AK.outdated and ("  (the Quartermaster needs v" .. AK.outdated .. "+)") or ""))
  elseif cmd == "holds" then
    -- AE fail-safe review list, from the last HOLDS the Keeper sent (officers)
    local list = AK.cache.holds or {}
    PL.Request("LOG_REQ", { r = AK.Now() }, { "r" })
    if table.getn(list) == 0 then AK.Print("Nobody on hold (asking the Quartermaster for a fresh list).") end
    local i
    for i = 1, table.getn(list) do
      local h = list[i]
      AK.Print(tostring(h.name) .. ": " .. (AK.Integrity.HoldText(h.why) or "-") .. "  -  " .. AK.FormatAE(h.before) .. " -> " ..
               AK.FormatAE(h.after) .. ", " .. AK.FormatAE(h.held) .. " AE held" .. (h.frz and ", frozen" or "") ..
               ((h.adj or 0) ~= 0 and (", adjust " .. h.adj) or "") .. ((h.t or 0) > 0 and ("  (" .. date("%m/%d %H:%M", h.t) .. ")") or ""))
    end
  elseif cmd == "release" or cmd == "discard" or cmd == "freeze" or cmd == "unfreeze" or cmd == "adjust" then
    local acts = { release = "rel", discard = "dis", freeze = "frz", unfreeze = "unf", adjust = "adj" }
    if not w[2] or (cmd == "adjust" and not tonumber(w[3])) then
      AK.Print("Usage: /qm " .. cmd .. " PlayerName" .. (cmd == "adjust" and " 500   (or -500; 0 removes it)" or ""))
      return
    end
    PL.Admin({ op = "ae", k = w[2], a = acts[cmd], ae = w[3] })
  elseif cmd == "ahprices" then
    PL.Request("LOG_REQ", { r = AK.Now() }, { "r" })
    local lines = AK.AH.Lines(w[2] and table.concat(w, " ", 2) or nil, AK.cache.ahPrices)
    local i
    for i = 1, table.getn(lines) do AK.Print(lines[i]) end
  elseif cmd == "debug" then
    AK.db.config.debug = not AK.db.config.debug
    AK.Print("Debug: " .. tostring(AK.db.config.debug))
  else
    AK.Print("/qm  (open the Quartermaster window)   /qm status   /qm setkeeper Grizzwick  (then /reload)")
    AK.Print("AE review (Oath Captain+): /qm holds   /qm release Name   /qm discard Name   /qm freeze Name   /qm unfreeze Name   /qm adjust Name 500")
    AK.Print("/qm ahprices  (officers: the last Auction House prices, or /qm ahprices lotus)")
  end
end

SLASH_ASHENQM1 = "/qm"
SLASH_ASHENQM2 = "/quartermaster"
SLASH_ASHENQM3 = "/ak"
SlashCmdList["ASHENQM"] = AK.BannerCommand
