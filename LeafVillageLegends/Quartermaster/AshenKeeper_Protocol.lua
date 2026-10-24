-- GENERATED from AshenKeeper\AshenKeeper_Protocol.lua by scripts\Build-BannerQuartermaster.ps1 - edit the AshenKeeper file, not this copy.
if ASHEN_QM_STANDDOWN then return end   -- AshenKeeper is loaded: it runs the Quartermaster client (QM_Host.lua)
-- ABK1 addon-message protocol between players and the Keeper client.
-- Isolated from UI/economy code: other modules only call Protocol.On / Protocol.Send / Protocol.Reply.
--
-- Wire format (never shown in normal chat; it travels as a hidden addon message):
--   TYPE^key=value^key=value ...        (values escaped by AshenKeeper.Esc, max ~250 chars total)
-- Lists inside one value use ';' between entries and ':' between fields of an entry.
--
-- Messages: HELLO STATE_REQ STATE SHOP_REQ SHOP BOARD_REQ BOARD PURCHASE_REQ PURCHASE_OK
--           PURCHASE_FAIL DONATE_REQ DONATE_OK DONATE_FAIL STOCK_UPDATE KEEPER_PING
--           LOG_REQ TLOG WEEKLY (officers: trade log + weekly report)

AshenKeeper.Protocol = AshenKeeper.Protocol or {}
local AK = AshenKeeper
local P = AK.Protocol

P.handlers = {}
P.queue = {}
P.lastFrom = {}
P.SEND_SPACING = 0.35     -- seconds between outgoing addon messages (server throttling)
P.MAX_LEN = 250

function P.Encode(msgType, fields, order)
  local out = msgType
  local used = {}
  local i, k, v
  if order then
    for i = 1, table.getn(order) do
      k = order[i]
      v = fields[k]
      if v ~= nil then
        out = out .. "^" .. k .. "=" .. AK.Esc(v)
        used[k] = true
      end
    end
  end
  for k, v in pairs(fields) do
    if not used[k] then out = out .. "^" .. k .. "=" .. AK.Esc(v) end
  end
  return out
end

function P.Decode(msg)
  if type(msg) ~= "string" or msg == "" then return nil end
  local parts = AK.Split(msg, "^")
  local msgType = parts[1]
  local fields = {}
  local i
  for i = 2, table.getn(parts) do
    local eq = string.find(parts[i], "=", 1, true)
    if eq then
      fields[string.sub(parts[i], 1, eq - 1)] = AK.Unesc(string.sub(parts[i], eq + 1))
    end
  end
  return msgType, fields
end

function P.On(msgType, fn)
  P.handlers[msgType] = fn
end

------------------------------------------------------------------------------
-- Outgoing queue (drained by a tiny OnUpdate that only runs while messages are pending)
------------------------------------------------------------------------------
local function Drain()
  local item = table.remove(P.queue, 1)
  if item then
    local ok, err = pcall(function()
      if type(SendAddonMessage) == "function" then
        if item.channel == "WHISPER" then
          SendAddonMessage(AK.PREFIX, item.msg, "WHISPER", item.target)
        else
          SendAddonMessage(AK.PREFIX, item.msg, "GUILD")
        end
      end
    end)
    if not ok then AK.Debug("send failed: " .. tostring(err)) end
    if P.sentHook then P.sentHook(item) end
  end
  if table.getn(P.queue) == 0 then AK.Cancel("abk-drain") end
end

-- Sends everything still queued right now (used by tests and diagnostics, ignores spacing).
function P.Flush()
  while table.getn(P.queue) > 0 do Drain() end
end

-- target: character name this message is for (nil = broadcast to the guild).
function P.Send(msgType, fields, order, target)
  fields = fields or {}
  if target then fields.to = target end
  local msg = P.Encode(msgType, fields, order)
  if string.len(msg) > P.MAX_LEN then
    -- Never fail silently again: a dropped message is a missing shop/stock update for everybody.
    AK.Print("WARNING: message too long, not sent: " .. msgType .. " (" .. string.len(msg) .. " chars)")
    return false
  end
  local channel = "GUILD"
  if AK.db and AK.db.config.transport == "WHISPER" and target then channel = "WHISPER" end
  table.insert(P.queue, { msg = msg, channel = channel, target = target, type = msgType })
  AK.Every("abk-drain", P.SEND_SPACING, Drain)
  return true
end

-- Keeper -> player reply convenience.
function P.Reply(player, msgType, fields, order)
  return P.Send(msgType, fields, order, player)
end

-- Players -> Keeper request convenience. Returns false when no Keeper is known.
function P.ToKeeper(msgType, fields, order)
  local kn = AK.KeeperName()
  if not kn then return false end
  return P.Send(msgType, fields, order, kn)
end

-- Per-sender, per-type spam guard. Returns true if the message may be processed.
function P.Allow(sender, msgType, cooldown)
  local key = tostring(sender) .. ":" .. tostring(msgType)
  local now = AK.Clock()
  local last = P.lastFrom[key]
  if last and (now - last) < cooldown then return false end
  P.lastFrom[key] = now
  return true
end

------------------------------------------------------------------------------
-- Incoming
------------------------------------------------------------------------------
function P.Dispatch(sender, msg)
  local msgType, fields = P.Decode(msg)
  if not msgType then return end
  local to = fields.to
  if to and AK.Norm(to) ~= AK.Norm(AK.MyName()) then return end
  local fn = P.handlers[msgType]
  if fn then
    local ok, err = pcall(fn, sender, fields, msgType)
    if not ok then AK.NoteError("handler " .. msgType .. " error: " .. tostring(err)) end
  end
end

function P.OnAddon(prefix, msg, channel, sender)
  if prefix ~= AK.PREFIX then return end
  if AK.Norm(sender) == AK.Norm(AK.MyName()) and not P.allowSelf then return end
  P.Dispatch(sender, msg)
end

function P.Init()
  if type(RegisterAddonMessagePrefix) == "function" then pcall(RegisterAddonMessagePrefix, AK.PREFIX) end
end

------------------------------------------------------------------------------
-- Shared list encoders (Keeper encodes, player decodes)
------------------------------------------------------------------------------
-- Splits "a;b;c" entries into chunks that fit a message and returns an array of strings.
function P.ChunkList(entries, maxChars)
  local chunks = {}
  local cur = ""
  local i
  for i = 1, table.getn(entries) do
    local e = entries[i]
    if cur ~= "" and string.len(cur) + string.len(e) + 1 > maxChars then
      table.insert(chunks, cur)
      cur = ""
    end
    if cur == "" then cur = e else cur = cur .. ";" .. e end
  end
  if cur ~= "" then table.insert(chunks, cur) end
  return chunks
end

function P.SplitList(s)
  if type(s) ~= "string" or s == "" then return {} end
  return AK.Split(s, ";")
end
