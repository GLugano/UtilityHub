local moduleName = 'AutoBuy';
---@class AutoBuy
local Module = UtilityHub.Addon:NewModule(moduleName);

---@type boolean
Module.eventRegistered = false;

function Module:SearchAndBuyItems()
  local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};

  if (#autoBuyList == 0) then
    return;
  end

  local freeBagSlots = UtilityHub.Helpers.Item:GetFreeBagSlots();
  local purchasedItems = {};
  local playerName = UnitName("player");
  local playerClass = UnitClassBase("player");

  -- Iterate through autoBuyList in order
  for _, itemData in ipairs(autoBuyList) do
    local boughtItems;
    boughtItems, freeBagSlots = Module:FindAndBuyItem(itemData, freeBagSlots);
    tAppendAll(purchasedItems, boughtItems);
  end

  -- Consolidated notification
  if (#purchasedItems > 0) then
    if (#purchasedItems == 1) then
      UtilityHub.Helpers.Notification:ShowNotification("Bought: " .. purchasedItems[1]);
    else
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Bought %d items", #purchasedItems)
      );
    end
  end
end

---comment
---@param itemMerchantIndex number
---@param quantityToBuy number
---@param freeBagSlots number
---@param isPartial? boolean
---@return string[], number
function Module:BuyItemByStack(
    itemMerchantIndex,
    quantityToBuy,
    freeBagSlots,
    isPartial
)
  local itemName, _, _, stackCount = GetMerchantItemInfo(itemMerchantIndex);
  ---@type number
  local totalBought = 0;
  local remainingToBuy = quantityToBuy;
  local purchasedItems = {};

  while (remainingToBuy > 0 and freeBagSlots > 0) do
    local buyAmount = math.min(remainingToBuy, stackCount);
    BuyMerchantItem(itemMerchantIndex, buyAmount);
    totalBought = totalBought + buyAmount;
    remainingToBuy = remainingToBuy - buyAmount;
    freeBagSlots = freeBagSlots - 1;
  end

  local pattern = "%s x%d";

  if (isPartial) then
    pattern = pattern .. " (partial)";
  end

  if (totalBought > 0) then
    tinsert(purchasedItems, string.format(pattern, itemName, totalBought));
  end

  return purchasedItems, freeBagSlots;
end

---@param itemData AutoBuyItem
---@param freeBagSlots number
---@return string[], number
function Module:FindAndBuyItem(itemData, freeBagSlots)
  ---@param itemID any
  ---@return number?
  local function FindMerchantIndex(itemID)
    for i = 1, GetMerchantNumItems() do
      if (GetMerchantItemID(i) == itemID) then
        return i;
      end
    end

    return nil;
  end

  local itemID = tonumber(string.match(itemData.itemLink, "item:(%d+):")) or nil;
  ---@type string[]
  local purchasedItems = {};

  if (not itemID) then
    return purchasedItems, freeBagSlots;
  end

  local i = FindMerchantIndex(itemID);

  -- Item doesn't exist in the current merchant
  if (i == nil) then
    return purchasedItems, freeBagSlots;
  end

  local _, _, price, stackCount = GetMerchantItemInfo(i);
  local unitPrice = price / stackCount;

  ---@type number
  local quantityToBuy = 0;

  if (itemData.quantity == 1) then
    -- Buy once mode: just buy 1
    quantityToBuy = 1;
  else
    -- Restock mode: calculate deficit
    local currentCount = UtilityHub.Helpers.Item:GetItemCount(itemID, true);
    local deficit = itemData.quantity - currentCount;

    if (deficit > 0) then
      quantityToBuy = deficit;
    end
  end

  -- If we need to buy something
  if (quantityToBuy > 0) then
    local totalCost = unitPrice * quantityToBuy;
    local slotsNeeded = math.ceil(quantityToBuy / stackCount);

    local canAfford = (GetMoney() >= totalCost);
    local priceTooHigh = unitPrice >= MERCHANT_HIGH_PRICE_COST;
    local hasSpace = freeBagSlots >= slotsNeeded;
    local itemName = C_Item.GetItemInfo(itemData.itemLink) or itemData.itemLink;

    if (not hasSpace) then
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Insufficient bag space for %s", itemName)
      );
    elseif (priceTooHigh) then
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Price of %s is too high", itemName)
      );
    elseif (not canAfford) then
      -- Partial buy: buy maximum possible (only for restock mode)
      if (itemData.quantity > 1) then
        local maxAffordable = math.floor(GetMoney() / unitPrice);

        if (maxAffordable > 0 and maxAffordable < quantityToBuy) then
          local boughtItems;
          boughtItems, freeBagSlots = Module:BuyItemByStack(
            i,
            maxAffordable,
            freeBagSlots,
            true
          );

          tAppendAll(purchasedItems, boughtItems);
        else
          UtilityHub.Helpers.Notification:ShowNotification(
            string.format("Insufficient gold for %s", itemName)
          );
        end
      else
        UtilityHub.Helpers.Notification:ShowNotification(
          string.format("Insufficient gold for %s", itemName)
        );
      end
    else
      local boughtItems;
      boughtItems, freeBagSlots = Module:BuyItemByStack(i, quantityToBuy, freeBagSlots);

      tAppendAll(purchasedItems, boughtItems);
    end
  end

  return purchasedItems, freeBagSlots;
end

function Module:OnEnable()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("MERCHANT_SHOW", function()
    if (not UtilityHub.Addon:GetModule("AutoBuy"):IsEnabled()) then
      return;
    end

    -- Skip the buy proccess by holding
    if (IsShiftKeyDown()) then
      return
    end

    Module:SearchAndBuyItems();
  end);
end
