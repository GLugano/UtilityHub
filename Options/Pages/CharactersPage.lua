local ADDON_NAME = ...;

---@class CharactersPage
local CharactersPage = {};

---@type Frame|nil
local listFrame = nil;

---@return Frame
local function GetOrCreateEditDialog()
  if (_G["UtilityHubCharactersEditDialog"]) then
    return _G["UtilityHubCharactersEditDialog"];
  end

  local dialog = CreateFrame("Frame", "UtilityHubCharactersEditDialog", UIParent, "BasicFrameTemplate");
  dialog:SetSize(320, 195);
  dialog:SetPoint("CENTER");
  dialog:SetFrameStrata("DIALOG");
  dialog:SetMovable(true);
  dialog:EnableMouse(true);
  dialog:RegisterForDrag("LeftButton");
  dialog:SetScript("OnDragStart", dialog.StartMoving);
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing);
  dialog:Hide();

  -- Scope label
  local groupLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  groupLabel:SetPoint("TOPLEFT", 15, -30);
  groupLabel:SetText("Scope:");

  dialog.groupButtons = {};

  local orderedGroups = {};
  for _, key in pairs(UtilityHub.Enums.CharacterGroup) do
    tinsert(orderedGroups, { key = key, name = UtilityHub.Enums.CharacterGroupText[key] });
  end

  table.sort(orderedGroups, function(a, b)
    return a.key < b.key;
  end);

  local i = 0;
  for _, value in ipairs(orderedGroups) do
    i = i + 1;
    local ceil = math.ceil(i / 2);
    local even = (i % 2) == 0;
    local radio = CreateFrame("CheckButton", nil, dialog, "UIRadioButtonTemplate");
    radio:SetPoint("TOPLEFT", groupLabel, "BOTTOMLEFT", (even and 1 or 0) * 150, -5 - (20 * (ceil - 1)));
    radio:SetSize(16, 16);
    radio.groupKey = value.key;

    local radioLabel = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    radioLabel:SetPoint("LEFT", radio, "RIGHT", 2, 0);
    radioLabel:SetText(value.name);

    radio:SetScript("OnClick", function(self)
      for _, btn in ipairs(dialog.groupButtons) do
        btn:SetChecked(btn == self);
      end
    end);

    tinsert(dialog.groupButtons, radio);
  end

  -- Save / Cancel buttons
  local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate");
  cancelBtn:SetText("Cancel");
  cancelBtn:SetSize(80, 22);
  cancelBtn:SetPoint("BOTTOMRIGHT", -15, 15);
  cancelBtn:SetScript("OnClick", function()
    dialog:Hide();
  end);

  local saveBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate");
  saveBtn:SetText("Save");
  saveBtn:SetSize(80, 22);
  saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -5, 0);
  dialog.saveBtn = saveBtn;

  ---@param currentData Character
  ---@param onSave fun(group: EnumCharacterGroup )
  function dialog:Open(currentData, onSave)
    local currentoGroup = currentData.group or UtilityHub.Enums.CharacterGroup.UNGROUPED;

    for _, btn in ipairs(self.groupButtons) do
      btn:SetChecked(btn.groupKey == currentoGroup);
    end

    self.saveBtn:SetScript("OnClick", function()
      local group = UtilityHub.Enums.CharacterGroup.UNGROUPED;

      for _, btn in ipairs(self.groupButtons) do
        if (btn:GetChecked()) then
          group = btn.groupKey;
          break;
        end
      end

      onSave(group);
      self:Hide();
    end);

    self:Show();
    self:Raise();
  end

  return dialog;
end

---@param parent Frame
---@return Frame
function CharactersPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubCharactersPage", parent);

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("Characters");

  local framesHelper = UtilityHub.GameOptions.framesHelper;

  -- Forward-declare so closures defined before the function bodies can capture them
  local RefreshList;

  listFrame          = framesHelper:CreateCustomList(
    "CharactersList",
    frame,
    nil,
    {
      SortComparator = function(a, b)
        if (a.name == b.name) then
          return a.realm < b.name;
        end

        return a.name < b.name;
      end,
      Predicate = function(rowData)
        return string.format("%s-%s", rowData.name, rowData.realm);
      end,
      GetText = function(rowData)
        local realmColor = "FFB68655";

        if (GetRealmName() == rowData.realm) then
          realmColor = "FFCA4F4B";
        end

        local group = rowData.group or UtilityHub.Enums.CharacterGroup.UNGROUPED;
        local groupText = UtilityHub.Helpers.Color:AddColorToString(
          " (" .. UtilityHub.Enums.CharacterGroupText[group] .. ")", "FF949392");
        local realmText = UtilityHub.Helpers.Color:AddColorToString(
          " [" .. rowData.realm .. "]", realmColor);
        return string.format("%s %s %s", rowData.name, realmText, groupText);
      end,
      OnRemove = function(rowData, configuration)
        StaticPopupDialogs["UTILITY_HUB_ON_REMOVE_CHARACTER"] = {
          text = string.format("You really want to remove %s-%s?", rowData.name, rowData.realm),
          button1 = "Yes",
          button2 = "No",
          OnAccept = function()
            ---@type Character[]
            local list = UtilityHub.Database.global.characters or {};
            local removeName = rowData.name;
            local removeRealm = rowData.realm;

            for i = #list, 1, -1 do
              if (list[i] ~= nil and list[i].name == removeName and list[i].realm == removeRealm) then
                tremove(list, i);
                break;
              end
            end

            UtilityHub.Database.global.characters = list;
            UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
            RefreshList();
          end,
          OnCancel = function() end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
        };

        StaticPopup_Show("UTILITY_HUB_ON_REMOVE_CHARACTER");
      end,
      CustomizeRow = function(listFrame, helpers)
        if (not listFrame.customElements) then
          listFrame.customElements = {};
        end

        if (not listFrame.customElements.EditButton) then
          local editButton = CreateFrame("Button", nil, listFrame);
          listFrame.customElements.EditButton = editButton;
          editButton:SetSize(16, 16);
          editButton:SetPoint("TOPRIGHT", -25, -5);
          local texture = editButton:CreateTexture();
          UtilityHub.Textures:ApplyTexture("OrangeCogs", texture);

          editButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText("Edit");
            GameTooltip:Show();
          end);

          editButton:SetScript("OnLeave", function(self)
            if (GameTooltip:IsOwned(self)) then
              GameTooltip:Hide();
            end
          end);
        end

        local currentCharacterData = UtilityHub.DatabaseFunctions.GetCurrentCharacterData();

        if (listFrame.customElements.DeleteIconButton) then
          local rowData = listFrame.rowData;

          if (currentCharacterData and rowData.name == currentCharacterData.name and rowData.realm == currentCharacterData.realm) then
            listFrame.customElements.DeleteIconButton:Hide();
          else
            listFrame.customElements.DeleteIconButton:Show();
          end
        end

        -- Re-bind OnClick each time to capture the current rowData.
        listFrame.customElements.EditButton:SetScript("OnClick", function(self)
          local dialog = GetOrCreateEditDialog();
          local rowData = self:GetParent().rowData;

          dialog:Open(rowData, function(group)
            ---@type Character[]
            local characters = UtilityHub.Database.global.characters or {};
            local characterName = rowData.name;
            local characterRealm = rowData.realm;

            for _, character in ipairs(characters) do
              if (character.name == characterName == character.realm == characterRealm) then
                character.group = group;
                break;
              end
            end

            UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
            RefreshList();
          end);
        end);
      end,
      showRemoveIcon = true,
      hasHyperlink = false,
    },
    "InsetFrameTemplate"
  );

  listFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
  listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20);

  RefreshList = function()
    listFrame:ReplaceData(UtilityHub.Database.global.characters);
  end;

  -- Load initial data
  RefreshList();

  return frame;
end

-- Register page
UtilityHub.OptionsPages.Characters = CharactersPage;
