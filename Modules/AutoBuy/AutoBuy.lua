local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

Module.eventRegistered = false;

function Module:SearchAndBuyRares()
  local autoBuyList = UH.db.global.options.autoBuyList or {};

  for i = 1, GetMerchantNumItems() do
    local itemID = GetMerchantItemID(i);
    local searchResult = UH.UTILS:ValueInTable(autoBuyList, function(value)
      return itemID == tonumber(string.match(value, "item:(%d+):"));
    end);

    if (searchResult) then
      local _, _, price, stackCount = GetMerchantItemInfo(i);
      local unitPrice = price / stackCount;
      local canAfford = (GetMoney() - unitPrice) > 0;
      local priceTooHigh = unitPrice >= MERCHANT_HIGH_PRICE_COST;

      if (not canAfford) then
        UH.Helpers:ShowNotification("Doesn't have enough money for " .. searchResult);
      elseif (not priceTooHigh) then
        UH.Helpers:ShowNotification("The price of " ..
        searchResult .. " is too high (would give a high price popup warn)");
      end

      if (canAfford and not priceTooHigh) then
        BuyMerchantItem(i, 1);
        UH.Helpers:ShowNotification("Bought: " .. searchResult);
      end
    end
  end
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UH:GetModule("AutoBuy"):IsEnabled()) then
      return;
    end

    Module:SearchAndBuyRares();
  end);
end
