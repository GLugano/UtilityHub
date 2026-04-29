local changedFrames = {};

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

    if (
          npcName == "Tal"
          and elementData.info.name == "Can you take me to Orgrimmar?"
          and UtilityHub.Database.global.options.askBeforeFlyingFromTBtoORGFromOption
        ) then
      SetConfirmPopupToButton(
        frame,
        "You really want to go to Orgrimmar?"
      );
    elseif (
          npcName == "Thysta"
          and elementData.info.name == "Can you take me to Stonard?"
          and UtilityHub.Database.global.options.askBeforeFlyingFromGromgolToStonardFromOption
        ) then
      SetConfirmPopupToButton(
        frame,
        "You really want to go to Stonard?"
      );
    elseif (
          npcName == "Craftsman Wilhelm"
          and elementData.info.gossipOptionID == 117482
          and #C_GossipInfo.GetOptions() == 1
          and UtilityHub.Database.global.options.automaticOpenMerchantFrameLHCBlacksmith
        ) then
      C_GossipInfo.SelectOptionByIndex(elementData.info.orderIndex);
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
