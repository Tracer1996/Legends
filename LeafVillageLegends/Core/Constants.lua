_G = _G or (getfenv and getfenv(0)) or {}

LATEST_VERSION = "19.3.2"
LEAFVE_STYLE = _G.LeafVE_Styles or {}
LEAFVE_UI_MODERN = _G.LeafVE_UIModernization or {}

SEP = "\31"
SECONDS_PER_DAY = 86400
SECONDS_PER_HOUR = 3600
OUTDATED_VERSION_POPUP_COOLDOWN = 24 * SECONDS_PER_HOUR
GROUP_MIN_TIME = 300
GROUP_COOLDOWN = 900
GROUP_POINT_INTERVAL = 3600
GUILD_ROSTER_CACHE_DURATION = 30
GUILD_ROSTER_MIN_REBUILD_GAP = 15
-- A guildmate is only treated as "confirmed departed" (and their Ashen
-- Ember/banner data purged) after being absent from this many consecutive
-- COMPLETE roster scans (see UpdateGuildRosterCache's SetGuildRosterShowOffline
-- toggle) AND at least this much real time has passed since they were first
-- noticed missing -- both conditions, not either, so a single dropped scan or
-- a normal multi-day absence can never trigger a purge on its own.
ROSTER_DEPARTURE_MIN_MISS_STREAK = 5
ROSTER_DEPARTURE_MIN_ELAPSED = 3 * SECONDS_PER_DAY
SHOUTOUT_MAX_PER_DAY = 2
WORK_ORDER_LOGIN_ALERT_COOLDOWN = 24 * SECONDS_PER_HOUR
LBOARD_RESYNC_COOLDOWN = 30
LBOARD_RESPOND_COOLDOWN = 30
MYSTATS_RESPOND_COOLDOWN = 5
MAX_FUTURE_EPOCH_OFFSET = 7 * SECONDS_PER_DAY
SHOUT_SYNC_RESPOND_COOLDOWN = 30
-- v19.3.0 sync limits (see the PERFORMANCE section in Core.lua)
ACH_SYNC_RESPOND_COOLDOWN = 120      -- own achievements re-sent on request at most this often
SHOUT_BROADCAST_MIN_GAP = 240        -- full shoutout table sent by one client at most this often
SHOUT_DIGEST_INTERVAL = 900          -- shoutout digest (one short message) sent this often
TALENT_FULL_BROADCAST_MIN_GAP = 60   -- full (template-carrying) talent payload at most this often
SYNC_STALE_CACHE_SECONDS = 90 * SECONDS_PER_DAY
OTHER_PLAYER_HISTORY_KEEP_SECONDS = 60 * SECONDS_PER_DAY
DEFAULT_ACHIEVEMENT_POINTS = 10
FULL_WIPE_GUILD_MARKER = "LVLFW"
FULL_WIPE_GUILD_MARKER_PATTERN = "%[" .. FULL_WIPE_GUILD_MARKER .. ":(%d+)%]"
FULL_WIPE_GUILD_MARKER_STRIP_PATTERN = "%s*%[" .. FULL_WIPE_GUILD_MARKER .. ":%d+%]%s*"

GEAR_BROADCAST_THROTTLE = 10
GEAR_CAPTURE_CACHE_WINDOW = 5
GEAR_REQUEST_THROTTLE = 8
GEAR_EVENT_DEBOUNCE = 0.2
GUILD_BANK_REFRESH_DEBOUNCE = 0.2

-- The Ashen Banner v19.3.2: lifetime Ashen Embers and banner reputation from the
-- Nov 15 2026 backup, used once to undo the stray guild-wide wipe (version 9999999999).
-- Keys are lowercase character names. Generated from the VM backups; do not edit by hand.

LeafVE_EmberRestore = {
  ["bluntskix"] = {L = 3700, G = 110753.5, S = 1610},  -- Bluntskix 116063.5
  ["pontolicious"] = {L = 4140, G = 94031.5, S = 360},  -- Pontolicious 98531.5
  ["shambert"] = {L = 2760, G = 93494.5, S = 1280},  -- Shambert 97534.5
  ["triel"] = {L = 2680, G = 80587, S = 1840},  -- Triel 85107
  ["maevin"] = {L = 3380, G = 79696, S = 410},  -- Maevin 83486
  ["jimbo"] = {L = 2380, G = 69402, S = 340},  -- Jimbo 72122
  ["barnne"] = {L = 1900, G = 54975, S = 510},  -- Barnne 57385
  ["zoobi"] = {L = 2080, G = 46925.5, S = 500},  -- Zoobi 49505.5
  ["nocktus"] = {L = 1340, G = 47294.5, S = 0},  -- Nocktus 48634.5
  ["methl"] = {L = 1560, G = 46009, S = 990},  -- Methl 48559
  ["juniperblue"] = {L = 2920, G = 39678, S = 10},  -- Juniperblue 42608
  ["squeaky"] = {L = 2660, G = 39516, S = 120},  -- Squeaky 42296
  ["pawsome"] = {L = 1880, G = 35852.5, S = 200},  -- Pawsome 37932.5
  ["xanthoria"] = {L = 1160, G = 35870, S = 0},  -- Xanthoria 37030
  ["chronnox"] = {L = 1540, G = 34524.5, S = 300},  -- Chronnox 36364.5
  ["sousha"] = {L = 2600, G = 32948, S = 10},  -- Sousha 35558
  ["huntsy"] = {L = 3520, G = 31320.5, S = 30},  -- Huntsy 34870.5
  ["dellz"] = {L = 840, G = 33812, S = 0},  -- Dellz 34652
  ["whisperx"] = {L = 1140, G = 32331, S = 210},  -- Whisperx 33681
  ["whoville"] = {L = 2420, G = 29114, S = 1440},  -- Whoville 32974
  ["aedhrian"] = {L = 740, G = 25720, S = 40},  -- Aedhrian 26500
  ["plowmyfield"] = {L = 1340, G = 22939.5, S = 810},  -- Plowmyfield 25089.5
  ["healsy"] = {L = 3280, G = 18427, S = 360},  -- Healsy 22067
  ["amishcow"] = {L = 2240, G = 17701, S = 320},  -- Amishcow 20261
  ["radishes"] = {L = 1480, G = 15486, S = 0},  -- Radishes 16966
  ["amishmootwo"] = {L = 1580, G = 14767, S = 210},  -- Amishmootwo 16557
  ["rootbears"] = {L = 2580, G = 13392, S = 300},  -- Rootbears 16272
  ["ratfink"] = {L = 3580, G = 11712, S = 320},  -- Ratfink 15612
  ["loosi"] = {L = 1300, G = 14255, S = 0},  -- Loosi 15555
  ["teeter"] = {L = 3000, G = 10704.5, S = 0},  -- Teeter 13704.5
  ["slambert"] = {L = 1640, G = 11691, S = 20},  -- Slambert 13351
  ["glambert"] = {L = 1300, G = 11589, S = 20},  -- Glambert 12909
  ["beastwood"] = {L = 1800, G = 9508.5, S = 0},  -- Beastwood 11308.5
  ["whispr"] = {L = 1140, G = 9335, S = 500},  -- Whispr 10975
  ["wyrmclaw"] = {L = 140, G = 10065, S = 360},  -- Wyrmclaw 10565
  ["rodeo"] = {L = 720, G = 9269, S = 350},  -- Rodeo 10339
  ["icarex"] = {L = 1700, G = 8594, S = 0},  -- Icarex 10294
  ["unomat"] = {L = 3520, G = 5417.5, S = 1110},  -- Unomat 10047.5
  ["lasso"] = {L = 660, G = 8876, S = 300},  -- Lasso 9836
  ["paperskull"] = {L = 640, G = 9195, S = 0},  -- Paperskull 9835
  ["jhawnbo"] = {L = 1000, G = 8545, S = 0},  -- Jhawnbo 9545
  ["macaronia"] = {L = 1880, G = 7314.5, S = 100},  -- Macaronia 9294.5
  ["royalseq"] = {L = 640, G = 7934, S = 100},  -- Royalseq 8674
  ["lucylockjaw"] = {L = 700, G = 7243, S = 610},  -- Lucylockjaw 8553
  ["nomsy"] = {L = 340, G = 8040, S = 0},  -- Nomsy 8380
  ["hammerslap"] = {L = 640, G = 7392, S = 0},  -- Hammerslap 8032
  ["zoombi"] = {L = 1300, G = 6600, S = 100},  -- Zoombi 8000
  ["demonussy"] = {L = 100, G = 7240, S = 170},  -- Demonussy 7510
  ["juniperbrown"] = {L = 1560, G = 5834.5, S = 100},  -- Juniperbrown 7494.5
  ["brenna"] = {L = 920, G = 5620, S = 300},  -- Brenna 6840
  ["thunderbust"] = {L = 1120, G = 5183.5, S = 230},  -- Thunderbust 6533.5
  ["livewild"] = {L = 740, G = 5435, S = 0},  -- Livewild 6175
  ["suegondeez"] = {L = 1060, G = 4887, S = 10},  -- Suegondeez 5957
  ["yourbull"] = {L = 1000, G = 4840, S = 100},  -- Yourbull 5940
  ["scythen"] = {L = 1440, G = 3860, S = 310},  -- Scythen 5610
  ["chulk"] = {L = 1060, G = 4418.5, S = 100},  -- Chulk 5578.5
  ["zagrim"] = {L = 1120, G = 4442, S = 0},  -- Zagrim 5562
  ["nawak"] = {L = 760, G = 4769.5, S = 0},  -- Nawak 5529.5
  ["thegnomancer"] = {L = 940, G = 4510, S = 0},  -- Thegnomancer 5450
  ["warzy"] = {L = 2320, G = 2180, S = 320},  -- Warzy 4820
  ["gaba"] = {L = 120, G = 4599.5, S = 0},  -- Gaba 4719.5
  ["cruznin"] = {L = 420, G = 4160.5, S = 0},  -- Cruznin 4580.5
  ["violettide"] = {L = 920, G = 2795, S = 760},  -- Violettide 4475
  ["goreblaster"] = {L = 240, G = 3627, S = 410},  -- Goreblaster 4277
  ["flammaholy"] = {L = 720, G = 2912, S = 300},  -- Flammaholy 3932
  ["socks"] = {L = 740, G = 2980, S = 30},  -- Socks 3750
  ["cheerios"] = {L = 1840, G = 1900, S = 0},  -- Cheerios 3740
  ["moodicare"] = {L = 1100, G = 2599, S = 0},  -- Moodicare 3699
  ["aggroterra"] = {L = 660, G = 2597, S = 0},  -- Aggroterra 3257
  ["pawniard"] = {L = 240, G = 2852, S = 0},  -- Pawniard 3092
  ["ignayshus"] = {L = 80, G = 3005, S = 0},  -- Ignayshus 3085
  ["luluianna"] = {L = 100, G = 2930, S = 0},  -- Luluianna 3030
  ["belavierr"] = {L = 440, G = 2185, S = 400},  -- Belavierr 3025
  ["obergine"] = {L = 600, G = 2317, S = 100},  -- Obergine 3017
  ["pokemyhole"] = {L = 520, G = 2495, S = 0},  -- Pokemyhole 3015
  ["mahatma"] = {L = 520, G = 2492, S = 0},  -- Mahatma 3012
  ["beau"] = {L = 1840, G = 855, S = 210},  -- Beau 2905
  ["primusx"] = {L = 720, G = 2129.5, S = 0},  -- Primusx 2849.5
  ["relationship"] = {L = 760, G = 1883, S = 0},  -- Relationship 2643
  ["kuridan"] = {L = 2060, G = 540, S = 0},  -- Kuridan 2600
  ["tenletters"] = {L = 80, G = 2400, S = 10},  -- Tenletters 2490
  ["eindal"] = {L = 2480, G = 0, S = 10},  -- Eindal 2490
  ["alegria"] = {L = 500, G = 1920, S = 0},  -- Alegria 2420
  ["gwuikui"] = {L = 1440, G = 865, S = 100},  -- Gwuikui 2405
  ["fayru"] = {L = 1220, G = 1025, S = 0},  -- Fayru 2245
  ["vasiah"] = {L = 520, G = 1705, S = 0},  -- Vasiah 2225
  ["belier"] = {L = 1480, G = 229, S = 500},  -- Belier 2209
  ["tahoma"] = {L = 160, G = 1959, S = 80},  -- Tahoma 2199
  ["armour"] = {L = 1300, G = 860, S = 0},  -- Armour 2160
  ["shadowpirate"] = {L = 1020, G = 1069, S = 0},  -- Shadowpirate 2089
  ["jerryos"] = {L = 1580, G = 495, S = 0},  -- Jerryos 2075
  ["pont"] = {L = 1100, G = 850, S = 100},  -- Pont 2050
  ["zhavok"] = {L = 920, G = 807, S = 300},  -- Zhavok 2027
  ["willith"] = {L = 260, G = 1707, S = 0},  -- Willith 1967
  ["tenhou"] = {L = 700, G = 1148.5, S = 110},  -- Tenhou 1958.5
  ["skanx"] = {L = 980, G = 868.5, S = 100},  -- Skanx 1948.5
  ["maitraya"] = {L = 280, G = 1590, S = 0},  -- Maitraya 1870
  ["rendvend"] = {L = 800, G = 998, S = 0},  -- Rendvend 1798
  ["wiskeria"] = {L = 400, G = 1380, S = 0},  -- Wiskeria 1780
  ["gandoof"] = {L = 800, G = 810, S = 0},  -- Gandoof 1610
  ["codemagick"] = {L = 300, G = 1300, S = 0},  -- Codemagick 1600
  ["icarax"] = {L = 1260, G = 330, S = 0},  -- Icarax 1590
  ["shloberz"] = {L = 460, G = 1130, S = 0},  -- Shloberz 1590
  ["thresha"] = {L = 160, G = 1417, S = 0},  -- Thresha 1577
  ["krizee"] = {L = 140, G = 1420, S = 0},  -- Krizee 1560
  ["ironmane"] = {L = 1180, G = 345, S = 0},  -- Ironmane 1525
  ["baros"] = {L = 1080, G = 439.5, S = 0},  -- Baros 1519.5
  ["ucantphaseme"] = {L = 620, G = 865, S = 0},  -- Ucantphaseme 1485
  ["hoofsy"] = {L = 1060, G = 219, S = 200},  -- Hoofsy 1479
  ["spudgunxlxtr"] = {L = 260, G = 1202, S = 0},  -- Spudgunxlxtr 1462
  ["nivekohgr"] = {L = 1360, G = 80, S = 0},  -- Nivekohgr 1440
  ["vicuska"] = {L = 1440, G = 0, S = 0},  -- Vicuska 1440
  ["unopal"] = {L = 1400, G = 0, S = 0},  -- Unopal 1400
  ["sensuella"] = {L = 1400, G = 0, S = 0},  -- Sensuella 1400
  ["horryn"] = {L = 720, G = 670, S = 0},  -- Horryn 1390
  ["roland"] = {L = 1340, G = 0, S = 0},  -- Roland 1340
  ["amishterror"] = {L = 820, G = 415, S = 0},  -- Amishterror 1235
  ["serafim"] = {L = 1040, G = 171.5, S = 0},  -- Serafim 1211.5
  ["numbtongue"] = {L = 460, G = 715.5, S = 0},  -- Numbtongue 1175.5
  ["waaghthedog"] = {L = 540, G = 620, S = 0},  -- Waaghthedog 1160
  ["ashenkeeper"] = {L = 1040, G = 20, S = 100},  -- Ashenkeeper 1160
  ["rhyanne"] = {L = 1140, G = 10, S = 10},  -- Rhyanne 1160
  ["kamehameheal"] = {L = 960, G = 105, S = 10},  -- Kamehameheal 1075
  ["amishcheese"] = {L = 880, G = 180, S = 0},  -- Amishcheese 1060
  ["crazyndn"] = {L = 640, G = 380, S = 0},  -- Crazyndn 1020
  ["shmizuli"] = {L = 560, G = 445.5, S = 0},  -- Shmizuli 1005.5
  ["sankamon"] = {L = 220, G = 762, S = 0},  -- Sankamon 982
  ["boarred"] = {L = 680, G = 300, S = 0},  -- Boarred 980
  ["oakshadran"] = {L = 500, G = 360, S = 100},  -- Oakshadran 960
  ["feyborne"] = {L = 660, G = 175, S = 100},  -- Feyborne 935
  ["dauerschlaf"] = {L = 40, G = 890, S = 0},  -- Dauerschlaf 930
  ["gardon"] = {L = 360, G = 360, S = 200},  -- Gardon 920
  ["ishotmahfoot"] = {L = 740, G = 175.5, S = 0},  -- Ishotmahfoot 915.5
  ["eakers"] = {L = 60, G = 700, S = 130},  -- Eakers 890
  ["cyberwine"] = {L = 240, G = 600, S = 0},  -- Cyberwine 840
  ["huuda"] = {L = 480, G = 305, S = 50},  -- Huuda 835
  ["grragrgr"] = {L = 340, G = 475.5, S = 0},  -- Grragrgr 815.5
  ["nightfaller"] = {L = 160, G = 620, S = 0},  -- Nightfaller 780
  ["cosmodius"] = {L = 780, G = 0, S = 0},  -- Cosmodius 780
  ["skyfaller"] = {L = 140, G = 630, S = 0},  -- Skyfaller 770
  ["ngkuafl"] = {L = 760, G = 6, S = 0},  -- Ngkuafl 766
  ["gimmlee"] = {L = 180, G = 585, S = 0},  -- Gimmlee 765
  ["sunath"] = {L = 180, G = 580.5, S = 0},  -- Sunath 760.5
  ["onlydans"] = {L = 580, G = 165, S = 0},  -- Onlydans 745
  ["cowabunga"] = {L = 240, G = 0, S = 500},  -- Cowabunga 740
  ["shartmaster"] = {L = 660, G = 60, S = 0},  -- Shartmaster 720
  ["afflican"] = {L = 80, G = 640, S = 0},  -- Afflican 720
  ["thongor"] = {L = 620, G = 20, S = 0},  -- Thongor 640
  ["akish"] = {L = 600, G = 25, S = 0},  -- Akish 625
  ["heeler"] = {L = 260, G = 145, S = 200},  -- Heeler 605
  ["emeel"] = {L = 580, G = 0, S = 0},  -- Emeel 580
  ["shogek"] = {L = 540, G = 0, S = 0},  -- Shogek 540
  ["britosupreme"] = {L = 140, G = 355, S = 0},  -- Britosupreme 495
  ["snypen"] = {L = 480, G = 0, S = 0},  -- Snypen 480
  ["ryoka"] = {L = 40, G = 440, S = 0},  -- Ryoka 480
  ["wyrmfang"] = {L = 40, G = 440, S = 0},  -- Wyrmfang 480
  ["graddoc"] = {L = 460, G = 0, S = 0},  -- Graddoc 460
  ["edwinn"] = {L = 160, G = 280, S = 0},  -- Edwinn 440
  ["zimbi"] = {L = 440, G = 0, S = 0},  -- Zimbi 440
  ["dolonar"] = {L = 280, G = 145, S = 0},  -- Dolonar 425
  ["lunia"] = {L = 420, G = 0, S = 0},  -- Lunia 420
  ["grizzwick"] = {L = 420, G = 0, S = 0},  -- Grizzwick 420
  ["mylk"] = {L = 420, G = 0, S = 0},  -- Mylk 420
  ["ham"] = {L = 0, G = 0, S = 420},  -- Ham 420
  ["nickels"] = {L = 0, G = 0, S = 410},  -- Nickels 410
  ["flammastab"] = {L = 400, G = 0, S = 0},  -- Flammastab 400
  ["shmulk"] = {L = 400, G = 0, S = 0},  -- Shmulk 400
  ["arcannon"] = {L = 220, G = 175, S = 0},  -- Arcannon 395
  ["dreadgirl"] = {L = 0, G = 0, S = 390},  -- Dreadgirl 390
  ["avzi"] = {L = 360, G = 27, S = 0},  -- Avzi 387
  ["bruteson"] = {L = 360, G = 25, S = 0},  -- Bruteson 385
  ["methyl"] = {L = 380, G = 0, S = 0},  -- Methyl 380
  ["entheo"] = {L = 380, G = 0, S = 0},  -- Entheo 380
  ["eiraelis"] = {L = 360, G = 0, S = 0},  -- Eiraelis 360
  ["wolfjaeger"] = {L = 160, G = 195, S = 0},  -- Wolfjaeger 355
  ["paladln"] = {L = 340, G = 0, S = 0},  -- Paladln 340
  ["vaultina"] = {L = 340, G = 0, S = 0},  -- Vaultina 340
  ["canibalecter"] = {L = 320, G = 16, S = 0},  -- Canibalecter 336
  ["cchef"] = {L = 240, G = 90, S = 0},  -- Cchef 330
  ["mortexxa"] = {L = 320, G = 0, S = 0},  -- Mortexxa 320
  ["rueed"] = {L = 0, G = 0, S = 310},  -- Rueed 310
  ["gobloknocare"] = {L = 0, G = 0, S = 300},  -- Gobloknocare 300
  ["corndogs"] = {L = 60, G = 220, S = 0},  -- Corndogs 280
  ["azshuare"] = {L = 280, G = 0, S = 0},  -- Azshuare 280
  ["trapping"] = {L = 40, G = 130, S = 100},  -- Trapping 270
  ["novanius"] = {L = 260, G = 0, S = 0},  -- Novanius 260
  ["rottin"] = {L = 260, G = 0, S = 0},  -- Rottin 260
  ["sacramentum"] = {L = 240, G = 0, S = 0},  -- Sacramentum 240
  ["bladecast"] = {L = 120, G = 20, S = 100},  -- Bladecast 240
  ["spamela"] = {L = 220, G = 0, S = 0},  -- Spamela 220
  ["iznocowlevel"] = {L = 220, G = 0, S = 0},  -- Iznocowlevel 220
  ["weedweed"] = {L = 220, G = 0, S = 0},  -- Weedweed 220
  ["allchallenge"] = {L = 220, G = 0, S = 0},  -- Allchallenge 220
  ["minniu"] = {L = 220, G = 0, S = 0},  -- Minniu 220
  ["nympha"] = {L = 0, G = 0, S = 220},  -- Nympha 220
  ["blacktree"] = {L = 0, G = 0, S = 220},  -- Blacktree 220
  ["laincore"] = {L = 0, G = 0, S = 220},  -- Laincore 220
  ["tuilja"] = {L = 200, G = 0, S = 0},  -- Tuilja 200
  ["yooner"] = {L = 0, G = 0, S = 200},  -- Yooner 200
  ["mokagru"] = {L = 0, G = 0, S = 200},  -- Mokagru 200
  ["miniuiu"] = {L = 140, G = 50, S = 0},  -- Miniuiu 190
  ["eluune"] = {L = 180, G = 0, S = 0},  -- Eluune 180
  ["vice"] = {L = 0, G = 0, S = 180},  -- Vice 180
  ["olgala"] = {L = 180, G = 0, S = 0},  -- Olgala 180
  ["sanlina"] = {L = 180, G = 0, S = 0},  -- Sanlina 180
  ["gloreesa"] = {L = 0, G = 0, S = 180},  -- Gloreesa 180
  ["pyron"] = {L = 160, G = 16.5, S = 0},  -- Pyron 176.5
  ["holywayne"] = {L = 0, G = 0, S = 170},  -- Holywayne 170
  ["sekhaelis"] = {L = 160, G = 0, S = 0},  -- Sekhaelis 160
  ["onaharu"] = {L = 160, G = 0, S = 0},  -- Onaharu 160
  ["drakka"] = {L = 160, G = 0, S = 0},  -- Drakka 160
  ["yvlon"] = {L = 160, G = 0, S = 0},  -- Yvlon 160
  ["freyaelis"] = {L = 160, G = 0, S = 0},  -- Freyaelis 160
  ["muck"] = {L = 0, G = 0, S = 160},  -- Muck 160
  ["hayt"] = {L = 0, G = 0, S = 150},  -- Hayt 150
  ["ponto"] = {L = 140, G = 0, S = 0},  -- Ponto 140
  ["davana"] = {L = 140, G = 0, S = 0},  -- Davana 140
  ["kriptic"] = {L = 140, G = 0, S = 0},  -- Kriptic 140
  ["mallet"] = {L = 0, G = 0, S = 140},  -- Mallet 140
  ["tyrivandril"] = {L = 0, G = 0, S = 130},  -- Tyrivandril 130
  ["sulaelis"] = {L = 120, G = 0, S = 0},  -- Sulaelis 120
  ["homtanks"] = {L = 0, G = 0, S = 120},  -- Homtanks 120
  ["topaz"] = {L = 0, G = 0, S = 120},  -- Topaz 120
  ["crypty"] = {L = 0, G = 0, S = 110},  -- Crypty 110
  ["kittygirl"] = {L = 0, G = 0, S = 110},  -- Kittygirl 110
  ["steve"] = {L = 0, G = 0, S = 110},  -- Steve 110
  ["zanardi"] = {L = 0, G = 0, S = 110},  -- Zanardi 110
  ["fireburns"] = {L = 0, G = 0, S = 110},  -- Fireburns 110
  ["torgrosh"] = {L = 0, G = 0, S = 110},  -- Torgrosh 110
  ["arcadium"] = {L = 100, G = 0, S = 0},  -- Arcadium 100
  ["kruzlwix"] = {L = 60, G = 40, S = 0},  -- Kruzlwix 100
  ["valkaelis"] = {L = 100, G = 0, S = 0},  -- Valkaelis 100
  ["taliaelis"] = {L = 100, G = 0, S = 0},  -- Taliaelis 100
  ["hekaelis"] = {L = 100, G = 0, S = 0},  -- Hekaelis 100
  ["hallstaralie"] = {L = 0, G = 0, S = 100},  -- Hallstaralie 100
  ["voodoov"] = {L = 0, G = 0, S = 100},  -- Voodoov 100
  ["colonblow"] = {L = 0, G = 0, S = 100},  -- Colonblow 100
  ["dorobo"] = {L = 0, G = 0, S = 100},  -- Dorobo 100
  ["swampdonkey"] = {L = 0, G = 0, S = 100},  -- Swampdonkey 100
  ["dualis"] = {L = 0, G = 0, S = 100},  -- Dualis 100
  ["tiamaty"] = {L = 0, G = 0, S = 100},  -- Tiamaty 100
  ["chillbro"] = {L = 0, G = 0, S = 100},  -- Chillbro 100
  ["litni"] = {L = 0, G = 0, S = 100},  -- Litni 100
  ["saich"] = {L = 0, G = 0, S = 100},  -- Saich 100
  ["lanaeus"] = {L = 0, G = 0, S = 100},  -- Lanaeus 100
  ["erineas"] = {L = 0, G = 0, S = 100},  -- Erineas 100
  ["lustrate"] = {L = 0, G = 0, S = 90},  -- Lustrate 90
  ["linxia"] = {L = 0, G = 0, S = 90},  -- Linxia 90
  ["paladamnson"] = {L = 0, G = 0, S = 90},  -- Paladamnson 90
  ["touche"] = {L = 0, G = 0, S = 90},  -- Touche 90
  ["beakers"] = {L = 0, G = 0, S = 90},  -- Beakers 90
  ["tyraelis"] = {L = 80, G = 0, S = 0},  -- Tyraelis 80
  ["poppi"] = {L = 80, G = 0, S = 0},  -- Poppi 80
  ["parantiq"] = {L = 80, G = 0, S = 0},  -- Parantiq 80
  ["gazi"] = {L = 80, G = 0, S = 0},  -- Gazi 80
  ["nyxaelis"] = {L = 80, G = 0, S = 0},  -- Nyxaelis 80
  ["gottamus"] = {L = 80, G = 0, S = 0},  -- Gottamus 80
  ["ascary"] = {L = 0, G = 0, S = 80},  -- Ascary 80
  ["bockry"] = {L = 0, G = 0, S = 70},  -- Bockry 70
  ["doughboy"] = {L = 0, G = 0, S = 70},  -- Doughboy 70
  ["kuromichan"] = {L = 60, G = 0, S = 0},  -- Kuromichan 60
  ["lilleara"] = {L = 20, G = 40, S = 0},  -- Lilleara 60
  ["annimalistic"] = {L = 60, G = 0, S = 0},  -- Annimalistic 60
  ["alariel"] = {L = 0, G = 0, S = 60},  -- Alariel 60
  ["reijsellia"] = {L = 0, G = 0, S = 60},  -- Reijsellia 60
  ["grizna"] = {L = 0, G = 0, S = 60},  -- Grizna 60
  ["whiski"] = {L = 0, G = 0, S = 60},  -- Whiski 60
  ["bearricky"] = {L = 40, G = 15, S = 0},  -- Bearricky 55
  ["twap"] = {L = 0, G = 0, S = 50},  -- Twap 50
  ["staticx"] = {L = 0, G = 0, S = 50},  -- Staticx 50
  ["corli"] = {L = 0, G = 0, S = 50},  -- Corli 50
  ["tektite"] = {L = 0, G = 0, S = 50},  -- Tektite 50
  ["jules"] = {L = 0, G = 0, S = 50},  -- Jules 50
  ["miss"] = {L = 0, G = 0, S = 50},  -- Miss 50
  ["papaspliff"] = {L = 0, G = 0, S = 50},  -- Papaspliff 50
  ["waylock"] = {L = 0, G = 0, S = 50},  -- Waylock 50
  ["slowpaladin"] = {L = 40, G = 0, S = 0},  -- Slowpaladin 40
  ["wilham"] = {L = 40, G = 0, S = 0},  -- Wilham 40
  ["korial"] = {L = 40, G = 0, S = 0},  -- Korial 40
  ["brute"] = {L = 40, G = 0, S = 0},  -- Brute 40
  ["dawitcher"] = {L = 40, G = 0, S = 0},  -- Dawitcher 40
  ["marlexis"] = {L = 40, G = 0, S = 0},  -- Marlexis 40
  ["arawyn"] = {L = 40, G = 0, S = 0},  -- Arawyn 40
  ["ghostrike"] = {L = 0, G = 0, S = 40},  -- Ghostrike 40
  ["mitzi"] = {L = 0, G = 0, S = 40},  -- Mitzi 40
  ["babybel"] = {L = 0, G = 0, S = 40},  -- Babybel 40
  ["dashi"] = {L = 0, G = 0, S = 40},  -- Dashi 40
  ["waylund"] = {L = 0, G = 0, S = 40},  -- Waylund 40
  ["medgirl"] = {L = 0, G = 0, S = 40},  -- Medgirl 40
  ["alathea"] = {L = 0, G = 0, S = 40},  -- Alathea 40
  ["daddymilker"] = {L = 0, G = 0, S = 40},  -- Daddymilker 40
  ["zvarat"] = {L = 0, G = 0, S = 40},  -- Zvarat 40
  ["zegion"] = {L = 0, G = 0, S = 40},  -- Zegion 40
  ["maeve"] = {L = 0, G = 0, S = 30},  -- Maeve 30
  ["alieeza"] = {L = 0, G = 0, S = 30},  -- Alieeza 30
  ["rickard"] = {L = 0, G = 0, S = 30},  -- Rickard 30
  ["poetry"] = {L = 0, G = 0, S = 30},  -- Poetry 30
  ["nahm"] = {L = 0, G = 0, S = 30},  -- Nahm 30
  ["cerene"] = {L = 0, G = 0, S = 30},  -- Cerene 30
  ["dingus"] = {L = 0, G = 0, S = 30},  -- Dingus 30
  ["racduck"] = {L = 0, G = 0, S = 30},  -- Racduck 30
  ["selphira"] = {L = 0, G = 0, S = 30},  -- Selphira 30
  ["yogi"] = {L = 0, G = 0, S = 30},  -- Yogi 30
  ["elri"] = {L = 0, G = 0, S = 30},  -- Elri 30
  ["herself"] = {L = 0, G = 0, S = 30},  -- Herself 30
  ["badmage"] = {L = 0, G = 0, S = 30},  -- Badmage 30
  ["arius"] = {L = 0, G = 0, S = 30},  -- Arius 30
  ["fuego"] = {L = 0, G = 0, S = 30},  -- Fuego 30
  ["kamehameha"] = {L = 0, G = 0, S = 30},  -- Kamehameha 30
  ["pathos"] = {L = 0, G = 0, S = 30},  -- Pathos 30
  ["sahalas"] = {L = 0, G = 0, S = 30},  -- Sahalas 30
  ["threads"] = {L = 0, G = 0, S = 30},  -- Threads 30
  ["dankwizard"] = {L = 0, G = 0, S = 30},  -- Dankwizard 30
  ["dernos"] = {L = 20, G = 0, S = 0},  -- Dernos 20
  ["cowpriest"] = {L = 20, G = 0, S = 0},  -- Cowpriest 20
  ["daraniir"] = {L = 20, G = 0, S = 0},  -- Daraniir 20
  ["aelynn"] = {L = 20, G = 0, S = 0},  -- Aelynn 20
  ["hotpockets"] = {L = 20, G = 0, S = 0},  -- Hotpockets 20
  ["glorya"] = {L = 20, G = 0, S = 0},  -- Glorya 20
  ["fehnryl"] = {L = 0, G = 0, S = 20},  -- Fehnryl 20
  ["moushamas"] = {L = 0, G = 0, S = 20},  -- Moushamas 20
  ["hughheifer"] = {L = 0, G = 0, S = 20},  -- Hughheifer 20
  ["hesha"] = {L = 0, G = 0, S = 20},  -- Hesha 20
  ["boopbeep"] = {L = 0, G = 0, S = 20},  -- Boopbeep 20
  ["swarovski"] = {L = 0, G = 0, S = 20},  -- Swarovski 20
  ["doktorevil"] = {L = 0, G = 0, S = 20},  -- Doktorevil 20
  ["endymeon"] = {L = 0, G = 0, S = 20},  -- Endymeon 20
  ["sabs"] = {L = 0, G = 0, S = 20},  -- Sabs 20
  ["lrdrogue"] = {L = 0, G = 0, S = 20},  -- Lrdrogue 20
  ["thimble"] = {L = 0, G = 0, S = 20},  -- Thimble 20
  ["solarendil"] = {L = 0, G = 0, S = 20},  -- Solarendil 20
  ["kallie"] = {L = 0, G = 0, S = 20},  -- Kallie 20
  ["withered"] = {L = 0, G = 0, S = 20},  -- Withered 20
  ["vorherre"] = {L = 0, G = 0, S = 20},  -- Vorherre 20
  ["kittyangel"] = {L = 0, G = 0, S = 20},  -- Kittyangel 20
  ["zestanova"] = {L = 0, G = 0, S = 20},  -- Zestanova 20
  ["narcissus"] = {L = 0, G = 0, S = 20},  -- Narcissus 20
  ["tattersail"] = {L = 0, G = 0, S = 20},  -- Tattersail 20
  ["ventriliqwst"] = {L = 0, G = 0, S = 20},  -- Ventriliqwst 20
  ["toltec"] = {L = 0, G = 0, S = 20},  -- Toltec 20
  ["furmidable"] = {L = 0, G = 0, S = 20},  -- Furmidable 20
  ["angryorc"] = {L = 0, G = 0, S = 20},  -- Angryorc 20
  ["coldzera"] = {L = 0, G = 0, S = 20},  -- Coldzera 20
  ["lenji"] = {L = 0, G = 0, S = 20},  -- Lenji 20
  ["omegadeth"] = {L = 0, G = 0, S = 20},  -- Omegadeth 20
  ["killafuze"] = {L = 0, G = 0, S = 20},  -- Killafuze 20
  ["spartacus"] = {L = 0, G = 0, S = 20},  -- Spartacus 20
  ["ariah"] = {L = 0, G = 0, S = 20},  -- Ariah 20
  ["yrene"] = {L = 0, G = 0, S = 20},  -- Yrene 20
  ["krunchr"] = {L = 0, G = 0, S = 20},  -- Krunchr 20
  ["prior"] = {L = 0, G = 0, S = 20},  -- Prior 20
  ["oshire"] = {L = 0, G = 0, S = 20},  -- Oshire 20
  ["trokkan"] = {L = 0, G = 0, S = 20},  -- Trokkan 20
  ["anomander"] = {L = 0, G = 0, S = 20},  -- Anomander 20
  ["barcode"] = {L = 0, G = 0, S = 20},  -- Barcode 20
  ["oreoeis"] = {L = 0, G = 0, S = 20},  -- Oreoeis 20
  ["yohannes"] = {L = 0, G = 0, S = 20},  -- Yohannes 20
  ["waynestatic"] = {L = 0, G = 0, S = 20},  -- Waynestatic 20
  ["beefmold"] = {L = 0, G = 0, S = 20},  -- Beefmold 20
  ["starstrike"] = {L = 0, G = 0, S = 20},  -- Starstrike 20
  ["boko"] = {L = 0, G = 0, S = 20},  -- Boko 20
  ["barolt"] = {L = 0, G = 0, S = 20},  -- Barolt 20
  ["surestrike"] = {L = 0, G = 0, S = 20},  -- Surestrike 20
  ["darkevilhin"] = {L = 0, G = 0, S = 20},  -- Darkevilhin 20
  ["oldtimes"] = {L = 0, G = 0, S = 20},  -- Oldtimes 20
  ["knutt"] = {L = 0, G = 0, S = 20},  -- Knutt 20
  ["nickel"] = {L = 0, G = 0, S = 20},  -- Nickel 20
  ["wildstalker"] = {L = 0, G = 0, S = 20},  -- Wildstalker 20
  ["shadowthorne"] = {L = 0, G = 0, S = 20},  -- Shadowthorne 20
  ["retridina"] = {L = 0, G = 0, S = 20},  -- Retridina 20
  ["muffpunch"] = {L = 0, G = 0, S = 20},  -- Muffpunch 20
  ["ketameanie"] = {L = 0, G = 0, S = 20},  -- Ketameanie 20
  ["aganeiya"] = {L = 0, G = 0, S = 20},  -- Aganeiya 20
  ["chimer"] = {L = 0, G = 0, S = 20},  -- Chimer 20
  ["aths"] = {L = 0, G = 0, S = 20},  -- Aths 20
  ["cein"] = {L = 0, G = 0, S = 20},  -- Cein 20
  ["setsuna"] = {L = 0, G = 0, S = 20},  -- Setsuna 20
  ["moonpaw"] = {L = 0, G = 0, S = 20},  -- Moonpaw 20
  ["nonchalant"] = {L = 0, G = 0, S = 20},  -- Nonchalant 20
  ["dalia"] = {L = 0, G = 0, S = 20},  -- Dalia 20
  ["oshikuru"] = {L = 0, G = 0, S = 20},  -- Oshikuru 20
  ["alths"] = {L = 0, G = 0, S = 20},  -- Alths 20
  ["nun"] = {L = 0, G = 0, S = 20},  -- Nun 20
  ["aelin"] = {L = 0, G = 0, S = 10},  -- Aelin 10
  ["kavax"] = {L = 0, G = 0, S = 10},  -- Kavax 10
  ["moonkey"] = {L = 0, G = 0, S = 10},  -- Moonkey 10
  ["ironmade"] = {L = 0, G = 0, S = 10},  -- Ironmade 10
  ["beefhammer"] = {L = 0, G = 0, S = 10},  -- Beefhammer 10
  ["virtue"] = {L = 0, G = 0, S = 10},  -- Virtue 10
  ["fruits"] = {L = 0, G = 0, S = 10},  -- Fruits 10
  ["grannyrags"] = {L = 0, G = 0, S = 10},  -- Grannyrags 10
  ["makrini"] = {L = 0, G = 0, S = 10},  -- Makrini 10
  ["invisicooch"] = {L = 0, G = 0, S = 10},  -- Invisicooch 10
  ["nikynoonoo"] = {L = 0, G = 0, S = 10},  -- Nikynoonoo 10
  ["honksnake"] = {L = 0, G = 0, S = 10},  -- Honksnake 10
  ["furrier"] = {L = 0, G = 0, S = 10},  -- Furrier 10
  ["xfilo"] = {L = 0, G = 0, S = 10},  -- Xfilo 10
  ["praetor"] = {L = 0, G = 0, S = 10},  -- Praetor 10
  ["diablokitsun"] = {L = 0, G = 0, S = 10},  -- Diablokitsun 10
  ["jchunt"] = {L = 0, G = 0, S = 10},  -- Jchunt 10
  ["cinnamoroll"] = {L = 0, G = 0, S = 10},  -- Cinnamoroll 10
  ["eggoyeet"] = {L = 0, G = 0, S = 10},  -- Eggoyeet 10
  ["suppenkasper"] = {L = 0, G = 0, S = 10},  -- Suppenkasper 10
  ["yagger"] = {L = 0, G = 0, S = 10},  -- Yagger 10
  ["varug"] = {L = 0, G = 0, S = 10},  -- Varug 10
  ["hammy"] = {L = 0, G = 0, S = 10},  -- Hammy 10
  ["vermeil"] = {L = 0, G = 0, S = 10},  -- Vermeil 10
  ["context"] = {L = 0, G = 0, S = 10},  -- Context 10
  ["jimo"] = {L = 0, G = 0, S = 10},  -- Jimo 10
  ["zombi"] = {L = 0, G = 0, S = 10},  -- Zombi 10
  ["vorelle"] = {L = 0, G = 0, S = 10},  -- Vorelle 10
  ["starlene"] = {L = 0, G = 0, S = 10},  -- Starlene 10
  ["clem"] = {L = 0, G = 0, S = 10},  -- Clem 10
  ["skyfire"] = {L = 0, G = 0, S = 10},  -- Skyfire 10
  ["wings"] = {L = 0, G = 0, S = 10},  -- Wings 10
  ["port"] = {L = 0, G = 0, S = 10},  -- Port 10
  ["djdillydally"] = {L = 0, G = 0, S = 10},  -- Djdillydally 10
  ["dizzied"] = {L = 0, G = 0, S = 10},  -- Dizzied 10
  ["gjestr"] = {L = 0, G = 0, S = 10},  -- Gjestr 10
  ["lavona"] = {L = 0, G = 0, S = 10},  -- Lavona 10
  ["oddynuff"] = {L = 0, G = 0, S = 10},  -- OddyNuff 10
  ["delicanli"] = {L = 0, G = 0, S = 10},  -- Delicanli 10
  ["odysseuss"] = {L = 0, G = 0, S = 10},  -- Odysseuss 10
  ["ctesias"] = {L = 0, G = 0, S = 10},  -- Ctesias 10
  ["hollie"] = {L = 0, G = 0, S = 10},  -- Hollie 10
  ["parmesan"] = {L = 0, G = 0, S = 10},  -- Parmesan 10
  ["galinda"] = {L = 0, G = 0, S = 10},  -- Galinda 10
  ["ponthoof"] = {L = 0, G = 0, S = 10},  -- Ponthoof 10
  ["sancturion"] = {L = 0, G = 0, S = 10},  -- Sancturion 10
  ["palagius"] = {L = 0, G = 0, S = 10},  -- Palagius 10
  ["harbinger"] = {L = 0, G = 0, S = 10},  -- Harbinger 10
  ["brooke"] = {L = 0, G = 0, S = 10},  -- Brooke 10
  ["flambeau"] = {L = 0, G = 0, S = 10},  -- Flambeau 10
  ["helicon"] = {L = 0, G = 0, S = 10},  -- Helicon 10
  ["creamypie"] = {L = 0, G = 0, S = 10},  -- Creamypie 10
  ["ruderinie"] = {L = 0, G = 0, S = 10},  -- Ruderinie 10
  ["xontropapas"] = {L = 0, G = 0, S = 10},  -- Xontropapas 10
  ["lurtrim"] = {L = 0, G = 0, S = 10},  -- Lurtrim 10
  ["cowadin"] = {L = 0, G = 0, S = 10},  -- Cowadin 10
  ["dementia"] = {L = 0, G = 0, S = 10},  -- Dementia 10
  ["lunaverse"] = {L = 0, G = 0, S = 10},  -- Lunaverse 10
  ["dietbarolt"] = {L = 0, G = 0, S = 10},  -- Dietbarolt 10
  ["carmel"] = {L = 0, G = 0, S = 10},  -- Carmel 10
  ["ilianta"] = {L = 0, G = 0, S = 10},  -- Ilianta 10
  ["cession"] = {L = 0, G = 0, S = 10},  -- Cession 10
  ["mirils"] = {L = 0, G = 0, S = 10},  -- Mirils 10
  ["ness"] = {L = 0, G = 0, S = 10},  -- Ness 10
  ["vesh"] = {L = 0, G = 0, S = 10},  -- Vesh 10
  ["octobear"] = {L = 0, G = 0, S = 10},  -- Octobear 10
  ["bennymax"] = {L = 0, G = 0, S = 10},  -- Bennymax 10
  ["chichikoobi"] = {L = 0, G = 0, S = 10},  -- Chichikoobi 10
  ["bobbygbrown"] = {L = 0, G = 0, S = 10},  -- Bobbygbrown 10
  ["lumielle"] = {L = 0, G = 0, S = 10},  -- Lumielle 10
  ["cassyiskewl"] = {L = 0, G = 0, S = 10},  -- Cassyiskewl 10
  ["mkay"] = {L = 0, G = 0, S = 10},  -- Mkay 10
  ["krom"] = {L = 0, G = 0, S = 10},  -- Krom 10
  ["burnjayalive"] = {L = 0, G = 0, S = 10},  -- Burnjayalive 10
  ["athrandil"] = {L = 0, G = 0, S = 10},  -- Athrandil 10
  ["singsangsong"] = {L = 0, G = 0, S = 10},  -- Singsangsong 10
  ["vargoth"] = {L = 0, G = 0, S = 10},  -- Vargoth 10
  ["secer"] = {L = 0, G = 0, S = 10},  -- Secer 10
  ["capnpunch"] = {L = 0, G = 0, S = 10},  -- Capnpunch 10
  ["majin"] = {L = 0, G = 0, S = 10},  -- Majin 10
  ["geppetto"] = {L = 0, G = 0, S = 10},  -- Geppetto 10
  ["durnik"] = {L = 0, G = 0, S = 10},  -- Durnik 10
  ["castrice"] = {L = 0, G = 0, S = 10},  -- Castrice 10
  ["tunarul"] = {L = 0, G = 0, S = 10},  -- Tunarul 10
  ["nubran"] = {L = 0, G = 0, S = 10},  -- Nubran 10
  ["yeezus"] = {L = 0, G = 0, S = 10},  -- Yeezus 10
  ["danari"] = {L = 0, G = 0, S = 10},  -- Danari 10
  ["gorehound"] = {L = 0, G = 0, S = 10},  -- Gorehound 10
  ["scylla"] = {L = 0, G = 0, S = 10},  -- Scylla 10
  ["lightricky"] = {L = 0, G = 5, S = 0},  -- Lightricky 5
}

LeafVE_RepRestore = {
  ["aedhrian"] = {name = "Aedhrian", amount = 7746, updatedAt = 1794793852},
  ["afflican"] = {name = "Afflican", amount = 25, updatedAt = 1792104968},
  ["aggroterra"] = {name = "Aggroterra", amount = 536, updatedAt = 1792297383},
  ["alegria"] = {name = "Alegria", amount = 613, updatedAt = 1794651759},
  ["amishcow"] = {name = "Amishcow", amount = 3484, updatedAt = 1793849129},
  ["amishmootwo"] = {name = "Amishmootwo", amount = 221, updatedAt = 1793849134},
  ["armour"] = {name = "Armour", amount = 78, updatedAt = 1783821604},
  ["avzi"] = {name = "Avzi", amount = 138, updatedAt = 1793135946},
  ["barnne"] = {name = "Barnne", amount = 3880, updatedAt = 1793328457},
  ["beastwood"] = {name = "Beastwood", amount = 2665, updatedAt = 1793772466},
  ["blacktree"] = {name = "Blacktree", amount = 100, updatedAt = 1791172495},
  ["bluntskix"] = {name = "Bluntskix", amount = 13687, updatedAt = 1793633318},
  ["brenna"] = {name = "Brenna", amount = 316, updatedAt = 1786910428},
  ["britosupreme"] = {name = "Britosupreme", amount = 22, updatedAt = 1794585730},
  ["cheerios"] = {name = "Cheerios", amount = 483, updatedAt = 1793826309},
  ["chronnox"] = {name = "Chronnox", amount = 9898, updatedAt = 1791702140},
  ["chulk"] = {name = "Chulk", amount = 220, updatedAt = 1787538032},
  ["codemagick"] = {name = "Codemagick", amount = 112, updatedAt = 1791517588},
  ["cowabunga"] = {name = "Cowabunga", amount = 60, updatedAt = 1793678428},
  ["cruznin"] = {name = "Cruznin", amount = 1159, updatedAt = 1793255370},
  ["crypty"] = {name = "Crypty", amount = 25, updatedAt = 1793612495},
  ["cyberwine"] = {name = "Cyberwine", amount = 22, updatedAt = 1790740388},
  ["dauerschlaf"] = {name = "Dauerschlaf", amount = 234, updatedAt = 1792946448},
  ["dellz"] = {name = "Dellz", amount = 10, updatedAt = 1793564935},
  ["demonussy"] = {name = "Demonussy", amount = 7940, updatedAt = 1793661748},
  ["emeel"] = {name = "Emeel", amount = 65, updatedAt = 1793746416},
  ["erineas"] = {name = "Erineas", amount = 25, updatedAt = 1792505003},
  ["feyborne"] = {name = "Feyborne", amount = 57, updatedAt = 1792511550},
  ["flammaholy"] = {name = "Flammaholy", amount = 300, updatedAt = 1793825060},
  ["gazi"] = {name = "Gazi", amount = 15, updatedAt = 1793662993},
  ["gimmlee"] = {name = "Gimmlee", amount = 56, updatedAt = 1791664506},
  ["glambert"] = {name = "Glambert", amount = 208, updatedAt = 1786757859},
  ["goreblaster"] = {name = "Goreblaster", amount = 1300, updatedAt = 1793817101},
  ["grragrgr"] = {name = "Grragrgr", amount = 56, updatedAt = 1791010816},
  ["gwuikui"] = {name = "Gwuikui", amount = 715, updatedAt = 1794762189},
  ["hammerslap"] = {name = "Hammerslap", amount = 1796, updatedAt = 1793849240},
  ["healsy"] = {name = "Healsy", amount = 4762, updatedAt = 1793370334},
  ["heeler"] = {name = "Heeler", amount = 22, updatedAt = 1791320469},
  ["horryn"] = {name = "Horryn", amount = 22, updatedAt = 1794377158},
  ["huntsy"] = {name = "Huntsy", amount = 5001, updatedAt = 1793318335},
  ["icarex"] = {name = "Icarex", amount = 424, updatedAt = 1793484057},
  ["ignayshus"] = {name = "Ignayshus", amount = 786, updatedAt = 1793210370},
  ["jerryos"] = {name = "Jerryos", amount = 45, updatedAt = 1792301975},
  ["jimbo"] = {name = "Jimbo", amount = 9697, updatedAt = 1793318603},
  ["juniperblue"] = {name = "Juniperblue", amount = 8729, updatedAt = 1794705722},
  ["juniperbrown"] = {name = "Juniperbrown", amount = 402, updatedAt = 1792355207},
  ["krizee"] = {name = "Krizee", amount = 392, updatedAt = 1793614277},
  ["lasso"] = {name = "Lasso", amount = 538, updatedAt = 1793610021},
  ["lightricky"] = {name = "Lightricky", amount = 1, updatedAt = 1793779457},
  ["lilleara"] = {name = "Lilleara", amount = 15, updatedAt = 1791503488},
  ["livewild"] = {name = "Livewild", amount = 45, updatedAt = 1793842631},
  ["loosi"] = {name = "Loosi", amount = 3975, updatedAt = 1794675874},
  ["lucylockjaw"] = {name = "Lucylockjaw", amount = 1358, updatedAt = 1794711833},
  ["luluianna"] = {name = "Luluianna", amount = 488, updatedAt = 1793772447},
  ["macaronia"] = {name = "Macaronia", amount = 620, updatedAt = 1793675088},
  ["maevin"] = {name = "Maevin", amount = 586, updatedAt = 1792344874},
  ["mahatma"] = {name = "Mahatma", amount = 466, updatedAt = 1792297044},
  ["maitraya"] = {name = "Maitraya", amount = 74, updatedAt = 1791573173},
  ["methl"] = {name = "Methl", amount = 10503, updatedAt = 1794793807},
  ["moodicare"] = {name = "Moodicare", amount = 346, updatedAt = 1794790880},
  ["nickels"] = {name = "Nickels", amount = 75, updatedAt = 1793407827},
  ["nightfaller"] = {name = "Nightfaller", amount = 22, updatedAt = 1793319959},
  ["nocktus"] = {name = "Nocktus", amount = 12514, updatedAt = 1794793901},
  ["nomsy"] = {name = "Nomsy", amount = 2115, updatedAt = 1792296829},
  ["nympha"] = {name = "Nympha", amount = 50, updatedAt = 1792969326},
  ["oakshadran"] = {name = "Oakshadran", amount = 80, updatedAt = 1793599763},
  ["obergine"] = {name = "Obergine", amount = 282, updatedAt = 1785228446},
  ["onlydans"] = {name = "Onlydans", amount = 130, updatedAt = 1789664412},
  ["paperskull"] = {name = "Paperskull", amount = 2524, updatedAt = 1792355120},
  ["parantiq"] = {name = "Parantiq", amount = 20, updatedAt = 1794734601},
  ["pawniard"] = {name = "Pawniard", amount = 515, updatedAt = 1793835644},
  ["pawsome"] = {name = "Pawsome", amount = 8770, updatedAt = 1792286030},
  ["plowmyfield"] = {name = "Plowmyfield", amount = 6050, updatedAt = 1793845096},
  ["pontolicious"] = {name = "Pontolicious", amount = 16249, updatedAt = 1794793797},
  ["primusx"] = {name = "Primusx", amount = 78, updatedAt = 1784224614},
  ["pyron"] = {name = "Pyron", amount = 25, updatedAt = 1793478801},
  ["radishes"] = {name = "Radishes", amount = 542, updatedAt = 1794693687},
  ["ratfink"] = {name = "Ratfink", amount = 6818, updatedAt = 1794770799},
  ["rhyanne"] = {name = "Rhyanne", amount = 22, updatedAt = 1782355252},
  ["rodeo"] = {name = "Rodeo", amount = 312, updatedAt = 1793445721},
  ["rootbears"] = {name = "Rootbears", amount = 1685, updatedAt = 1792285329},
  ["royalseq"] = {name = "Royalseq", amount = 476, updatedAt = 1793849239},
  ["rueed"] = {name = "Rueed", amount = 100, updatedAt = 1793414152},
  ["sankamon"] = {name = "Sankamon", amount = 52, updatedAt = 1791597637},
  ["scythen"] = {name = "Scythen", amount = 1228, updatedAt = 1794772327},
  ["shadowpirate"] = {name = "Shadowpirate", amount = 446, updatedAt = 1794787174},
  ["shambert"] = {name = "Shambert", amount = 13446, updatedAt = 1794762415},
  ["shartmaster"] = {name = "Shartmaster", amount = 180, updatedAt = 1790993013},
  ["shloberz"] = {name = "Shloberz", amount = 230, updatedAt = 1794589260},
  ["shmizuli"] = {name = "Shmizuli", amount = 10, updatedAt = 1792678474},
  ["skyfaller"] = {name = "Skyfaller", amount = 22, updatedAt = 1793319957},
  ["slambert"] = {name = "Slambert", amount = 3047, updatedAt = 1794762007},
  ["sousha"] = {name = "Sousha", amount = 6670, updatedAt = 1794792090},
  ["spudgunxlxtr"] = {name = "Spudgunxlxtr", amount = 52, updatedAt = 1791453515},
  ["squeaky"] = {name = "Squeaky", amount = 8296, updatedAt = 1794790588},
  ["suegondeez"] = {name = "Suegondeez", amount = 208, updatedAt = 1786618861},
  ["sunath"] = {name = "Sunath", amount = 22, updatedAt = 1793780471},
  ["teeter"] = {name = "Teeter", amount = 3375, updatedAt = 1794793124},
  ["tenletters"] = {name = "Tenletters", amount = 615, updatedAt = 1793411796},
  ["thegnomancer"] = {name = "Thegnomancer", amount = 1228, updatedAt = 1791930877},
  ["thresha"] = {name = "Thresha", amount = 126, updatedAt = 1794583545},
  ["triel"] = {name = "Triel", amount = 19491, updatedAt = 1794793627},
  ["ucantphaseme"] = {name = "Ucantphaseme", amount = 100, updatedAt = 1788833122},
  ["unomat"] = {name = "Unomat", amount = 782, updatedAt = 1794777107},
  ["vasiah"] = {name = "Vasiah", amount = 56, updatedAt = 1792240860},
  ["vice"] = {name = "Vice", amount = 30, updatedAt = 1793407839},
  ["violettide"] = {name = "Violettide", amount = 52, updatedAt = 1792085424},
  ["waaghthedog"] = {name = "Waaghthedog", amount = 22, updatedAt = 1790820828},
  ["warzy"] = {name = "Warzy", amount = 770, updatedAt = 1793618405},
  ["whisperx"] = {name = "Whisperx", amount = 8570, updatedAt = 1794793876},
  ["whispr"] = {name = "Whispr", amount = 2854, updatedAt = 1794773677},
  ["whoville"] = {name = "Whoville", amount = 9195, updatedAt = 1793814800},
  ["willith"] = {name = "Willith", amount = 182, updatedAt = 1794486073},
  ["wiskeria"] = {name = "Wiskeria", amount = 458, updatedAt = 1793673416},
  ["wyrmclaw"] = {name = "Wyrmclaw", amount = 873, updatedAt = 1794793794},
  ["xanthoria"] = {name = "Xanthoria", amount = 9383, updatedAt = 1794793860},
  ["yourbull"] = {name = "Yourbull", amount = 272, updatedAt = 1787538018},
  ["zagrim"] = {name = "Zagrim", amount = 611, updatedAt = 1791730666},
  ["zoobi"] = {name = "Zoobi", amount = 1069, updatedAt = 1793565037},
}
