MDH.ItemGroupOptions = {
    ["GreenEquipment"] = {
        label = "Green Equipment",
        checkItemBelongsToGroup = function(itemLink)
            local _, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _ = C_Item.GetItemInfo(itemLink);

            -- Check if the item is Green (Quality 2) and is an Equipment type
            if (itemQuality == 2 and (itemType == "Armor" or itemType == "Weapon")) then
                return true;
            end

            return false;
        end
    },
    ["BlueEquipment"] = {
        label = "Blue Equipment",
        checkItemBelongsToGroup = function(itemLink)
            local _, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _ = C_Item.GetItemInfo(itemLink);

            -- Check if the item is Green (Quality 2) and is an Equipment type
            if (itemQuality == 3 and (itemType == "Armor" or itemType == "Weapon")) then
                return true;
            end

            return false;
        end
    },
    ["EssenceElemental"] = {
        label = "Essence/Elemental",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _ = C_Item.GetItemInfo(itemLink);
            local essenceList = {
                -- Water
                "Elemental Water",
                "Globe of Water",
                "Essence of Water",
                -- Fire
                "Elemental Fire",
                "Heart of Fire",
                "Essence of Fire",
                -- Wind
                "Elemental Air",
                "Breath of Wind",
                "Essence of Air",
                -- Earth
                "Elemental Earth",
                "Core of Earth",
                "Essence of Earth",
                -- Undeath
                "Ichor of Undeath",
                "Essence of Undeath",
                -- Living
                "Heart of the Wild",
                "Living Essence"
            };

            return MDH.UTILS:ValueInTable(essenceList, itemName);
        end
    },
    ["Stone"] = {
        label = "Stone",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _ = C_Item.GetItemInfo(itemLink);
            local itemsList = {
                "Rough Stone",
                "Coarse Stone",
                "Heavy Stone",
                "Solid Stone",
                "Dense Stone"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Gem"] = {
        label = "Gem",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                "Malachite",
                "Tigerseye",
                "Small Lustrous Pearl",
                "Shadowgem",
                "Moss Agate",
                "Iridescent Pearl",
                "Lesser Moonstone",
                "Jade",
                "Black Pearl",
                "Golden Pearl",
                "Citrine",
                "Aquamarine",
                "Star Ruby",
                "Blood of the Mountain",
                "Souldarite",
                "Large Opal",
                "Blue Sapphire",
                "Azerothian Diamond",
                "Arcane Crystal",
                "Huge Emerald"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Enchant"] = {
        label = "Enchant",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                -- Dust
                "Strange Dust",
                "Soul Dust",
                "Vision Dust",
                "Dream Dust",
                "Illusion Dust",

                -- Lesser essence
                "Lesser Magic Essence",
                "Lesser Astral Essence",
                "Lesser Mystic Essence",
                "Lesser Nether Essence",
                "Lesser Eternal Essence",

                -- Greater essence
                "Greater Magic Essence",
                "Greater Astral Essence",
                "Greater Mystic Essence",
                "Greater Nether Essence",
                "Greater Eternal Essence",

                -- Shard Small
                "Small Glimmering Shard",
                "Small Glowing Shard",
                "Small Radiant Shard",
                "Small Brilliant Shard",

                -- Shard large
                "Large Glimmering Shard",
                "Large Glowing Shard",
                "Large Radiant Shard",
                "Large Brilliant Shard"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Cloth"] = {
        label = "Cloth",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                -- Cloth
                "Linen Cloth",
                "Wool Cloth",
                "Silk Cloth",
                "Mageweave Cloth",
                "Runecloth",
                "Felcloth",
                "Mooncloth",

                -- Bolt
                "Bolt of Linen Cloth",
                "Bolt of Wool Cloth",
                "Bolt of Silk Cloth",
                "Bolt of Mageweave Cloth",
                "Bolt of Runecloth"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Herb"] = {
        label = "Herb",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                "Peacebloom",
                "Silverleaf",
                "Earthroot",
                "Mageroyal",
                "Briarthorn",
                "Stranglekelp",
                "Bruiseweed",
                "Wild Steelbloom",
                "Grave Moss",
                "Kingsblood",
                "Liferoot",
                "Fadeleaf",
                "Goldthorn",
                "Khadgar's Whisker",
                "Wintersbite",
                "Wildvine",
                "Firebloom",
                "Purple Lotus",
                "Arthas' Tears",
                "Sungrass",
                "Ghost Mushroom",
                "Blindweed",
                "Gromsblood",
                "Dreamfoil",
                "Mountain Silversage",
                "Plaguebloom",
                "Icecap",
                "Black Lotus",
                "Bloodvine"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Consumables"] = {
        label = "Consumables (except mana/health potions)",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 0) then
                return false;
            end

            if (string.find(itemName, "Potion") ~= nil and
                (string.find(itemName, "Mana") ~= nil or string.find(itemName, "Healing") ~= nil)) then
                return false;
            end

            if (itemName == "Supercharged Chronoboon Displacer") then
                return false;
            end

            return true;
        end
    },
    ["Ore"] = {
        label = "Ore",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                -- Normal
                "Copper Ore",
                "Tin Ore",
                "Silver Ore",
                "Iron Ore",
                "Gold Ore",
                "Mithril Ore",
                "Truesilver Ore",
                "Thorium Ore",
                "Dark Iron Ore",
                "Elementium Ore",
                -- Misc
                "Incendite Ore",
                "Lesser Bloodstone Ore"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Bar"] = {
        label = "Bar",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 7) then
                return false;
            end

            local itemsList = {
                "Copper Bar",
                "Tin Bar",
                "Bronze Bar",
                "Silver Bar",
                "Iron Bar",
                "Steel Bar",
                "Gold Bar",
                "Mithril Bar",
                "Truesilver Bar",
                "Thorium Bar",
                "Dark Iron Bar",
                "Enchanted Thorium Bar",
                "Arcanite Bar",
                "Elementium Bar"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Lockbox"] = {
        label = "Lockbox",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 15) then
                return false;
            end

            local itemsList = {
                -- Junkbox
                "Battered Junkbox",
                "Worn Junkbox",
                "Sturdy Junkbox",
                "Heavy Junkbox",
                -- Lockbox
                "Ornate Bronze Lockbox",
                "Heavy Bronze Lockbox",
                "Iron Lockbox",
                "Strong Iron Lockbox",
                "Steel Lockbox",
                "Reinforced Steel Lockbox",
                "Mithril Lockbox",
                "Thorium Lockbox",
                "Elementium Lockbox"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    },
    ["Recipe"] = {
        label = "Recipe",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (classID ~= 9) then
                return false;
            end

            return true;
        end
    },
    ["ZgCurrency"] = {
        label = "ZG Currency",
        checkItemBelongsToGroup = function(itemLink)
            local itemName, _, itemQuality, _, _, itemType, itemSubType, _, _, _, _, classID = C_Item.GetItemInfo(
                itemLink);

            if (MDH.UTILS:StringEndsWith(itemName, "Hakkari Bijou")) then
                return true;
            end

            local itemsList = {
                "Bloodscalp Coin",
                "Gurubashi Coin",
                "Hakkari Coin",
                "Razzashi Coin",
                "Sandfury Coin",
                "Skullsplitter Coin",
                "Vilebranch Coin",
                "Witherbark Coin",
                "Zulian Coin"
            };

            return MDH.UTILS:ValueInTable(itemsList, itemName);
        end
    }
};
local temp = {
    items = {},
    itemsExclusion = {}
};
local id = nil;

function MDH:CreateNewPresetFrame()
    local frameHeight = 350;
    MDH.NewPresetFrame = CreateFrame("Frame", MDH.UTILS:ApplyPrefix("NewPresetFrame"), UIParent, "DialogBoxFrame");
    MDH.NewPresetFrame:SetPoint("CENTER", UIParent, "CENTER");
    MDH.NewPresetFrame:SetClampedToScreen(true);
    MDH.NewPresetFrame:SetSize(350, frameHeight);
    MDH.NewPresetFrame:Hide();

    MDH.UTILS:AddMovableToFrame(MDH.NewPresetFrame);

    -- Hide original button
    select(1, MDH.NewPresetFrame:GetChildren()):Hide();

    -- Text
    MDH.NewPresetFrame.TitleRef = MDH.NewPresetFrame:CreateFontString(nil, "OVERLAY");
    MDH.NewPresetFrame.TitleRef:SetFontObject("GameFontHighlight");
    MDH.NewPresetFrame.TitleRef:SetSize(350, 20);
    MDH.NewPresetFrame.TitleRef:SetPoint("CENTER", MDH.NewPresetFrame, "TOP", 0, -30);

    local font, _, flags = MDH.NewPresetFrame.TitleRef:GetFont();

    if (font) then
        MDH.NewPresetFrame.TitleRef:SetFont(font, 16, flags);
    end

    local y = -50;

    -- Name
    local input, label = MDH:CreateFormField("NewPresetInputName", "Name", MDH.NewPresetFrame, y);
    MDH.NewPresetFrame.NameInput = input;
    MDH.NewPresetFrame.NameLabel = label;

    -- To
    y = y - 30;
    input, label = MDH:CreateFormField("NewPresetInputTo", "To", MDH.NewPresetFrame, y);
    MDH.NewPresetFrame.ToInput = input;
    MDH.NewPresetFrame.ToLabel = label;

    -- Scroll Frame parent
    y = y - 30;
    MDH.NewPresetFrame.ScrollFrameParent = CreateFrame("Frame", nil, MDH.NewPresetFrame, "BackdropTemplate");
    MDH.NewPresetFrame.ScrollFrameParent:SetPoint("TOPLEFT", MDH.NewPresetFrame, "TOPLEFT", 12, y);
    MDH.NewPresetFrame.ScrollFrameParent:SetPoint("BOTTOMRIGHT", MDH.NewPresetFrame, "BOTTOMRIGHT", -12, 12 + 50);
    MDH.NewPresetFrame.ScrollFrameParent:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = {
            left = 5,
            right = 5,
            top = 5,
            bottom = 5
        }
    });

    -- Creating tabs
    local tabCustom, tabCustomButton = MDH:CreateNewPresetTab("Custom", 1, "Custom", frameHeight, y);
    local tabItemGroups, tabItemGroupsButton = MDH:CreateNewPresetTab("ItemGroups", 2, "Item Groups", frameHeight, y,
        tabCustomButton);
    local tabExclusions, tabExclusionsButton = MDH:CreateNewPresetTab("Exclusions", 3, "Exclusions", frameHeight, y,
        tabItemGroupsButton);

    -- Customizing tabCustom
    MDH:AddListToTab(tabCustom, "items");

    -- Customizing tabItemGroups
    MDH.NewPresetFrame.checkboxList = {};

    local height = 0;
    local previousRef = nil;

    for key, value in MDH.UTILS:OrderedPairs(MDH.ItemGroupOptions) do
        MDH.NewPresetFrame.checkboxList[key] = MDH:CreateItemGroupOption(key, value.label, previousRef,
            tabItemGroups.ScrollChildFrame);
        previousRef = MDH.NewPresetFrame.checkboxList[key];
        height = height + MDH.NewPresetFrame.checkboxList[key].TextRef:GetStringHeight() + 15;
    end

    tabItemGroups.ScrollChildFrame:SetHeight(height);

    -- Customizing tabExclusions
    MDH:AddListToTab(tabExclusions, "itemsExclusion");

    -- Configure the tabs with the parent frame
    MDH.NewPresetFrame.tabList = {
        tabCustom,
        tabItemGroups,
        tabExclusions
    };
    MDH.NewPresetFrame.ScrollFrameParent.Tabs = {};
    tinsert(MDH.NewPresetFrame.ScrollFrameParent.Tabs, tabCustomButton:GetID(), tabCustomButton);
    tinsert(MDH.NewPresetFrame.ScrollFrameParent.Tabs, tabItemGroupsButton:GetID(), tabItemGroupsButton);
    tinsert(MDH.NewPresetFrame.ScrollFrameParent.Tabs, tabExclusionsButton:GetID(), tabExclusionsButton);
    MDH.NewPresetFrame.ScrollFrameParent.numTabs = MDH.UTILS:TableLength(MDH.NewPresetFrame.ScrollFrameParent.Tabs);

    -- After creating all tabs
    MDH:OnClickTab(tabCustomButton);

    -- Footer
    MDH.NewPresetFrame.CloseButton = CreateFrame("Button", MDH.UTILS:ApplyPrefix("NewPresetFrameCloseButton"),
        MDH.NewPresetFrame, "UIPanelButtonTemplate");
    MDH.NewPresetFrame.CloseButton:SetPoint("BOTTOMRIGHT", MDH.NewPresetFrame, "BOTTOMRIGHT", -10, 10);
    MDH.NewPresetFrame.CloseButton:SetWidth(80);
    MDH.NewPresetFrame.CloseButton:SetText("Close");
    MDH.NewPresetFrame.CloseButton:HookScript("OnClick", function()
        MDH:CloseNewPresetFrame();
    end);

    MDH.NewPresetFrame.SaveButton = CreateFrame("Button", MDH.UTILS:ApplyPrefix("NewPresetFrameSaveButton"),
        MDH.NewPresetFrame, "UIPanelButtonTemplate");
    MDH.NewPresetFrame.SaveButton:SetPoint("RIGHT", MDH.NewPresetFrame.CloseButton, "LEFT", -5, 0);
    MDH.NewPresetFrame.SaveButton:SetWidth(80);
    MDH.NewPresetFrame.SaveButton:SetText("Save");
    MDH.NewPresetFrame.SaveButton:HookScript("OnClick", function()
        MDH:SavePreset();
    end);

    MDH:UpdateNewPresetItemRows(MDH.NewPresetFrame.tabList[1], "items");
    MDH:UpdateNewPresetItemRows(MDH.NewPresetFrame.tabList[3], "itemsExclusion");
end

function MDH:CreateItemGroupOption(key, label, previousRef, parent)
    local checkbox = MDH.UTILS:CreateCheckbox(MDH.UTILS:ApplyPrefix("Checkbox" .. key), parent, label, false, function()
    end);

    if (previousRef) then
        checkbox:SetPoint("TOPLEFT", previousRef, "TOPLEFT", 0, -26);
    else
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2);
    end

    return checkbox;
end

function MDH:CreateNewPresetTab(name, index, label, frameHeight, y, previousTabButton)
    local tab = CreateFrame("Button", MDH.UTILS:ApplyPrefix("NewPresetTab" .. name),
        MDH.NewPresetFrame.ScrollFrameParent, "CharacterFrameTabButtonTemplate");
    tab:SetID(index);
    tab:SetText(label);
    tab:SetScript("OnClick", function(self)
        MDH:OnClickTab(self);
    end);

    if (index == 1) then
        tab:SetPoint("TOPLEFT", MDH.NewPresetFrame.ScrollFrameParent, "BOTTOMLEFT", 5, 3);
    else
        tab:SetPoint("TOPLEFT", previousTabButton, "TOPRIGHT", -14, 0);
    end

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, MDH.NewPresetFrame.ScrollFrameParent,
        "UIPanelScrollFrameTemplate");
    scrollFrame:SetPoint("TOPLEFT", MDH.NewPresetFrame.ScrollFrameParent, "TOPLEFT", 6, -4);
    scrollFrame:SetPoint("BOTTOMRIGHT", MDH.NewPresetFrame.ScrollFrameParent, "BOTTOMRIGHT", -6, 6);
    scrollFrame:Hide();

    -- Events
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local newValue = self:GetVerticalScroll() - (delta * 20);

        if (newValue < 0) then
            newValue = 0;
        elseif (newValue > self:GetVerticalScrollRange()) then
            newValue = self:GetVerticalScrollRange();
        end

        self:SetVerticalScroll(newValue);
    end);

    -- Scroll Child Frame
    scrollFrame.ScrollChildFrame = CreateFrame("Frame", nil, scrollFrame);
    scrollFrame.ScrollChildFrame:SetSize(300, frameHeight - y);
    scrollFrame:SetScrollChild(scrollFrame.ScrollChildFrame);
    scrollFrame.ScrollChildFrame.ItemRows = {};

    -- Scrollbar
    scrollFrame.ScrollBar:ClearAllPoints();
    scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -6, -20);
    scrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -7, 16);

    tab.scrollFrame = scrollFrame;

    return scrollFrame, tab;
end

function MDH:UpdateNewPresetItemRows(tab, tempKey)
    local height = 5;
    local rowHeight = 30;
    local rows = temp[tempKey];
    local scrollChildFrame = tab.ScrollChildFrame;

    -- Hide all rows until reprocessed
    for key, value in pairs(scrollChildFrame.ItemRows) do
        if (value) then
            value:Hide();
        end
    end

    for i, itemLink in ipairs(rows) do
        local itemId = MDH.UTILS:GetItemIDFromLink(itemLink);

        if (itemId) then
            local rowRef = scrollChildFrame.ItemRows[itemId];
            local textRef;

            if (rowRef) then
                textRef = rowRef.TextRef;
            else
                rowRef = CreateFrame("Frame", nil, scrollChildFrame, "BackdropTemplate")
                rowRef:SetSize(308, rowHeight);

                -- Button on the left
                rowRef.RemoveButtonRef = CreateFrame("Button", nil, rowRef, "UIPanelButtonTemplate")
                rowRef.RemoveButtonRef:SetSize(30, rowHeight - 5);
                rowRef.RemoveButtonRef:SetPoint("LEFT", rowRef, "LEFT", 5, 0);
                rowRef.RemoveButtonRef:SetText("X");
                rowRef.RemoveButtonRef:SetScript("OnClick", function()
                    local newTempItems = {};

                    for key, value in pairs(temp[tempKey]) do
                        if (value ~= itemLink) then
                            tinsert(newTempItems, value);
                        end
                    end

                    temp[tempKey] = newTempItems;

                    MDH:UpdateNewPresetItemRows(tab, tempKey);
                end);

                -- Text on the right
                textRef = rowRef:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                textRef:SetPoint("LEFT", rowRef.RemoveButtonRef, "RIGHT", 6, 0);
                rowRef.TextRef = textRef;

                scrollChildFrame.ItemRows[itemId] = rowRef;
            end

            textRef:SetText(itemLink);
            rowRef:Show();
            rowRef:SetPoint("TOP", 0, -((i - 1) * rowHeight));
            height = height + rowHeight;
        end
    end

    if (MDH.UTILS:TableLength(temp[tempKey]) == 0) then
        tab.EmptyText:Show();
    else
        tab.EmptyText:Hide();
    end

    tab.ScrollChildFrame:SetHeight(height);
end

function MDH:AddListToTab(tab, tempKey)
    tab.EmptyText = tab:CreateFontString(nil, "OVERLAY");
    tab.EmptyText:SetFontObject("GameFontHighlight");
    tab.EmptyText:SetSize(200, 40);
    tab.EmptyText:SetPoint("CENTER", tab, "CENTER", 0, 0);
    tab.EmptyText:SetText("Drop items in this area do add to the list");
    tab.EmptyText:Hide();

    tab:SetScript("OnMouseUp", function()
        local _, _, itemLink = GetCursorInfo();

        if (itemLink and not MDH.UTILS:ValueInTable(temp[tempKey], itemLink)) then
            tinsert(temp[tempKey], itemLink);
            MDH:UpdateNewPresetItemRows(tab, tempKey);
            C_Timer.After(0.01, function()
                tab:SetVerticalScroll(tab:GetVerticalScrollRange());
            end);
        end

        ClearCursor();
    end);
end

function MDH:OnClickTab(tabButton)
    PanelTemplates_SetTab(tabButton:GetParent(), tabButton:GetID());

    for key, value in pairs(MDH.NewPresetFrame.tabList) do
        value:Hide();
    end

    tabButton.scrollFrame:Show();
end

function MDH:UpdateWithRegister(register, registerID)
    MDH.NewPresetFrame.TitleRef:SetText(register and "Edit preset" or "New preset");

    if (not register) then
        register = {};
        id = nil;
    else
        id = registerID;
    end

    MDH.NewPresetFrame.NameInput:SetText(register.name or "");
    MDH.NewPresetFrame.ToInput:SetText(register.to or "");
    temp.items = MDH.UTILS:ShallowCopyTable(register.custom or {});
    temp.itemsExclusion = MDH.UTILS:ShallowCopyTable(register.exclusion or {});

    -- Clear all previous checked
    for key, value in pairs(MDH.ItemGroupOptions) do
        MDH.NewPresetFrame.checkboxList[key]:SetChecked(false);
    end

    -- Check if there is itemGroups in the register
    if (register.itemGroups) then
        for key, value in pairs(register.itemGroups) do
            MDH.NewPresetFrame.checkboxList[key]:SetChecked(value or false);
        end
    end

    -- Reset to the first tab
    MDH:OnClickTab(MDH.NewPresetFrame.ScrollFrameParent.Tabs[1]);
    MDH:UpdateNewPresetItemRows(MDH.NewPresetFrame.tabList[1], "items");
    MDH:UpdateNewPresetItemRows(MDH.NewPresetFrame.tabList[3], "itemsExclusion");
end

function MDH:OpenNewPresetFrame(register, registerID)
    if (not MDH.NewPresetFrame) then
        MDH:CreateNewPresetFrame();
    end

    MDH:UpdateWithRegister(register, registerID);
    MDH.NewPresetFrame:Show();
end

function MDH:CloseNewPresetFrame()
    if (not MDH.NewPresetFrame) then
        return;
    end

    MDH:UpdateWithRegister({});
    MDH.NewPresetFrame:Hide();
end

function MDH:ToggleNewPresetFrame()
    if (not MDH.NewPresetFrame) then
        MDH:CreateNewPresetFrame();
    end

    if (MDH.NewPresetFrame:IsShown()) then
        MDH:CloseNewPresetFrame();
    else
        MDH:OpenNewPresetFrame();
    end
end

function MDH:CreateFormField(name, labelText, parent, y)
    local label = parent:CreateFontString(nil, "OVERLAY");
    label:SetFontObject("GameFontHighlight");
    label:SetSize(80, 20);
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y - 6);
    label:SetText(labelText);
    label:SetJustifyH("LEFT");

    local input = CreateFrame("EditBox", MDH.UTILS:ApplyPrefix(name), parent, "InputBoxTemplate");
    input:SetSize(180, 30);
    input:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, y);
    input:SetAutoFocus(false);
    input:SetText("");
    input:SetCursorPosition(0);

    return input, label;
end

function MDH:SavePreset()
    local preset = {
        name = MDH.NewPresetFrame.NameInput:GetText(),
        to = MDH.NewPresetFrame.ToInput:GetText(),
        custom = temp.items,
        itemGroups = {},
        exclusion = temp.itemsExclusion
    };

    if (not preset.name or #preset.name < 1) then
        MDH.NewPresetFrame.NameInput:SetFocus();
        MDH.UTILS:ShowChatNotification("Field Name is required");
        return;
    end

    if (not preset.to or #preset.to < 1) then
        MDH.NewPresetFrame.ToInput:SetFocus();
        MDH.UTILS:ShowChatNotification("Field To is required");
        return;
    end

    local atLeastOneCheck = false;

    for key, value in pairs(MDH.ItemGroupOptions) do
        preset.itemGroups[key] = MDH.NewPresetFrame.checkboxList[key]:GetChecked();

        if (preset.itemGroups[key]) then
            atLeastOneCheck = true;
        end
    end

    if (MDH.UTILS:TableLength(preset.custom) == 0 and (not atLeastOneCheck)) then
        MDH.UTILS:ShowChatNotification("At least one rule is required");
        -- Warn that at least one config needs to be selected for a preset to be valid
        return;
    end

    -- Save
    if (id) then
        MDH.db.global.presets[id] = preset;
    else
        tinsert(MDH.db.global.presets, preset);
    end

    MDH:CloseNewPresetFrame();
end
