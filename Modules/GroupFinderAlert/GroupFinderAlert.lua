---@type fun(): boolean
local HasLFGRestrictions = HasLFGRestrictions or function()
  return false;
end

local function CreateObject()
  local alertFrame = CreateFrame("Frame", "LFGGroupAlertFrame", UIParent, "DialogBoxFrame");
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
  msg:SetPoint("CENTER", alertFrame, "CENTER", 16, 0);
  msg:SetWidth(340);
  msg:SetJustifyH("CENTER");
  msg:SetText("You have joined a group\nthat is queued via the Group Finder!");

  -- Dismiss button
  -- The button is always the first child of a DialogBoxFrame
  local btn = select(1, alertFrame:GetChildren());
  btn:SetText("Dismiss");
  btn:SetScript("OnClick", function() alertFrame:Hide() end);

  ---@class GroupFinderAlert
  local object = {
    ---@type boolean
    wasInGroup = false,
    ---@type Frame
    AlertFrame = alertFrame,
    ---@param self GroupFinderAlert
    Show = function(self)
      if (UtilityHub.Database.global.options.showWarningEnteringListedGroupInLFG) then
        self.AlertFrame:Show();
      end
    end,
    Hide = function(self)
      self.AlertFrame:Hide();
    end,
    ---@return boolean
    isGroupFromLFG = function()
      -- HasLFGRestrictions: returns true if the group was formed by the dungeon finder
      if (HasLFGRestrictions()) then
        return true;
      end

      local mode = GetLFGMode(LE_LFG_CATEGORY_LFD);

      if (IsInGroup() and (mode == "queued" or mode == "listed")) then
        return true;
      end

      if (C_LFGList.HasActiveEntryInfo()) then
        return true;
      end

      return false;
    end,
    ---@param self GroupFinderAlert
    ---@param event any
    CheckGroup = function(self, event)
      if (event == "PLAYER_LOGIN") then
        self.wasInGroup = IsInGroup() or IsInRaid();
        return;
      end

      ---@type boolean
      local nowInGroup = IsInGroup() or IsInRaid();

      if (not nowInGroup) then
        self:Hide();
      elseif (not self.wasInGroup and self:isGroupFromLFG() and not UnitIsGroupLeader("player")) then
        self:Show();
      end

      self.wasInGroup = nowInGroup;
    end
  };

  EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", function()
    object:CheckGroup("GROUP_ROSTER_UPDATE");
  end);

  EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    object:CheckGroup("PLAYER_LOGIN");
  end);

  return object;
end

if (UtilityHub.Constants.IsTBC) then
  CreateObject();
end
