function MDH:CreateMailIconButtons()
    if (MDH.MailIconButton) then
        return;
    end

    -- New
    MailFrame.NewPresetButton = MDH:CreateIconButton(MailFrame, MDH:ApplyPrefix("NewPresetButton"));
    MailFrame.NewPresetButton:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 2, -60);
    MailFrame.NewPresetButton.baseTextureRef:SetTexture("Interface/GuildBankFrame/UI-GuildBankFrame-NewTab");

    -- Events
    MailFrame.NewPresetButton:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
        MDH:ToggleNewPresetFrame();
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

    -- Load
    MailFrame.LoadPresetButton = MDH:CreateIconButton(MailFrame, MDH:ApplyPrefix("LoadPresetButton"));
    MailFrame.LoadPresetButton:SetPoint("BOTTOM", MailFrame.NewPresetButton, "BOTTOM", 0, -40);
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

    MailFrame.LoadPresetButton:SetupMenu(MDH:GetLoadPresetGeneratorFunction());

    -- Manage
    MailFrame.ManagePresetButton = MDH:CreateIconButton(MailFrame, MDH:ApplyPrefix("ManagePresetButton"));
    MailFrame.ManagePresetButton:SetPoint("BOTTOM", MailFrame.NewPresetButton, "BOTTOM", 0, -80);
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

    MailFrame.ManagePresetButton:SetupMenu(MDH:GetManagePresetGeneratorFunction());
end
