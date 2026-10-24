-- /raidmode [on|off|status]: one-step raid profile. Turning it on disables the
-- addons below and applies lighter render settings; off restores exactly what
-- was enabled/set before. Addon changes need a UI reload, which it does for you.

local RAID_OFF_ADDONS = {
  "WhoDidIt", "ChronicleCompanion",
  "Kui_Nameplates", "Kui_Nameplates_Auras",
  "MikScrollingBattleText", "MikScrollingBattleTextOptions",
  "GuildBroadcast", "GuildInviter", "MethlBroadcast", "AutoInvite",
  "AutoLFM", "MethlLFM", "DifficultBulletinBoard",
  "aux-addon", "Profits", "AshenRelics", "pfQuest", "pfQuest-turtle",
  "!AshenProfiler",
}

local RAID_CVARS = {
  PB_PlayerRenderDistInCombat = "40",
  PB_PetRenderDistInCombat = "0",
  PB_SummonRenderDistInCombat = "0",
  PB_ShowPlayerAuraVisuals = "0",
  PB_HideLaggyBossSpellsOnOthers = "1",
  -- Mobs stay fully visible so distant packs can be marked: player limits
  -- only apply to players, and marked units always render.
  PB_TrashUnitRenderDist = "-1",
  PB_TrashUnitRenderDistInCombat = "-1",
  PB_AlwaysRenderRaidMarks = "1",
  particleDensity = "0.1",
  spellEffectLevel = "0",
}

local function say(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37[Raid Mode]|r " .. text)
end

local function db()
  AshenRaidModeDB = AshenRaidModeDB or {}
  return AshenRaidModeDB
end

local function addonEnabled(name)
  local title, _, _, enabled = GetAddOnInfo(name)
  if not title then return nil end
  return enabled and true or false
end

local function getCVar(name)
  local ok, v = pcall(GetCVar, name)
  if ok then return v end
  return nil
end

local function setCVar(name, value)
  pcall(SetCVar, name, value)
  -- PerfBoostSettings can re-apply its own saved per-character values on
  -- login; keep it in step so it doesn't undo raid mode.
  if PerfBoost and PerfBoost.db and PerfBoost.db.profile and string.find(name, "^PB_") then
    PerfBoost.db.profile[name] = tonumber(value) or value
  end
end

local function applyCVars()
  for name, value in pairs(RAID_CVARS) do setCVar(name, value) end
end

local function turnOn()
  local d = db()
  if d.on then say("already on. /raidmode off to restore.") return end
  d.prevAddons, d.prevCVars = {}, {}
  local list = {}
  for _, name in ipairs(RAID_OFF_ADDONS) do table.insert(list, name) end
  -- BannerMark has GreedMeter built in; don't run two meters.
  if addonEnabled("BannerMark") then table.insert(list, "GreedMeter") end
  local count = 0
  for _, name in ipairs(list) do
    local enabled = addonEnabled(name)
    if enabled then
      d.prevAddons[name] = true
      DisableAddOn(name)
      count = count + 1
    end
  end
  for name in pairs(RAID_CVARS) do
    local v = getCVar(name)
    if v ~= nil then d.prevCVars[name] = v end
  end
  applyCVars()
  d.on = true
  say("ON: disabled " .. count .. " addons, lighter player/spell rendering. Reloading...")
  ReloadUI()
end

local function turnOff()
  local d = db()
  if not d.on then say("already off.") return end
  local count = 0
  for name in pairs(d.prevAddons or {}) do
    EnableAddOn(name)
    count = count + 1
  end
  for name, value in pairs(d.prevCVars or {}) do setCVar(name, value) end
  d.on = false
  d.prevAddons, d.prevCVars = nil, nil
  say("OFF: re-enabled " .. count .. " addons and restored your settings. Reloading...")
  ReloadUI()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
  local d = db()
  if d.on then
    applyCVars()
    say("is ON. Type /raidmode off after the raid.")
  end
end)

SLASH_ASHENRAIDMODE1 = "/raidmode"
SlashCmdList["ASHENRAIDMODE"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "on" then turnOn()
  elseif msg == "off" then turnOff()
  elseif msg == "status" then
    say(db().on and "ON" or "OFF")
  elseif db().on then turnOff()
  else turnOn() end
end
