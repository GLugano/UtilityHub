local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

function Module:SearchAndBuyRares()
    local rareItems = {
        14468, -- Pattern: Runecloth Bag
        14481, -- Pattern: Runecloth Gloves
        16224, -- Formula: Enchant Cloak - Superior Defense
        14256, -- Felcloth
        14634, -- Recipe: Frost Oil
        32381, -- TBC - Schematic: Fused Wiring
    };

    for i = 1, GetMerchantNumItems() do
        local itemLink = GetMerchantItemLink(i);

        if (itemLink) then
            local itemID = tonumber(string.match(itemLink, "item:(%d+):"));

            if (UH.UTILS:ValueInTable(rareItems, itemID)) then
                BuyMerchantItem(i, 1);
                UH.Helpers:ShowNotification("Bought: " .. itemLink);
            end
        end
    end
end

function Module:OnInitialize()
    EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
        if (not UH:GetModule("Trade"):IsEnabled()) then
            ---@diagnostic disable-next-line: undefined-field
            UH:EnableModule("AutoBuy");
        end

        Module:SearchAndBuyRares();
    end);
end
