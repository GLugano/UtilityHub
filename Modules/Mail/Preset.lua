local ADDON_NAME, addonTable = ...;
local moduleName = 'Preset';
---@class Preset : AceModule
local Module = UtilityHub.Addon:NewModule(moduleName);

local classicItems = addonTable.classicItems; ---@type ClassicItems
local tbcItems = addonTable.tbcItems; ---@type TBCItems
--- @param itemLink string
--- @param itemList PresetItemsDBItem[]
--- @return boolean
local function CheckItemLinkInList(itemLink, itemList)
  local itemID = UtilityHub.Libs.Utils:GetItemIDFromLink(itemLink);

  for _, loopItem in ipairs(itemList) do
    if (itemID == loopItem.itemID) then
      return true;
    end
  end

  return false;
end

Module.defaultPresetColor = { r = 1, g = 1, b = 1, a = 1 };
---@type table<string, ItemGroupOption>
Module.ItemGroupOptions = {
  ["GreenEquipment"] = {
    label = "Green Equipment",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, itemQuality, _, _, itemType, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        -- Check if the item is Green (Quality 2) and is an Equipment type
        return itemQuality == 2 and (itemType == "Armor" or itemType == "Weapon");
      else
        return (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon) and
            itemQuality == Enum.ItemQuality.Good;
      end
    end
  },
  ["BlueEquipment"] = {
    label = "Blue Equipment",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, itemQuality, _, _, itemType, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        -- Check if the item is Blue (Quality 3) and is an Equipment type
        return itemQuality == 3 and (itemType == "Armor" or itemType == "Weapon");
      else
        return (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon) and
            itemQuality == Enum.ItemQuality.Rare;
      end
    end
  },
  ["EssenceElemental"] = {
    label = "Essence/Elemental",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.elemental);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 10;
      end
    end
  },
  ["Stone"] = {
    label = "Stone",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.stone);
      else
        return classID == Enum.ItemClass.Tradegoods
            and subclassID == 7
            and CheckItemLinkInList(itemLink, classicItems.stone);
      end
    end
  },
  ["Gem"] = {
    label = "Gem",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(
        itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.gem);
      else
        return classID == Enum.ItemClass.Gem;
      end
    end
  },
  ["Enchant"] = {
    label = "Enchant",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.enchant);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 12;
      end
    end
  },
  ["Cloth"] = {
    label = "Cloth",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.cloth);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 5;
      end
    end
  },
  ["Herb"] = {
    label = "Herb",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.herb);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 9;
      end
    end
  },
  ["Consumables"] = {
    label = "Consumables (except mana/health potions)",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        -- Consumable
        if (classID == 0) then
          if (string.find(itemName, "Potion") ~= nil and
                (string.find(itemName, "Mana") ~= nil or string.find(itemName, "Healing") ~= nil)) then
            return false;
          end


          if (itemName == "Supercharged Chronoboon Displacer") then
            return false;
          end

          return true;
          -- Trade Goods
        elseif (classID == 7) then
          if (string.find(itemName, "Wizard Oil") == nil and string.find(itemName, "Mana Oil") == nil) then
            return false;
          end

          return true;
        end
      else
        if (classID == Enum.ItemClass.Consumable and not (Module.ItemGroupOptions.PotionsMana.CheckItemBelongsToGroup(itemLink)) and not (Module.ItemGroupOptions.PotionsHealth.CheckItemBelongsToGroup(itemLink))) then
          return true;
        end
      end

      return false;
    end
  },
  ["Ore"] = {
    label = "Ore",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.ore);
      else
        return classID == Enum.ItemClass.Tradegoods
            and subclassID == 7
            and (
              CheckItemLinkInList(itemLink, classicItems.ore)
              or CheckItemLinkInList(itemLink, tbcItems.ore)
            );
      end
    end
  },
  ["Bar"] = {
    label = "Bar",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 7) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.bar);
      else
        return classID == Enum.ItemClass.Tradegoods
            and subclassID == 7
            and (
              CheckItemLinkInList(itemLink, classicItems.bar)
              or CheckItemLinkInList(itemLink, tbcItems.bar)
            );
      end
    end
  },
  ["Lockbox"] = {
    label = "Lockbox",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 15) then
          return false;
        end

        return CheckItemLinkInList(itemLink, classicItems.lockbox);
      else
        if (classID == Enum.ItemClass.Miscellaneous and subclassID == 0) then
          return string.find(itemName, " Junkbox") or string.find(itemName, " Lockbox");
        end
      end

      return false;
    end
  },
  ["Recipe"] = {
    label = "Recipe",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, _ = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        if (classID ~= 9) then
          return false;
        end

        return true;
      else
        if (classID == Enum.ItemClass.Recipe) then
          return true;
        end
      end

      return false;
    end
  },
  ["ZgCurrency"] = {
    label = "ZG Currency",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (not UtilityHub.Constants.IsClassic and not (classID == Enum.ItemClass.Questitem and subclassID == 0)) then
        return false
      end

      return CheckItemLinkInList(itemLink, classicItems.zulGurubCurrency);
    end
  },
  ["PotionsMana"] = {
    label = "Potions: Mana",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return classID == 0 and CheckItemLinkInList(itemLink, classicItems.manaPotion);
      else
        if (classID == Enum.ItemClass.Consumable and subclassID == 1 and string.find(itemName, "Mana Potion")) then
          return true;
        end
      end

      return false;
    end
  },
  ["PotionsHealth"] = {
    label = "Potions: Health",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return classID == 0 and CheckItemLinkInList(itemLink, classicItems.healthPotion);
      else
        if (classID == Enum.ItemClass.Consumable and subclassID == 1 and string.find(itemName, "Healing Potion")) then
          return true;
        end
      end

      return false;
    end
  },
  ["Scrolls"] = {
    label = "Scrolls",
    CheckItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return classID == 0 and CheckItemLinkInList(itemLink, classicItems.scroll);
      else
        if (classID == Enum.ItemClass.Consumable and subclassID == 4) then
          return true;
        end
      end

      return false;
    end
  },
  ["Bombs"] = {
    label = "Bombs",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.explosives);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 2;
      end
    end
  },
  ["Leather"] = {
    label = "Leather",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.leather);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 6;
      end
    end
  },
  ["RawFood"] = {
    label = "Raw food",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UtilityHub.Constants.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.rawFood);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 8;
      end
    end
  },
  ["AldorScryer"] = {
    label = "Aldor/Scryer",
    IsEnabledInThisExpansion = function()
      return UtilityHub.Constants.IsTBCorLater;
    end,
    CheckItemBelongsToGroup = function(itemLink)
      return CheckItemLinkInList(itemLink, classicItems.aldorScryer);
    end
  },
  ["EngiMats"] = {
    label = "Enginnering Materials",
    CheckItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (classID == Enum.ItemClass.Tradegoods and subclassID == 1) then
        return true;
      end

      return false;
    end
  },
};

---@param text string
---@param onHideFn fun()|nil
function Module:ShowFormErrorPopup(text, onHideFn)
  local popupName = ADDON_NAME .. "NewPresetError";
  StaticPopupDialogs[popupName] = {
    text = text,
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnHide = function()
      if (onHideFn) then
        onHideFn();
      end
    end
  }

  StaticPopup_Show(popupName);
end

---@param data any
---@param dataID number|nil
---@return boolean
function Module:SavePreset(data)
  local dataID = data.id;

  if (not data.name or #data.name < 1) then
    Module:ShowFormErrorPopup("Field Name is required");

    return false;
  end

  if (not data.to or #data.to < 1) then
    Module:ShowFormErrorPopup("Field To is required", function()
      if (not data) then
        Module.NewPresetFrame.ToInput:SetFocus();
      end
    end);

    return false;
  end

  local atLeastOneCheck = false;

  for _, value in pairs(data.itemGroups) do
    if (value) then
      atLeastOneCheck = true;
    end
  end

  if (UtilityHub.Libs.Utils:TableLength(data.custom) == 0 and (not atLeastOneCheck)) then
    Module:ShowFormErrorPopup("At least one item group needs to be checked or one item added to the inclusions");
    return false;
  end

  -- Save
  if (dataID) then
    for key, value in pairs(UtilityHub.Database.global.presets) do
      if (value.id == dataID) then
        UtilityHub.Database.global.presets[key] = data;
      end
    end
  else
    data.id = Module:GetNextID();
    tinsert(UtilityHub.Database.global.presets, data);
  end

  return true;
end

function Module:GetNextID()
  local maxID = 0;

  for key, value in pairs(UtilityHub.Database.global.presets) do
    if (value.id and value.id > maxID) then
      maxID = value.id;
    end
  end

  return maxID + 1;
end;

---@return MailPreset
function Module:GetNewEmptyPreset()
  ---@type MailPreset
  local preset = {
    id = nil,
    name = "",
    to = "",
    color = Module.defaultPresetColor,
    itemGroups = {},
    custom = {},
    exclusion = {},
  };

  for itemGroupName, itemGroup in UtilityHub.Libs.Utils:OrderedPairs(Module.ItemGroupOptions) do
    tinsert(preset.itemGroups, { checked = false, name = itemGroup.label, key = itemGroupName });
  end

  return preset;
end

-- Execution
function Module:GetLoadPresetGeneratorFunction()
  return function(owner, rootDescription)
    rootDescription:CreateTitle(UtilityHub.Libs.Utils:TableLength(UtilityHub.Database.global.presets) == 0 and
      "No presets available" or
      "Presets available");

    for key, value in pairs(UtilityHub.Database.global.presets) do
      local presetButton = rootDescription:CreateButton(value.name, function(data)
        Module:ExecutePreset(value);
      end);
      presetButton:AddInitializer(function(button, description, menu)
        local color = value.color or Module.defaultPresetColor;
        button.fontString:SetTextColor(color.r, color.g, color.b);
      end);
    end
  end
end

function Module:GetManagePresetGeneratorFunction()
  return function(owner, rootDescription)
    rootDescription:CreateTitle(UtilityHub.Libs.Utils:TableLength(UtilityHub.Database.global.presets) == 0 and
      "No presets available" or
      "Presets available");

    for i, value in pairs(UtilityHub.Database.global.presets) do
      local button = rootDescription:CreateButton(value.name);

      button:CreateButton("Edit", function()
        Module:OpenNewPresetFrame(value, i);
      end);

      button:CreateButton("Remove", function()
        local newPresets = {};

        for j, value in pairs(UtilityHub.Database.global.presets) do
          if (i ~= j) then
            tinsert(newPresets, value);
          end
        end

        UtilityHub.Database.global.presets = newPresets;
      end);
    end
  end
end

function Module:ExecutePreset(preset)
  UtilityHub.Helpers.Mail:OpenSendMailTab(function()
    UtilityHub.Helpers.Mail:ClearAllMailSlots();

    UtilityHub.Helpers.Mail:SetRecipient(preset.to);
    SendMailSubjectEditBox:SetText("UH - Generated by preset [" .. preset.name .. "]");
    local itemGroupFunctions = {};

    for key, value in pairs((preset.itemGroups or {})) do
      if (value) then
        tinsert(itemGroupFunctions, Module.ItemGroupOptions[key].CheckItemBelongsToGroup);
      end
    end

    for bag = 0, 4 do -- Loops through bags 0 (backpack) to 4 (bags)
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
        local itemLink = C_Container.GetContainerItemLink(bag, slot);

        if (itemLink) then
          local isSoulbound = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot));
          local isConjured = UtilityHub.Libs.Utils:IsItemConjured(itemLink);

          if (not isSoulbound and not isConjured and Module:ItemShouldBeAdded(itemLink, itemGroupFunctions, preset.custom, preset.exclusion)) then
            UtilityHub.Helpers.Mail:AddItemToNextEmptyMailSlot(bag, slot);
          end
        end
      end
    end

    ClearCursor();
  end);
end

function Module:ItemLinkIsMemberOfGroup(itemLink, itemGroupFunctions)
  for key, fn in pairs(itemGroupFunctions) do
    if (fn(itemLink)) then
      return true;
    end
  end

  return false;
end

function Module:ItemShouldBeAdded(itemLink, itemGroupFunctions, customItems, excludedItems)
  return not Module:ItemIsMemberOfList(itemLink, excludedItems) and
      (Module:ItemLinkIsMemberOfGroup(itemLink, itemGroupFunctions) or Module:ItemIsMemberOfList(itemLink, customItems));
end

function Module:ItemIsMemberOfList(itemLink, list)
  if (not list or #list == 0) then
    return false;
  end

  for key, customItemLink in pairs(list) do
    if (itemLink == customItemLink) then
      return true;
    end
  end

  return false;
end
