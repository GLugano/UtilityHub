local ADDON_NAME = ...;
local moduleName = 'Mail';
local Module = UtilityHub.Addon:NewModule(moduleName);
---@type Preset
local PresetModule;
---@type Characters
local CharactersModule;
---@type Item
local ItemModule;

UtilityHub.Events:RegisterCallback("PLAYER_GUILD_UPDATE", function(_, name)
  Module:UpdateMailButtons();
end);

function Module:GetMailAnchorFrame()
  if (UtilityHub.Integration.TSM.Enabled and not MailFrame:IsVisible()) then
    local tsmFrame = UtilityHub.Integration.TSM:GetTSMMailFrame();
    if (tsmFrame) then
      return tsmFrame;
    end
  end

  return MailFrame;
end

function Module:AnchorButtons()
  if (not Module.ButtonContainer) then return end
  local anchor = Module:GetMailAnchorFrame();
  Module.ButtonContainer:ClearAllPoints();

  if (anchor ~= MailFrame) then
    Module.ButtonContainer:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, 0);
  else
    Module.ButtonContainer:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, -60);
  end

  Module.ButtonContainer:SetFrameLevel(anchor:GetFrameLevel() + 5);
end

function Module:CreateMailIconButtons()
  local previousFrame = nil;

  -- Container frame parented to UIParent (independent of MailFrame)
  Module.ButtonContainer = CreateFrame("Frame",
    UtilityHub.Helpers.String:ApplyPrefix("MailButtonContainer"), UIParent);
  Module.ButtonContainer:SetSize(40, 280);
  Module.ButtonContainer:SetFrameStrata("HIGH");
  Module.ButtonContainer:Hide();

  local function SetPosition(frame)
    if (previousFrame) then
      frame:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      frame:SetPoint("TOPLEFT", Module.ButtonContainer, "TOPLEFT", 0, 0);
    end

    previousFrame = frame;
  end

  local function CreateLoadPresetButton()
    -- Load
    Module.LoadPresetButton = UtilityHub.Libs.Utils:CreateIconButton(Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("LoadPresetButton"));
    SetPosition(Module.LoadPresetButton);

    local iconTexture = Module.LoadPresetButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Calendar\\MoreArrow.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(30, 30);
    iconTexture:SetPoint("CENTER", Module.LoadPresetButton, "CENTER", 1, -5);
    Module.LoadPresetButton:SetFrameLevel(Module.LoadPresetButton:GetFrameLevel() + 1);

    Module.LoadPresetButton.menuRelativePoint = "TOPRIGHT";
    Module.LoadPresetButton.menuMixin = MenuStyle2Mixin;
    Module.LoadPresetButton:SetMenuAnchor(AnchorUtil.CreateAnchor(Module.LoadPresetButton.menuPoint,
      Module.LoadPresetButton, Module.LoadPresetButton.menuRelativePoint, Module.LoadPresetButton.menuPointX,
      Module.LoadPresetButton.menuPointY));

    -- Events
    Module.LoadPresetButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Load preset", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.LoadPresetButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.LoadPresetButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    Module.LoadPresetButton:SetupMenu(PresetModule:GetLoadPresetGeneratorFunction());

    return Module.LoadPresetButton;
  end

  local function CreateCharactersButton()
    Module.CharactersButton = UtilityHub.Libs.Utils:CreateIconButton(Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("CharactersButton"));
    SetPosition(Module.CharactersButton);

    local iconTexture = Module.CharactersButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetAtlas("UI-HUD-MicroMenu-Housing-Mouseover");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(24, 24);
    iconTexture:SetPoint("CENTER", Module.CharactersButton, "CENTER", 0, 0);
    Module.CharactersButton:SetFrameLevel(Module.CharactersButton:GetFrameLevel() + 1);

    Module.CharactersButton.menuRelativePoint = "TOPRIGHT";
    Module.CharactersButton.menuMixin = MenuStyle2Mixin;
    Module.CharactersButton:SetMenuAnchor(AnchorUtil.CreateAnchor(Module.CharactersButton.menuPoint,
      Module.CharactersButton, Module.CharactersButton.menuRelativePoint,
      Module.CharactersButton.menuPointX, Module.CharactersButton.menuPointY));

    -- Events
    Module.CharactersButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Account characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.CharactersButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.CharactersButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    Module.CharactersButton:SetupMenu(CharactersModule:GetAccountCharactersGeneratorFunction());

    return Module.CharactersButton;
  end

  local function CreateHistoryButton()
    Module.HistoryButton = UtilityHub.Libs.Utils:CreateIconButton(Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("HistoryButton"));
    SetPosition(Module.HistoryButton);

    local iconTexture = Module.HistoryButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", Module.HistoryButton, "CENTER", 0, 0);
    Module.HistoryButton:SetFrameLevel(Module.HistoryButton:GetFrameLevel() + 1);

    Module.HistoryButton.menuMixin = MenuStyle2Mixin;
    Module.HistoryButton.menuRelativePoint = "TOPRIGHT";
    Module.HistoryButton:SetMenuAnchor(AnchorUtil.CreateAnchor(Module.HistoryButton.menuPoint,
      Module.HistoryButton, Module.HistoryButton.menuRelativePoint,
      Module.HistoryButton.menuPointX, Module.HistoryButton.menuPointY));

    -- Events
    Module.HistoryButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Recently sent to", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.HistoryButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.HistoryButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    Module.HistoryButton:SetupMenu(Module:GetHistoryGeneratorFunction());

    return Module.HistoryButton;
  end

  local function CreateConfigEmailButton()
    Module.OpenConfigEmailButton = UtilityHub.Libs.Utils:CreateIconButton(Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("OpenConfigEmailButton"));
    SetPosition(Module.OpenConfigEmailButton);

    local iconTexture = Module.OpenConfigEmailButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Buttons\\UI-OptionsButton.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", Module.OpenConfigEmailButton, "CENTER", 0, 0);
    Module.OpenConfigEmailButton:SetFrameLevel(Module.OpenConfigEmailButton:GetFrameLevel() + 1);

    -- Events
    Module.OpenConfigEmailButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Open configuration", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.OpenConfigEmailButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.OpenConfigEmailButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
      -- Open main settings and show Mail page
      UtilityHub.GameOptions.OpenConfig("mail");
    end);

    return Module.OpenConfigEmailButton;
  end

  local function CreateGuildButton()
    Module.GuildButton = UtilityHub.Libs.Utils:CreateIconButton(
      Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("GuildButton")
    );
    SetPosition(Module.GuildButton);

    local iconTexture = Module.GuildButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\CHATFRAME\\UI-ChatConversationIcon.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", Module.GuildButton, "CENTER", 0, 0);
    Module.GuildButton:SetFrameLevel(Module.GuildButton:GetFrameLevel() + 1);

    Module.GuildButton.menuMixin = MenuStyle2Mixin;
    Module.GuildButton.menuRelativePoint = "TOPRIGHT";
    Module.GuildButton:SetMenuAnchor(AnchorUtil.CreateAnchor(Module.GuildButton.menuPoint,
      Module.GuildButton, Module.GuildButton.menuRelativePoint,
      Module.GuildButton.menuPointX, Module.GuildButton.menuPointY));

    -- Events
    Module.GuildButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Guild characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.GuildButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.GuildButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    Module.GuildButton:SetupMenu(CharactersModule:GetGuildCharactersGeneratorFunction());

    return Module.GuildButton;
  end

  local function CreateItemClassButton()
    -- Load
    Module.ItemTypesButton = UtilityHub.Libs.Utils:CreateIconButton(Module.ButtonContainer,
      UtilityHub.Helpers.String:ApplyPrefix("ItemTypesButton"));
    SetPosition(Module.ItemTypesButton);

    local iconTexture = Module.ItemTypesButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetAtlas("legionmission-icon-currency");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(30, 30);
    iconTexture:SetPoint("CENTER", Module.ItemTypesButton, "CENTER", 1, 0);
    Module.ItemTypesButton:SetFrameLevel(Module.ItemTypesButton:GetFrameLevel() + 1);

    Module.ItemTypesButton.menuRelativePoint = "TOPRIGHT";
    Module.ItemTypesButton.menuMixin = MenuStyle2Mixin;
    Module.ItemTypesButton:SetMenuAnchor(
      AnchorUtil.CreateAnchor(
        Module.ItemTypesButton.menuPoint,
        Module.ItemTypesButton,
        Module.ItemTypesButton.menuRelativePoint,
        Module.ItemTypesButton.menuPointX,
        Module.ItemTypesButton.menuPointY
      )
    );

    -- Events
    Module.ItemTypesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Item class/subclass", nil, nil, nil);
      GameTooltip:Show();
    end);
    Module.ItemTypesButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    Module.ItemTypesButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    Module.ItemTypesButton:SetupMenu(ItemModule:GetLoadItemGeneratorFunction());

    return Module.ItemTypesButton;
  end

  CreateLoadPresetButton();
  CreateItemClassButton();
  CreateCharactersButton();
  CreateGuildButton();
  CreateHistoryButton();
  CreateConfigEmailButton();

  Module:UpdateMailButtons();
end

function Module:GetLongestHistoryNameWidth()
  if (not Module.historyMeasureFS) then
    Module.historyMeasureFS = UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    Module.historyMeasureFS:Hide();
  end

  local maxWidth = 0;
  for _, name in ipairs(UtilityHub.Helpers.Mail:GetHistory()) do
    Module.historyMeasureFS:SetText(name);
    local w = Module.historyMeasureFS:GetStringWidth();
    if (w > maxWidth) then
      maxWidth = w;
    end
  end

  return maxWidth;
end

function Module:GetHistoryGeneratorFunction()
  return function(dropdown, rootDescription)
    local history = UtilityHub.Helpers.Mail:GetHistory();

    if (#history == 0) then
      rootDescription:CreateTitle("No history yet");
      return;
    end

    -- Fit menu width to longest name + left margin + × button + right margin
    local nameWidth = Module:GetLongestHistoryNameWidth();
    rootDescription:SetMinimumWidth(nameWidth + 52);

    for i, name in ipairs(history) do
      local button = rootDescription:CreateButton(name, function()
        UtilityHub.Helpers.Mail:OpenSendMailTab(function()
          UtilityHub.Helpers.Mail:SetRecipient(name);
        end);
      end);

      button:AddInitializer(function(btn, description, menu)
        local xBtn = btn._uhHistoryDeleteBtn;
        if (not xBtn) then
          xBtn = CreateFrame("Button", nil, btn);
          xBtn:SetSize(20, 20);
          xBtn:SetPoint("RIGHT", btn, "RIGHT", -4, 0);
          xBtn:SetFrameLevel(btn:GetFrameLevel() + 2);

          local fs = xBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal");
          fs:SetAllPoints();
          fs:SetText("|cffff4444×|r");

          xBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:AddLine("Remove from history");
            GameTooltip:Show();
          end);
          xBtn:SetScript("OnLeave", function(self)
            if (GameTooltip:IsOwned(self)) then
              GameTooltip:Hide();
            end
          end);

          -- Hide when the parent frame is recycled by another menu
          btn:HookScript("OnHide", function()
            if (btn._uhHistoryDeleteBtn) then
              btn._uhHistoryDeleteBtn:Hide();
            end
          end);

          btn._uhHistoryDeleteBtn = xBtn;
        end

        xBtn:Show();

        -- Always update click handler with current index (frame may be reused)
        xBtn:SetScript("OnClick", function(self)
          UtilityHub.Helpers.Mail:RemoveFromHistory(i);
          Menu.GetManager():CloseMenus();
        end);

        return nil, 20;
      end);
    end
  end;
end

function Module:UpdateMailButtons()
  if (Module.GuildButton) then
    if (IsInGuild()) then
      Module.GuildButton:Enable();
    else
      Module.GuildButton:Disable();
    end
  end
end

function Module:OnInitialize()
  EventRegistry:RegisterFrameEventAndCallback("MAIL_SHOW", function()
    if (not UtilityHub.Addon:GetModule("Mail"):IsEnabled()) then
      UtilityHub.Addon:EnableModule("Mail");
    end

    if (Module.ButtonContainer) then
      Module.ButtonContainer:Show();
      -- Delay for TSM to have time to create its frame
      C_Timer.After(0.15, function()
        Module:AnchorButtons();
      end);
    end
  end);

  -- Capture recipient before SendMailFrame_SendMail returns (fires before MAIL_SEND_SUCCESS resets the field)
  hooksecurefunc("SendMailFrame_SendMail", function()
    Module.pendingRecipient = SendMailNameEditBox:GetText();
  end);

  -- MAIL_SEND_SUCCESS fires after SendMailFrame_Reset clears SendMailNameEditBox.
  -- Priority: hook capture (Blizzard UI) > SetRecipient cache (TSM) > field text (fallback)
  EventRegistry:RegisterFrameEventAndCallback("MAIL_SEND_SUCCESS", function()
    local recipient = Module.pendingRecipient
        or UtilityHub.Helpers.Mail.lastRecipient
        or SendMailNameEditBox:GetText();
    Module.pendingRecipient = nil;
    UtilityHub.Helpers.Mail.lastRecipient = nil;
    if (recipient and recipient ~= "") then
      UtilityHub.Helpers.Mail:AddToHistory(recipient);
    end
  end);

  MailFrame:HookScript("OnHide", function()
    if (not Module.ButtonContainer) then return end

    if (UtilityHub.Integration.TSM.Enabled) then
      -- Delay to give TSM time to show and position its frame
      C_Timer.After(0.3, function()
        if (not Module.ButtonContainer:IsShown()) then return end

        local tsmFrame = UtilityHub.Integration.TSM:GetTSMMailFrame();

        if (tsmFrame) then
          Module:AnchorButtons();

          -- Re-anchor after TSM finishes layout
          C_Timer.After(0.3, function()
            Module:AnchorButtons();
          end);

          -- Hook TSM frame OnHide to catch when TSM closes
          if (not tsmFrame.uhHooked) then
            tsmFrame:HookScript("OnHide", function()
              if (Module.ButtonContainer) then
                Module.ButtonContainer:Hide();
                UtilityHub.Integration.TSM.mailFrame = nil;
              end
            end);
            tsmFrame.uhHooked = true;
          end
          return;
        end

        Module.ButtonContainer:Hide();
        UtilityHub.Integration.TSM.mailFrame = nil;
      end);
      return;
    end

    Module.ButtonContainer:Hide();
    UtilityHub.Integration.TSM.mailFrame = nil;
  end);
end

function Module:OnEnable()
  PresetModule = UtilityHub.Addon:GetModule("Preset");
  CharactersModule = UtilityHub.Addon:GetModule("Characters");
  ItemModule = UtilityHub.Addon:GetModule("Item");
  Module:CreateMailIconButtons();
end
