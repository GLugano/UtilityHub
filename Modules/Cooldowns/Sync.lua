---@class SyncDataTable
---@field version string
---@field character Character

local SYNC_PREFIX = "UHCDSync";
local CHANNEL_PREFIX = "uhsync";
local FAKE_SYNC_FLAG = "_isFakeSync";

local currentChannel = nil;
local knownPeers = {};

---@type Cooldowns
local CooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");

---@return boolean
local function IsSyncEnabled()
  local opts = UtilityHub.Database.global.options;
  return opts.cooldowns and opts.cooldownSync;
end

---@param character Character
---@return string
local function GenerateExportTable(character)
  return C_EncodingUtil.SerializeJSON({
    version = UtilityHub.Constants.AddonVersion,
    character = character,
  });
end

---@return boolean
local function IsDebugMode()
  return UtilityHub.Database and UtilityHub.Database.global and UtilityHub.Database.global.debugMode;
end

--- Format a cooldown category for debug logging
---@param categoryName string
---@param cooldowns CurrentCooldown[]
---@return string
local function DebugFormatCooldownCategory(categoryName, cooldowns)
  if (not cooldowns or #cooldowns == 0) then
    return "    " .. categoryName .. ": (empty)";
  end

  local lines = { "    " .. categoryName .. ":" };
  local now = GetTime();

  for _, cd in ipairs(cooldowns) do
    local status;
    local remaining = 0;

    if (cd.start == 0 or cd.maxCooldown == 0) then
      status = "READY";
    else
      local endTime = cd.start + cd.maxCooldown;
      remaining = endTime - now;

      if (remaining > 0) then
        status = string.format("CD (%.0fs left)", remaining);
      else
        status = "READY (expired)";
      end
    end

    lines[#lines + 1] = string.format(
      "      %s: start=%.2f max=%d end=%.2f [%s]",
      cd.name,
      cd.start,
      cd.maxCooldown,
      cd.start + cd.maxCooldown,
      status
    );
  end

  return table.concat(lines, "\n");
end

--- Get all known peers
---@return string[]
local function GetChannelMembers()
  local members = {};

  for name in pairs(knownPeers) do
    tinsert(members, name);
  end

  return members;
end

--- Send a single character's data to all channel members via WHISPER
---@param charData Character
local function SendCharacterData(charData)
  local json = GenerateExportTable(charData);

  if (not json) then
    return;
  end

  local members = GetChannelMembers();

  for _, member in ipairs(members) do
    UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", member, "BULK");
  end
end

--- Send current player's data to all channel members
local function BroadcastSyncData()
  if (not currentChannel) then
    return;
  end

  local charData = UtilityHub.DatabaseFunctions.GetCurrentCharacterData();

  if (not charData) then
    return;
  end

  -- Log Point 4: Envio de Dados
  if (IsDebugMode()) then
    local members = GetChannelMembers();
    local categoryCount = 0;
    local cooldownCount = 0;

    if (charData.cooldownGroup) then
      for _, cooldowns in pairs(charData.cooldownGroup) do
        categoryCount = categoryCount + 1;
        cooldownCount = cooldownCount + #cooldowns;
      end
    end

    UtilityHub.Helpers.DebugLog:Add(string.format(
      "|cffFFFF00[UH-SYNC]|r |cff00BFFFSEND|r char=%s to [%s]: %d categories, %d cooldowns", charData.name,
      table.concat(members, ", "), categoryCount, cooldownCount));
  end

  SendCharacterData(charData);
end

local function LeaveSyncChannel()
  if (currentChannel) then
    LeaveChannelByName(currentChannel);
    currentChannel = nil;
    wipe(knownPeers);
  end
end

---@param channelName string
local function JoinSyncChannel(channelName)
  if (not channelName or channelName == "") then
    return;
  end

  local fullName = CHANNEL_PREFIX .. channelName;

  if (currentChannel and currentChannel ~= fullName) then
    LeaveSyncChannel();
  end

  if (currentChannel == fullName) then
    return;
  end

  -- Join, then leave and rejoin to force CHAT_MSG_CHANNEL_JOIN on other clients
  JoinChannelByName(fullName, nil, nil, false);
  currentChannel = fullName;

  C_Timer.After(1, function()
    LeaveChannelByName(fullName);

    C_Timer.After(1, function()
      JoinChannelByName(fullName, nil, nil, false);

      C_Timer.After(0.5, function()
        local id = GetChannelName(fullName);

        if (id and id > 0) then
          -- Move channel to the end of the list
          local channels = { GetChannelList() };
          local numChannels = #channels / 3; -- Each channel has 3 entries: id, name, disabled

          -- Swap the sync channel to the last position
          for i = id, numChannels - 1 do
            C_ChatInfo.SwapChatChannelsByChannelIndex(i, i + 1);
          end

          C_Timer.After(1.5, function()
            BroadcastSyncData();
          end);
        else
          currentChannel = nil;
        end
      end);
    end);
  end);
end

local function ClearFakeCharactersFromDB()
  local removed = 0;

  for i = #UtilityHub.Database.global.characters, 1, -1 do
    if (UtilityHub.Database.global.characters[i][FAKE_SYNC_FLAG]) then
      tremove(UtilityHub.Database.global.characters, i);
      removed = removed + 1;
    end
  end

  return removed;
end

--- When receiving character data via WHISPER, merge into local DB
---@param prefix string
---@param data string
---@param distribution string
---@param sender string
local function OnSyncDataReceived(prefix, data, distribution, sender)
  sender = Ambiguate(sender, "none");
  local myName = UnitName("player");

  if (sender == myName) then
    return;
  end

  ---@type SyncDataTable
  local syncData = C_EncodingUtil.DeserializeJSON(data);

  if (not syncData or not syncData.character) then
    return;
  end

  -- Log Point 1: Recepção de Mensagem
  if (IsDebugMode() and syncData.character.name and syncData.character.cooldownGroup) then
    local categoryCount = 0;

    for _ in pairs(syncData.character.cooldownGroup) do
      categoryCount = categoryCount + 1;
    end

    UtilityHub.Helpers.DebugLog:Add(string.format(
      "|cffFFFF00[UH-SYNC]|r |cff00FF00RECV|r from %s: char=%s, categories=%d", sender, syncData.character.name,
      categoryCount));
  end

  -- Handle clear command
  if (syncData.character.action == "clearFakeSync") then
    local removed = ClearFakeCharactersFromDB();
    CooldownsModule:UpdateCooldownsFrameList();
    return;
  end

  if (not syncData.character.name) then
    return;
  end

  -- Track sender as a known peer and reply if first contact
  local isNewPeer = (currentChannel and not knownPeers[sender]);

  if (currentChannel) then
    knownPeers[sender] = true;
  end

  ---@type Character|nil
  local characterFound = nil;
  local characterIndex = nil;

  for index, character in ipairs(UtilityHub.Database.global.characters) do
    if (character.name == syncData.character.name) then
      characterFound = character;
      characterIndex = index;
      break;
    end
  end

  syncData.character.importedCharacter = true;
  syncData.character.importTimestamp = GetServerTime();

  if (characterFound == nil) then
    tinsert(UtilityHub.Database.global.characters, syncData.character);
  else
    UtilityHub.Database.global.characters[characterIndex] = syncData.character;
  end

  UtilityHub.Events:TriggerEvent("CHARACTERS_IMPORT_COMPLETED");

  -- If this is a new peer, reply with all our local characters
  if (isNewPeer) then
    if (IsDebugMode()) then
      local charCount = #UtilityHub.Database.global.characters;
      UtilityHub.Helpers.DebugLog:Add(string.format(
        "|cffFFFF00[UH-SYNC]|r |cffFF6B6BNEW PEER|r %s joined, sending %d characters", sender, charCount));
    end

    for _, character in ipairs(UtilityHub.Database.global.characters) do
      -- Send only non-imported characters
      if (character.importedCharacter ~= true) then
        local json = GenerateExportTable(character);

        if (json) then
          UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", sender, "BULK");
        end
      end
    end
  end
end

-- Register AceComm handler for sync data
UtilityHub.Addon:RegisterComm(SYNC_PREFIX, OnSyncDataReceived);

-- Broadcast to channel members when local character data updates
UtilityHub.Events:RegisterCallback("CHARACTER_UPDATED", function()
  if (currentChannel) then
    BroadcastSyncData();
  end
end);

-- Detect when someone joins the sync channel and send them our data
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_CHANNEL_JOIN",
  function(_, _, sender, _, _, _, _, _, _, channelBaseName)
    if (not currentChannel) then
      return;
    end

    local myName = UnitName("player");
    sender = Ambiguate(sender, "none");

    if (sender == myName) then
      return;
    end

    if (not channelBaseName or channelBaseName ~= currentChannel) then
      return;
    end

    knownPeers[sender] = true;

    C_Timer.After(1, function()
      for _, character in ipairs(UtilityHub.Database.global.characters) do
        local json = GenerateExportTable(character);

        if (json) then
          UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, json, "WHISPER", sender, "BULK");
        end
      end
    end);
  end);

-- Remove peers when they leave the sync channel
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_CHANNEL_LEAVE",
function(_, _, sender, _, _, _, _, _, _, channelBaseName)
    if (not currentChannel) then
      return;
    end

    if (not channelBaseName or channelBaseName ~= currentChannel) then
      return;
    end

    sender = Ambiguate(sender, "none");
    knownPeers[sender] = nil;
  end);

---@return boolean "true if joined, false otherwise"
local function TryJoinSyncChannel()
  if (not IsSyncEnabled()) then
    return false;
  end

  local channelName = UtilityHub.Database.global.options.cooldownSyncChannel;

  if (channelName and channelName ~= "") then
    JoinSyncChannel(channelName);
    return true;
  end

  return false;
end

-- Join channel on addon ready if configured
EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  C_Timer.After(4, function()
    TryJoinSyncChannel();
  end);
end);

-- Handle sync option changes
UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "cooldownSync" or name == "cooldownSyncChannel" or name == "cooldowns") then
    if (not TryJoinSyncChannel()) then
      LeaveSyncChannel();
    end
  end
end);

-- Debug: fake sync data
local function GenerateFakeCharacters()
  local now = GetTime();

  return {
    {
      name = "Fakemage",
      race = "Human",
      className = "MAGE",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Tailoring = {
          { name = "Mooncloth", start = 0, maxCooldown = 0 },
        },
        Alchemy = {
          { name = "Arcanite Bar", start = now, maxCooldown = 172800 },
        },
      },
    },
    {
      name = "Fakepriest",
      race = "NightElf",
      className = "PRIEST",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Tailoring = {
          { name = "Mooncloth", start = now - 86400, maxCooldown = 259200 },
        },
        Alchemy = {
          { name = "Arcanite Bar", start = 0,          maxCooldown = 0 },
          { name = "Water to Air", start = now - 3600, maxCooldown = 172800 },
        },
      },
    },
    {
      name = "Fakewarrior",
      race = "Dwarf",
      className = "WARRIOR",
      group = UtilityHub.Enums.CharacterGroup.UNGROUPED,
      [FAKE_SYNC_FLAG] = true,
      cooldownGroup = {
        Leatherworking = {
          { name = "Refined Deeprock Salt", start = 0, maxCooldown = 0 },
        },
      },
    },
  };
end

function CooldownsModule:InjectFakeSyncData()
  if (not IsDebugMode()) then
    UtilityHub.Helpers.Notification:ShowNotification("Debug mode must be enabled to use fakesync");
    return;
  end

  local channelName = UtilityHub.Database.global.options.cooldownSyncChannel;
  JoinSyncChannel((channelName and channelName ~= "") and channelName or "test");

  local fakeChars = GenerateFakeCharacters();
  local injected = 0;

  for _, fakeChar in ipairs(fakeChars) do
    local found = false;

    for index, character in ipairs(UtilityHub.Database.global.characters) do
      if (character.name == fakeChar.name) then
        UtilityHub.Database.global.characters[index] = fakeChar;
        found = true;
        break;
      end
    end

    if (not found) then
      tinsert(UtilityHub.Database.global.characters, fakeChar);
    end

    injected = injected + 1;
  end

  CooldownsModule:UpdateCooldownsFrameList();
  BroadcastSyncData();

  for _, fakeChar in ipairs(fakeChars) do
    SendCharacterData(fakeChar);
  end

  UtilityHub.Helpers.Notification:ShowNotification("Injected " .. injected .. " fake sync characters");
end

function CooldownsModule:ClearFakeSyncData()
  if (not IsDebugMode()) then
    UtilityHub.Helpers.Notification:ShowNotification("Debug mode must be enabled to use clearfakesync");
    return;
  end

  -- Send clear command to peers before cleaning locally
  local clearPayload = C_EncodingUtil.SerializeJSON({ action = "clearFakeSync" });

  if (clearPayload) then
    local members = GetChannelMembers();

    for _, member in ipairs(members) do
      UtilityHub.Addon:SendCommMessage(SYNC_PREFIX, clearPayload, "WHISPER", member, "BULK");
    end
  end

  local removed = ClearFakeCharactersFromDB();
  CooldownsModule:UpdateCooldownsFrameList();
  LeaveSyncChannel();
  UtilityHub.Helpers.Notification:ShowNotification("Removed " .. removed .. " fake sync characters");
end
