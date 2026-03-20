---@class GeneralPage
local GeneralPage = {};

---@param parent Frame
---@param labelText string
---@param dbKey string
---@param tooltip? string
---@param previousCheckbox? CheckButton
---@return CheckButton
function GeneralPage:CreateCheckbox(parent, labelText, dbKey, tooltip, previousCheckbox)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
  checkbox:SetSize(24, 24);

  if (previousCheckbox) then
    checkbox:SetPoint("TOPLEFT", previousCheckbox, "BOTTOMLEFT", 0, -10);
  else
    checkbox:SetPoint("TOPLEFT", 20, -20);
  end

  -- Label
  local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
  label:SetText(labelText);

  -- Set initial state
  checkbox:SetChecked(UtilityHub.Database.global.options[dbKey]);

  -- OnClick handler
  checkbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked();
    UtilityHub.Database.global.options[dbKey] = checked;
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", dbKey, checked);
  end);

  -- Tooltip
  if (tooltip) then
    checkbox:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(labelText, 1, 1, 1);
      GameTooltip:AddLine(tooltip, nil, nil, nil, true);
      GameTooltip:Show();
    end);
    checkbox:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
  end

  return checkbox;
end

---@param parent Frame
---@return Frame
function GeneralPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubGeneralPage", parent);

  -- Scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate");
  scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
  scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 0);

  -- Scroll child (content lives here)
  local content = CreateFrame("Frame", nil, scrollFrame);
  content:SetHeight(750);
  content:SetWidth(scrollFrame:GetWidth());
  content:SetClipsChildren(true);
  scrollFrame:SetScrollChild(content);

  -- Keep content width in sync
  scrollFrame:SetScript("OnSizeChanged", function(self, w)
    content:SetWidth(w);
  end);
  scrollFrame:HookScript("OnShow", function(self)
    content:SetWidth(self:GetWidth());
  end);

  -- Title
  local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("General Settings");

  -- Section: Tooltip
  local sectionTooltip = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionTooltip:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20);
  sectionTooltip:SetText("Tooltip");

  local cbTooltip = self:CreateCheckbox(
    content,
    "Simplified stats display",
    "simpleStatsTooltip",
    "Change the way most stats are shown in the tooltip",
    nil
  );
  cbTooltip:SetPoint("TOPLEFT", sectionTooltip, "BOTTOMLEFT", 0, -10);

  -- Section: Trade
  local sectionTrade = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionTrade:SetPoint("TOPLEFT", cbTooltip, "BOTTOMLEFT", 0, -20);
  sectionTrade:SetText("Trade");

  local cbTrade = self:CreateCheckbox(
    content,
    "Extra info frame",
    "tradeExtraInfo",
    "Show extra frame with more info about the person you are trading",
    cbTooltip
  );
  cbTrade:SetPoint("TOPLEFT", sectionTrade, "BOTTOMLEFT", 0, -10);

  -- Section: Daily Quests
  local sectionDaily = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionDaily:SetPoint("TOPLEFT", cbTrade, "BOTTOMLEFT", 0, -20);
  sectionDaily:SetText("Daily Quests");

  local cbDaily = self:CreateCheckbox(
    content,
    "Enable tracking",
    "dailyQuests",
    "Enable tracking of daily quests",
    cbTrade
  );
  cbDaily:SetPoint("TOPLEFT", sectionDaily, "BOTTOMLEFT", 0, -10);

  -- Section: Professions
  local sectionProfessions = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionProfessions:SetPoint("TOPLEFT", cbDaily, "BOTTOMLEFT", 0, -20);
  sectionProfessions:SetText("Professions");

  local cbEnchant = self:CreateCheckbox(
    content,
    "Automatic filter enchants when trading",
    "automaticEnchantFilter",
    "When trading and the enchant frame is open, the filter will be updated when the person you are trading change the item in the non-trade slot",
    cbDaily
  );
  cbEnchant:SetPoint("TOPLEFT", sectionProfessions, "BOTTOMLEFT", 0, -10);

  -- Section: NPCs
  local sectionNPCs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionNPCs:SetPoint("TOPLEFT", cbEnchant, "BOTTOMLEFT", 0, -20);
  sectionNPCs:SetText("NPCs");

  local cbAutoOpenMerchantFrameLHCBlacksmith = self:CreateCheckbox(
    content,
    "Auto open merchant frame with BS in LHC",
    "automaticOpenMerchantFrameLHCBlacksmith",
    "Automatic open the trade window with the blacksmith in Light's Hope Chapel (Craftsman Wilhelm) when there is only one gossip option available",
    cbDaily
  );
  cbAutoOpenMerchantFrameLHCBlacksmith:SetPoint("TOPLEFT", sectionNPCs, "BOTTOMLEFT", 0, -10);

  local cbPopupFlyTBtoOrg = self:CreateCheckbox(
    content,
    "Ask before flying from TB to ORG (option)",
    "askBeforeFlyingFromTBtoORGFromOption",
    "When active, the option that enables you to fly from Thunder Bluff to Orgrimmar will ask first before flying",
    cbAutoOpenMerchantFrameLHCBlacksmith
  );

  -- Section: Cooldowns
  local sectionCooldowns = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionCooldowns:SetPoint("TOPLEFT", cbPopupFlyTBtoOrg, "BOTTOMLEFT", 0, -20);
  sectionCooldowns:SetText("Cooldowns");

  local cbCooldowns = self:CreateCheckbox(
    content,
    "Enable tracking",
    "cooldowns",
    "Enable tracking and listing of all character cooldowns",
    cbPopupFlyTBtoOrg
  );
  cbCooldowns:SetPoint("TOPLEFT", sectionCooldowns, "BOTTOMLEFT", 0, -10);

  local cbCooldownSound = self:CreateCheckbox(
    content,
    "Play sound when ready",
    "cooldownPlaySound",
    "Play sound when a cooldown is ready",
    cbCooldowns
  );

  local cbCooldownCollapsed = self:CreateCheckbox(
    content,
    "Start collapsed",
    "cooldownStartCollapsed",
    "When opening the cooldowns content, all groups will start minimized",
    cbCooldownSound
  );

  local cbCooldownSync = self:CreateCheckbox(
    content,
    "Enable cross-account sync",
    "cooldownSync",
    "Sync cooldown data between multiple WoW accounts via a shared chat channel",
    cbCooldownCollapsed
  );

  -- Sync channel input
  local syncChannelContainer = CreateFrame("Frame", nil, content);
  syncChannelContainer:SetSize(400, 30);
  syncChannelContainer:SetPoint("TOPLEFT", cbCooldownSync, "BOTTOMLEFT", 0, -10);

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

  -- Section: Loot
  local sectionLoot = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionLoot:SetPoint("TOPLEFT", syncChannelContainer, "BOTTOMLEFT", 0, -20);
  sectionLoot:SetText("Loot");

  local cbLootConfirmStrat = self:CreateCheckbox(
    content,
    "Disable loot confirm in Stratholme",
    "disableLootConfirmInStrat",
    "Disable the loot confirm popup while looting in Stratholme while level 70 or higher"
  );
  cbLootConfirmStrat:SetPoint("TOPLEFT", sectionLoot, "BOTTOMLEFT", 0, -10);

  -- Section: LFG
  local sectionLFG = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  sectionLFG:SetPoint("TOPLEFT", cbLootConfirmStrat, "BOTTOMLEFT", 0, -20);
  sectionLFG:SetText("LFG");

  local cbEnteringListedGroupWarning = self:CreateCheckbox(
    content,
    "Show warning when entering an already listed group",
    "showWarningEnteringListedGroupInLFG",
    "When you enter in a group with someone listed in the LFG (Ex: invited someone to enchant), you will be listed too even if the other player leaves, so this will make a warning show in the middle of the screen"
  );
  cbEnteringListedGroupWarning:SetPoint("TOPLEFT", sectionLFG, "BOTTOMLEFT", 0, -10);

  return frame;
end

-- Register page
UtilityHub.OptionsPages.General = GeneralPage;
