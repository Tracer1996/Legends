-- LeafVE_Ach_Toys.lua
-- OctoWoW toy collection achievements and shared collection metadata.
-- Vanilla/Turtle WoW 1.12, Lua 5.0 compatible.

local TOY_CATEGORY = "Toys"
local TOY_ICON = "Interface\\Icons\\INV_Misc_Toy_10"

local TOY_SOURCE = "Collection"
local TOY_OBTAINED_FROM = "OctoWoW custom toy; exact acquisition is not verified in the bundled catalogue."
local TOY_SOURCE_CONFIDENCE = "Unverified Turtle source"

local TOY_CATALOG = {
  {name="Orb of Deception",itemID=1973,sourceCategory="Novelty"},
  {name="Croak Cannon",itemID=7013,desc="Throw a frog into your unsuspecting friend's face.",sourceCategory="Novelty"},
  {name="Goblin Radio KABOOM-Box X23B76",itemID=10585,desc="Highly explosive tunes!",sourceCategory="Novelty"},
  {name="Elune's Lantern",itemID=21540,desc="A device said to capture the light shed by Elune herself.",sourceCategory="Ambience"},
  {name="Everlasting Firework",itemID=23714,desc="The best way to give away your position!",sourceCategory="Novelty"},
  {name="Carved Ogre Idol",itemID=23716,sourceCategory="Ambience"},
  {name="Blazing Forge Kit",itemID=31825,desc="Unpack the Blazing Forge Kit, because a dedicated blacksmith never lets the impossibility of carrying a forge and anvil slow them down.",sourceCategory="Utility"},
  {name="Tome of Tactical Escape I",itemID=31826,desc="After countless escapes, the magic of the Hearthstone has seared into your mind, making the physical stone unnecessary. Now, the power to return home is just a thought away, with a cooldown of only 30 minutes.",sourceCategory="Utility"},
  {name="Sacred Chalice",itemID=31827,desc="A sacred vessel filled with the essence of a moonwell, allowing tailors to craft Mooncloth anywhere under Elune's blessing.",sourceCategory="Utility"},
  {name="Miniature Winter Veil Tree",itemID=51250,desc="Summon a Winter Veil Tree with fluffy branches and beautiful bright lights!",sourceCategory="Ambience"},
  {name="Toy Train Set",itemID=51255,desc="All Aboard!",sourceCategory="Novelty"},
  {name="Goblin Brainwashing Device",itemID=51715,desc="Use it at your own risk. The procedure of talent reset costs money.",sourceCategory="Utility"},
  {name="Music: Winds of Kamio",itemID=70043,sourceCategory="Music"},
  {name="Music: Emerald Dream",itemID=70080,sourceCategory="Music"},
  {name="Music: Bells of the Dawn",itemID=70081,sourceCategory="Music"},
  {name="Music: Hourglass of Eternity",itemID=70082,sourceCategory="Music"},
  {name="Music: Hyjal Summit",itemID=70083,sourceCategory="Music"},
  {name="Music: Jaguero Isle",itemID=70084,sourceCategory="Music"},
  {name="Music: Stratholme's Best Days",itemID=70085,sourceCategory="Music"},
  {name="Music: Titanic Mystery",itemID=70086,sourceCategory="Music"},
  {name="Music: Aerie Peak",itemID=70087,sourceCategory="Music"},
  {name="Music: Hateforge Quarry Interior",itemID=70088,sourceCategory="Music"},
  {name="Music: Bastion",itemID=70090,sourceCategory="Music"},
  {name="Music: Hateforge Quarry Exterior",itemID=70091,sourceCategory="Music"},
  {name="Music: Stormwind Vault",itemID=70092,sourceCategory="Music"},
  {name="Music: Dun Argath",itemID=70094,sourceCategory="Music"},
  {name="Music: Snowing in the Vale",itemID=70095,sourceCategory="Music"},
  {name="Fox's Spirit Stone",itemID=81059,desc="It disappears as quietly and mysteriously as the mist.",sourceCategory="Ambience"},
  {name="Picnic Basket",itemID=81116,desc="Set up a relaxing little picnic.",sourceCategory="Ambience"},
}

local TOY_MILESTONES = {
  {id="casual_toy_collector", name="Toy Box", desc="Collect 5 OctoWoW toys.", goal=5, points=50},
  {id="toy_collector_10", name="Toy Chest", desc="Collect 10 OctoWoW toys.", goal=10, points=100},
  {id="toy_collector_20", name="Toy Vault", desc="Collect 20 OctoWoW toys.", goal=20, points=150},
}

local function Slugify(text)
  local slug=string.lower(tostring(text or ""))
  slug=string.gsub(slug,"'","")
  slug=string.gsub(slug,"[^a-z0-9]+","_")
  slug=string.gsub(slug,"^_+","")
  slug=string.gsub(slug,"_+$","")
  return slug
end

local function GetToyModuleState()
  if not LeafVE_AchTest_DB then return nil end
  if not LeafVE_AchTest_DB.toyTracker then LeafVE_AchTest_DB.toyTracker={} end
  return LeafVE_AchTest_DB.toyTracker
end

local TOY_BY_ACH_ID={}
local TOY_IDS={}
local TOY_LOOKUP={}
LeafVE_Ach_ToysMaster=LeafVE_Ach_ToysMaster or {}

local function RegisterToyLookup(name,achievementId)
  local key=Slugify(name)
  if key=="" or not achievementId or achievementId=="" then return end
  if not TOY_LOOKUP[key] then TOY_LOOKUP[key]=achievementId end
end

local function RegisterMasterName(name,data)
  if not name or name=="" then return end
  LeafVE_Ach_ToysMaster[name]={
    name=name, source=data.source, obtainedFrom=data.obtainedFrom,
    sourceConfidence=data.sourceConfidence, category=data.sourceCategory,
    sourceCategory=data.sourceCategory, points=data.points, difficulty=data.difficulty,
    icon=data.icon or TOY_ICON, achievementId=data.id, itemID=data.itemID,
    description=data.desc,
  }
end

for _,raw in ipairs(TOY_CATALOG) do
  local key=Slugify(raw.name)
  local achievementId="toy_"..key
  local data={
    id=achievementId, name=raw.name,
    desc=(raw.desc and raw.desc ~= "" and raw.desc) or ("Collect "..raw.name.."."),
    category=TOY_CATEGORY, points=raw.points or 50,
    difficulty=raw.difficulty or "Uncommon", icon=raw.icon or TOY_ICON,
    source=raw.source or TOY_SOURCE, obtainedFrom=raw.obtainedFrom or TOY_OBTAINED_FROM,
    sourceConfidence=raw.sourceConfidence or TOY_SOURCE_CONFIDENCE, sourceCategory=raw.sourceCategory or "Collection",
    itemID=raw.itemID,
  }
  table.insert(TOY_IDS,achievementId)
  TOY_BY_ACH_ID[achievementId]=data
  RegisterToyLookup(raw.name,achievementId)
  RegisterMasterName(raw.name,data)
end

local TOY_TOTAL=table.getn(TOY_IDS)
table.insert(TOY_MILESTONES,{id="toy_collector_all",name="Toy Master",desc="Collect all "..TOY_TOTAL.." OctoWoW toys.",goal=TOY_TOTAL,points=250})

-- Chat titles awarded alongside the milestone achievements above, mirroring
-- COMPANION_TITLE_DEFS in LeafVE_Ach_Companions.lua.
local TOY_TITLE_DEFS = {
  {id="title_toy_jester",name="Jester",achievement="casual_toy_collector",desc="Awarded for collecting 5 OctoWoW toys.",icon="Interface\\Icons\\INV_Misc_Bell_01"},
  {id="title_toy_trickster",name="Trickster",achievement="toy_collector_10",desc="Awarded for collecting 10 OctoWoW toys.",icon="Interface\\Icons\\Spell_Shadow_Charm"},
  {id="title_toy_showman",name="Showman",achievement="toy_collector_20",desc="Awarded for collecting 20 OctoWoW toys.",icon="Interface\\Icons\\INV_Gizmo_02"},
  {id="title_toy_toymaster",name="Toymaster",achievement="toy_collector_all",desc="Awarded for collecting every OctoWoW toy.",icon="Interface\\Icons\\Spell_Nature_Polymorph"},
}

function LeafVE_AchTest:GetToyPointValue(name)
  local id=TOY_LOOKUP[Slugify(name)]
  local data=id and TOY_BY_ACH_ID[id]
  return data and data.points or 50
end

function LeafVE_AchTest:GetToyAchievementId(name)
  return TOY_LOOKUP[Slugify(name)]
end

local function RegisterToyAchievements()
  if not LeafVE_AchTest or not LeafVE_AchTest.AddAchievement then return end
  for _,achievementId in ipairs(TOY_IDS) do
    local data=TOY_BY_ACH_ID[achievementId]
    LeafVE_AchTest:AddAchievement(achievementId,{
      id=data.id,name=data.name,desc=data.desc,category=data.category,points=data.points,icon=data.icon,
      toyType="individual",collectionType="toy",source=data.source,obtainedFrom=data.obtainedFrom,
      sourceConfidence=data.sourceConfidence,difficulty=data.difficulty,itemID=data.itemID,
    })
  end
  for _,milestone in ipairs(TOY_MILESTONES) do
    LeafVE_AchTest:AddAchievement(milestone.id,{id=milestone.id,name=milestone.name,desc=milestone.desc,category=TOY_CATEGORY,points=milestone.points,icon=TOY_ICON,toyType="milestone",collectionType="toy"})
    if LeafVE_AchTest.RegisterProgressDef then LeafVE_AchTest:RegisterProgressDef(milestone.id,{counter="toys",goal=milestone.goal}) end
  end
  if LeafVE_AchTest.AddTitle then
    for _,titleData in ipairs(TOY_TITLE_DEFS) do
      LeafVE_AchTest:AddTitle({id=titleData.id,name=titleData.name,chatName=titleData.name,achievement=titleData.achievement,prefix=false,category=TOY_CATEGORY,icon=titleData.icon or TOY_ICON,desc=titleData.desc})
    end
  end
end

-- Written directly into the same DB table the Collections module's own
-- spellbook scan uses (LeafVE_AchTest_DB.collections.toys[name].icon)
-- so the achievement toast/row (which read from there) have the real
-- scanned icon the instant the achievement fires here, instead of racing
-- a separate scan in a different file that might not have run yet.
local function CaptureToyIcon(name,icon)
  if not icon or icon=="" or not name or name=="" or not LeafVE_AchTest_DB then return end
  LeafVE_AchTest_DB.collections=LeafVE_AchTest_DB.collections or {}
  LeafVE_AchTest_DB.collections.toys=LeafVE_AchTest_DB.collections.toys or {}
  local saved=LeafVE_AchTest_DB.collections.toys
  if type(saved[name])~="table" then saved[name]={} end
  saved[name].icon=icon
end

local function AddDetectedToy(seen,name,icon)
  local id=TOY_LOOKUP[Slugify(name)]
  if id then
    seen[id]=true
    if icon then CaptureToyIcon(name,icon) end
  end
end

local function ScanSpellbook(seen)
  if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellName then return end
  local tabCount=GetNumSpellTabs() or 0
  for tabIndex=1,tabCount do
    local _,_,offset,spellCount=GetSpellTabInfo(tabIndex)
    offset=offset or 0; spellCount=spellCount or 0
    for spellOffset=1,spellCount do
      local spellIndex=offset+spellOffset
      local spellName=GetSpellName(spellIndex,BOOKTYPE_SPELL or "spell")
      if spellName and spellName~="" then
        local icon=GetSpellTexture and GetSpellTexture(spellIndex,BOOKTYPE_SPELL or "spell")
        AddDetectedToy(seen,spellName,icon)
      end
    end
  end
end

local function CountOwnedToys(playerName)
  local count=0
  for _,achievementId in ipairs(TOY_IDS) do
    if LeafVE_AchTest:HasAchievement(playerName,achievementId) then count=count+1 end
  end
  return count
end

local function AwardToyMilestones(totalOwned,silent)
  for _,milestone in ipairs(TOY_MILESTONES) do
    if totalOwned>=milestone.goal then LeafVE_AchTest:AwardAchievement(milestone.id,silent) end
  end
end

local function RefreshStoredPointValues(playerName)
  if not LeafVE_AchTest_DB or not LeafVE_AchTest_DB.achievements or not playerName then return end
  local earned=LeafVE_AchTest_DB.achievements[playerName]
  if not earned then return end
  for _,achievementId in ipairs(TOY_IDS) do
    if earned[achievementId] and TOY_BY_ACH_ID[achievementId] then earned[achievementId].points=TOY_BY_ACH_ID[achievementId].points end
  end
  for _,milestone in ipairs(TOY_MILESTONES) do if earned[milestone.id] then earned[milestone.id].points=milestone.points end end
end

-- Toys are only awarded once actually learned into the spellbook (using the
-- item teaches the toy "spell" on this server), same as mounts/companions.
local function ScanToys(forceSilent)
  if not LeafVE_AchTest or not LeafVE_AchTest.AwardAchievement or not LeafVE_AchTest.SetCounter then return end
  local me=LeafVE_AchTest.ShortName and LeafVE_AchTest.ShortName(UnitName("player"))
  if not me then return end
  local moduleState=GetToyModuleState(); if not moduleState then return end
  local isSeedScan=not moduleState.seeded
  local silent=forceSilent or isSeedScan
  local seen={}
  ScanSpellbook(seen)
  for achievementId in pairs(seen) do LeafVE_AchTest:AwardAchievement(achievementId,silent) end
  RefreshStoredPointValues(me)
  local totalOwned=CountOwnedToys(me)
  LeafVE_AchTest.SetCounter(me,"toys",totalOwned)
  AwardToyMilestones(totalOwned,silent)
  moduleState.seeded=true
end

RegisterToyAchievements()

local toyFrame=CreateFrame("Frame")
toyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
toyFrame:RegisterEvent("SPELLS_CHANGED")
local toyReady=false
toyFrame:SetScript("OnEvent",function()
  if event=="PLAYER_ENTERING_WORLD" then toyReady=true; ScanToys(true); return end
  if not toyReady then return end
  if event=="SPELLS_CHANGED" then ScanToys(false) end
end)
