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

---@return number|nil
local function GetCurrentProfessionID()
  if (not CraftFrame or not CraftFrame:IsShown()) then
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

local function RegisterEvent()
  EventRegistry:RegisterFrameEventAndCallback(
    "TRADE_TARGET_ITEM_CHANGED",
    function()
      if (not UtilityHub.Database.global.options.automaticEnchantFilter) then
        return;
      end

      local slotValue = GetTradeTargetItem7Slot();
      local dfUIModuleActive = UtilityHub.Integration.DragonflightUI:ModuleActive();
      local IsEnchantFrameOpen = function()
        return CraftFrame:IsShown();
      end;

      if (dfUIModuleActive) then
        IsEnchantFrameOpen = function()
          return UtilityHub.Integration.DragonflightUI:IsEnchantFrameOpen();
        end;
      end

      -- Do nothing if craft frame inst open or the opened profession is something else
      if (GetCurrentProfessionID() ~= 7411) then
        return;
      end

      -- If there is nothing in the slot that has a slotName
      if (not slotValue) then
        -- If the enchant frame is not open, nothing should be done
        if (not IsEnchantFrameOpen()) then
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

      if (not IsEquipSlotValid(slotValue) or not IsEnchantFrameOpen()) then
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

      if (dfUIModuleActive) then
        -- TODO: waiting karl add the filter this addon, slacker
        -- local slot = GetSlotOptionNameByIndex(index);
        -- local slotName = getglobal(slot);

        -- UtilityHub.Integration.DragonflightUI:UpdateSearchBox(slotName);
      else
        UpdateCraftFilter(index);
      end
    end
  );
end

RegisterEvent();
