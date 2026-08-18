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

  local purchasedItems = {};
  local playerName = UnitName("player");
  local playerClass = UnitClassBase("player");

  -- Iterate through autoBuyList in order
  for _, itemData in ipairs(autoBuyList) do
    local scope = itemData.scope or UtilityHub.Enums.AutoBuyScope.ACCOUNT;
    local inScope = true;

    if (scope == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
      inScope = (itemData.scopeValue == playerName);
    elseif (scope == UtilityHub.Enums.AutoBuyScope.CLASS) then
      inScope = (itemData.scopeValue == playerClass);
    end

    if (inScope) then
      local boughtItems;
      boughtItems = Module:FindAndBuyItem(itemData);
      tAppendAll(purchasedItems, boughtItems);
    end
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
---@param itemQuantityList number[]
---@return string[] purchasedItems
function Module:BuyItemQuantityListByStack(itemMerchantIndex, itemQuantityList)
  local itemName, _, _, _, availableCount = GetMerchantItemInfo(itemMerchantIndex);
  ---@type number
  local totalBought = 0;
  local purchasedItems = {};
  local maxStack = GetMerchantItemMaxStack(itemMerchantIndex);

  for i, itemQuantity in ipairs(itemQuantityList) do
    if (availableCount == -1) then
      availableCount = maxStack;
    end

    BuyMerchantItem(itemMerchantIndex, itemQuantity);
    totalBought = totalBought + itemQuantity;
    availableCount = select(5, GetMerchantItemInfo(itemMerchantIndex));
  end

  local pattern = "%s x%d";

  if (totalBought > 0) then
    tinsert(purchasedItems, string.format(pattern, itemName, totalBought));
  end

  return purchasedItems;
end

---@param itemID number
---@param quantityToBuy number
---@param maxStackSize number
---@param unitPrice number
---@return number remaning
---@return integer[]
function Module:CanBuyItem(itemID, quantityToBuy, maxStackSize, unitPrice, freeBagSlots)
  local existingStacks = UtilityHub.Helpers.Item:GetItemBagSlots(itemID);
  ---@type number[]
  local buyList = {};
  local fullStacksCount = math.floor(quantityToBuy / maxStackSize);
  local remaining = quantityToBuy;
  local bagSlotsRemaining = freeBagSlots;
  local currentMoney = GetMoney();

  local function UpdateBagAndMoney(amount)
    tinsert(buyList, amount);
    remaining = remaining - amount;
    currentMoney = currentMoney - (unitPrice * amount);
  end

  -- Loop full stacks until there is no more bag slots empty or all full stacks are inserted
  for i = 1, fullStacksCount do
    -- Break if there is no more bags or cant buy a single unit
    if (bagSlotsRemaining == 0 or unitPrice > currentMoney) then
      break;
    end

    local amountPrice = unitPrice * maxStackSize;

    -- If the current stack price is higher than expected current money in the loop
    if (amountPrice > currentMoney) then
      -- In this situation, the maxAffordable is always smaller than maxStackSize
      local maxAffordable = math.floor(GetMoney() / unitPrice);

      if (maxAffordable > 1) then
        UpdateBagAndMoney(maxAffordable);
      end

      break; -- Always break as there is no more money
    else
      bagSlotsRemaining = bagSlotsRemaining - 1;
      UpdateBagAndMoney(maxStackSize);
    end
  end

  -- Then loop the existing stacks until there is no more items remaining to buy, adding only when the stacks are incomplete
  for _, stack in ipairs(existingStacks) do
    if (remaining == 0 or unitPrice > currentMoney) then
      break;
    end

    if (stack.count < maxStackSize) then
      -- Calc the amount to complete the stack size
      local newStackAmount = maxStackSize - stack.count;

      if (newStackAmount > remaining) then
        newStackAmount = remaining;
      end

      local amountPrice = unitPrice * newStackAmount;

      -- If the current stack price is higher than expected current money in the loop
      if (amountPrice > currentMoney) then
        -- In this situation, the? maxAffordable is always smaller than maxStackSize
        local maxAffordable = math.floor(GetMoney() / unitPrice);

        if (maxAffordable > 1) then
          UpdateBagAndMoney(maxAffordable);
        end

        break; -- Always break as there is no more money
      else
        UpdateBagAndMoney(newStackAmount);
      end
    end
  end

  return remaining, buyList;
end

---@param itemData AutoBuyItem
---@return string[]
function Module:FindAndBuyItem(itemData)
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
    return purchasedItems;
  end

  local i = FindMerchantIndex(itemID);

  -- Item doesn't exist in the current merchant
  if (i == nil) then
    return purchasedItems;
  end

  local _, _, price, stackCount = GetMerchantItemInfo(i);
  local maxStackSize = GetMerchantItemMaxStack(i);
  local unitPrice = price / stackCount;

  ---@type number
  local quantityToBuy = 0;
  ---@type number
  local freeBagSlots = UtilityHub.Helpers.Item:GetFreeBagSlots();

  if (itemData.quantity == 1) then
    -- Buy once mode: just buy 1
    quantityToBuy = 1;
  else
    -- Doesnt count the bank items
    local currentCount = C_Item.GetItemCount(itemID, false);
    local deficit = itemData.quantity - currentCount;

    if (deficit > 0) then
      quantityToBuy = deficit;
    end
  end

  -- If we need to buy something
  if (quantityToBuy > 0) then
    local totalCost = unitPrice * quantityToBuy;
    local priceTooHigh = unitPrice >= MERCHANT_HIGH_PRICE_COST;
    local itemName = C_Item.GetItemInfo(itemData.itemLink) or itemData.itemLink;
    local remaning, buyList = Module:CanBuyItem(itemID, quantityToBuy, maxStackSize, unitPrice, freeBagSlots);

    if (remaning == quantityToBuy) then
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Insufficient bag space for %s", itemName)
      );
    elseif (priceTooHigh) then
      UtilityHub.Helpers.Notification:ShowNotification(
        string.format("Price of %s is too high", itemName)
      );
    else
      local boughtItems = Module:BuyItemQuantityListByStack(i, buyList);

      tAppendAll(purchasedItems, boughtItems);
    end
  end

  return purchasedItems;
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
