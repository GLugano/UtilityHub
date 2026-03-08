local VALID_SLOT_VALUES = {
  "INVTYPE_CHEST",
  "INVTYPE_ROBE",
  "INVTYPE_FEET",
  "INVTYPE_WRIST",
  "INVTYPE_HAND",
  "INVTYPE_CLOAK",
  "INVTYPE_WEAPON",
  "INVTYPE_SHIELD",
  "INVTYPE_2HWEAPON",
  "INVTYPE_WEAPONMAINHAND",
  "INVTYPE_WEAPONOFFHAND",
};

---@param equipSlot any
---@return boolean
local function IsEquipSlotValid(equipSlot)
  for _, value in ipairs(VALID_SLOT_VALUES) do
    if (value == equipSlot) then
      return true;
    end
  end

  return false;
end

---@param isCraftFrameOpen? fun(): boolean
---@return number|nil
local function GetCurrentProfessionID(isCraftFrameOpen)
  if (not isCraftFrameOpen) then
    isCraftFrameOpen = function()
      return not CraftFrame or not CraftFrame:IsShown();
    end;
  end

  if (not isCraftFrameOpen()) then
    return nil;
  end

  local professionName = GetCraftName();

  -- Map profession names to spell IDs
  local professionIDs = {
    [GetSpellInfo(7411)] = 7411,   -- Enchanting
    [GetSpellInfo(2259)] = 2259,   -- Alchemy
    [GetSpellInfo(2018)] = 2018,   -- Blacksmithing
    [GetSpellInfo(4036)] = 4036,   -- Engineering
    [GetSpellInfo(2108)] = 2108,   -- Leatherworking
    [GetSpellInfo(3908)] = 3908,   -- Tailoring
    [GetSpellInfo(25229)] = 25229, -- Jewelcrafting (TBC)
  }

  return professionIDs[professionName];
end

---@return string|nil
local function GetTradeTargetItem7Slot()
  local itemLink = GetTradeTargetItemLink(7);
  UtilityHub.Helpers.Debug:ChatMessage(string.format("GetTradeTargetItemLink(7) = %s", itemLink or "nil"));

  if (not itemLink) then
    return nil;
  end

  local equipSlot = select(9, C_Item.GetItemInfo(itemLink));

  if (not equipSlot or equipSlot == "") then
    return nil;
  end

  return equipSlot;
end

---@return string[]
local function GetMenuSlotOptions()
  local options = {};

  for index, slot in ipairs({ GetCraftSlots() }) do -- Dropdown table can change, so ensure we do not cache this.
    tinsert(options, index, slot);
  end

  return options;
end

---@param index number
---@return string
local function GetSlotOptionNameByIndex(index)
  ---@type string
  local slot;

  if (index == 0) then
    slot = "ALL_INVENTORY_SLOTS";
  else
    local options = GetMenuSlotOptions();
    slot = options[index];
  end

  return slot;
end

---@param index number
local function UpdateCraftFilter(index)
  local slot = GetSlotOptionNameByIndex(index);

  SetCraftFilter(index);
  CraftFrame.Dropdown:SetText(getglobal(slot));
end

---@param attempt number
local function OnEvent(attempt)
  if (not UtilityHub.Database.global.options.automaticEnchantFilter) then
    UtilityHub.Helpers.Debug:ChatMessage("automaticEnchantFilter flag disabled");
    return;
  end

  local slotValue = GetTradeTargetItem7Slot();
  local dfUIModuleActive = UtilityHub.Integration.DragonflightUI:ModuleActive();
  local IsEnchantFrameOpen;

  if (dfUIModuleActive) then
    IsEnchantFrameOpen = function()
      return UtilityHub.Integration.DragonflightUI:IsProfessionFrameOpen();
    end;
  end

  -- Do nothing if craft frame inst open or the opened profession is something else
  if (GetCurrentProfessionID(IsEnchantFrameOpen) ~= 7411) then
    UtilityHub.Helpers.Debug:ChatMessage("No profession frame or wrong profession");
    return;
  end

  -- If there is nothing in the slot that has a slotName
  if (not slotValue) then
    UtilityHub.Helpers.Debug:ChatMessage("No slot value");

    if (attempt == 1) then
      UtilityHub.Helpers.Debug:ChatMessage("Retrying to get item info in 0.5 seconds");
      C_Timer.After(0.5, function() OnEvent(2) end);
      return;
    end

    if (dfUIModuleActive) then
      -- If the current text in the search box a slotName, clear it
      if (UtilityHub.Integration.DragonflightUI:IsCurrentSearchSlotName()) then
        UtilityHub.Integration.DragonflightUI:UpdateSearchBox("");
      end
    else
      UpdateCraftFilter(0);
    end

    return;
  end

  if (not IsEquipSlotValid(slotValue)) then
    UtilityHub.Helpers.Debug:ChatMessage(string.format("%s (%s)", "Invalid equipSlot", slotValue));
    return;
  end

  local options = GetMenuSlotOptions();
  local craftSlot = UtilityHub.Constants.SlotValueToCraftSlotMap[slotValue];
  local index;

  for i, value in ipairs(options) do
    if (value == craftSlot) then
      index = i;
      break;
    end
  end

  UtilityHub.Helpers.Debug:ChatMessage(string.format("craftSlot: %s / index: %s", craftSlot, index));

  if (dfUIModuleActive) then
    -- TODO: waiting karl add the filter this addon, slacker
    -- local slot = GetSlotOptionNameByIndex(index);
    -- local slotName = getglobal(slot);

    -- UtilityHub.Integration.DragonflightUI:UpdateSearchBox(slotName);
  else
    UpdateCraftFilter(index);
  end
end

local function RegisterEvent()
  EventRegistry:RegisterFrameEventAndCallback(
    "TRADE_TARGET_ITEM_CHANGED",
    function()
      OnEvent(1);
    end
  );
end

RegisterEvent();
