---@class CooldownNotification
---@field cooldownInternalID number
---@field cooldownName string
---@field notified boolean
---@field character string
---@field className string

---@param profession Profession
local function KnowsProfession(profession)
  for _, spellID, value in ipairs(profession.spellIDs) do
    if (C_SpellBook.IsSpellKnown(spellID)) then
      return true;
    end
  end

  --- Fallback to skill lines
  for i = 1, GetNumSkillLines() do
    local name = GetSkillLineInfo(i);

    if (name == profession.name) then
      return true;
    end
  end

  return false;
end

---@param professionID number
---@return table<number, ProfessionCooldownData>
local function GetProfessionTable(professionID)
  local professionData = UtilityHub.DatabaseFunctions.GetCurrentCharacterData().professionsData;

  if (not professionData[professionID]) then
    professionData[professionID] = {};
  end

  return professionData[professionID];
end

---@param professionID number
local function RemoveProfessionTable(professionID)
  local professionData = UtilityHub.DatabaseFunctions.GetCurrentCharacterData().professionsData;

  if (professionData[professionID]) then
    professionData[professionID] = nil;
  end
end

---@param professionTable table<number, ProfessionCooldownData>
---@return ProfessionCooldownData
---@return boolean isNew
local function GetCooldownTable(professionTable, cooldownID)
  for index, cooldown in ipairs(professionTable) do
    if (cooldown.internalID == cooldownID) then
      return cooldown, false;
    end
  end

  ---@type ProfessionCooldownData
  local newCooldownTable = {};

  tinsert(professionTable, newCooldownTable);

  return newCooldownTable, true;
end

---@param spellID number
---@return BasicCooldown|GroupedCooldown|nil groupName
---@return number|nil professionID
local function GetCooldownBySpellID(spellID)
  for _, data in pairs(UtilityHub.Constants.Cooldowns) do
    for _, cdOrGroup in pairs(data.cooldowns) do
      if (cdOrGroup.spellList and #cdOrGroup.spellList > 0) then
        for _, cd in ipairs(cdOrGroup.spellList) do
          if (cd.spellID == spellID) then
            return cdOrGroup, data.id;
          end
        end
      elseif (cdOrGroup.spellID == spellID) then
        return cdOrGroup, data.id;
      end
    end
  end

  return nil, nil;
end

---@param internalID number
---@return BasicCooldown|GroupedCooldown|nil groupName
---@return number|nil professionID
local function GetCooldownByInternalID(internalID)
  for _, profession in pairs(UtilityHub.Constants.Cooldowns) do
    for _, cdOrGroup in pairs(profession.cooldowns) do
      if (cdOrGroup.internalID == internalID) then
        return cdOrGroup, profession.id;
      end
    end
  end

  return nil, nil;
end
--- It will only update the cooldowns of the current selected profession
local function UpdateCooldownsFromTradeSkill()
  for i = 1, GetNumTradeSkills() do
    local skillName, skillType = GetTradeSkillInfo(i);

    -- Skip headers/subheaders, they have no recipe link
    if (skillType ~= "header" and skillType ~= "subheader") then
      local link = GetTradeSkillRecipeLink(i);

      if (link) then
        local spellID = tonumber(link:match("|H%w+:(%d+)"));

        if (spellID) then
          local cooldown, professionID = GetCooldownBySpellID(spellID);

          if (cooldown ~= nil) then
            local currentCD = GetTradeSkillCooldown(i) or 0;
            local endCD = 0;
            local professionTable = GetProfessionTable(professionID);
            local cooldownTable, isCooldownTableNew = GetCooldownTable(professionTable, cooldown.internalID);

            if (isCooldownTableNew) then
              cooldownTable.source = "TRADE_SKILL_FRAME";
              cooldownTable.name = cooldown.name;
              cooldownTable.internalID = cooldown.internalID;
            end

            if (currentCD > 0) then
              endCD = GetServerTime() + currentCD;
            end

            cooldownTable.source = "TRADE_SKILL_FRAME";
            cooldownTable.endTime = endCD;
          end
        end
      end
    end
  end
end

---@param internalID number
---@return CooldownConfig|nil
local function GetCooldownConfig(internalID)
  ---@type CooldownConfig[]
  local baseData = UtilityHub.Database.global.options.cooldownConfigs;

  for _, cooldownConfig in ipairs(baseData) do
    if (cooldownConfig.internalID == internalID) then
      return cooldownConfig;
    end
  end

  return nil;
end

--------------------------------------------------------------------------------------
--- Functions for Other Sources
--------------------------------------------------------------------------------------
---@param cooldown BasicCooldown|GroupedCooldown
---@return number|nil
local function GetSpellIDFromCooldown(cooldown)
  if (cooldown.spellList and #cooldown.spellList > 0) then
    for _, spell in pairs(cooldown.spellList) do
      if (C_SpellBook.IsSpellKnown(spell.spellID)) then
        return spell.spellID;
      end
    end
  else
    if (C_SpellBook.IsSpellKnown(cooldown.spellID)) then
      return cooldown.spellID;
    end
  end

  return nil;
end

local function GetEndTimeFromStartAndDuration(start, duration)
  -- Offset between client uptime clock and server unix time
  local clientToServer = GetServerTime() - GetTime();

  local startTimeServer = start + clientToServer;
  local endTime = startTimeServer + duration;

  return endTime;
end

local function UpdateCooldownsFromOtherSources()
  ---@param cooldownOrGroup BasicCooldown|GroupedCooldown
  ---@return boolean exist
  local function UpdateProfessionCooldown(cooldownOrGroup)
    local startTime = 0;
    local duration = 0;

    do -- Find start/duration based on spellID, itemID or both
      if (cooldownOrGroup.itemID and C_Item.GetItemCount(cooldownOrGroup.itemID, true) > 0) then
        startTime, duration = C_Container.GetItemCooldown(cooldown.itemID);
      else
        ---@type number|nil
        local spellID = GetSpellIDFromCooldown(cooldownOrGroup);

        if (spellID) then
          local spi = C_Spell.GetSpellCooldown(spellID);
          startTime = spi.startTime;
          duration = spi.duration;
        else
          -- Only return as not existent IF there is no itemID in the cooldown, as its not needed to "learn it", the item can be in the player bag, bank or in the mail
          if (cooldownOrGroup.itemID == nil) then
            return false;
          else -- If itemID exists, pretent if the item is off cd
            startTime = 0;
            duration = 0;
          end
        end
      end
    end

    local _, professionID = GetCooldownByInternalID(cooldownOrGroup.internalID);
    local professionTable = GetProfessionTable(professionID);
    local cooldownTable, isCooldownTableNew = GetCooldownTable(professionTable, cooldownOrGroup.internalID);

    if (isCooldownTableNew) then
      cooldownTable.source = "SPELL_API";
      cooldownTable.name = cooldownOrGroup.name;
      cooldownTable.internalID = cooldownOrGroup.internalID;
    end

    -- Can ignore source check as the CD is 0 now
    if (duration == 0) then
      cooldownTable.source = "SPELL_API";
      cooldownTable.endTime = 0;
      cooldownTable.startTimeSpellAPI = nil;
      return true;
    end

    -- If the source is the trade skill frame, dont touch it
    if (cooldownTable.source == "TRADE_SKILL_FRAME") then
      return true;
    end

    -- Here the CD will always be different than 0
    local endTime = GetEndTimeFromStartAndDuration(startTime, duration);

    -- If the endTime of the newly calculated value and the saved value difference is less than 1 second, consider it the same and dont touch it
    if (cooldownTable.endTime ~= nil and (endTime - cooldownTable.endTime) <= 1) then
      return true;
    end

    cooldownTable.source = "SPELL_API";
    cooldownTable.endTime = endTime;
    cooldownTable.startTimeSpellAPI = startTime;

    return true;
  end

  for _, professionData in pairs(UtilityHub.Constants.Cooldowns) do
    local groupsToRemove = {};

    if (KnowsProfession(professionData)) then
      for _, cooldownOrGroup in ipairs(professionData.cooldowns) do
        local exists = UpdateProfessionCooldown(cooldownOrGroup);

        if (not exists) then
          tinsert(groupsToRemove, cooldownOrGroup.internalID);
        end
      end

      if (#groupsToRemove > 0) then
        local professionTable = GetProfessionTable(professionData.id);

        for _, cooldownOrGroupInternalID in ipairs(groupsToRemove) do
          table.remove(professionTable, cooldownOrGroupInternalID);
        end

        if (#professionTable == 0) then
          RemoveProfessionTable(professionData.id);
        end
      end
    else
      RemoveProfessionTable(professionData.id);
    end
  end
end

local function SendNotifications()
  local sessionData = UtilityHub.DatabaseFunctions.GetSessionData();
  ---@type CooldownNotification[]|nil
  local sessionCooldowns = sessionData.cooldowns;

  if (not sessionCooldowns) then
    return;
  end

  for _, cooldownNotification in ipairs(sessionCooldowns) do
    if (not cooldownNotification.notified) then
      local color = UtilityHub.Helpers.Color:GetRGBFromClassName(cooldownNotification.className);
      local character = color:WrapTextInColorCode(cooldownNotification.character);

      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Cooldown - %s - %s is ready!", character, cooldownNotification.cooldownName)
      );
      cooldownNotification.notified = true;
    end
  end
end

local function ProcessNotifications()
  local changed = false;
  local sessionData = UtilityHub.DatabaseFunctions.GetSessionData();
  ---@type Character[]
  local characters = UtilityHub.Database.global.characters;

  if (not sessionData.cooldowns) then
    sessionData.cooldowns = {};
  end

  if (sessionData.lastCooldownReadyCount == nil) then
    sessionData.lastCooldownReadyCount = 0;
  end

  ---@type CooldownNotification[]
  local sessionCooldowns = sessionData.cooldowns;
  local readyCooldownCount = 0;

  for _, character in ipairs(characters) do
    for _, cooldownList in pairs(character.professionsData) do
      for _, cooldown in ipairs(cooldownList) do
        local config = GetCooldownConfig(cooldown.internalID);
        local isReady = cooldown.endTime < GetServerTime();
        local isHidden = not config.showNotification;

        if (not isHidden and isReady) then
          local currentNotification = nil;
          readyCooldownCount = readyCooldownCount + 1;

          for _, cooldownNotification in ipairs(sessionCooldowns) do
            if (cooldownNotification.cooldownInternalID == cooldown.internalID and cooldownNotification.character == character.name) then
              currentNotification = cooldownNotification;
              break;
            end
          end

          -- Only creates a new notification if it inst exist (regardless if notified is true or false)
          if (currentNotification == nil) then
            tinsert(sessionCooldowns, {
              notified = false,
              cooldownName = cooldown.name,
              cooldownInternalID = cooldown.internalID,
              character = character.name,
              className = character.className
            });
            changed = true;
          end
        else
          for i, cooldownNotification in ipairs(sessionCooldowns) do
            if (cooldownNotification.cooldownInternalID == cooldown.internalID and cooldownNotification.character == character.name) then
              tremove(sessionCooldowns, i);
              break;
            end
          end
        end
      end
    end
  end

  local countChanged = sessionData.lastCooldownReadyCount ~= readyCooldownCount;
  sessionData.lastCooldownReadyCount = readyCooldownCount;

  UtilityHub.Events:TriggerEvent(
    "COUNT_READY_COOLDOWNS_CHANGED",
    readyCooldownCount,
    countChanged
  );

  if (changed) then
    SendNotifications();
  end
end

local function UpdateCooldowns()
  if (not UtilityHub.Flags.addonReady) then
    return;
  end

  -- If there is a tradeSkill loaded in the frame so we can access the functions, but if there is a filter and its empty, we cant access the hidden recipes
  if (TradeSkillFrame) then
    UpdateCooldownsFromTradeSkill();
  end

  UpdateCooldownsFromOtherSources();
  ProcessNotifications();

  UtilityHub.Events:TriggerEvent("COOLDOWNS_UPDATED");
end

EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_LIST_UPDATE", UpdateCooldowns);
EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_UPDATE", UpdateCooldowns);
UtilityHub.Events:RegisterCallback("CHARACTER_UPDATE_NEEDED", UpdateCooldowns);
UtilityHub.Events:RegisterCallback("CHARACTERS_IMPORT_COMPLETED", UpdateCooldowns);
