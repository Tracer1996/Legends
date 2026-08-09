-- LeafVE_Ach_FlightPoints.lua
--
-- Live flight-point discovery achievements, ported from OctoAchieve
-- Data\FlightPoints.lua + the flight-point half of Tracking.lua. One
-- achievement per continent (Eastern Kingdoms / Kalimdor), filed under
-- Exploration alongside the zone-discovery achievements.
--
-- Live data: C_TaxiMap.GetTaxiNodesForMap() reads TaxiNodes.dbc directly --
-- every real flight master on every continent, faction-tagged, in one call.
-- No hand-scraped flight-point table needed, and it auto-covers whatever
-- flight points this server actually has, custom ones included. Filtered to
-- flight points this character's faction can actually reach (Neutral goblin
-- towns count for everyone; Alliance/Horde-only ones only for that faction)
-- so the achievement is always completable.
--
-- Discovery state has no live query, unlike zone exploration
-- (C_MapExplorationInfo has no flight-point equivalent) -- C_TaxiMap.
-- GetTaxiNodesForMap doesn't expose it either. The only live signal is the
-- flight map itself: opening any flight master's map (TAXIMAP_OPENED) lists
-- every node reachable from it via C_TaxiMap.GetAllTaxiNodes(), and a node
-- can only be "reachable" if it's already discovered -- so this snapshots
-- that every time a flight map is opened. That means credit lags until the
-- next time you talk to any flight master, not fully real-time like zone
-- exploration -- the closest this data actually gets to a discovery flag.

local CONTINENTS = {
  [0] = { id = "explore_flight_eastern_kingdoms", name = "Eastern Kingdoms" },
  [1] = { id = "explore_flight_kalimdor",         name = "Kalimdor" },
}

-- Defensive: this server's C_TaxiMap polyfill is untested for position
-- data specifically (nothing in the original OctoAchieve port needed it,
-- it only ever read faction/name/mapID). Modern TaxiNodeInfo exposes it as
-- a position table (position.x/position.y), so that's tried first; a flat
-- n.x/n.y is tried as a fallback in case this polyfill shapes it
-- differently. Returns nil, nil if neither is present -- callers must
-- treat that as "no map pin for this node," not (0, 0).
local function ExtractFlightPointPosition(n)
  if n.position and n.position.x and n.position.y then
    return n.position.x, n.position.y
  end
  if n.x and n.y then
    return n.x, n.y
  end
  return nil, nil
end

function LeafVE_AchTest_FlightPoints_LiveInit()
  if not C_TaxiMap or not C_TaxiMap.GetTaxiNodesForMap or not UnitFactionGroup or not Enum then
    return
  end
  local playerFaction = UnitFactionGroup("player")
  local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap)
  if not ok or not nodes then return end

  local byContinent = {}
  local byContinentPositions = {}
  local positionsFound, positionsMissing = 0, 0
  for _, n in ipairs(nodes) do
    local reachable = (n.faction == Enum.FlightPathFaction.Neutral)
      or (playerFaction == "Alliance" and n.faction == Enum.FlightPathFaction.Alliance)
      or (playerFaction == "Horde" and n.faction == Enum.FlightPathFaction.Horde)
    if reachable and n.name and n.mapID ~= nil and CONTINENTS[n.mapID] then
      byContinent[n.mapID] = byContinent[n.mapID] or {}
      table.insert(byContinent[n.mapID], n.name)

      local px, py = ExtractFlightPointPosition(n)
      if px and py then
        byContinentPositions[n.mapID] = byContinentPositions[n.mapID] or {}
        byContinentPositions[n.mapID][n.name] = {x = px, y = py}
        positionsFound = positionsFound + 1
      else
        positionsMissing = positionsMissing + 1
      end
    end
  end

  if LeafVE_AchTest.DEBUG and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF69CCF0[FlightPoints]|r position data: "
      ..positionsFound.." node(s) with, "..positionsMissing.." without"
      ..(positionsFound == 0 and " -- map view will show no pins, checklist still works" or ""))
  end

  local allContinentIds = {}
  for mapID, continent in pairs(CONTINENTS) do
    local areas = byContinent[mapID] or {}
    table.sort(areas)
    local goal = table.getn(areas)
    if goal > 0 then
      local desc = "Discover every flight point in " .. continent.name .. " (" .. goal .. " total)."
      local positions = byContinentPositions[mapID] or {}
      local def = LeafVE_AchTest:GetAchievementDef(continent.id)
      if not def then
        LeafVE_AchTest:AddAchievement(continent.id, {
          id = continent.id,
          name = "Master Flyer: " .. continent.name,
          desc = desc,
          category = "Exploration",
          points = 20,
          icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
          criteria_type = "flight_zone",
          criteria_areas = areas,
          criteria_positions = positions,
        })
      else
        def.desc = desc
        def.criteria_areas = areas
        def.criteria_positions = positions
      end
      table.insert(allContinentIds, continent.id)
    end
  end

  -- Combined "every flight point on both continents" achievement. Plain
  -- ach_meta over the two continent achievements above -- the main file's
  -- existing generic ach_meta handling (award-on-completion, progress bar,
  -- tooltip checklist, login backlog recheck) covers this for free, no
  -- separate tracking needed. Points = sum of the two continent
  -- achievements, same convention as the other continent-pair metas
  -- (explore_wanderer et al) already use.
  --
  -- Gated on both continents having actually been found this pass (not
  -- table.getn(CONTINENTS) -- CONTINENTS is keyed [0]/[1], and table.getn's
  -- border search doesn't reliably count an index-0 entry, so that would
  -- silently undercount) -- registering with an incomplete criteria_ids
  -- list would create a meta achievement with fewer requirements than
  -- intended, or -- if a pcall failure ever left it completely empty --
  -- one that vacuously auto-completes for everyone.
  if table.getn(allContinentIds) == 2 and not LeafVE_AchTest:GetAchievementDef("explore_flight_all") then
    LeafVE_AchTest:AddAchievement("explore_flight_all", {
      id = "explore_flight_all",
      name = "Master Flyer: Azeroth",
      desc = "Discover every flight point on Eastern Kingdoms and Kalimdor.",
      category = "Exploration",
      points = 40,
      icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
      criteria_type = "ach_meta",
      criteria_ids = allContinentIds,
    })
  end
end

-- Titles for the three achievements above. Registered once at file load,
-- not from inside LiveInit -- AddTitle has no id-based dedup the way
-- AddAchievement does (it's a plain table.insert), and LiveInit deliberately
-- reruns on every PLAYER_ENTERING_WORLD to refresh live taxi data, so
-- calling AddTitle from there would insert a duplicate title entry on every
-- zone change. Title metadata itself doesn't depend on live data, only the
-- achievements' own criteria_areas do, so a one-time registration is enough.
local function RegisterFlightPointTitles()
  if not LeafVE_AchTest.AddTitle then return end
  LeafVE_AchTest:AddTitle({
    id = "title_skyfarer",
    name = "Skyfarer",
    chatName = "Skyfarer",
    achievement = "explore_flight_eastern_kingdoms",
    prefix = false,
    category = "Exploration",
    icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
    desc = "Every flight path across the Eastern Kingdoms lies mapped and mastered, wind-worn wings never far from ready.",
  })
  LeafVE_AchTest:AddTitle({
    id = "title_windwalker_azeroth",
    name = "Windwalker",
    chatName = "Windwalker",
    achievement = "explore_flight_kalimdor",
    prefix = false,
    category = "Exploration",
    icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
    desc = "The wild skies of Kalimdor hold no secrets left uncharted -- every gryphon roost known by heart.",
  })
  LeafVE_AchTest:AddTitle({
    id = "title_skybound",
    name = "Skybound",
    chatName = "Skybound",
    achievement = "explore_flight_all",
    prefix = false,
    category = "Exploration",
    icon = "Interface\\Icons\\Ability_Mount_Gryphon_01",
    desc = "Bound to no single horizon -- every flight point on Azeroth answers to their call.",
  })
end
RegisterFlightPointTitles()

-- silent may be a plain boolean/nil (applied uniformly to every continent --
-- what the PLAYER_ENTERING_WORLD recheck wants, always silent regardless of
-- per-continent state) or a table keyed by mapID (what CheckFlightPointsLive
-- wants, since Eastern Kingdoms and Kalimdor track their own independent
-- first-open state).
function LeafVE_AchTest:CheckFlightZoneAchievements(silent)
  local me = LeafVE_AchTest.ShortName(UnitName("player") or "")
  if not me or me == "" then return end
  if not LeafVE_AchTest_DB then return end
  if not LeafVE_AchTest_DB.discoveredFlightPoints then LeafVE_AchTest_DB.discoveredFlightPoints = {} end
  local discovered = LeafVE_AchTest_DB.discoveredFlightPoints[me]
  if not discovered then return end

  -- Dry run first: figure out which continents are newly complete this
  -- call, and whether that completion is itself a backfill, WITHOUT
  -- awarding anything yet. explore_flight_all (below) needs this before any
  -- continent is actually awarded -- AwardAchievement's own generic
  -- ach_meta pass-through would otherwise award the combined achievement
  -- itself, silent/loud decided by whichever continent happens to trigger
  -- it, which -- if both continents complete in the same call -- would just
  -- be whichever this loop processes second, not a deliberate choice.
  local toAward = {}
  local anySilentCompletion = false
  for mapID, continent in pairs(CONTINENTS) do
    local def = LeafVE_AchTest:GetAchievementDef(continent.id)
    if def and def.criteria_areas and not LeafVE_AchTest:HasAchievement(me, continent.id) then
      local total = table.getn(def.criteria_areas)
      local found = 0
      for _, name in ipairs(def.criteria_areas) do
        if discovered[name] then found = found + 1 end
      end
      if total > 0 and found == total then
        local continentSilent = silent
        if type(silent) == "table" then
          continentSilent = silent[mapID]
        end
        table.insert(toAward, {id = continent.id, silent = continentSilent})
        if continentSilent then anySilentCompletion = true end
      end
    end
  end

  if table.getn(toAward) == 0 then return end

  -- Would explore_flight_all become satisfied once everything in toAward is
  -- earned? If so, award it now, first, with a deliberate silent choice:
  -- silent if ANY of the completions responsible for it this pass were
  -- themselves a backfill, since a capstone achievement shouldn't announce
  -- loudly off the back of what's partly just database catch-up.
  local allDef = LeafVE_AchTest:GetAchievementDef("explore_flight_all")
  if allDef and allDef.criteria_ids and not LeafVE_AchTest:HasAchievement(me, "explore_flight_all") then
    local willBeEarned = {}
    for _, award in ipairs(toAward) do willBeEarned[award.id] = true end
    local allDone = true
    for _, reqId in ipairs(allDef.criteria_ids) do
      if not (LeafVE_AchTest:HasAchievement(me, reqId) or willBeEarned[reqId]) then
        allDone = false
        break
      end
    end
    if allDone then
      LeafVE_AchTest:AwardAchievement("explore_flight_all", anySilentCompletion)
    end
  end

  -- Now award the continents themselves. explore_flight_all is already
  -- earned by this point if it was going to be, so the generic ach_meta
  -- check inside these calls is a harmless no-op for it.
  for _, award in ipairs(toAward) do
    LeafVE_AchTest:AwardAchievement(award.id, award.silent)
  end
end

-- The only live signal available (see header comment): a flight map lists
-- every node reachable from it, and a node can only be reachable once
-- discovered, so snapshot that whenever any flight map is opened.
function LeafVE_AchTest:CheckFlightPointsLive()
  if not C_TaxiMap or not C_TaxiMap.GetAllTaxiNodes or not Enum then return end
  local me = LeafVE_AchTest.ShortName(UnitName("player") or "")
  if not me or me == "" then return end
  local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes)
  if not ok or not nodes then return end

  if not LeafVE_AchTest_DB then return end
  if not LeafVE_AchTest_DB.discoveredFlightPoints then LeafVE_AchTest_DB.discoveredFlightPoints = {} end
  if not LeafVE_AchTest_DB.discoveredFlightPoints[me] then LeafVE_AchTest_DB.discoveredFlightPoints[me] = {} end
  local discovered = LeafVE_AchTest_DB.discoveredFlightPoints[me]

  -- The very first flight map we ever see opened *for a given continent* is
  -- a backfill, not a real-time discovery -- there's no live "already known"
  -- query (see header comment), so this first snapshot is however many
  -- flight points they've actually already learned over their whole
  -- playtime, not something they just now discovered. Tracked per continent
  -- (mapID), not globally: opening a Kalimdor flight master first shouldn't
  -- burn the "first open" pass for Eastern Kingdoms too, since that's still
  -- genuinely unseen data. Award silently only for a continent's first
  -- pass; every open after that is a real live event for that continent.
  if not LeafVE_AchTest_DB.flightPointsFirstOpenDone then LeafVE_AchTest_DB.flightPointsFirstOpenDone = {} end
  if not LeafVE_AchTest_DB.flightPointsFirstOpenDone[me] then LeafVE_AchTest_DB.flightPointsFirstOpenDone[me] = {} end
  local firstOpenDone = LeafVE_AchTest_DB.flightPointsFirstOpenDone[me]
  local isFirstOpenByContinent = {}
  for mapID in pairs(CONTINENTS) do
    isFirstOpenByContinent[mapID] = not firstOpenDone[mapID]
  end

  local changed = false
  for _, n in ipairs(nodes) do
    if n.name and n.state ~= Enum.FlightPathState.Unreachable then
      if not discovered[n.name] then
        discovered[n.name] = true
        changed = true
      end
      -- Mark this continent as seen even if nothing new came from it this
      -- time (e.g. a continent already fully known before this feature
      -- shipped) -- it's still been observed once now, so it's done being
      -- "first."
      if n.mapID ~= nil and CONTINENTS[n.mapID] then
        firstOpenDone[n.mapID] = true
      end
    end
  end

  if changed then
    LeafVE_AchTest:CheckFlightZoneAchievements(isFirstOpenByContinent)
    if LeafVE_AchTest.UI and LeafVE_AchTest.UI.Refresh then
      LeafVE_AchTest.UI:Refresh()
    end
  end
end

-- ===== Event wiring =====
-- Self-contained frame/event set -- doesn't touch the existing
-- PLAYER_ENTERING_WORLD handlers already in LeafVillageAchievements.lua.

local flightPointsFrame = CreateFrame("Frame", "LeafVE_FlightPointsFrame")
flightPointsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
flightPointsFrame:RegisterEvent("TAXIMAP_OPENED")

flightPointsFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    LeafVE_AchTest_FlightPoints_LiveInit()
    LeafVE_AchTest:CheckFlightZoneAchievements(true)
  elseif event == "TAXIMAP_OPENED" then
    LeafVE_AchTest:CheckFlightPointsLive()
  end
end)
