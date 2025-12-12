local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'AutoBuy';
---@class AutoBuy
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

Module.eventRegistered = false;

function Module:SearchAndBuyRares()
  local autoBuyList = UH.db.global.autoBuyList or {};

  for i = 1, GetMerchantNumItems() do
    local itemLink = GetMerchantItemLink(i);

    if (itemLink) then
      local itemID = tonumber(string.match(itemLink, "item:(%d+):"));

      if (UH.UTILS:ValueInTable(autoBuyList, itemID)) then
        BuyMerchantItem(i, 1);
        UH.Helpers:ShowNotification("Bought: " .. itemLink);
      end
    end
  end
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UH:GetModule("Trade"):IsEnabled()) then
      return;
    end

    Module:SearchAndBuyRares();
  end);
end

-- Events
UH.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name ~= "autoBuy") then
    return;
  end

  if (UH.db.global.options.autoBuy) then
    UH:EnableModule("AutoBuy");
  else
    UH:DisableModule("AutoBuy");
  end
end);
