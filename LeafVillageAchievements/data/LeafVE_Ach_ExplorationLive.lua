-- LeafVE_Ach_ExplorationLive.lua
--
-- Live, DBC-driven zone exploration achievements -- ported from OctoAchieve's
-- Data\ZoneExploration.lua + Tracking.lua exploration section
-- (~/achievements-octowow/OctoAchieve). Replaces the hand-typed
-- ZONE_GROUP_ZONES subzone lists (LeafVillageAchievements.lua) as the data
-- source for every per-zone "Explorer of <Zone>" achievement: C_Map.GetAreas/
-- GetMapZones/C_Map.GetMapOverlays give the exact real subzones for every
-- zone in the game straight from this server's own map data, and
-- C_MapExplorationInfo.GetExploredMapTextures gives real fog-of-war state,
-- so already-explored areas from before this file existed get credited
-- immediately instead of only from the next "Discovered X" message onward.
--
-- A zone that already has a curated achievement today (Balor, Gilneas,
-- Hyjal, Lapidis Isle, Gillijim's Isle, Northwind, Scarlet Enclave, Grim
-- Reaches, Tel'Abim, Tirisfal Uplands, Elwynn Forest, The Barrens) keeps its
-- existing id/name/points -- only its criteria becomes live instead of
-- hand-typed (REUSE_ZONE_ACHIEVEMENT_ID below). Every other real zone gets a
-- brand-new achievement with a stable "explore_zone_<slug>" id derived from
-- the zone's own name, not an index-based scheme -- an index shifts every
-- id if a new zone ever sorts earlier alphabetically, which is exactly the
-- kind of instability a stable id is supposed to avoid.

-- ===== Name normalization / slugging =====

local function NormalizeMapName(name)
  if not name then return "" end
  local s = string.lower(name)
  s = string.gsub(s, "^the%s+", "")
  s = string.gsub(s, "[^%w]", "")
  return s
end

local function Slugify(name)
  local s = string.lower(name or "")
  s = string.gsub(s, "[^%w]+", "_")
  s = string.gsub(s, "^_+", "")
  s = string.gsub(s, "_+$", "")
  return s
end

-- Zones that already have a curated exploration achievement -- reuse that
-- achievement's id/name/points and only replace its criteria with live data
-- (see RegisterOrUpdateZoneAchievement) instead of minting a duplicate.
local REUSE_ZONE_ACHIEVEMENT_ID = {}
local function RegisterReuse(zoneName, achId)
  REUSE_ZONE_ACHIEVEMENT_ID[NormalizeMapName(zoneName)] = achId
end
RegisterReuse("Balor",              "explore_tw_balor")
RegisterReuse("Gillijim's Isle",    "explore_tw_gillijim")
RegisterReuse("Gilneas",            "explore_tw_gilneas")
RegisterReuse("Hyjal",              "explore_tw_hyjal")
RegisterReuse("Lapidis Isle",       "explore_tw_lapidis")
RegisterReuse("Northwind",          "explore_tw_northwind")
RegisterReuse("Tel'Abim",           "explore_tw_telabim")
RegisterReuse("The Grim Reaches",   "explore_tw_grim_reaches")
RegisterReuse("Grim Reaches",       "explore_tw_grim_reaches")
RegisterReuse("The Scarlet Enclave","explore_tw_scarlet_enclave")
RegisterReuse("Scarlet Enclave",    "explore_tw_scarlet_enclave")
RegisterReuse("Tirisfal Uplands",   "explore_tw_tirisfal_uplands")
RegisterReuse("Elwynn Forest",      "casual_explore_elwynn")
RegisterReuse("The Barrens",        "casual_explore_barrens")
RegisterReuse("Barrens",            "casual_explore_barrens")

-- ===== Live resolution helpers (ported from OctoAchieve Data\ZoneExploration.lua) =====

-- Cached once per session: C_Map.GetAreas() enumerates every AreaTable row
-- in the game, so it's only worth walking with pairs() a single time.
local nameToAreaID = nil

local function ResolveZoneAreaID(zoneName)
  if not nameToAreaID then
    local ok, areas = pcall(C_Map.GetAreas)
    if not ok or not areas then return nil end
    nameToAreaID = areas
  end
  for id, name in pairs(nameToAreaID) do
    if name == zoneName then return id end
  end
  local norm = NormalizeMapName(zoneName)
  for id, name in pairs(nameToAreaID) do
    if NormalizeMapName(name) == norm then return id end
  end
  return nil
end

-- 1 = Eastern Kingdoms, 2 = Kalimdor -- the only two continents vanilla has.
-- GetMapZones(continent) is stock vanilla's own zone-dropdown data source,
-- so "every zone available" here means exactly what the default world map's
-- continent dropdown offers.
local CONTINENTS = { 1, 2 }

local zoneList = nil          -- sorted array of zone name strings, both continents
local zoneIndexByName = nil   -- [name] = stable 1-based index into zoneList
local zonesByContinent = nil  -- [1|2] = sorted array of zone names on that continent

local function DiscoverZoneNames()
  local seen, names = {}, {}
  zonesByContinent = { [1] = {}, [2] = {} }
  for _, continent in ipairs(CONTINENTS) do
    local packed = { pcall(GetMapZones, continent) }
    if packed[1] then
      for i = 2, table.getn(packed) do
        local zname = packed[i]
        if zname and zname ~= "" then
          if not seen[zname] then
            seen[zname] = true
            table.insert(names, zname)
          end
          table.insert(zonesByContinent[continent], zname)
        end
      end
    end
  end
  table.sort(names)
  table.sort(zonesByContinent[1])
  table.sort(zonesByContinent[2])
  return names
end

local function EnsureZoneList()
  if not zoneList then
    zoneList = DiscoverZoneNames()
    zoneIndexByName = {}
    for i, zname in ipairs(zoneList) do
      zoneIndexByName[zname] = i
    end
  end
end

local function IsKnownZoneName(zoneName)
  EnsureZoneList()
  return zoneIndexByName ~= nil and zoneIndexByName[zoneName] ~= nil
end

-- The achievement row icon fallback (used before/if the live mosaic
-- thumbnail can't be built): the single largest tile (by drawn area) among
-- all the zone's overlay tiles, cropped to its valid texcoord rect.
local function PickZoneIcon(overlays)
  local best, bestArea = nil, -1
  for _, ov in ipairs(overlays or {}) do
    if ov.tiles then
      for _, t in ipairs(ov.tiles) do
        local area = (t.width or 0) * (t.height or 0)
        if area > bestArea then
          bestArea = area
          best = t
        end
      end
    end
  end
  if not best then return nil, nil end
  return best.file, { 0, best.texCoordX, 0, best.texCoordY }
end

-- The zone map mosaic (UI.lua's LayoutThumbnail/LayoutMosaic) used to scale
-- every tile against a fixed 1002x668 "world map canvas" constant borrowed
-- from OctoAchieve. That's wrong: a zone's own tile offsets aren't bounded
-- by that figure at all (confirmed via /leafzonedebug on Loch Modan --
-- Farstrider Lodge's own remainder tiles are legitimately positioned at
-- offsetX 997 with width 128, i.e. extending to x=1125, correctly adjacent
-- to its own other tiles, not stray/duplicate data). What looked like a
-- rendering artifact was real content being scaled against a canvas
-- reference too small for it. Fixed properly: compute each zone's own true
-- bounding box from all of its own tiles and scale/position against that
-- instead of any fixed constant.
local function ComputeZoneBounds(overlays)
  local minX, minY, maxX, maxY = nil, nil, nil, nil
  for _, ov in ipairs(overlays) do
    if ov.tiles then
      for _, t in ipairs(ov.tiles) do
        if (t.width or 0) > 0 and (t.height or 0) > 0 then
          local x1, y1 = t.offsetX or 0, t.offsetY or 0
          local x2, y2 = x1 + t.width, y1 + t.height
          if not minX or x1 < minX then minX = x1 end
          if not minY or y1 < minY then minY = y1 end
          if not maxX or x2 > maxX then maxX = x2 end
          if not maxY or y2 > maxY then maxY = y2 end
        end
      end
    end
  end
  if not minX then return nil end
  return { minX = minX, minY = minY, width = maxX - minX, height = maxY - minY }
end

local function OverlayHasNamedArea(ov, zoneAreaID)
  local ids = ov.areaIDs
  if ids and table.getn(ids) > 0 then
    for _, aid in ipairs(ids) do
      if aid and aid > 0 and aid ~= zoneAreaID then return true end
    end
    return false
  end
  return ov.areaID and ov.areaID > 0 and ov.areaID ~= zoneAreaID
end

-- Specific tiles confirmed (via /leafzonedebug plus checking the stock
-- in-game world map, which renders these zones correctly) to render as a
-- disconnected floating fragment rather than the general per-zone bounds
-- math being wrong. Both known offenders share the same signature: a
-- narrow "remainder" tile (width well under a full 256) that claims
-- tc=(1.000,...) -- zero cropping -- when every other correctly-behaving
-- remainder tile in the same zone has a fractional texcoord proportional
-- to its own size (e.g. Grizzlepaw Ridge's 6px-wide remainder is
-- tc.X=0.375, Mogrosh Stronghold's 31px is tc.X=0.969). Isolated to these
-- specific POIs' own live data rather than a bug in the general tile
-- pipeline (verified by hand: every other tile in the zone composes
-- correctly), so patched by excluding these specific texture files
-- instead of reworking the shared layout code.
local EXCLUDED_TILE_FILES = {
  ["interface\\worldmap\\lochmodan\\thefarstriderlodge2"] = true,
  ["interface\\worldmap\\lochmodan\\thefarstriderlodge3"] = true,
  ["interface\\worldmap\\lochmodan\\thefarstriderlodge4"] = true,
}

local function IsExcludedTile(t)
  if not t or not t.file then return false end
  return EXCLUDED_TILE_FILES[string.lower(t.file)] == true
end

-- Every named subzone under zoneAreaID: its own overlay(s) (areaOverlays --
-- the tiles that actually depict it, keyed by name; used by the Zone Map
-- window to light those tiles up on checklist hover), the full unfiltered
-- overlay list (for drawing the whole zone mosaic), and that mosaic's own
-- true bounding box (see ComputeZoneBounds above) for scaling against.
local function BuildZoneCriteria(zoneAreaID)
  local ok, overlays = pcall(C_Map.GetMapOverlays, zoneAreaID)
  if not ok or not overlays then return nil end

  for _, ov in ipairs(overlays) do
    if ov.tiles then
      local kept = {}
      for _, t in ipairs(ov.tiles) do
        if not IsExcludedTile(t) then
          table.insert(kept, t)
        end
      end
      ov.tiles = kept
    end
  end

  local bounds = ComputeZoneBounds(overlays)

  local areas, areaOverlays, seen = {}, {}, {}
  for _, ov in ipairs(overlays) do
    local ids = ov.areaIDs
    if not ids or table.getn(ids) == 0 then ids = { ov.areaID } end
    for _, aid in ipairs(ids) do
      if aid and aid > 0 and aid ~= zoneAreaID then
        local name = C_Map.GetAreaInfo(aid)
        if name and name ~= "" then
          if not seen[aid] then
            seen[aid] = true
            table.insert(areas, name)
          end
          areaOverlays[name] = areaOverlays[name] or {}
          table.insert(areaOverlays[name], ov)
        end
      end
    end
  end
  table.sort(areas)
  return areas, areaOverlays, overlays, bounds
end

-- ===== Achievement registration =====

-- ids registered/updated by the most recent LiveInit -- the tracking
-- functions below iterate this instead of the (main-file-local) ACHIEVEMENTS
-- table directly.
local liveZoneAchievementIds = {}
-- Rotating cursor into liveZoneAchievementIds for the throttled backfill
-- sweep (CheckZoneExplorationLive) -- declared here, ahead of both that
-- function and the throttled scan below, since Lua resolves locals as
-- upvalues lexically.
local backfillIndex = 1
-- Flips true once backfillIndex has wrapped all the way around
-- liveZoneAchievementIds at least once -- i.e., every known zone
-- achievement has been checked against C_MapExplorationInfo's
-- fog-of-war data at least one time. Before that point, any award this
-- sweep produces is (or at least might be) retroactively catching up on
-- exploration the player did before this feature -- or this character's
-- login -- ever ran, not something happening live right now, so it's
-- kept silent (see the `silent` args threaded through
-- CheckZoneExplorationLive/CheckExploreCountAchievements below). After
-- the first full pass, further completions are genuinely new.
local hasCompletedFirstSweep = false

local function RegisterOrUpdateZoneAchievement(zoneName, zoneAreaID, areas, areaOverlays, overlays, bounds)
  local goal = table.getn(areas)
  local icon, iconTexCoord = PickZoneIcon(overlays)
  local desc = "Discover every area in " .. zoneName .. " (" .. goal .. " locations)."

  local reuseId = REUSE_ZONE_ACHIEVEMENT_ID[NormalizeMapName(zoneName)]
  local id = reuseId
  local def = reuseId and LeafVE_AchTest:GetAchievementDef(reuseId)

  if not def then
    id = "explore_zone_" .. Slugify(zoneName)
    def = LeafVE_AchTest:GetAchievementDef(id)
  end

  if def then
    -- Already registered (either the curated original or a previous
    -- LiveInit run this session) -- refresh its criteria/desc/icon in
    -- place. Name/points/category stay whatever they already are.
    def.criteria_type = "explore_zone_live"
    def.criteria_areas = areas
    def.criteria_areaOverlays = areaOverlays
    def.criteria_overlays = overlays
    def.criteria_bounds = bounds
    def.criteria_zoneAreaID = zoneAreaID
    def.desc = desc
    if icon then
      def.icon = icon
      def.iconTexCoord = iconTexCoord
    end
    -- A reused def's criteria_key is a leftover from the old zone_group
    -- data source; clear it so nothing accidentally falls back to the
    -- static ZONE_GROUP_ZONES table for this achievement anymore.
    def.criteria_key = nil
  else
    local points = math.min(100, 10 + goal * 3)
    LeafVE_AchTest:AddAchievement(id, {
      id = id,
      name = "Explorer of " .. zoneName,
      desc = desc,
      category = "Exploration",
      points = points,
      icon = icon or "Interface\\Icons\\INV_Misc_Map_01",
      iconTexCoord = iconTexCoord,
      criteria_type = "explore_zone_live",
      criteria_areas = areas,
      criteria_areaOverlays = areaOverlays,
      criteria_overlays = overlays,
      criteria_bounds = bounds,
      criteria_zoneAreaID = zoneAreaID,
    })
  end

  table.insert(liveZoneAchievementIds, id)
end

-- Generic "discover N total areas" tiers (OctoAchieve Data\Exploration.lua
-- ids 2000-2005) -- LeafVillageAchievements had no equivalent of this
-- before. Tracked off the total size of LeafVE_AchTest_DB.exploredZones[me],
-- the same per-player dedupe set every exploration achievement type reads.
local EXPLORE_COUNT_TIERS = {
  { id = "explore_areas_10",  goal = 10,  points = 5,  name = "Wide Eyed Wanderer" },
  { id = "explore_areas_25",  goal = 25,  points = 5,  name = "Getting Your Bearings" },
  { id = "explore_areas_50",  goal = 50,  points = 10, name = "Well Traveled" },
  { id = "explore_areas_100", goal = 100, points = 15, name = "Cartographer's Pride" },
  { id = "explore_areas_150", goal = 150, points = 20, name = "Wanderer of Azeroth" },
  { id = "explore_areas_200", goal = 200, points = 25, name = "There and Back Again" },
}

local function RegisterExploreCountTiers()
  for _, tier in ipairs(EXPLORE_COUNT_TIERS) do
    if not LeafVE_AchTest:GetAchievementDef(tier.id) then
      LeafVE_AchTest:AddAchievement(tier.id, {
        id = tier.id,
        name = tier.name,
        desc = "Discover " .. tier.goal .. " areas.",
        category = "Exploration",
        points = tier.points,
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        criteria_type = "explore_count",
        criteria_goal = tier.goal,
      })
    end
  end
end

-- "Visit every zone" (OctoAchieve's "Seen It All", ZoneExploration.lua
-- id 2020) -- goal is the live discovered zone count itself, not a
-- hand-picked number, so it always matches whatever this server's
-- continents actually contain.
local function RegisterZonesVisitedAchievement()
  local goal = table.getn(zoneList)
  if goal <= 0 then return end
  local desc = "Set foot in every zone (" .. goal .. " total)."
  local def = LeafVE_AchTest:GetAchievementDef("explore_seen_it_all")
  if def then
    def.criteria_goal = goal
    def.desc = desc
  else
    LeafVE_AchTest:AddAchievement("explore_seen_it_all", {
      id = "explore_seen_it_all",
      name = "Seen It All",
      desc = desc,
      category = "Exploration",
      points = 30,
      icon = "Interface\\Icons\\INV_Misc_Map_02",
      criteria_type = "zone_visited_count",
      criteria_goal = goal,
    })
  end
end

-- Calling C_Map.GetMapOverlays for every zone (60-100+) in one synchronous
-- burst right on PLAYER_ENTERING_WORLD -- immediately followed by another
-- full-zone burst of C_MapExplorationInfo.GetExploredMapTextures for the
-- retroactive backfill -- crashed the client outright (a native
-- ACCESS_VIOLATION, not a Lua error, so no pcall can catch it). Most likely
-- either a race with the ClassicAPI backport's own login-time init, or the
-- backport simply not tolerating a rapid-fire burst of calls. Two changes
-- address both possibilities: delay the first scan a few seconds after
-- entering world (the same pattern LeafVillageAchievements.lua's own
-- hookFrame already uses for HookChatWithTitles, for the same kind of
-- reason), and process only a couple of zones per frame instead of the
-- whole list at once, via the scanState machine + OnUpdate driver below.
local ZONES_PER_TICK = 2
local scanState = "idle" -- idle | scanning | done
local scanIndex = 1

local function TickLiveInitScan()
  local processed = 0
  while scanIndex <= table.getn(zoneList) and processed < ZONES_PER_TICK do
    local zoneName = zoneList[scanIndex]
    scanIndex = scanIndex + 1
    processed = processed + 1
    local zoneAreaID = ResolveZoneAreaID(zoneName)
    if zoneAreaID then
      local areas, areaOverlays, overlays, bounds = BuildZoneCriteria(zoneAreaID)
      if areas and table.getn(areas) > 0 then
        RegisterOrUpdateZoneAchievement(zoneName, zoneAreaID, areas, areaOverlays, overlays, bounds)
      end
    end
  end

  if scanIndex > table.getn(zoneList) then
    RegisterExploreCountTiers()
    RegisterZonesVisitedAchievement()
    scanState = "done"
    if LeafVE_AchTest.UI and LeafVE_AchTest.UI.frame and LeafVE_AchTest.UI.frame:IsShown() then
      LeafVE_AchTest.UI:Refresh()
    end
  end
end

-- Kicks off (or restarts, e.g. on a later PLAYER_ENTERING_WORLD from a zone
-- change) the throttled scan above -- does none of the actual C_Map work
-- itself. The OnUpdate driver in the event-wiring section below is what
-- calls TickLiveInitScan a couple of zones at a time.
function LeafVE_AchTest_ExplorationLive_Init()
  if not C_Map or not C_Map.GetMapOverlays or not C_Map.GetAreas or not C_Map.GetAreaInfo
    or not GetMapZones then
    return
  end

  EnsureZoneList()

  -- Continent-level "discover all zones in X" achievements (explore_kalimdor/
  -- explore_eastern_kingdoms) already exist as criteria_type="zone_group";
  -- just repoint their zone list at the live per-continent list instead of
  -- the hand-typed one -- same mechanism (LeafVE_AchTest:CheckExplorationAchievements
  -- still reads ZONE_GROUP_ZONES.kalimdor/.eastern_kingdoms), live source.
  local zgz = LeafVE_AchTest:GetZoneGroupZones()
  if zgz and zonesByContinent then
    if table.getn(zonesByContinent[2]) > 0 then zgz.kalimdor = zonesByContinent[2] end
    if table.getn(zonesByContinent[1]) > 0 then zgz.eastern_kingdoms = zonesByContinent[1] end
  end

  liveZoneAchievementIds = {}
  backfillIndex = 1
  scanIndex = 1
  scanState = "scanning"
end

-- ===== Tracking =====

-- Real fog-of-war, not a chat-text guess: C_MapExplorationInfo.
-- GetExploredMapTextures returns exactly the WorldMapOverlay rows this
-- character has actually revealed for a zone, keyed the same way as
-- C_Map.GetMapOverlays. Folding that into LeafVE_AchTest_DB.exploredZones,
-- the same dedupe table the "Discovered X" zone-change tracking
-- (LeafVillageAchievements.lua's zoneDiscFrame) already writes to, means
-- both the checklist and the achievement award check are correct
-- immediately -- including areas explored before this file ever existed --
-- rather than only from the next zone transition onward.
-- Throttled the same way as the registration scan above (BACKFILL_ZONES_PER_TICK
-- zones per call, rotating through liveZoneAchievementIds via backfillIndex,
-- wrapping back to the start once it reaches the end) rather than every
-- zone in one synchronous burst -- called repeatedly off the poll timer
-- below, so the full list still gets swept regularly, just spread out.
local BACKFILL_ZONES_PER_TICK = 2

function LeafVE_AchTest:CheckZoneExplorationLive()
  if not C_MapExplorationInfo or not C_MapExplorationInfo.GetExploredMapTextures then return end
  local total = table.getn(liveZoneAchievementIds)
  if total == 0 then return end
  local me = LeafVE_AchTest.ShortName(UnitName("player") or "")
  if not me or me == "" then return end
  if not LeafVE_AchTest_DB then return end
  if not LeafVE_AchTest_DB.exploredZones then LeafVE_AchTest_DB.exploredZones = {} end
  if not LeafVE_AchTest_DB.exploredZones[me] then LeafVE_AchTest_DB.exploredZones[me] = {} end
  local discovered = LeafVE_AchTest_DB.exploredZones[me]

  local changed = false
  local processed = 0
  while processed < BACKFILL_ZONES_PER_TICK and processed < total do
    if backfillIndex > total then
      backfillIndex = 1
      hasCompletedFirstSweep = true
    end
    local id = liveZoneAchievementIds[backfillIndex]
    backfillIndex = backfillIndex + 1
    processed = processed + 1

    local def = LeafVE_AchTest:GetAchievementDef(id)
    if def and def.criteria_zoneAreaID then
      local ok, explored = pcall(C_MapExplorationInfo.GetExploredMapTextures, def.criteria_zoneAreaID)
      if ok and explored then
        for _, ov in ipairs(explored) do
          local ids = ov.areaIDs
          if not ids or table.getn(ids) == 0 then ids = { ov.areaID } end
          for _, aid in ipairs(ids) do
            if aid and aid > 0 and aid ~= def.criteria_zoneAreaID then
              local name = C_Map.GetAreaInfo(aid)
              if name and name ~= "" and not discovered[name] then
                discovered[name] = true
                changed = true
              end
            end
          end
        end
      end
    end
  end

  if changed then
    -- Silent until the first full sweep completes -- see
    -- hasCompletedFirstSweep's comment above.
    local silent = not hasCompletedFirstSweep
    if LeafVE_AchTest.CheckExplorationAchievements then
      LeafVE_AchTest:CheckExplorationAchievements(silent)
    end
    if LeafVE_AchTest.CheckExploreCountAchievements then
      LeafVE_AchTest:CheckExploreCountAchievements(silent)
    end
  end
end

function LeafVE_AchTest:CheckExploreCountAchievements(silent)
  local me = LeafVE_AchTest.ShortName(UnitName("player") or "")
  if not me or me == "" then return end
  if not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.exploredZones or not LeafVE_AchTest_DB.exploredZones[me] then
    return
  end
  local total = 0
  for _ in pairs(LeafVE_AchTest_DB.exploredZones[me]) do total = total + 1 end
  for _, tier in ipairs(EXPLORE_COUNT_TIERS) do
    if total >= tier.goal and not LeafVE_AchTest:HasAchievement(me, tier.id) then
      LeafVE_AchTest:AwardAchievement(tier.id, silent)
    end
  end
end

function LeafVE_AchTest:CheckZonesVisitedLive()
  local zone = GetRealZoneText and GetRealZoneText() or nil
  if not zone or zone == "" then return end
  if not IsKnownZoneName(zone) then return end
  local me = LeafVE_AchTest.ShortName(UnitName("player") or "")
  if not me or me == "" then return end
  if not LeafVE_AchTest_DB then return end
  if not LeafVE_AchTest_DB.zonesVisited then LeafVE_AchTest_DB.zonesVisited = {} end
  if not LeafVE_AchTest_DB.zonesVisited[me] then LeafVE_AchTest_DB.zonesVisited[me] = {} end
  local visited = LeafVE_AchTest_DB.zonesVisited[me]
  if visited[zone] then return end
  visited[zone] = true

  local count = 0
  for _ in pairs(visited) do count = count + 1 end
  local def = LeafVE_AchTest:GetAchievementDef("explore_seen_it_all")
  if def and count >= (def.criteria_goal or 0) and not LeafVE_AchTest:HasAchievement(me, "explore_seen_it_all") then
    LeafVE_AchTest:AwardAchievement("explore_seen_it_all")
  end
end

-- ===== Event wiring =====
-- A self-contained frame/event set, same pattern OctoAchieve's Tracking.lua
-- uses -- doesn't touch any of the existing PLAYER_ENTERING_WORLD handlers
-- already in LeafVillageAchievements.lua.

local liveExploreFrame = CreateFrame("Frame", "LeafVE_ExplorationLiveFrame")
liveExploreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
liveExploreFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- INIT_DELAY: how long after entering world before the (still throttled)
-- registration scan starts -- gives the ClassicAPI backport and every other
-- addon's own login-time init a head start instead of racing it.
-- POLL_INTERVAL: how often, once the registration scan has finished, the
-- throttled backfill sweep (CheckZoneExplorationLive) advances by
-- BACKFILL_ZONES_PER_TICK zones. Both were lowered from an earlier
-- unthrottled version that called C_Map for every zone in one synchronous
-- burst and crashed the client outright.
local INIT_DELAY = 3
local POLL_INTERVAL = 5
local initTimer = 0
local pollElapsed = 0

liveExploreFrame:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    if scanState ~= "scanning" then
      initTimer = 0
    end
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    LeafVE_AchTest:CheckZonesVisitedLive()
  end
end)

liveExploreFrame:SetScript("OnUpdate", function()
  if scanState == "idle" then
    initTimer = initTimer + arg1
    if initTimer >= INIT_DELAY then
      initTimer = 0
      LeafVE_AchTest_ExplorationLive_Init()
    end
    return
  end

  if scanState == "scanning" then
    TickLiveInitScan()
    return
  end

  -- scanState == "done": the registration scan is fully populated, so it's
  -- now safe to run the (also throttled) backfill sweep and the count/
  -- visited checks on a normal interval.
  pollElapsed = pollElapsed + arg1
  if pollElapsed >= POLL_INTERVAL then
    pollElapsed = 0
    LeafVE_AchTest:CheckZoneExplorationLive()
    -- Same silent-until-first-full-sweep rule as inside
    -- CheckZoneExplorationLive itself (see hasCompletedFirstSweep) --
    -- this direct call re-derives the count independent of whether this
    -- particular tick discovered anything new.
    LeafVE_AchTest:CheckExploreCountAchievements(not hasCompletedFirstSweep)
    LeafVE_AchTest:CheckZonesVisitedLive()
  end
end)

-- ===== Debug =====
-- /leafzonedebug <zone name> -- dumps every overlay/tile this file resolved
-- for that zone's live achievement (offsets, sizes, texcoords, which
-- overlay rows have no named area attached). For diagnosing mosaic
-- rendering artifacts precisely instead of guessing at the geometry blind.
SLASH_LEAFZONEDEBUG1 = "/leafzonedebug"
SlashCmdList["LEAFZONEDEBUG"] = function(msg)
  local zoneName = Trim and Trim(msg or "") or msg
  if not zoneName or zoneName == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /leafzonedebug <zone name>")
    return
  end
  local id = REUSE_ZONE_ACHIEVEMENT_ID[NormalizeMapName(zoneName)] or ("explore_zone_" .. Slugify(zoneName))
  local def = LeafVE_AchTest:GetAchievementDef(id)
  if not def or not def.criteria_overlays then
    DEFAULT_CHAT_FRAME:AddMessage("No live zone data for '" .. zoneName .. "' (tried id " .. id .. ")")
    return
  end
  DEFAULT_CHAT_FRAME:AddMessage(def.name .. " -- zoneAreaID=" .. tostring(def.criteria_zoneAreaID)
    .. ", " .. table.getn(def.criteria_overlays) .. " overlay row(s)")
  for oi, ov in ipairs(def.criteria_overlays) do
    local named = OverlayHasNamedArea(ov, def.criteria_zoneAreaID)
    DEFAULT_CHAT_FRAME:AddMessage("Overlay " .. oi .. ": areaID=" .. tostring(ov.areaID)
      .. " namedArea=" .. tostring(named) .. " tiles=" .. table.getn(ov.tiles or {}))
    for ti, t in ipairs(ov.tiles or {}) do
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  tile %d: off=(%d,%d) size=(%d,%d) tc=(%.3f,%.3f) file=%s",
        ti, t.offsetX or -1, t.offsetY or -1, t.width or -1, t.height or -1,
        t.texCoordX or -1, t.texCoordY or -1, tostring(t.file)))
    end
  end
end
