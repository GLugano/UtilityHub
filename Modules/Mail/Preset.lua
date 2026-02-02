local ADDON_NAME, addonTable = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Preset';
---@class Preset
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

local classicItems = addonTable.classicItems; ---@type ClassicItems
local tbcItems = addonTable.tbcItems; ---@type TBCItems
--- @param itemLink string
--- @param itemList PresetItemsDBItem[]
--- @return boolean
local function CheckItemLinkInList(itemLink, itemList)
  local itemID = UH.UTILS:GetItemIDFromLink(itemLink);

  for _, loopItem in ipairs(itemList) do
    if (itemID == loopItem.itemID) then
      return true;
    end
  end

  return false;
end

Module.defaultPresetColor = { r = 1, g = 1, b = 1, a = 1 };
Module.ItemGroupOptions = {
  ["GreenEquipment"] = {
    label = "Green Equipment",
    checkItemBelongsToGroup = function(itemLink)
      local _, _, itemQuality, _, _, itemType, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, itemQuality, _, _, itemType, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.elemental);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 10;
      end
    end
  },
  ["Stone"] = {
    label = "Stone",
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(
        itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
        if (classID == Enum.ItemClass.Consumable and not (Module.ItemGroupOptions.PotionsMana.checkItemBelongsToGroup(itemLink)) and not (Module.ItemGroupOptions.PotionsHealth.checkItemBelongsToGroup(itemLink))) then
          return true;
        end
      end

      return false;
    end
  },
  ["Ore"] = {
    label = "Ore",
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, _ = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (not UH.IsClassic and not (classID == Enum.ItemClass.Questitem and subclassID == 0)) then
        return false
      end

      return CheckItemLinkInList(itemLink, classicItems.zulGurubCurrency);
    end
  },
  ["PotionsMana"] = {
    label = "Potions: Mana",
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
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
    checkItemBelongsToGroup = function(itemLink)
      local itemName, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
        return classID == 0 and CheckItemLinkInList(itemLink, classicItems.bar);
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
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.explosives);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 2;
      end
    end
  },
  ["Leather"] = {
    label = "Leather",
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.leather);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 6;
      end
    end
  },
  ["RawFood"] = {
    label = "Raw food",
    checkItemBelongsToGroup = function(itemLink)
      local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = C_Item.GetItemInfo(itemLink);

      if (UH.IsClassic) then
        return CheckItemLinkInList(itemLink, classicItems.rawFood);
      else
        return classID == Enum.ItemClass.Tradegoods and subclassID == 8;
      end
    end
  },
};
local temp = {
  items = {},
  itemsExclusion = {}
};
local id = nil;

function Module:CreateNewPresetFrame()
  local frameHeight = 350;
  Module.NewPresetFrame = CreateFrame("Frame", UH.Helpers:ApplyPrefix("NewPresetFrame"), UIParent, "DialogBoxFrame");
  Module.NewPresetFrame:SetPoint("CENTER", UIParent, "CENTER");
  Module.NewPresetFrame:SetClampedToScreen(true);
  Module.NewPresetFrame:SetSize(350, frameHeight);
  Module.NewPresetFrame:Hide();
  Module.NewPresetFrame:SetPropagateKeyboardInput(false);
  Module.NewPresetFrame:EnableKeyboard(true);
  Module.NewPresetFrame:SetScript("OnKeyDown", function(self, key)
    if (key == "ESCAPE") then
      Module:CloseNewPresetFrame();
    elseif (self and type(self.PropagateKeyDown) == "function") then
      self:PropagateKeyDown(key);
    end
  end);

  UH.UTILS:AddMovableToFrame(Module.NewPresetFrame);

  -- Hide original button
  select(1, Module.NewPresetFrame:GetChildren()):Hide();

  -- Text
  Module.NewPresetFrame.TitleRef = Module.NewPresetFrame:CreateFontString(nil, "OVERLAY");
  Module.NewPresetFrame.TitleRef:SetFontObject("GameFontHighlight");
  Module.NewPresetFrame.TitleRef:SetSize(350, 20);
  Module.NewPresetFrame.TitleRef:SetPoint("CENTER", Module.NewPresetFrame, "TOP", 0, -30);

  local font, _, flags = Module.NewPresetFrame.TitleRef:GetFont();

  if (font) then
    Module.NewPresetFrame.TitleRef:SetFont(font, 16, flags);
  end

  local y = -50;

  -- Name
  local input, label = Module:CreateFormField("NewPresetInputName", "Name", Module.NewPresetFrame, y);
  Module.NewPresetFrame.NameInput = input;
  Module.NewPresetFrame.NameLabel = label;

  -- To
  y = y - 30;
  input, label = Module:CreateFormField("NewPresetInputTo", "To", Module.NewPresetFrame, y);
  Module.NewPresetFrame.ToInput = input;
  Module.NewPresetFrame.ToLabel = label;

  -- Scroll Frame parent
  y = y - 30;
  Module.NewPresetFrame.ScrollFrameParent = CreateFrame("Frame", nil, Module.NewPresetFrame, "BackdropTemplate");
  Module.NewPresetFrame.ScrollFrameParent:SetPoint("TOPLEFT", Module.NewPresetFrame, "TOPLEFT", 12, y);
  Module.NewPresetFrame.ScrollFrameParent:SetPoint("BOTTOMRIGHT", Module.NewPresetFrame, "BOTTOMRIGHT", -12, 12 + 50);
  Module.NewPresetFrame.ScrollFrameParent:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = {
      left = 5,
      right = 5,
      top = 5,
      bottom = 5
    }
  });

  -- Creating tabs
  local tabCustom, tabCustomButton = Module:CreateNewPresetTab("Custom", 1, "Custom", frameHeight, y);
  local tabItemGroups, tabItemGroupsButton = Module:CreateNewPresetTab("ItemGroups", 2, "Item Groups", frameHeight, y,
    tabCustomButton);
  local tabExclusions, tabExclusionsButton = Module:CreateNewPresetTab("Exclusions", 3, "Exclusions", frameHeight, y,
    tabItemGroupsButton);

  -- Customizing tabCustom
  Module:AddListToTab(tabCustom, "items");

  -- Customizing tabItemGroups
  Module.NewPresetFrame.checkboxList = {};

  local height = 0;
  local previousRef = nil;

  for key, value in UH.UTILS:OrderedPairs(Module.ItemGroupOptions) do
    Module.NewPresetFrame.checkboxList[key] = Module:CreateItemGroupOption(key, value.label, previousRef,
      tabItemGroups.ScrollChildFrame);
    previousRef = Module.NewPresetFrame.checkboxList[key];
    height = height + Module.NewPresetFrame.checkboxList[key].TextRef:GetStringHeight() + 15;
  end

  tabItemGroups.ScrollChildFrame:SetHeight(height);

  -- Customizing tabExclusions
  Module:AddListToTab(tabExclusions, "itemsExclusion");

  -- Configure the tabs with the parent frame
  Module.NewPresetFrame.tabList = {
    tabCustom,
    tabItemGroups,
    tabExclusions
  };
  Module.NewPresetFrame.ScrollFrameParent.Tabs = {};
  tinsert(Module.NewPresetFrame.ScrollFrameParent.Tabs, tabCustomButton:GetID(), tabCustomButton);
  tinsert(Module.NewPresetFrame.ScrollFrameParent.Tabs, tabItemGroupsButton:GetID(), tabItemGroupsButton);
  tinsert(Module.NewPresetFrame.ScrollFrameParent.Tabs, tabExclusionsButton:GetID(), tabExclusionsButton);
  Module.NewPresetFrame.ScrollFrameParent.numTabs = UH.UTILS:TableLength(Module.NewPresetFrame.ScrollFrameParent.Tabs);

  -- After creating all tabs
  Module:OnClickTab(tabCustomButton);

  -- Footer
  Module.NewPresetFrame.CloseButton = CreateFrame("Button", UH.Helpers:ApplyPrefix("NewPresetFrameCloseButton"),
    Module.NewPresetFrame, "UIPanelButtonTemplate");
  Module.NewPresetFrame.CloseButton:SetPoint("BOTTOMRIGHT", Module.NewPresetFrame, "BOTTOMRIGHT", -10, 10);
  Module.NewPresetFrame.CloseButton:SetWidth(80);
  Module.NewPresetFrame.CloseButton:SetText("Close");
  Module.NewPresetFrame.CloseButton:HookScript("OnClick", function()
    Module:CloseNewPresetFrame();
  end);

  Module.NewPresetFrame.SaveButton = CreateFrame("Button", UH.Helpers:ApplyPrefix("NewPresetFrameSaveButton"),
    Module.NewPresetFrame, "UIPanelButtonTemplate");
  Module.NewPresetFrame.SaveButton:SetPoint("RIGHT", Module.NewPresetFrame.CloseButton, "LEFT", -5, 0);
  Module.NewPresetFrame.SaveButton:SetWidth(80);
  Module.NewPresetFrame.SaveButton:SetText("Save");
  Module.NewPresetFrame.SaveButton:HookScript("OnClick", function()
    Module:SavePreset();
  end);

  Module:UpdateNewPresetItemRows(Module.NewPresetFrame.tabList[1], "items");
  Module:UpdateNewPresetItemRows(Module.NewPresetFrame.tabList[3], "itemsExclusion");
end

function Module:CreateItemGroupOption(key, label, previousRef, parent)
  local checkbox = UH.UTILS:CreateCheckbox(UH.Helpers:ApplyPrefix("Checkbox" .. key), parent, label, false,
    function()
    end);

  if (previousRef) then
    checkbox:SetPoint("TOPLEFT", previousRef, "TOPLEFT", 0, -26);
  else
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2);
  end

  return checkbox;
end

function Module:CreateNewPresetTab(name, index, label, frameHeight, y, previousTabButton)
  local tab = CreateFrame("Button", UH.Helpers:ApplyPrefix("NewPresetTab" .. name),
    Module.NewPresetFrame.ScrollFrameParent, "CharacterFrameTabButtonTemplate");
  tab:SetID(index);
  tab:SetText(label);
  tab:SetScript("OnClick", function(self)
    Module:OnClickTab(self);
  end);

  if (index == 1) then
    tab:SetPoint("TOPLEFT", Module.NewPresetFrame.ScrollFrameParent, "BOTTOMLEFT", 5, 3);
  else
    tab:SetPoint("TOPLEFT", previousTabButton, "TOPRIGHT", -14, 0);
  end

  -- Scroll Frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, Module.NewPresetFrame.ScrollFrameParent,
    "UIPanelScrollFrameTemplate");
  scrollFrame:SetPoint("TOPLEFT", Module.NewPresetFrame.ScrollFrameParent, "TOPLEFT", 6, -4);
  scrollFrame:SetPoint("BOTTOMRIGHT", Module.NewPresetFrame.ScrollFrameParent, "BOTTOMRIGHT", -6, 6);
  scrollFrame:Hide();

  -- Events
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local newValue = self:GetVerticalScroll() - (delta * 20);

    if (newValue < 0) then
      newValue = 0;
    elseif (newValue > self:GetVerticalScrollRange()) then
      newValue = self:GetVerticalScrollRange();
    end

    self:SetVerticalScroll(newValue);
  end);

  -- Scroll Child Frame
  scrollFrame.ScrollChildFrame = CreateFrame("Frame", nil, scrollFrame);
  scrollFrame.ScrollChildFrame:SetSize(300, frameHeight - y);
  scrollFrame:SetScrollChild(scrollFrame.ScrollChildFrame);
  scrollFrame.ScrollChildFrame.ItemRows = {};

  -- Scrollbar
  scrollFrame.ScrollBar:ClearAllPoints();
  scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -6, -20);
  scrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -7, 16);

  tab.scrollFrame = scrollFrame;

  return scrollFrame, tab;
end

function Module:UpdateNewPresetItemRows(tab, tempKey)
  local height = 5;
  local rowHeight = 30;
  local rows = temp[tempKey];
  local scrollChildFrame = tab.ScrollChildFrame;

  -- Hide all rows until reprocessed
  for key, value in pairs(scrollChildFrame.ItemRows) do
    if (value) then
      value:Hide();
    end
  end

  for i, itemLink in ipairs(rows) do
    local itemId = UH.UTILS:GetItemIDFromLink(itemLink);

    if (itemId) then
      local rowRef = scrollChildFrame.ItemRows[itemId];
      local textRef;

      if (rowRef) then
        textRef = rowRef.TextRef;
      else
        rowRef = CreateFrame("Frame", nil, scrollChildFrame, "BackdropTemplate")
        rowRef:SetSize(308, rowHeight);

        -- Button on the left
        rowRef.RemoveButtonRef = CreateFrame("Button", nil, rowRef, "UIPanelButtonTemplate")
        rowRef.RemoveButtonRef:SetSize(30, rowHeight - 5);
        rowRef.RemoveButtonRef:SetPoint("LEFT", rowRef, "LEFT", 5, 0);
        rowRef.RemoveButtonRef:SetText("X");
        rowRef.RemoveButtonRef:SetScript("OnClick", function()
          local newTempItems = {};

          for key, value in pairs(temp[tempKey]) do
            if (value ~= itemLink) then
              tinsert(newTempItems, value);
            end
          end

          temp[tempKey] = newTempItems;

          Module:UpdateNewPresetItemRows(tab, tempKey);
        end);

        -- Text on the right
        textRef = rowRef:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textRef:SetPoint("LEFT", rowRef.RemoveButtonRef, "RIGHT", 6, 0);
        rowRef.TextRef = textRef;

        scrollChildFrame.ItemRows[itemId] = rowRef;
      end

      textRef:SetText(itemLink);
      rowRef:Show();
      rowRef:SetPoint("TOP", 0, -((i - 1) * rowHeight));
      height = height + rowHeight;
    end
  end

  if (UH.UTILS:TableLength(temp[tempKey]) == 0) then
    tab.EmptyText:Show();
  else
    tab.EmptyText:Hide();
  end

  tab.ScrollChildFrame:SetHeight(height);
end

function Module:AddListToTab(tab, tempKey)
  tab.EmptyText = tab:CreateFontString(nil, "OVERLAY");
  tab.EmptyText:SetFontObject("GameFontHighlight");
  tab.EmptyText:SetSize(200, 40);
  tab.EmptyText:SetPoint("CENTER", tab, "CENTER", 0, 0);
  tab.EmptyText:SetText("Drop items in this area do add to the list");
  tab.EmptyText:Hide();

  tab:SetScript("OnMouseUp", function()
    local _, _, itemLink = GetCursorInfo();

    if (itemLink and not UH.UTILS:ValueInTable(temp[tempKey], itemLink)) then
      tinsert(temp[tempKey], itemLink);
      Module:UpdateNewPresetItemRows(tab, tempKey);
      C_Timer.After(0.01, function()
        tab:SetVerticalScroll(tab:GetVerticalScrollRange());
      end);
    end

    ClearCursor();
  end);
end

function Module:OnClickTab(tabButton)
  PanelTemplates_SetTab(tabButton:GetParent(), tabButton:GetID());

  for key, value in pairs(Module.NewPresetFrame.tabList) do
    value:Hide();
  end

  tabButton.scrollFrame:Show();
end

function Module:UpdateWithRegister(register, registerID)
  Module.NewPresetFrame.TitleRef:SetText(register and "Edit preset" or "New preset");

  if (not register) then
    register = {};
    id = nil;
  else
    id = registerID;
  end

  Module.NewPresetFrame.NameInput:SetText(register.name or "");
  Module.NewPresetFrame.ToInput:SetText(register.to or "");
  temp.items = UH.UTILS:ShallowCopyTable(register.custom or {});
  temp.itemsExclusion = UH.UTILS:ShallowCopyTable(register.exclusion or {});

  -- Clear all previous checked
  for key, value in pairs(Module.ItemGroupOptions) do
    Module.NewPresetFrame.checkboxList[key]:SetChecked(false);
  end

  -- Check if there is itemGroups in the register
  if (register.itemGroups) then
    for key, value in pairs(register.itemGroups) do
      Module.NewPresetFrame.checkboxList[key]:SetChecked(value or false);
    end
  end

  -- Reset to the first tab
  Module:OnClickTab(Module.NewPresetFrame.ScrollFrameParent.Tabs[1]);
  Module:UpdateNewPresetItemRows(Module.NewPresetFrame.tabList[1], "items");
  Module:UpdateNewPresetItemRows(Module.NewPresetFrame.tabList[3], "itemsExclusion");
end

function Module:OpenNewPresetFrame(register, registerID)
  if (not Module.NewPresetFrame) then
    Module:CreateNewPresetFrame();
  end

  Module:UpdateWithRegister(register, registerID);
  Module.NewPresetFrame:Show();
end

function Module:CloseNewPresetFrame()
  if (not Module.NewPresetFrame) then
    return;
  end

  Module:UpdateWithRegister({});
  Module.NewPresetFrame:Hide();
end

function Module:ToggleNewPresetFrame()
  if (not Module.NewPresetFrame) then
    Module:CreateNewPresetFrame();
  end

  if (Module.NewPresetFrame:IsShown()) then
    Module:CloseNewPresetFrame();
  else
    Module:OpenNewPresetFrame();
  end
end

---@param name string
---@param labelText string
---@param parent table
---@param y number
---@return table|EditBox|InputBoxTemplate input
---@return table label
function Module:CreateFormField(name, labelText, parent, y)
  local label = parent:CreateFontString(nil, "OVERLAY");
  label:SetFontObject("GameFontHighlight");
  label:SetSize(80, 20);
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y - 6);
  label:SetText(labelText);
  label:SetJustifyH("LEFT");

  local input = CreateFrame("EditBox", UH.Helpers:ApplyPrefix(name), parent, "InputBoxTemplate");
  input:SetSize(180, 30);
  input:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y);
  input:SetAutoFocus(false);
  input:SetText("");
  input:SetCursorPosition(0);

  return input, label;
end

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
function Module:SavePreset(data, dataID)
  local preset = {};

  if (data) then
    preset = data;
  else
    preset = {
      name = Module.NewPresetFrame.NameInput:GetText(),
      to = Module.NewPresetFrame.ToInput:GetText(),
      custom = temp.items,
      itemGroups = {},
      exclusion = temp.itemsExclusion,
      color = temp.color,
    };
  end

  if (not preset.name or #preset.name < 1) then
    Module:ShowFormErrorPopup("Field Name is required", function()
      if (not data) then
        Module.NewPresetFrame.NameInput:SetFocus();
      end
    end);

    return false;
  end

  if (not preset.to or #preset.to < 1) then
    Module:ShowFormErrorPopup("Field To is required", function()
      if (not data) then
        Module.NewPresetFrame.ToInput:SetFocus();
      end
    end);

    return false;
  end

  local atLeastOneCheck = false;

  if (data) then
    for _, value in pairs(preset.itemGroups) do
      if (value) then
        atLeastOneCheck = true;
      end
    end
  else
    for key, value in pairs(Module.ItemGroupOptions) do
      preset.itemGroups[key] = Module.NewPresetFrame.checkboxList[key]:GetChecked();

      if (preset.itemGroups[key]) then
        atLeastOneCheck = true;
      end
    end
  end

  if (UH.UTILS:TableLength(preset.custom) == 0 and (not atLeastOneCheck)) then
    Module:ShowFormErrorPopup("At least one item group needs to be checked or one item added to the inclusions");
    return false;
  end

  -- Save
  if (id or dataID) then
    UH.db.global.presets[id or dataID] = preset;
  else
    tinsert(UH.db.global.presets, preset);
  end

  if (not data) then
    Module:CloseNewPresetFrame();
  end

  return true;
end

function Module:GetNewEmptyPreset()
  local preset = {
    id = nil,
    name = "",
    to = "",
    color = Module.defaultPresetColor,
    itemGroups = {},
    custom = {},
    exclusion = {},
  };

  for itemGroupName, itemGroup in UH.UTILS:OrderedPairs(Module.ItemGroupOptions) do
    tinsert(preset.itemGroups, { checked = false, name = itemGroup.label, key = itemGroupName });
  end

  return preset;
end

-- Execution
function Module:GetLoadPresetGeneratorFunction()
  local refUH = UH;

  return function(owner, rootDescription)
    rootDescription:CreateTitle(refUH.UTILS:TableLength(refUH.db.global.presets) == 0 and "No presets available" or
      "Presets available");

    for key, value in pairs(refUH.db.global.presets) do
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
  local refUH = UH;

  return function(owner, rootDescription)
    rootDescription:CreateTitle(refUH.UTILS:TableLength(refUH.db.global.presets) == 0 and "No presets available" or
      "Presets available");

    for i, value in pairs(refUH.db.global.presets) do
      local button = rootDescription:CreateButton(value.name);

      button:CreateButton("Edit", function()
        Module:OpenNewPresetFrame(value, i);
      end);

      button:CreateButton("Remove", function()
        local newPresets = {};

        for j, value in pairs(refUH.db.global.presets) do
          if (i ~= j) then
            tinsert(newPresets, value);
          end
        end

        refUH.db.global.presets = newPresets;
      end);
    end
  end
end

function Module:ExecutePreset(preset)
  MailFrameTab_OnClick(_G["MailFrameTab2"]);
  Module:ClearAllMailSlots();

  SendMailNameEditBox:SetText(preset.to);
  SendMailSubjectEditBox:SetText("UH - Generated by preset [" .. preset.name .. "]");
  local itemGroupFunctions = {};

  for key, value in pairs((preset.itemGroups or {})) do
    if (value) then
      tinsert(itemGroupFunctions, Module.ItemGroupOptions[key].checkItemBelongsToGroup);
    end
  end

  for bag = 0, 4 do -- Loops through bags 0 (backpack) to 4 (bags)
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local itemLink = C_Container.GetContainerItemLink(bag, slot);

      if (itemLink) then
        local isSoulbound = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot));
        local isConjured = UH.UTILS:IsItemConjured(itemLink);

        if (not isSoulbound and not isConjured and Module:ItemShouldBeAdded(itemLink, itemGroupFunctions, preset.custom, preset.exclusion)) then
          Module:AddItemToNextEmptyMailSlot(bag, slot);
        end
      end
    end
  end

  ClearCursor();
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

function Module:AddItemToNextEmptyMailSlot(bag, slot)
  for mailSlot = 1, ATTACHMENTS_MAX_SEND do
    if (not HasSendMailItem(mailSlot)) then
      C_Container.PickupContainerItem(bag, slot);
      ClickSendMailItemButton(mailSlot);

      return true;
    end
  end

  return false;
end

function Module:ClearAllMailSlots()
  for i = 1, ATTACHMENTS_MAX_SEND do
    ClickSendMailItemButton(i, true);
  end
end

function Module:OnEnable()
  EventRegistry:RegisterFrameEventAndCallback("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, _, type)
    -- 17 = MailInfo
    if (type == 17) then
      Module:CloseNewPresetFrame();
    end
  end);
end
