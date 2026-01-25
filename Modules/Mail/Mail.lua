local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Mail';
---@class Mail
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);
---@diagnostic disable-next-line: undefined-field
---@type Preset
local PresetModule;
---@type Characters
local CharactersModule;

UH.Events:RegisterCallback("PLAYER_GUILD_UPDATE", function(_, name)
  Module:UpdateMailButtons();
end);

function Module:CreateMailIconButtons()
  function CreateNewPresetButton(previousFrame)
    -- New
    MailFrame.NewPresetButton = UH.UTILS:CreateIconButton(MailFrame, UH.Helpers:ApplyPrefix("NewPresetButton"));
    if (previousFrame) then
      MailFrame.NewPresetButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      MailFrame.NewPresetButton:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    end
    MailFrame.NewPresetButton.baseTextureRef:SetTexture("Interface/GuildBankFrame/UI-GuildBankFrame-NewTab");

    -- Events
    MailFrame.NewPresetButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
      PresetModule:ToggleNewPresetFrame();
    end);
    MailFrame.NewPresetButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("New preset", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.NewPresetButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);

    return MailFrame.NewPresetButton;
  end

  function CreateLoadPresetButton(previousFrame)
    -- Load
    MailFrame.LoadPresetButton = UH.UTILS:CreateIconButton(MailFrame, UH.Helpers:ApplyPrefix("LoadPresetButton"));
    if (previousFrame) then
      MailFrame.LoadPresetButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      MailFrame.LoadPresetButton:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    end
    local iconTexture = MailFrame.LoadPresetButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Calendar\\MoreArrow.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(30, 30);
    iconTexture:SetPoint("CENTER", MailFrame.LoadPresetButton, "CENTER", 1, -5);
    MailFrame.LoadPresetButton:SetFrameLevel(MailFrame.LoadPresetButton:GetFrameLevel() + 1);

    MailFrame.LoadPresetButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.LoadPresetButton.menuMixin = MenuStyle2Mixin;
    MailFrame.LoadPresetButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.LoadPresetButton.menuPoint,
      MailFrame.LoadPresetButton, MailFrame.LoadPresetButton.menuRelativePoint, MailFrame.LoadPresetButton.menuPointX,
      MailFrame.LoadPresetButton.menuPointY));

    -- Events
    MailFrame.LoadPresetButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Load preset", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.LoadPresetButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.LoadPresetButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.LoadPresetButton:SetupMenu(PresetModule:GetLoadPresetGeneratorFunction());

    return MailFrame.LoadPresetButton;
  end

  function CreateManagePresetButton(previousFrame)
    -- Manage
    MailFrame.ManagePresetButton = UH.UTILS:CreateIconButton(MailFrame, UH.Helpers:ApplyPrefix("ManagePresetButton"));
    MailFrame.ManagePresetButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    local iconTexture = MailFrame.ManagePresetButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Buttons\\UI-OptionsButton.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", MailFrame.ManagePresetButton, "CENTER", 0, 0);
    MailFrame.ManagePresetButton:SetFrameLevel(MailFrame.ManagePresetButton:GetFrameLevel() + 1);

    MailFrame.ManagePresetButton.menuMixin = MenuStyle2Mixin;
    MailFrame.ManagePresetButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.ManagePresetButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.ManagePresetButton.menuPoint,
      MailFrame.ManagePresetButton, MailFrame.ManagePresetButton.menuRelativePoint,
      MailFrame.ManagePresetButton.menuPointX, MailFrame.ManagePresetButton.menuPointY));

    -- Events
    MailFrame.ManagePresetButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Manage preset", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.ManagePresetButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.ManagePresetButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.ManagePresetButton:SetupMenu(PresetModule:GetManagePresetGeneratorFunction());

    return MailFrame.ManagePresetButton;
  end

  function CreateCharactersButton(previousFrame)
    MailFrame.CharactersButton = UH.UTILS:CreateIconButton(MailFrame, UH.Helpers:ApplyPrefix("CharactersButton"));
    if (previousFrame) then
      MailFrame.CharactersButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      MailFrame.CharactersButton:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    end
    local iconTexture = MailFrame.CharactersButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetAtlas("UI-HUD-MicroMenu-Housing-Mouseover");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(24, 24);
    iconTexture:SetPoint("CENTER", MailFrame.CharactersButton, "CENTER", 0, 0);
    MailFrame.CharactersButton:SetFrameLevel(MailFrame.CharactersButton:GetFrameLevel() + 1);

    MailFrame.CharactersButton.menuMixin = MenuStyle2Mixin;
    MailFrame.CharactersButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.CharactersButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.CharactersButton.menuPoint,
      MailFrame.CharactersButton, MailFrame.CharactersButton.menuRelativePoint,
      MailFrame.CharactersButton.menuPointX, MailFrame.CharactersButton.menuPointY));

    -- Events
    MailFrame.CharactersButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Account characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.CharactersButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.CharactersButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.CharactersButton:SetupMenu(CharactersModule:GetAccountCharactersGeneratorFunction());

    return MailFrame.CharactersButton;
  end

  function CreateConfigEmailButton(previousFrame)
    MailFrame.OpenConfigEmailButton = UH.UTILS:CreateIconButton(MailFrame,
      UH.Helpers:ApplyPrefix("OpenConfigEmailButton"));
    MailFrame.OpenConfigEmailButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    local iconTexture = MailFrame.OpenConfigEmailButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\Buttons\\UI-OptionsButton.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", MailFrame.OpenConfigEmailButton, "CENTER", 0, 0);
    MailFrame.OpenConfigEmailButton:SetFrameLevel(MailFrame.OpenConfigEmailButton:GetFrameLevel() + 1);

    -- Events
    MailFrame.OpenConfigEmailButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Open configuration", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.OpenConfigEmailButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.OpenConfigEmailButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);

      if (UH.AceConfigDialog.OpenFrames[ADDON_NAME .. "_Mail"]) then
        UH.AceConfigDialog:Close(ADDON_NAME .. "_Mail");
      else
        UH.AceConfigDialog:Open(ADDON_NAME .. "_Mail");
      end
    end);

    return MailFrame.OpenConfigEmailButton;
  end

  function CreateGuildButton(previousFrame)
    MailFrame.GuildButton = UH.UTILS:CreateIconButton(MailFrame, UH.Helpers:ApplyPrefix("GuildButton"));
    if (previousFrame) then
      MailFrame.GuildButton:SetPoint("BOTTOM", previousFrame, "BOTTOM", 0, -40);
    else
      MailFrame.GuildButton:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    end
    local iconTexture = MailFrame.GuildButton:CreateTexture(nil, "ARTWORK");
    iconTexture:SetTexture("Interface\\CHATFRAME\\UI-ChatConversationIcon.blp");
    iconTexture:ClearAllPoints();
    iconTexture:SetSize(20, 20);
    iconTexture:SetPoint("CENTER", MailFrame.GuildButton, "CENTER", 0, 0);
    MailFrame.GuildButton:SetFrameLevel(MailFrame.GuildButton:GetFrameLevel() + 1);

    MailFrame.GuildButton.menuMixin = MenuStyle2Mixin;
    MailFrame.GuildButton.menuRelativePoint = "TOPRIGHT";
    MailFrame.GuildButton:SetMenuAnchor(AnchorUtil.CreateAnchor(MailFrame.GuildButton.menuPoint,
      MailFrame.GuildButton, MailFrame.GuildButton.menuRelativePoint,
      MailFrame.GuildButton.menuPointX, MailFrame.GuildButton.menuPointY));

    -- Events
    MailFrame.GuildButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:AddLine("Guild characters", nil, nil, nil);
      GameTooltip:Show();
    end);
    MailFrame.GuildButton:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);
    MailFrame.GuildButton:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    end);

    MailFrame.GuildButton:SetupMenu(CharactersModule:GetGuildCharactersGeneratorFunction());

    return MailFrame.GuildButton;
  end

  local previousFrame = nil;

  previousFrame = CreateLoadPresetButton(previousFrame);
  previousFrame = CreateCharactersButton(previousFrame);
  previousFrame = CreateGuildButton(previousFrame);
  previousFrame = CreateConfigEmailButton(previousFrame);

  Module:UpdateMailButtons();
end

function Module:UpdateMailButtons()
  if (MailFrame.GuildButton) then
    if (IsInGuild()) then
      MailFrame.GuildButton:Enable();
    else
      MailFrame.GuildButton:Disable();
    end
  end
end

function Module:OnInitialize()
  EventRegistry:RegisterFrameEventAndCallback("MAIL_SHOW", function()
    if (not UH:GetModule("Mail"):IsEnabled()) then
      ---@diagnostic disable-next-line: undefined-field
      UH:EnableModule("Mail");
    end
  end);
end

function Module:OnEnable()
  PresetModule = UH:GetModule("Preset");
  CharactersModule = UH:GetModule("Characters");
  Module:CreateMailIconButtons();
end
