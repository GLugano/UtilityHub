---@enum DialogActionType
local DIALOG_ACTION_TYPE = {
  CONFIRM = 1,
  AUTO_INTERACT = 2,
};

---@class NpcGossipConfig
---@field npcName string
---@field dialogText? string
---@field action DialogActionType
---@field addonConfigOption string
---@field confirmText string?
---@field gossipOptionID number?
---@field ExtraChecks? fun(npcName: string, gossipConfig: NpcGossipConfig, elementData: table): boolean

local changedFrames = {};
---@type NpcGossipConfig[]
local dialogActionConfigs = {
  {
    npcName = "Tal",
    dialogText = "Can you take me to Orgrimmar?",
    action = DIALOG_ACTION_TYPE.CONFIRM,
    addonConfigOption = "askBeforeFlyingFromTBtoORGFromOption",
    confirmText = "You really want to go to Orgrimmar?",
  },
  {
    npcName = "Thysta",
    dialogText = "Can you take me to Stonard?",
    action = DIALOG_ACTION_TYPE.CONFIRM,
    addonConfigOption = "askBeforeFlyingFromGromgolToStonardFromOption",
    confirmText = "You really want to go to Stonard?",
  },
  {
    npcName = "Craftsman Wilhelm",
    addonConfigOption = "automaticOpenMerchantFrameLHCBlacksmith",
    action = DIALOG_ACTION_TYPE.AUTO_INTERACT,
    gossipOptionID = 117482,
    ExtraChecks = function()
      return #C_GossipInfo.GetOptions() == 1;
    end
  }
};

---@param npcName string
---@param gossipConfig NpcGossipConfig
---@param elementData table
---@return boolean
local function CheckOption(npcName, gossipConfig, elementData)
  if (not elementData or not elementData.info) then
    return false;
  end

  if (npcName ~= gossipConfig.npcName) then
    return false;
  end

  if (not UtilityHub.Database.global.options[gossipConfig.addonConfigOption]) then
    return false;
  end

  if (gossipConfig.ExtraChecks and not gossipConfig.ExtraChecks(npcName, gossipConfig, elementData)) then
    return false;
  end

  -- Final checks if the dialog is the right one, first for ID, second for text
  if (gossipConfig.gossipOptionID == elementData.info.gossipOptionID) then
    return true;
  end

  if (elementData.info.name == gossipConfig.dialogText) then
    return true;
  end

  return false;
end

---@param frame SimpleFrame
---@param text string
local function SetConfirmPopupToButton(frame, text)
  frame.OldOnClick = frame:GetScript("OnClick");
  frame:SetScript("OnClick", function(self, mouseButton)
    -- Show confirmation
    StaticPopupDialogs["GOSSIP_CONFIRM_PRECLICK"] = {
      text = text,
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        C_GossipInfo.SelectOptionByIndex(frame:GetID());
      end,
      OnCancel = function() end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
    }

    StaticPopup_Show("GOSSIP_CONFIRM_PRECLICK");
  end);

  tinsert(changedFrames, frame);
end

EventRegistry:RegisterFrameEventAndCallback("GOSSIP_SHOW", function()
  if (not GossipFrame:IsShown()) then
    return;
  end

  GossipFrame.GreetingPanel.ScrollBox:ForEachFrame(function(frame, elementData)
    if (not elementData or not elementData.info) then
      return;
    end

    local npcName = UnitName("npc");

    for _, gossipConfig in ipairs(dialogActionConfigs) do
      if (CheckOption(npcName, gossipConfig, elementData)) then
        if (gossipConfig.action == DIALOG_ACTION_TYPE.CONFIRM and gossipConfig.confirmText) then
          SetConfirmPopupToButton(frame, gossipConfig.confirmText);
        else
          C_GossipInfo.SelectOptionByIndex(elementData.info.orderIndex);
        end
        return;
      end
    end
  end);
end);

EventRegistry:RegisterFrameEventAndCallback("GOSSIP_CLOSED", function()
  for _, frame in ipairs(changedFrames) do
    if (frame.OldOnClick) then
      frame:SetScript("OnClick", frame.OldOnClick);
      frame.OldOnClick = nil;
    end
  end

  changedFrames = {};
end);
