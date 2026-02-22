local ADDON_NAME = ...;

---@class MailPage
local MailPage = {};

---@type Frame|nil
local mailListFrame = nil;

---@param parent Frame
---@return Frame
function MailPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubMailPage", parent);

  frame:HookScript("OnShow", function()
    --[[
      When updated and not visible, for some reason, nothing shows until
      scroll is used inside the list, so this is required
    ]]
    MailPage:RefreshList();
  end);

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("Mail Presets");

  -- Description
  local description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10);
  description:SetText("Create and manage mail presets for quick item sending.");

  -- Presets list label
  local presetsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  presetsLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20);
  presetsLabel:SetText("Presets:");

  -- Get framesHelper
  local framesHelper = UtilityHub.GameOptions.framesHelper;

  -- Create presets list
  mailListFrame = framesHelper:CreateCustomList(
    "MailPresetsList",
    frame,
    nil,
    {
      SortComparator = function(a, b)
        return a.name < b.name;
      end,
      Predicate = function(rowData)
        return rowData.name;
      end,
      CustomizeRow = function(frame, helpers)
        local rowData = frame.rowData;
        local color = rowData.color;
        local fontString = frame:GetFontString();

        fontString:SetTextColor(
          color and color.r or 1,
          color and color.g or 1,
          color and color.b or 1
        );

        -- Add edit button
        if (not frame.customElements) then
          frame.customElements = {};
        end

        if (not frame.customElements.EditButton) then
          local editButton = CreateFrame("Button", nil, frame);
          frame.customElements.EditButton = editButton;
          editButton:SetSize(16, 16);
          editButton:SetPoint("TOPRIGHT", -25, -5);
          local texture = editButton:CreateTexture();
          UtilityHub.Textures:ApplyTexture("OrangeCogs", texture);

          editButton:SetScript("OnClick", function(self)
            local selectedPreset = CopyTable(rowData);

            if (not selectedPreset.custom) then
              selectedPreset.custom = {};
            end

            if (not selectedPreset.exclusion) then
              selectedPreset.exclusion = {};
            end

            -- Store selected preset temporarily for the editor
            UtilityHub.tempSelectedPreset = selectedPreset;

            -- Open preset editor
            UtilityHub.GameOptions.OpenConfig(UtilityHub.GameOptions.subcategories.preset);
          end);

          editButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText("Edit Preset");
            GameTooltip:Show();
          end);

          editButton:SetScript("OnLeave", function(self)
            if (GameTooltip:IsOwned(self)) then
              GameTooltip:Hide();
            end
          end);
        end
      end,
      GetText = function(rowData)
        return rowData.name;
      end,
      OnRemove = function(rowData, configuration)
        local presets = UtilityHub.Database.global.presets or {};

        for i = #presets, 1, -1 do
          if (presets[i].id == rowData.id) then
            tremove(presets, i);
            break;
          end
        end

        UtilityHub.Database.global.presets = presets;

        -- Refresh list
        self:RefreshList();
      end,
      showRemoveIcon = true,
    },
    "InsetFrameTemplate"
  );

  mailListFrame:SetPoint("TOPLEFT", presetsLabel, "BOTTOMLEFT", 0, -10);
  mailListFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 70);

  -- Create new preset button
  local newPresetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  newPresetButton:SetSize(130, 30);
  newPresetButton:SetPoint("BOTTOMLEFT", 20, 20);
  newPresetButton:SetText("New Preset");
  newPresetButton:SetScript("OnClick", function()
    -- Clear temp preset
    UtilityHub.tempSelectedPreset = nil;

    -- Open preset editor
    UtilityHub.GameOptions.OpenConfig(UtilityHub.GameOptions.subcategories.preset);
  end);

  -- Load initial data
  MailPage:RefreshList();

  return frame;
end

-- Helper function to refresh the list
function MailPage:RefreshList()
  if (mailListFrame) then
    local presets = UtilityHub.Database.global.presets or {};
    mailListFrame:ReplaceData(presets);
  end
end

-- Register page
UtilityHub.OptionsPages.Mail = MailPage;
