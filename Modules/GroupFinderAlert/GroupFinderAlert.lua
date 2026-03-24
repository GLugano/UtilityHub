---@alias AlertFrameShownReason "ENTERING" | "LEAVING"

---@type fun(): boolean
local HasLFGRestrictions = HasLFGRestrictions or function()
  return false;
end

---@type fun(): boolean
local IsCurrentlyInGroup = function()
  return IsInGroup() or IsInRaid();
end

local function CreateObject()
  ---@type number
  local spacing = 10;
  ---@type number
  local bottomSpacing = 16;

  ---@class AlertFrame
  local alertFrame = CreateFrame("Frame", "LFGGroupAlertFrame", UIParent, "DialogBoxFrame");
  ---@type AlertFrameShownReason | nil
  alertFrame.shownFlag = nil;
  alertFrame:SetPoint("CENTER", UIParent, "CENTER");
  alertFrame:SetClampedToScreen(true);
  alertFrame:SetSize(350, 180);
  alertFrame:Hide();

  -- Icon
  local icon = alertFrame:CreateTexture("LFGTitleIcon", "ARTWORK");
  alertFrame.LFGTitleIcon = icon;
  icon.textureData = LFG_EYE_TEXTURES["default"];
  icon:SetSize(60, 60);
  icon:SetPoint("LEFT", alertFrame, "LEFT", 18, 0);
  icon:SetTexture(icon.textureData.file);
  alertFrame:SetScript("OnUpdate", function(self, elapsed)
    local iconTexture = self.LFGTitleIcon;

    AnimateTexCoords(
      iconTexture,
      iconTexture.textureData.width,
      iconTexture.textureData.height,
      iconTexture.textureData.iconSize,
      iconTexture.textureData.iconSize,
      iconTexture.textureData.frames,
      elapsed,
      iconTexture.textureData.delay
    );
  end);

  -- Title
  local title = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOP", alertFrame, "TOP", 0, -24);
  title:SetText("|cFFFFD700Group Finder Alert|r");

  -- Message
  local msg = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  alertFrame.messageFrame = msg;
  msg:SetPoint("CENTER", alertFrame, "CENTER", 16, 0);
  msg:SetWidth(340);
  msg:SetJustifyH("CENTER");
  msg:SetText("You have joined a group\nthat is queued via the Group Finder!");

  -- Dismiss button
  -- The button is always the first child of a DialogBoxFrame
  local dismissButton = select(1, alertFrame:GetChildren());
  alertFrame.dismissButton = dismissButton;
  dismissButton:SetText("Dismiss");
  dismissButton:SetScript("OnClick", function() alertFrame:Hide() end);

  local dismissButtonFontString = dismissButton:GetFontString();
  local dismissButtonFont, dismissButtonFontSize = dismissButtonFontString:GetFont();
  local delistButton = CreateFrame("Button", nil, alertFrame, "UIPanelButtonTemplate");
  local delistButtonFontString = delistButton:GetFontString();
  alertFrame.delistButton = delistButton;
  delistButton:SetText("Delist");
  delistButtonFontString:SetFont(dismissButtonFont, dismissButtonFontSize);
  delistButton:SetWidth(dismissButton:GetWidth());
  delistButton:SetHeight(dismissButton:GetHeight());
  delistButton:SetPoint(
    "BOTTOM",
    alertFrame,
    "BOTTOM",
    dismissButton:GetWidth() / 2 + spacing / 2, bottomSpacing
  );
  delistButton:Hide();

  ---@class GroupFinderAlert
  local object = {
    ---@type number
    bottomSpacing = bottomSpacing,
    ---@type number
    spacing = spacing,
    ---@type boolean
    wasInGroup = false,
    ---@type AlertFrame
    AlertFrame = alertFrame,
    ---@param self GroupFinderAlert
    ---@param mode AlertFrameShownReason
    Show = function(self, mode)
      ---@type string
      local text = "";
      ---@type number
      local bottomSpacing = 16;

      self.AlertFrame.dismissButton:ClearAllPoints();

      if (mode == "ENTERING") then
        text = "You have joined a group that is\nqueued via the Group Finder!";
        self.AlertFrame.delistButton:Hide();
        self.AlertFrame.dismissButton:SetPoint("BOTTOM", 0, bottomSpacing);
      else
        text = "You have left a group that was\nqueued via the Group Finder,\nbut you are still listed!";
        self.AlertFrame.delistButton:Show();
        self.AlertFrame.dismissButton:SetPoint(
          "BOTTOM",
          self.AlertFrame,
          "BOTTOM",
          -(self.AlertFrame.dismissButton:GetWidth() / 2 + self.spacing / 2), bottomSpacing
        );
      end

      self.AlertFrame.messageFrame:SetText(text);
      self.AlertFrame:Show();
    end,
    Hide = function(self)
      self.AlertFrame:Hide();
    end,
    ---@return boolean
    IsListedInLFG = function()
      -- HasLFGRestrictions: returns true if the group was formed by the dungeon finder
      if (HasLFGRestrictions()) then
        return true;
      end

      local mode = GetLFGMode(LE_LFG_CATEGORY_LFD);

      if (mode == "queued" or mode == "listed") then
        return true;
      end

      if (C_LFGList.HasActiveEntryInfo()) then
        return true;
      end

      return false;
    end,
    ---@param self GroupFinderAlert
    ---@param event "PLAYER_LOGIN" | "GROUP_ROSTER_UPDATE"
    CheckGroup = function(self, event)
      if (event == "PLAYER_LOGIN") then
        self.wasInGroup = IsCurrentlyInGroup();
        return;
      end

      ---@type boolean
      local nowInGroup = IsCurrentlyInGroup();

      if (self:IsListedInLFG()) then
        if (self.wasInGroup and not nowInGroup and UtilityHub.Database.global.options.showWarningLeavingListedGroupInLFG) then
          self:Show("LEAVING");
        elseif (not self.wasInGroup and nowInGroup and not UnitIsGroupLeader("player") and UtilityHub.Database.global.options.showWarningEnteringListedGroupInLFG) then
          self:Show("ENTERING");
        else
          self:Hide();
        end
      else
        self:Hide();
      end

      self.wasInGroup = nowInGroup;
    end
  };

  delistButton:SetScript("OnClick", function()
    C_LFGList.RemoveListing();
    object:Hide();
  end)

  EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", function()
    object:CheckGroup("GROUP_ROSTER_UPDATE");
  end);

  EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    object:CheckGroup("PLAYER_LOGIN");
  end);

  EventRegistry:RegisterFrameEventAndCallback("LFG_LIST_ACTIVE_ENTRY_UPDATE", function(...)
    if (not object:IsListedInLFG() and object.AlertFrame:IsShown()) then
      object:Hide();
    end
  end);

  return object;
end

if (UtilityHub.Constants.IsTBC) then
  CreateObject();
end
