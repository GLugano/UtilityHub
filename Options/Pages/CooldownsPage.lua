---@class ProfessionCooldownRow
---@field profession string
---@field name string
---@field internalID number
---@field formattedName string
---@field enabled boolean
---@field showNotification boolean

---@class CooldownsPage
local CooldownsPage = {};

---@type Frame|nil
local listFrame = nil;
---@type BasicDialog|nil
local basicDialog = nil;

---@return BasicDialog
local function GetOrCreateEditDialog()
  if (basicDialog) then
    return basicDialog;
  end

  basicDialog = UtilityHub.Components.BasicDialog
      :New({ name = "CooldownsEditDialog" })
      :AddCancelButton()
      :AddSaveButton()
      :RealignButtons()
      :RegisterOnSetData(function(self, data)
        self.frame.checkEnabled:SetChecked(data.enabled);
        self.frame.checkShowNotification:SetChecked(data.showNotification);
      end);

  local previous;

  do -- Enabled
    local checkEnabledLabel = basicDialog.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    checkEnabledLabel:SetPoint("TOPLEFT", 15, -40);
    checkEnabledLabel:SetText("Enabled:");

    local checkEnabled = CreateFrame("CheckButton", nil, basicDialog.frame, "UICheckButtonTemplate");
    checkEnabled:SetPoint("TOPRIGHT", checkEnabledLabel, 40, 10);

    basicDialog.frame.checkEnabled = checkEnabled;
    previous = checkEnabledLabel;

    checkEnabled:SetScript("OnClick", function(self)
      local value = self:GetChecked();

      if (value) then
        basicDialog.frame.checkShowNotification:SetEnabled(true);
        basicDialog.frame.checkShowNotification:SetAlpha(1);
      else
        basicDialog.frame.checkShowNotification:SetChecked(false);
        basicDialog.frame.checkShowNotification:SetEnabled(false);
        basicDialog.frame.checkShowNotification:SetAlpha(0.5);
      end
    end);
  end

  do -- Show notification
    local checkShowNotificationLabel = basicDialog.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    checkShowNotificationLabel:SetPoint("TOPLEFT", previous, 0, -30);
    checkShowNotificationLabel:SetText("Show notification:");

    local checkShowNotification = CreateFrame("CheckButton", nil, basicDialog.frame, "UICheckButtonTemplate");
    checkShowNotification:SetPoint("TOPRIGHT", checkShowNotificationLabel, 40, 10);

    basicDialog.frame.checkShowNotification = checkShowNotification;
  end

  return basicDialog;
end

---@param parent Frame
---@return Frame
function CooldownsPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubCooldownsPage", parent);

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("Cooldowns");

  local framesHelper = UtilityHub.GameOptions.framesHelper;

  -- Forward-declare so closures defined before the function bodies can capture them
  local RefreshList;

  listFrame          = framesHelper:CreateCustomList(
    "AutoBuyList",
    frame,
    nil,
    {
      ---@param a ProfessionCooldownRow
      ---@param b ProfessionCooldownRow
      SortComparator = function(a, b)
        return a.formattedName < b.formattedName;
      end,
      ---@param rowData ProfessionCooldownRow
      Predicate = function(rowData)
        return rowData.formattedName;
      end,
      ---@param rowData ProfessionCooldownRow
      GetText = function(rowData)
        return rowData.formattedName;
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

          listFrame.customElements.EditButton:SetScript("OnClick", function(self)
            local dialog = GetOrCreateEditDialog();
            local rowData = self:GetParent().rowData;

            dialog:SetTitle("Edit cooldown [" .. rowData.name .. "]");
            dialog:SetData(rowData);
            dialog:RegisterOnSave(function(self)
              local enabled = self.frame.checkEnabled:GetChecked();
              local showNotification = self.frame.checkShowNotification:GetChecked();

              ---@type CooldownConfig[]
              local baseData = UtilityHub.Database.global.options.cooldownConfigs;
              local internalID = rowData.internalID;

              for _, cooldownConfig in ipairs(baseData) do
                if (cooldownConfig.internalID == internalID) then
                  cooldownConfig.enabled = enabled;
                  cooldownConfig.showNotification = showNotification;
                  break;
                end
              end

              UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
              RefreshList();
              dialog:Hide();
            end);

            dialog:Show();
          end);
        end
      end,
      hasHyperlink = false,
    },
    "InsetFrameTemplate"
  );

  listFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6);
  listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20);

  RefreshList = function()
    ---@type CooldownConfig[]
    local baseData = UtilityHub.Database.global.options.cooldownConfigs;
    ---@type ProfessionCooldownRow[]
    local list = {};

    ---@param internalID number
    ---@return CooldownConfig|nil
    local FindConfig = function(internalID)
      for _, value in ipairs(baseData) do
        if (value.internalID == internalID) then
          return value;
        end
      end

      return nil;
    end

    for _, professionData in pairs(UtilityHub.Constants.Cooldowns) do
      for _, value in ipairs(professionData.cooldowns) do
        local config = FindConfig(value.internalID);

        if (config) then
          tinsert(list, {
            internalID = value.internalID,
            name = value.name,
            profession = professionData.name,
            enabled = config.enabled,
            showNotification = config.showNotification,
            formattedName = string.format("%s - %s", professionData.name, value.name),
          });
        end
      end
    end

    listFrame:ReplaceData(list);
  end;

  frame:SetScript("OnShow", function()
    RefreshList();
  end);

  return frame;
end

-- Register page
UtilityHub.OptionsPages.Cooldowns = CooldownsPage;
