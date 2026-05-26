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

  ---@type BasicDialogGenerator
  local generator = UtilityHub.Components.BasicDialog;

  basicDialog = generator
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

  local previous = title;

  do -- Enable
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    checkbox:SetSize(24, 24);
    checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -20);
    checkbox:SetChecked(UtilityHub.Database.global.options.cooldowns);

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
    label:SetText("Enabled");

    checkbox:SetScript("OnClick", function(self)
      local checked = self:GetChecked();
      UtilityHub.Database.global.options.cooldowns = checked;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldowns", checked);
    end);

    previous = checkbox;
  end

  do -- Play sound when ready
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    checkbox:SetSize(24, 24);
    checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5);
    checkbox:SetChecked(UtilityHub.Database.global.options.cooldownPlaySound);

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
    label:SetText("Play sound when ready");

    checkbox:SetScript("OnClick", function(self)
      local checked = self:GetChecked();
      UtilityHub.Database.global.options.cooldownPlaySound = checked;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownPlaySound", checked);
    end);

    previous = checkbox;
  end

  do -- Start collapsed
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    checkbox:SetSize(24, 24);
    checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5);
    checkbox:SetChecked(UtilityHub.Database.global.options.cooldownStartCollapsed);

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
    label:SetText("Start collapsed");

    checkbox:SetScript("OnClick", function(self)
      local checked = self:GetChecked();
      UtilityHub.Database.global.options.cooldownStartCollapsed = checked;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownStartCollapsed", checked);
    end);

    previous = checkbox;
  end

  do -- Enable cross-account sync
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    checkbox:SetSize(24, 24);
    checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5);
    checkbox:SetChecked(UtilityHub.Database.global.options.cooldownSync);

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
    label:SetText("Enable cross-account sync");

    checkbox:SetScript("OnClick", function(self)
      local checked = self:GetChecked();
      UtilityHub.Database.global.options.cooldownSync = checked;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownSync", checked);
    end);

    previous = checkbox;
  end

  do -- Sync channel
    local syncChannelContainer = CreateFrame("Frame", nil, frame);
    syncChannelContainer:SetSize(400, 30);
    syncChannelContainer:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -10);

    local syncChannelLabel = syncChannelContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    syncChannelLabel:SetPoint("LEFT", 30, 0);
    syncChannelLabel:SetText("Sync channel:");

    local syncChannelInput = CreateFrame("EditBox", nil, syncChannelContainer, "InputBoxTemplate");
    syncChannelInput:SetSize(200, 30);
    syncChannelInput:SetPoint("LEFT", syncChannelLabel, "RIGHT", 10, 0);
    syncChannelInput:SetAutoFocus(false);
    syncChannelInput:SetMaxLetters(50);

    -- Force text to be visible
    syncChannelInput:SetTextColor(1, 1, 1, 1);
    syncChannelInput:SetFontObject("ChatFontNormal");
    syncChannelInput:SetJustifyH("LEFT");

    -- Function to save the channel
    local function SaveChannel()
      local text = syncChannelInput:GetText();
      UtilityHub.Database.global.options.cooldownSyncChannel = text;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownSyncChannel", text);
    end

    -- Save when pressing Enter
    syncChannelInput:SetScript("OnEnterPressed", function(self)
      SaveChannel();
      self:ClearFocus();
    end);

    -- Save when losing focus
    syncChannelInput:SetScript("OnEditFocusLost", function(self)
      SaveChannel();
    end);

    -- Cancel on Escape
    syncChannelInput:SetScript("OnEscapePressed", function(self)
      -- Restore original value
      self:SetText(UtilityHub.Database.global.options.cooldownSyncChannel or "");
      self:ClearFocus();
    end);

    -- Tooltip
    syncChannelInput:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText("Sync Channel", 1, 1, 1);
      GameTooltip:AddLine("Enter the name of a custom chat channel (e.g., 'MyCooldowns')", nil, nil, nil, true);
      GameTooltip:AddLine("All accounts must use the same channel name to sync", nil, nil, nil, true);
      GameTooltip:Show();
    end);

    syncChannelInput:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);

    -- Update field value when page is shown
    frame:SetScript("OnShow", function(self)
      local currentValue = UtilityHub.Database.global.options.cooldownSyncChannel or "";
      syncChannelInput:SetText(currentValue);
      syncChannelInput:SetCursorPosition(0);
      syncChannelInput:ClearFocus();
    end);

    -- Load initial value immediately (in case frame is already shown)
    local initialValue = UtilityHub.Database.global.options.cooldownSyncChannel or "";
    syncChannelInput:SetText(initialValue);
    syncChannelInput:SetCursorPosition(0);
    syncChannelInput:ClearFocus();

    previous = syncChannelContainer;
  end

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

  listFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6);
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
